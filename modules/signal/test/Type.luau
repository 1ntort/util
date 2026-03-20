--!strict

local Signal = require("../src")
local TestType = require("../../../testrunner/TestType")

export type Signal = Signal.Signal
export type Connection = Signal.Connection

export type Test = TestType.Test<TestData>
export type TestFunction = TestType.TestFunction<TestData>
export type TestResult = TestType.TestResult

export type TestData = {
    module: typeof(Signal),
    instance: Signal,
}

return {}