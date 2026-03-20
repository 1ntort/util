--!strict
--!optimize 2

local name = "signal"

local Signal = require("./src")
local TestRegistrar = require("../../testrunner/TestRegistrar")
local Type = require("@self/Type")

export type Signal = Signal.Signal
export type Connection = Signal.Connection

export type Test = Type.Test
export type TestFunction = Type.TestFunction
export type TestData = Type.TestData
export type TestResult = Type.TestResult

TestRegistrar.instance():schedule(name)

local data: TestData = {
	module = Signal,
	instance = Signal.new(),
}

TestRegistrar.instance():registerAll(name, data, script.tests)