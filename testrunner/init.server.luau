--!strict
--!optimize 2

local EXCLUDED: string | { [string]: boolean } | nil = "-signal"

local TestRegistrar = require("@self/TestRegistrar")
local TestType = require("@self/TestType")

type Registered<TestData> = TestRegistrar.Registered<TestData>
type Test<TestData> = TestType.Test<TestData>
type TestFunction<TestData> = TestType.TestFunction<TestData>
type TestRegistrar = TestRegistrar.TestRegistrar
type TestResult = TestType.TestResult

local function checkExcluded(name: string): boolean
	if EXCLUDED == nil then return false end
	if typeof(EXCLUDED) == "string" then
		if EXCLUDED == "*" then
			return true
		elseif EXCLUDED == name then
			return true
		elseif string.match(EXCLUDED, "^%-%a+") then
			if EXCLUDED == `-{name}` then return false end
			return true
		end
	elseif typeof(EXCLUDED) == "table" then
		if EXCLUDED[name] == true then return true end
	end
	return false
end

local registrar: TestRegistrar = TestRegistrar.instance()
registrar:yield()

for _, registered: Registered<any> in registrar._registered do
	if checkExcluded(registered.name) == true then continue end

	local prefix = `[{string.upper(tostring(registered.name))}]:`
	print("\n\n\n\n\n")

	local tests: { Test<any> } = registered.tests
	table.sort(tests, function(a: Test<any>, b: Test<any>)
		local aPriority = TestType.priorityOrder[a.priority]
		local bPriority = TestType.priorityOrder[b.priority]

		if aPriority ~= bPriority then return aPriority < bPriority end
		return a.name < b.name
	end)

	local passed: number = 0
	local done: number = 0
	local total: number = #tests

	local stopped: boolean = false

	print(`{prefix} tests started`)
	for _, test: Test<any> in tests do
		print(`{prefix} running test '{test.name}'`)
		task.spawn(function()
			local success: boolean, result: TestResult = pcall(test.run, registered.data)
			if stopped == true then return end

			if success == false then
				warn(`{prefix} test '{test.name}' errored; {tostring(result)}`)
			elseif not result.success then
				warn(`{prefix} test '{test.name}' failed; {tostring(result.result)}`)
			else
				print(`{prefix} test '{test.name}' passed`)
				passed += 1
			end

			done += 1
		end)
	end

	task.delay(5, function()
		if done < total then
			stopped = true
			warn(`{prefix} some tests took too long; {done} / {total} done ({passed} passed)`)
		end
	end)

	repeat
		task.wait()
	until stopped == true or done >= total
	if stopped == true then return end
	print(`{prefix} a total of {passed} / {total} tests passed`)
end
