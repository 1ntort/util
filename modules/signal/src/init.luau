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
	_signal: Signal<...any>,
	_func: (...any) -> (),
	_connected: boolean,
}, { __index: typeof(Connection) }>

function Connection.new(signal: Signal<...any>, func: (...any) -> ()): Connection
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

export type Signal<T...> = setmetatable<{
	_connections: { Connection },
	_yieldedThreads: { [Connection]: thread },
	_proxyHandler: RBXScriptConnection?,
}, { __index: {
	connect: (self: Signal<T...>, (T...) -> ()) -> Connection,
	once: (self: Signal<T...>, (T...) -> ()) -> Connection,
	getConnections: (self: Signal<T...>) -> { Connection },
	disconnectAll: (self: Signal<T...>) -> (),
	fire: (self: Signal<T...>, T...) -> (),
	fireDeferred: (self: Signal<T...>, T...) -> (),
	wait: (self: Signal<T...>) -> (),
	destroy: (self: Signal<T...>) -> (),
} }>

function Signal.new<T...>(): Signal<T...>
	local instance: Signal<T...> = setmetatable({} :: any, Signal)

	instance._connections = {}
	instance._yieldedThreads = {}

	return instance
end

function Signal.wrap<T...>(rbxSignal: RBXScriptSignal): Signal<T...>
	local instance: Signal<T...> = Signal.new()
	instance._proxyHandler = rbxSignal:Connect(function(...) instance:fire(...) end)

	return instance
end

function Signal:connect<T...>(func: (T...) -> ()): Connection
	local this: Signal<T...> = self :: any

	local connection: Connection = Connection.new(this, func)
	this._connections[#this._connections + 1] = connection

	return connection
end

function Signal:once<T...>(func: (T...) -> ()): Connection
	local this: Signal<T...> = self :: any

	local connection: Connection
	local done: boolean = false

	connection = this:connect(function(...: T...)
		if done then
			connection:disconnect()
			return
		end

		done = true
		func(...)
	end)
	return connection
end

function Signal:getConnections<T...>(): { Connection }
	local this: Signal<T...> = self :: any

	local new: { Connection } = {}
	for key: number, connection: Connection in this._connections do
		new[key] = connection
	end
	return new
end

function Signal:disconnectAll<T...>()
	local this: Signal<T...> = self :: any

	for _, connection: Connection in this._connections do
		connection:disconnect()
	end
	this._connections = {}
end

function Signal:fire<T...>(...: T...)
	local this: Signal<T...> = self :: any

	for _, connection: Connection in this._connections do
		if connection._connected == false then continue end
		spawnFromPool(connection._func, ...)
	end
end

function Signal:fireDeferred<T...>(...: T...)
	local this: Signal<T...> = self :: any

	for _, connection: Connection in this._connections do
		task.defer(function(...: T...)
			if connection._connected == false then return end
			connection._func(...)
		end, ...)
	end
end

function Signal:wait<T...>()
	local this: Signal<T...> = self :: any

	local thread: thread = coroutine.running()

	local connection: Connection
	connection = this:once(function(...: T...)
		this._yieldedThreads[connection] = nil

		if coroutine.status(thread) == "suspended" then task.spawn(thread) end
	end)

	this._yieldedThreads[connection] = thread
	coroutine.yield()
end

function Signal:destroy<T...>()
	local this: Signal<T...> = self :: any

	this:disconnectAll()
	if this._proxyHandler ~= nil then this._proxyHandler:Disconnect() end
end

return Signal
