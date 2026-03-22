--!strict
--!optimize 2

local name = "signal"

local MODULE = require("./src")
local TestRegistrar = require("../../testrunner/TestRegistrar")
local Type = require("@self/Type")

type TestData = Type.TestData

TestRegistrar.instance():schedule(name)

local data: TestData = {}

TestRegistrar.instance():registerAll(name, data, script.tests)
