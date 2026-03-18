--!strict
--!optimize 2

local Signal = require("./src")
local Type = require("@self/Type")

export type Signal = Signal.Signal
export type Connection = Signal.Connection

export type Test = Type.Test
export type TestFunction = Type.TestFunction
export type TestData = Type.TestData
export type TestResult = Type.TestResult

local tests: { Test } = {}
for _, module: ModuleScript in script:GetChildren() do
    if module.Name == "Type" then continue end
    tests[#tests + 1] = require(module) :: Test
end

table.sort(tests, function(a: Test, b: Test)
    local aPriority = Type.priorityOrder[a.priority]
    local bPriority = Type.priorityOrder[b.priority]

    if aPriority ~= bPriority then return aPriority < bPriority end
    return a.name < b.name
end)

local testData: TestData = {
    module = Signal,
    instance = Signal.new(),
}

local passed: number = 0
local done: number = 0
local total: number = #tests

print("tests started")
for _, test: Test in tests do
    print(`running test {test.name}`)
    task.spawn(function()
        local success: boolean, result: TestResult = pcall(test.run, testData)

        if success == false then
            warn(`test '{test.name}' errored; {tostring(result)}`)
        elseif not result.success then
            warn(`test '{test.name}' failed; {tostring(result.result)}`)
        else
            print(`test '{test.name}' passed`)
            passed += 1
        end

        done += 1
    end)
end

local stopped: boolean = false
task.delay(5, function()
    if done < total then
        stopped = true
        warn(`some tests took too long; {done} / {total} done ({passed} passed)`)
    end
end)

repeat task.wait() until stopped == true or done >= total
if stopped == true then return end
print(`a total of {passed} / {total} tests passed`)