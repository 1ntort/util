--!strict
--!optimize 2

local Type = require("../Type")

type Test = Type.Test
type TestData = Type.TestData
type TestResult = Type.TestResult

local test: Test = {
	name = script.Name,
	priority = "HIGH",
	run = function(data: TestData): TestResult
		local success: boolean, result: string? = pcall(function()
			local fired: number, correctArgument: boolean = 0, false
			local connection = data.instance:once(function(argument: string)
				fired += 1
				if argument == "TEST_ARGUMENT" then correctArgument = true end
			end)

			task.wait(2)
			connection:disconnect()
			if fired > 1 then error("signal was fired more than once") end
			if correctArgument == false then
				error("signal was fired once, however the incorrect arguments were passed")
			end

			return nil
		end)
		return {
			success = success,
			result = result,
		}
	end,
}
return test
