-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file contains code for running stuff in a pseudo-thread

local TSM = select(2, ...)
local private = {threads={}, context=nil, frame=nil}
TSMAPI.Threading = {}

local VALID_THREAD_STATUSES = {
	["READY"] = true,
	["SLEEPING"] = true,
	["WAITING_FOR_MSG"] = true,
	["WAITING_FOR_EVENT"] = true,
	["WAITING_FOR_THREAD"] = true,
	["WAITING_FOR_FUNCTION"] = true,
	["FORCED_YIELD"] = true,
	["RUNNING"] = true,
	["DONE"] = true,
}
local MAX_QUANTUM_MS = 50
local RETURN_VALUE = {}



-- ============================================================================
-- Thread Object
-- ============================================================================

local ThreadDefaults = {
	endTime = 0,
	status = "READY",
	parentThreadId = nil,
	sleepTime = nil,
	eventName = nil,
	eventArgs = nil,
	waitThreadId = nil,
}
local ThreadPrototype = {
	-- sets the name of the thread (useful for debugging)
	SetThreadName = function(self, name)
		local thread = private.threads[self._threadId]
		thread.name = name
	end,

	-- Get the threadId of the thread
	GetThreadId = function(self)
		return self._threadId
	end,
	
	-- Get the threadId of the parent thread
	GetParentThreadId = function(self)
		return self._parentThreadId
	end,
	
	-- Yields if necessary, or if force is set to true
	-- Returns true if a yield was actually performed
	Yield = function(self, force)
		local thread = private.threads[self._threadId]
		if force or thread.status ~= "RUNNING" or debugprofilestop() > thread.endTime then
			-- only change the status if it's currently set to RUNNING
			if thread.status == "RUNNING" then
				thread.status = force and "FORCED_YIELD" or "READY"
			end
			coroutine.yield(RETURN_VALUE)
			if thread.yieldInvariant and not thread.yieldInvariant() then
				-- the invariant check failed so kill this thread
				TSMAPI.Threading:Kill(self._threadId)
				coroutine.yield(RETURN_VALUE)
				TSMAPI:Assert(false) -- we should never get here
			end
			return
		end
	end,
	
	-- Forces the thread to sleep for the specified number of seconds
	Sleep = function(self, seconds)
		local thread = private.threads[self._threadId]
		thread.status = "SLEEPING"
		thread.sleepTime = seconds
		self:Yield()
	end,
	
	-- Gets the number of pending messages for the thread
	GetNumMsgs = function(self)
		local thread = private.threads[self._threadId]
		return #thread.messages
	end,
	
	-- Receives a message which was sent to the thread (blocking until we receive one if we don't currently have any)
	ReceiveMsg = function(self)
		local thread = private.threads[self._threadId]
		if #thread.messages == 0 then
			-- change the status if there's no messages ready
			thread.status = "WAITING_FOR_MSG"
		end
		self:Yield()
		return tremove(thread.messages, 1)
	end,
	
	-- Allows a thread to easily send a message to itself
	SendMsgToSelf = function(self, ...)
		tinsert(private.threads[self._threadId].messages, {...})
	end,
	
	-- Allows a thread to send a message to its parent thread
	SendMsgToParent = function(self, ...)
		TSMAPI:Assert(TSMAPI.Threading:IsValid(self._parentThreadId))
		tinsert(private.threads[self._parentThreadId].messages, {...})
	end,
	
	-- Blocks until the specified event occurs and returns the arguments passed with the event
	WaitForEvent = function(self, event)
		local thread = private.threads[self._threadId]
		thread.status = "WAITING_FOR_EVENT"
		thread.eventName = event
		thread.eventArgs = nil
		private.frame:RegisterEvent(event)
		self:Yield()
		local result = thread.eventArgs
		thread.eventName = nil
		thread.eventArgs = nil
		return unpack(result)
	end,
	
	RegisterEvent = function(self, event, callback)
		local thread = private.threads[self._threadId]
		TSMAPI:Assert(not thread.events[event])
		thread.events[event] = callback
		private.frame:RegisterEvent(event)
		self:Yield()
	end,
	
	UnregisterEvent = function(self, event)
		local thread = private.threads[self._threadId]
		thread.events[event] = nil
	end,
	
	-- Blocks until the specified thread is done running
	WaitForThread = function(self, threadId)
		if not private.threads[threadId] then return self:Yield() end
		local thread = private.threads[self._threadId]
		thread.status = "WAITING_FOR_THREAD"
		thread.waitThreadId = threadId
		self:Yield()
	end,
	
	-- Blocks until the specified function returns a non-false/non-nil value
	WaitForFunction = function(self, func, ...)
		local thread = private.threads[self._threadId]
		-- try the function once before yielding
		local result = private:CheckWaitFunctionResult(func(...))
		if result then return unpack(result) end
		-- do the yield
		thread.status = "WAITING_FOR_FUNCTION"
		thread.waitFunction = func
		thread.waitFunctionArgs = {...}
		self:Yield()
		result = thread.waitFunctionResult
		thread.waitFunction = nil
		thread.waitFunctionArgs = nil
		thread.waitFunctionResult = nil
		return unpack(result)
	end,
	
	-- Sets a function which will be checked before resuming for a yield and will cause the thread to die if false
	SetYieldInvariant = function(self, func)
		local thread = private.threads[self._threadId]
		thread.yieldInvariant = func
	end,
}



-- ============================================================================
-- Scheduler Functions
-- ============================================================================

function private.RunThread(thread, quantum)
	if thread.status ~= "READY" then return true, 0 end
	local startTime = debugprofilestop()
	thread.endTime = startTime + quantum
	thread.status = "RUNNING"
	local noErr, returnVal = coroutine.resume(thread.co, thread.obj)
	local elapsedTime = debugprofilestop() - startTime
	if noErr then
		-- check the returnVal
		TSMAPI:Assert(returnVal == RETURN_VALUE, "Illegal yield.")
	else
		TSMAPI:Assert(false, returnVal, thread.co)
	end
	return not noErr, elapsedTime
end

function private:CheckWaitFunctionResult(...)
	-- if the first of the passed values evaluates to true, return the result
	if ... then
		return {...}
	end
end

function private.threadSort(a, b)
	return private.threads[a].priority > private.threads[b].priority
end
local queue, deadThreads = {}, {}
function private.RunScheduler(_, elapsed)
	-- deal with sleeping threads and try and assign requested quantums
	local totalPriority = 0
	local usedTime = 0
	wipe(queue)
	wipe(deadThreads)
	
	-- go through all the threads and update their status
	for threadId, thread in pairs(private.threads) do
		-- check what the thread status is
		if thread.status == "SLEEPING" then
			thread.sleepTime = thread.sleepTime - elapsed
			if thread.sleepTime <= 0 then
				thread.sleepTime = nil
				thread.status = "READY"
			end
		elseif thread.status == "WAITING_FOR_MSG" then
			if #thread.messages > 0 then
				thread.status = "READY"
			end
		elseif thread.status == "WAITING_FOR_EVENT" then
			TSMAPI:Assert(thread.eventName or thread.eventArgs)
			if thread.eventArgs then
				thread.status = "READY"
			end
		elseif thread.status == "WAITING_FOR_THREAD" then
			TSMAPI:Assert(thread.waitThreadId, "Waiting for thread without waitThreadId set")
			if not private.threads[thread.waitThreadId] then
				thread.status = "READY"
			end
		elseif thread.status == "WAITING_FOR_FUNCTION" then
			TSMAPI:Assert(thread.waitFunction, "Waiting for function without waitFunction set")
			local result = private:CheckWaitFunctionResult(thread.waitFunction(unpack(thread.waitFunctionArgs)))
			if result then
				thread.waitFunctionResult = result
				thread.status = "READY"
			end
		elseif thread.status == "FORCED_YIELD" then
			thread.status = "READY"
		elseif not VALID_THREAD_STATUSES[thread.status] then
			TSMAPI:Assert(false, "Invalid thread status: "..tostring(thread.status))
		end
		
		-- if it's ready to run, add it to the total priority
		if thread.status == "READY" then
			totalPriority = totalPriority + thread.priority
			tinsert(queue, threadId)
		elseif thread.status == "DONE" then
			tinsert(deadThreads, threadId)
		end
	end
	
	-- run the threads that are ready
	-- run lower priority threads first so that higher priority threads can potentially get extra time
	sort(queue, private.threadSort)
	local remainingTime = min(elapsed * 1000 * 0.75, MAX_QUANTUM_MS)
	while remainingTime > 0 and #queue > 0 do
		for i=#queue, 1, -1 do
			local threadId = queue[i]
			local thread = private.threads[threadId]
			local quantum = remainingTime * (thread.priority / totalPriority)
			local hadErr, elapsedTime = private.RunThread(thread, quantum)
			if hadErr then
				TSMAPI.Threading:Kill(threadId)
				tinsert(deadThreads, threadId)
			end
			-- check that it didn't run too long
			local shouldRemove = thread.status ~= "READY"
			if elapsedTime >= quantum then
				if elapsedTime > 1.1 * quantum and elapsedTime > quantum + 1 then
					-- any thread which ran excessively long should be removed from the queue
					shouldRemove = true
				end
				-- just deduct the quantum rather than penalizing other threads for this one going over
				remainingTime = remainingTime - quantum
			else
				-- return 75% of remaining time to other threads
				remainingTime = remainingTime - (0.75 * (quantum - elapsedTime))
				-- this thread did not use all of its time, so remove it from the queue
				shouldRemove = true
			end
			if shouldRemove then
				tremove(queue, i)
			end
		end
	end
	
	for _, threadId in ipairs(deadThreads) do
		private.threads[threadId] = nil
	end
end



-- ============================================================================
-- Helper Functions
-- ============================================================================

function private.ProcessEvent(self, ...)
	local event = ...
	local shouldUnregister = true
	for _, thread in pairs(private.threads) do
		if thread.status == "WAITING_FOR_EVENT" then
			TSMAPI:Assert(thread.eventName or thread.eventArgs)
			if thread.eventName == event then
				thread.eventName = nil -- only trigger the event once
				thread.eventArgs = {...}
			end
		end
		if thread.events[event] then
			thread.events[event](...)
			shouldUnregister = false
		end
	end
	if shouldUnregister then
		self:UnregisterEvent(event)
	end
end

function private:GetThreadFunctionWrapper(func, callback, param)
	return function(self)
		func(self, param)
		TSMAPI.Threading:Kill(self._threadId)
		if callback then
			callback()
		end
		return RETURN_VALUE
	end
end



-- ============================================================================
-- Threading API Functions
-- ============================================================================

function TSMAPI.Threading:Start(func, priority, callback, param, parentThreadId)
	TSMAPI:Assert(func and priority, "Missing required parameter")
	TSMAPI:Assert(priority <= 1 and priority > 0, "Priority must be > 0 and <= 1")
	
	-- get caller info for debugging purposes
	local caller = gsub(debugstack(3, 1, 0):trim(), "\\", "/")
	local startPos, endPos = strfind(caller, "TradeSkillMaster([^/]*)/([^%.]+)%.lua:([0-9]+)")
	if not startPos then
		caller = gsub(debugstack(4, 1, 0):trim(), "\\", "/")
		startPos, endPos = strfind(caller, "TradeSkillMaster([^/]*)/([^%.]+)%.lua:([0-9]+)")
	end
	if not startPos then
		caller = gsub(debugstack(2, 1, 0):trim(), "\\", "/")
		startPos, endPos = strfind(caller, "TradeSkillMaster([^/]*)/([^%.]+)%.lua:([0-9]+)")
	end
	if startPos then
		caller = strsub(caller, startPos, endPos)
	end
	
	local thread = CopyTable(ThreadDefaults)
	thread.messages = {}
	thread.co = coroutine.create(private:GetThreadFunctionWrapper(func, callback, param))
	thread.priority = priority
	thread.caller = caller
	thread.id = {} -- use table reference as unique threadIds
	thread.obj = setmetatable({_threadId=thread.id, _parentThreadId=parentThreadId}, {__index=ThreadPrototype})
	thread.parentThreadId = parentThreadId
	thread.events = {}
	
	private.threads[thread.id] = thread
	return thread.id
end

function TSMAPI.Threading:SendMsg(threadId, data, isSync)
	isSync = isSync or false
	if not TSMAPI.Threading:IsValid(threadId) then return end
	local thread = private.threads[threadId]
	if isSync then
		if thread.status == "WAITING_FOR_MSG" then
			tinsert(thread.messages, 1, data)
			thread.status = "READY"
			private.RunThread(thread, 0)
			return true
		else
			TSM:Print("ERROR: A sync message was not able to be delivered! (threadId=%s)", tostring(threadId))
		end
	else
		tinsert(thread.messages, data)
	end
end

function TSMAPI.Threading:Kill(threadId)
	if not TSMAPI.Threading:IsValid(threadId) then return end
	private.threads[threadId].status = "DONE"
	for tempThreadId, thread in pairs(private.threads) do
		if thread.parentThreadId == threadId then
			-- kill this child thread
			TSMAPI.Threading:Kill(tempThreadId)
		end
	end
end

function TSMAPI.Threading:IsValid(threadId)
	return threadId and private.threads[threadId] and private.threads[threadId].status ~= "DONE"
end



-- ============================================================================
-- Driver Frame
-- ============================================================================

do
	private.frame = CreateFrame("Frame")
	private.frame:SetScript("OnUpdate", private.RunScheduler)
	private.frame:SetScript("OnEvent", private.ProcessEvent)
end



-- ============================================================================
-- Debug Functions
-- ============================================================================

function private:GetCurrentThreadPosition(thread)
	local funcPosition = gsub(debugstack(thread.co, 2, 1, 0):trim(), "\\", "/")
	local startPos, endPos = strfind(funcPosition, "TradeSkillMaster([^/]*)/([^%.]+)%.lua:([0-9]+)")
	if startPos then
		funcPosition = strsub(funcPosition, startPos, endPos)
	end
	if not startPos or strfind(funcPosition, "Core/Threading") then
		funcPosition = gsub(debugstack(thread.co, 3, 1, 0):trim(), "\\", "/")
		startPos, endPos = strfind(funcPosition, "TradeSkillMaster([^/]*)/([^%.]+)%.lua:([0-9]+)")
		if startPos then
			funcPosition = strsub(funcPosition, startPos, endPos)
		end
	end
	return funcPosition
end

function TSMAPI.Debug:GetThreadInfo(returnResult, targetThreadId)
	local threadInfo = {}
	for threadId, thread in pairs(private.threads) do
		if not targetThreadId or threadId == targetThreadId then
			local events = {}
			for event in pairs(thread.events) do
				tinsert(events, event)
			end
			local temp = {}
			temp.funcPosition = private:GetCurrentThreadPosition(thread)
			temp.threadId = tostring(threadId)
			local parentThread = TSMAPI.Threading:IsValid(thread.parentThreadId) and private.threads[thread.parentThreadId]
			temp.parentThreadId = parentThread and parentThread.name or tostring(parentThread)
			temp.status = thread.status
			temp.priority = thread.priority
			temp.sleepTime = thread.sleepTime
			temp.numMessages = #thread.messages
			temp.waitThreadId = tostring(thread.waitThreadId)
			temp.eventName = thread.eventName
			temp.eventArgs = thread.eventArgs
			temp.waitFunction = thread.waitFunction
			temp.waitFunctionArgs = thread.waitFunctionArgs
			temp.waitFunctionResult = thread.waitFunctionResult
			temp.yieldInvariant = tostring(thread.yieldInvariant)
			temp.events = table.concat(events, ", ")
			temp.caller = thread.caller
			threadInfo[thread.name or thread.caller or tostring({})] = temp
		end
	end
	return TSMAPI.Debug:DumpTable(threadInfo, nil, nil, nil, returnResult)
end