--!strict

local Signal = require("../src")

export type Signal = Signal.Signal
export type Connection = Signal.Connection

export type Test = {
    name: string,
    priority: TestPriority,
    run: TestFunction,
}

export type TestFunction = (TestData) -> TestResult

export type TestData = {
    module: typeof(Signal),
    instance: Signal,
}

export type TestResult = {
    success: boolean,
    result: string?,
}

export type TestPriority = "LOW" | "MEDIUM" | "HIGH"

return {
    priorityOrder = {
        ["HIGH"] = 1,
        ["MEDIUM"] = 2,
        ["LOW"] = 3,
    } :: { [TestPriority]: number }
}