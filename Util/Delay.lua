-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--          http://www.curse.com/addons/wow/tradeskillmaster_warehousing          --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file contains various delay APIs

local TSM = select(2, ...)

local private = {delays={}, eventFrames={}, frameNumber=0}
TSMAPI:RegisterForTracing(private, "TradeSkillMaster.Delay_private")

do
	local frameNumberTracker = CreateFrame("frame")
	frameNumberTracker:Show()
	frameNumberTracker:SetScript("OnUpdate", function() private.frameNumber = private.frameNumber + 1 end)
end


function private:DelayThread()
	while true do
		if #private.delays > 0 then
			for i=#private.delays, 1, -1 do
				local startFrame = private.frameNumber
				if private.delays[i].endFrame and private.delays[i].endFrame <= private.frameNumber then
					-- the end time has passed
					local callback = private.delays[i].callback
					if private.delays[i].repeatDelay then	
						private.delays[i].endFrame = private.frameNumber + private.delays[i].repeatDelay
					else
						tremove(private.delays, i)
					end
					callback()
				elseif private.delays[i].endTime and private.delays[i].endTime <= GetTime() then
					-- the end time has passed
					local callback = private.delays[i].callback
					if private.delays[i].repeatDelay then	
						private.delays[i].endTime = GetTime() + private.delays[i].repeatDelay
					else
						tremove(private.delays, i)
					end
					callback()
				end
			end
		end
		self:Yield(true)
	end
end

function TSM:StartDelayThread()
	TSMAPI.Threading:Start(private.DelayThread, 0.4)
end

function TSMAPI:CreateTimeDelay(...)
	local label, duration, callback, repeatDelay
	if type(select(1, ...)) == "number" then
		-- use table as label if none specified
		label = {}
		duration, callback, repeatDelay = ...
	else
		label, duration, callback, repeatDelay = ...
	end
	assert(label and type(duration) == "number" and type(callback) == "function" and (not repeatDelay or type(repeatDelay) == "number"), format("invalid args '%s', '%s', '%s', '%s'", tostring(label), tostring(duration), tostring(callback), tostring(repeatDelay)))
	
	for _, delay in ipairs(private.delays) do
		if delay.label == label then
			-- delay is already running, so just return
			return
		end
	end
	
	tinsert(private.delays, {endTime=(GetTime()+duration), callback=callback, label=label, repeatDelay=repeatDelay})
end

function TSMAPI:CreateFrameDelay(...)
	local label, duration, callback, repeatDelay
	if type(select(1, ...)) == "number" then
		-- use table as label if none specified
		label = {}
		duration, callback, repeatDelay = ...
	else
		label, duration, callback, repeatDelay = ...
	end
	assert(label and type(duration) == "number" and type(callback) == "function" and (not repeatDelay or type(repeatDelay) == "number"), format("invalid args '%s', '%s', '%s', '%s'", tostring(label), tostring(duration), tostring(callback), tostring(repeatDelay)))
	
	for _, delay in ipairs(private.delays) do
		if delay.label == label then
			-- delay is already running, so just return
			return
		end
	end
	
	tinsert(private.delays, {endFrame=(private.frameNumber+duration), callback=callback, label=label, repeatDelay=repeatDelay})
end

function TSMAPI:CreateFunctionRepeat(label, callback)
	TSMAPI:CreateTimeDelay(label, 0, callback, 0)
end

function TSMAPI:CancelFrame(label)
	for i, delay in ipairs(private.delays) do
		if delay.label == label then
			tremove(private.delays, i)
			break
		end
	end
end



local function EventFrameOnUpdate(self)
	for event, data in pairs(self.events) do
		if data.eventPending and GetTime() > (data.lastCallback + data.bucketTime) then
			data.eventPending = nil
			data.lastCallback = GetTime()
			data.callback()
		end
	end
end

local function EventFrameOnEvent(self, event)
	self.events[event].eventPending = true
end

local function CreateEventFrame()
	local event = CreateFrame("Frame")
	event:Show()
	event:SetScript("OnEvent", EventFrameOnEvent)
	event:SetScript("OnUpdate", EventFrameOnUpdate)
	event.events = {}
	return event
end

function TSMAPI:CreateEventBucket(event, callback, bucketTime, label)
	local eventFrame
	for _, frame in ipairs(private.eventFrames) do
		if not frame.events[event] then
			eventFrame = frame
			break
		end
	end
	if not eventFrame then
		eventFrame = CreateEventFrame()
		tinsert(private.eventFrames, eventFrame)
	end
	
	eventFrame:RegisterEvent(event)
	eventFrame.events[event] = {callback=callback, bucketTime=bucketTime, lastCallback=0}
	eventFrame.label = label
end