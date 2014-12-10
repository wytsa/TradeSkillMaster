-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file contains all the code for debug logging

local TSM = select(2, ...)
local DebugLogging = TSM:NewModule("DebugLogging")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local LOG_BUFFER_SIZE = 100
local private = {startDebugTime=debugprofilestop(), startTime=time(), logUpdated=nil, threadId=nil, stackRaise=0, filters={module={}}}


-- a simple circular buffer class
local Buffer = {
	New = function(self, tbl)
		local o = tbl or {}
		o.max = o.max or LOG_BUFFER_SIZE
		o.len = o.len or 0
		o.cursor = o.cursor or 1
		setmetatable(o, self)
		self.__index = self
		if o.max ~= LOG_BUFFER_SIZE then
			-- if max size changes, copy to a new buffer
			local o2 = self:New()
			for val in o:Iterator() do
				o2:Append(val)
			end
			return o2
		end
		return o
	end,
	
	Append = function(self, entry)
		self[self.cursor] = entry
		self.cursor = self.cursor + 1
		if self.cursor == self.max + 1 then
			self.cursor = 1
		end
		if self.len < self.max then
			self.len = self.len + 1
		end
	end,
	
	Get = function(self, index)
		local c = self.cursor - self.len + index - 1
		if c < 1 then
			c = c + self.max
		end
		return self[c]
	end,
	
	Iterator = function(self)
		local i = 0
		return function()
			i = i + 1
			if i <= self.len then return self:Get(i) end
		end
	end,
}

function DebugLogging:OnEnable()
end

function DebugLogging:Embed(obj)
	for key, func in pairs(private.embeds) do
		obj[key] = func
	end
	local moduleName = TSM.Modules:GetName(obj)
	if moduleName == "TradeSkillMaster" then
		moduleName = "TSM (Core)"
	end
	-- the log buffers are circular buffers
	TSM.db.global.debugLogBuffers[moduleName] = Buffer:New(TSM.db.global.debugLogBuffers[moduleName])
end

function private:CreateViewer()
	if private.frame then return end
	
	local frameInfo = {
		type = "Frame",
		hidden = true,
		widget = private.frame,
		strata = "FULLSCREEN_DIALOG",
		size = {900, 400},
		points = {{"BOTTOMRIGHT"}},
		scripts = {"OnMouseDown", "OnMouseUp"},
		children = {
			{
				type = "Text",
				text = format("TSM Debug Log Viewer"),
				textFont = {TSMAPI.Design:GetContentFont(), 18},
				textColor = {0.6, 1, 1, 1},
				points = {{"TOP", "", 0, -3}},
			},
			{
				type = "VLine",
				offset = 0,
				size = {2, 25},
				points = {{"TOPRIGHT", -25, -1}},
			},
			{
				type = "Button",
				key = "closeBtn",
				text = "X",
				textHeight = 18,
				size = {19, 19},
				points = {{"TOPRIGHT", -3, -3}},
				scripts = {"OnClick"},
			},
			{
				type = "HLine",
				offset = -24,
			},
			{
				type = "Text",
				key = "filtersText",
				text = "Filters:",
				justify = {"LEFT", "CENTER"},
				size = {0, 45},
				points = {{"TOPLEFT", "", 5, -29}},
			},
			{
				type = "Dropdown",
				key = "moduleDropdown",
				label = "Module",
				multiselect = true,
				points = {{"TOPLEFT", "filtersText", "TOPRIGHT", 10, 0}},
				scripts = {"OnValueChanged"},
				tooltip = "The module(s) to filter the log on.",
			},
			{
				type = "HLine",
				offset = -79,
			},
			{
				type = "ScrollingTableFrame",
				key = "logST",
				headFontSize = 14,
				stCols = {{name="Timestamp", width=0.17}, {name="Module", width=0.1, align="CENTER"}, {name="Sev", width=0.05, align="CENTER"}, {name="File", width=0.25}, {name="Message", width=0.43}},
				stDisableSelection = true,
				points = {{"TOPLEFT", 5, -85}, {"BOTTOMRIGHT", "", -5, 5}},
				scripts = {"OnEnter", "OnLeave"},
			},
		},
		handlers = {
			OnMouseDown = function(self)
				self:StartMoving()
			end,
			OnMouseUp = function(self)
				self:StopMovingOrSizing()
			end,
			closeBtn = {
				OnClick = function(self)
					self:GetParent():Hide()
				end,
			},
			moduleDropdown = {
				OnValueChanged = function(self, key, value)
					private.filters.module[key] = value
					private.logUpdated = true
				end,
			},
			logST = {
				OnEnter = function(self, data)
					if not data.info then return end
					GameTooltip:SetOwner(self, "ANCHOR_NONE")
					GameTooltip:SetPoint("LEFT", self, "RIGHT")
					local color = TSMAPI.Design:GetInlineColor("link")
					GameTooltip:AddDoubleLine(format("|cff99ffffModule:|r |cffffffff%s|r", data.info.module))
					GameTooltip:AddDoubleLine(format("|cff99ffffSeverity:|r |cffffffff%s|r", data.info.severity))
					GameTooltip:AddDoubleLine(format("|cff99ffffTimestamp:|r |cffffffff%s|r", data.info.timestampStr))
					GameTooltip:AddDoubleLine(format("|cff99ffffFile:|r |cffffffff%s:%s|r", data.info.file, data.info.line))
					GameTooltip:AddDoubleLine(format("|cff99ffffMessage:|r |cffffffff%s|r", data.info.msg))
					GameTooltip:Show()
				end,
				OnLeave = function()
					GameTooltip:Hide()
				end,
			},
		},
	}
	private.frame = TSMAPI:BuildFrame(frameInfo)
	private.frame:SetMovable(true)
	private.frame:SetScale(UIParent:GetScale())
	TSMAPI.Design:SetFrameBackdropColor(private.frame)
	
	-- initialize module filters and dropdown list
	local moduleList = {}
	for name in pairs(TSM.db.global.debugLogBuffers) do
		moduleList[name] = name
		private.filters.module[name] = true
	end
	private.frame.moduleDropdown:SetList(moduleList)
end

function private:ShowLogViewer()
	if private.frame and private.frame:IsVisible() then return end
	private:CreateViewer()
	private.frame:Show()
	
	-- update module filter dropdown
	private.frame.moduleDropdown:SetValue({})
	for name, value in pairs(private.filters.module) do
		private.frame.moduleDropdown:SetItemValue(name, value)
	end
	
	if private.threadId then
		TSMAPI.Threading:Kill(private.threadId)
	end
	private.threadId = TSMAPI.Threading:Start(private.UpdateThread, 0.4, function() private.threadId = nil end)
end

function private.UpdateThread(self)
	while true do
		if not private.frame:IsVisible() then return end
		if private.logUpdated then
			-- update ST data
			local stData = {}
			for module, buffer in pairs(TSM.db.global.debugLogBuffers) do
				for logInfo in buffer:Iterator() do
					if private.filters.module[logInfo.module] then
						tinsert(stData, {
							cols = {
								{value = logInfo.timestampStr},
								{value = logInfo.module},
								{value = logInfo.severity},
								{value = logInfo.file..":"..logInfo.line},
								{value = logInfo.msg},
							},
							info = logInfo,
						})
					end
				end
			end
			sort(stData, function(a, b) return a.info.timestamp < b.info.timestamp end)
			private.frame.logST:SetData(stData)
			private.logUpdated = nil
		end
		self:Sleep(0.1)
	end
end

function DebugLogging:SlashCommandHandler(arg)
	local printUsage = false
	if arg == "view_log" then
		private:ShowLogViewer()
	elseif arg == "enable_log" then
		TSM.db.global.debugLoggingEnabled = true
		TSM:Print("Debug logging enabled")
	elseif arg == "disable_log" then
		TSM.db.global.debugLoggingEnabled = false
		TSM:Print("Debug logging disabled")
	else
		printUsage = true
	end
	if printUsage then
		local chatFrame = TSMAPI:GetChatFrame()
		TSM:Print("Debug Commands:")
		chatFrame:AddMessage("|cffffaa00/tsm debug view_log|r - Show the debug log viewer")
	end
end


function private.LOG(module, severity, ...)
	if not TSM.db.global.debugLoggingEnabled then return end
	if module == "TradeSkillMaster" then
		module = "TSM (Core)"
	end
	local args = {...}
	for i=1, #args do
		if type(args[i]) == "boolean" then
			args[i] = args[i] and "T" or "F"
		elseif type(args[i]) ~= "string" and type(args[i]) ~= "number" then
			args[i] = tostring(args[i])
		end
	end
	local file, line = (":"):split(strmatch(debugstack(3+private.stackRaise, 1, 0), "[A-Za-z_]+\.lua:[0-9]+") or "?:?")
	private.stackRaise = 0
	local timestamp = (debugprofilestop() - private.startDebugTime) / 1000 + private.startTime
	local timestampStr = format("%s.%.03f", date("%Y/%m/%d %H:%M:%S", floor(timestamp)), timestamp%1)
	TSM.db.global.debugLogBuffers[module]:Append({severity=severity, module=module, file=file, line=line, timestamp=timestamp, timestampStr=timestampStr, msg=format(unpack(args))})
	private.logUpdated = true
end

private.embeds = {
	LOG_RAISE_STACK = function()
		-- will look at one level higher in the debug stack next time we log
		private.stackRaise = private.stackRaise + 1
	end,

	LOG_INFO = function(obj, ...)
		private.LOG(TSM.Modules:GetName(obj), "INFO", ...)
	end,

	LOG_WARN = function(obj, ...)
		private.LOG(TSM.Modules:GetName(obj), "WARN", ...)
	end,

	LOG_ERR = function(obj, ...)
		private.LOG(TSM.Modules:GetName(obj), "ERR", ...)
	end,
}