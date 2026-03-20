--!strict

export type Test<TestData> = {
	name: string,
	priority: TestPriority,
	run: TestFunction<TestData>,
}

export type TestFunction<TestData> = (TestData) -> TestResult

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