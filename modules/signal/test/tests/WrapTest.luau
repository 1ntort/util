--!strict
--!optimize 2

local ServerStorage = game:GetService("ServerStorage")

local Type = require("../Type")

type Test = Type.Test
type TestData = Type.TestData
type TestResult = Type.TestResult

local test: Test = {
	name = script.Name,
	priority = "LOW",
	run = function(data: TestData): TestResult
		local success: boolean, result: string? = pcall(function()
			local signal = data.module.wrap(ServerStorage.ChildAdded)

			local fired: boolean, correctName: boolean = false, false
			signal:connect(function(instance: Instance)
				fired = true
				if instance.Name == "SIGNAL_TEST_INSTANCE" then correctName = true end
			end)

			local instance = Instance.new("Part")
			instance.Name = "SIGNAL_TEST_INSTANCE"
			instance.Parent = ServerStorage

			repeat
				task.wait()
			until fired == true
			if correctName == false then
				error("wrapped signal was fired, however the incorrect instance was passed")
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
