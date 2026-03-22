--!strict

local MODULE = require("../src")
local TestType = require("../../../testrunner/TestType")

export type MODULE = MODULE.MODULE

export type Test = TestType.Test<TestData>
export type TestFunction = TestType.TestFunction<TestData>
export type TestResult = TestType.TestResult

export type TestData = {}

return {}
