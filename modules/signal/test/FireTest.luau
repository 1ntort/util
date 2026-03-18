--!strict
--!optimize 2

local Type = require("./Type")

type Test = Type.Test
type TestData = Type.TestData
type TestResult = Type.TestResult

local test: Test = {
    name = script.Name,
    priority = "MEDIUM",
    run = function(data: TestData): TestResult
        local success: boolean, result: string? = pcall(function()
            data.instance:fire("TEST_ARGUMENT")
            data.instance:fire("ONCE_ARGUMENT")

            return nil
        end)
        return {
            success = success,
            result = result,
        }
    end
}
return test