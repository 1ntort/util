--!strict
--!optimize 2

local freeThreads: { thread } = {}

local function threadBody()
	local func: (...any) -> (), args: { any }
	func, args = coroutine.yield()
	while true do
		local success: boolean, result: string? = pcall(func :: (...any) -> ...any, table.unpack(args))
		if success == false then warn(debug.traceback("error while firing a connection; " .. tostring(result), 2)) end
		freeThreads[#freeThreads + 1] = coroutine.running()
		func, args = coroutine.yield()
	end
end

local function spawnFromPool(func: (...any) -> (), ...: any)
	local thread: thread
	if #freeThreads > 0 then
		thread = freeThreads[#freeThreads]
		freeThreads[#freeThreads] = nil
	else
		thread = coroutine.create(threadBody)
		coroutine.resume(thread)
	end
	coroutine.resume(thread, func, { ... })
end

local Connection = {}
Connection.__index = Connection

export type Connection = setmetatable<{
	_signal: Signal,
	_func: (...any) -> (),
	_connected: boolean,
}, { __index: typeof(Connection) }>

function Connection.new(signal: Signal, func: (...any) -> ()): Connection
	local instance: Connection = setmetatable({} :: any, Connection)

	instance._signal = signal
	instance._func = func
	instance._connected = true

	return instance
end

function Connection:disconnect()
	local this: Connection = self :: any

	this._connected = false
	local index: number? = table.find(this._signal._connections, this)
	if index ~= nil then this._signal._connections[index] = nil end

	local thread: thread = this._signal._yieldedThreads[this]
	if thread ~= nil then
		if coroutine.status(thread) == "suspended" then
			warn(debug.traceback(thread, "thread execution cancelled; connection was disconnected", 2))
			task.cancel(thread)
		end
		this._signal._yieldedThreads[this] = nil
	end
end

local Signal = {}
Signal.__index = Signal

export type Signal = setmetatable<{
	_connections: { Connection },
	_yieldedThreads: { [Connection]: thread },
	_proxyHandler: RBXScriptConnection?,
}, { __index: typeof(Signal) }>

function Signal.new(): Signal
	local instance: Signal = setmetatable({} :: any, Signal)

	instance._connections = {}
	instance._yieldedThreads = {}

	return instance
end

function Signal.wrap(rbxSignal: RBXScriptSignal): Signal
	local instance: Signal = Signal.new()
	instance._proxyHandler = rbxSignal:Connect(function(...) instance:fire(...) end)

	return instance
end

function Signal:connect(func: (...any) -> ()): Connection
	local this: Signal = self :: any

	local connection: Connection = Connection.new(this, func)
	this._connections[#this._connections + 1] = connection

	return connection
end

function Signal:once(func: (...any) -> ()): Connection
	local this: Signal = self :: any

	local connection: Connection
	local done: boolean = false

	connection = this:connect(function(...: any)
		if done then
			connection:disconnect()
			return
		end

		done = true
		func(...)
	end)
	return connection
end

function Signal:getConnections(): { Connection }
	local this: Signal = self :: any

	local new = {}
	for key: number, connection: Connection in this._connections do
		new[key] = connection
	end
	return new
end

function Signal:disconnectAll()
	local this: Signal = self :: any

	for _, connection: Connection in this._connections do
		connection:disconnect()
	end
	this._connections = {}
end

function Signal:fire(...: any)
	local this: Signal = self :: any

	for _, connection: Connection in this._connections do
		if connection._connected == false then continue end
		spawnFromPool(connection._func, ...)
	end
end

function Signal:fireDeferred(...: any)
	local this: Signal = self :: any

	for _, connection: Connection in this._connections do
		task.defer(function(...: any)
			if connection._connected == false then return end
			connection._func(...)
		end, ...)
	end
end

function Signal:wait(): ...any
	local this: Signal = self :: any

	local thread: thread = coroutine.running()

	local connection: Connection
	connection = this:once(function(...: any)
		this._yieldedThreads[connection] = nil

		if coroutine.status(thread) == "suspended" then task.spawn(thread, ...) end
	end)

	this._yieldedThreads[connection] = thread
	return coroutine.yield()
end

function Signal:destroy()
	local this: Signal = self :: any

	this:disconnectAll()
	if this._proxyHandler ~= nil then this._proxyHandler:Disconnect() end
end

return Signal
