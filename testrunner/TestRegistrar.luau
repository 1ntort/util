--!strict
--!optimize 2

local TestType = require("./TestType")

type Test<TestData> = TestType.Test<TestData>

local TestRegistrar = {}
TestRegistrar.__index = TestRegistrar

export type TestRegistrar = setmetatable<{
	_registered: { Registered<any> },
	_names: { [string]: true },
	_scheduled: { [string]: true },
	_expected: number,
	_done: number,
}, { __index: typeof(TestRegistrar) }>

export type Registered<TestData> = {
	name: string,
	tests: { Test<TestData> },
	data: TestData,
}

local globalInstance: TestRegistrar

function TestRegistrar.new(): TestRegistrar
	if globalInstance ~= nil then
		warn("attempted to create another TestRegistrar instance; returning global")
		return globalInstance
	end

	local instance: TestRegistrar = setmetatable({} :: any, TestRegistrar)

	instance._registered = {}
	instance._names = {}
	instance._scheduled = {}
	instance._expected = 0
	instance._done = 0

	globalInstance = instance
	return instance
end

function TestRegistrar.instance(): TestRegistrar return globalInstance or TestRegistrar.new() end

function TestRegistrar:registerAll<TestData>(name: string, data: TestData, testsFolder: Folder)
	local this: TestRegistrar = self :: any

	if this._names[name] == true then
		warn(`'{tostring(name)}' has already been registered`)
		return
	end

	local tests: { Test<TestData> } = {}
	for _, module: ModuleScript in testsFolder:GetChildren() do
		if not module:IsA("ModuleScript") then continue end
		tests[#tests + 1] = require(module) :: Test<TestData>
	end

	this:register({
		name = name,
		tests = tests,
		data = data,
	})
end

function TestRegistrar:register<TestData>(registered: Registered<TestData>)
	local this: TestRegistrar = self :: any

	local add: boolean = true
	if this._scheduled[registered.name] ~= true then
		warn(`'{tostring(registered.name)}' has not been scheduled; continuing`)
		add = false
	end

	if this._names[registered.name] == true then
		warn(`'{tostring(registered.name)}' has already been registered`)
		return
	end

	this._registered[#this._registered + 1] = registered
	this._names[registered.name] = true
	if add == true then
		this._done += 1
	end
end

function TestRegistrar:schedule(name: string)
	local this: TestRegistrar = self :: any

	if this._scheduled[name] == true then warn(`'{tostring(name)}' has already been scheduled`) end

	this._scheduled[name] = true
	this._expected += 1
end

function TestRegistrar:yield()
	local this: TestRegistrar = self :: any

	local stopped: boolean = false
	task.delay(3, function()
		if this._done < this._expected then warn("stopped yielding due to taking over 3 seconds") end
		stopped = true
	end)

	repeat
		task.wait()
	until (this._done >= this._expected and this._done ~= 0 and this._expected ~= 0) or stopped == true
end

return TestRegistrar
