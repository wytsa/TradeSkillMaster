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
local private = {startTime=(debugprofilestop() - (5 * 60 * 60 * 1000)), logs={}}
local embeds = {"LOG_TRACE", "LOG_DEBUG", "LOG_INFO", "LOG_WARNING", "LOG_ERROR"}

function DebugLogging:Embed(obj)
	local name = TSM.Modules:GetName(obj)
	for key, func in pairs(private.embeds) do
		obj[key] = func
	end
	private.logs[TSM.Modules:GetName(obj)] = {}
end

function private:CreateViewer()
	if private.frame then return end
	
	local frameInfo = {
		type = "Frame",
		hidden = true,
		widget = private.frame,
		strata = "DIALOG",
		size = {700, 500},
		points = {{"CENTER"}},
		scripts = {"OnMouseDown", "OnMouseUp"},
		children = {
			{
				type = "Text",
				text = format("TSM Debug Log Viewer"),
				textFont = {TSMAPI.Design:GetContentFont(), 18},
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
				text = "This is where some filters and such will go...",
				points = {{"CENTER", "", "TOP", 0, -39}},
			},
			{
				type = "HLine",
				offset = -54,
			},
			{
				type = "ScrollingTableFrame",
				key = "logST",
				headFontSize = 14,
				stCols = {{name="Time", width=0.11, align="RIGHT"}, {name="Module", width=0.1, align="CENTER"}, {name="Severity", width=0.1, align="CENTER"}, {name="Caller", width=0.2}, {name="Message", width=0.5}},
				stDisableSelection = true,
				points = {{"TOPLEFT", 5, -60}, {"BOTTOMRIGHT", "", -5, 5}},
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
		},
	}
	local frame = TSMAPI:BuildFrame(frameInfo)
	TSMAPI.Design:SetFrameBackdropColor(frame)
	frame:SetMovable(true)
	frame:SetScale(UIParent:GetScale())
	private.frame = frame
end

function TSMAPI.Debug:ShowLogViewer()
	private:CreateViewer()
	private.frame:Show()
	
	-- update ST data
	local stData = {}
	for module, logs in pairs(private.logs) do
		for i, logInfo in ipairs(logs) do
			tinsert(stData, {
				cols = {
					{value = format("%.3f", logInfo.timestamp)},
					{value = logInfo.module},
					{value = logInfo.severity},
					{value = logInfo.caller},
					{value = logInfo.msg},
				},
				timestamp = logInfo.timestamp,
			})
		end
	end
	sort(stData, function(a, b) return a.timestamp < b.timestamp end)
	private.frame.logST:SetData(stData)
end

function TSMAPI.Debug:PrintLogs(module)
	for _, data in ipairs(private.logs[module]) do
		print(format("[%10.3f] [%s] %s - %s: %s", data.timestamp, data.severity, data.module, data.caller, data.msg))
	end
end

function private.LOG(module, severity, ...)
	local args = {...}
	for i=1, #args do
		if type(args[i]) == "boolean" then
			args[i] = args[i] and "T" or "F"
		elseif type(args[i]) ~= "string" and type(args[i]) ~= "number" then
			args[i] = tostring(args[i])
		end
	end
	local caller = strmatch(debugstack(3, 1, 0), "[A-Za-z_]+\.lua:[0-9]+")
	caller = gsub(caller, "TradeSkillMaster", "TSM")
	local timestamp = floor(debugprofilestop()-private.startTime) / 1000
	tinsert(private.logs[module], {severity=severity, module=module, caller=caller, timestamp=timestamp, msg=format(unpack(args))})
end

private.embeds = {
	LOG_TRACE = function(obj, ...)
		private.LOG(TSM.Modules:GetName(obj), "TRACE", ...)
	end,

	LOG_DEBUG = function(obj, ...)
		private.LOG(TSM.Modules:GetName(obj), "DEBUG", ...)
	end,

	LOG_INFO = function(obj, ...)
		private.LOG(TSM.Modules:GetName(obj), "INFO", ...)
	end,

	LOG_WARNING = function(obj, ...)
		private.LOG(TSM.Modules:GetName(obj), "WARNING", ...)
	end,

	LOG_ERROR = function(obj, ...)
		private.LOG(TSM.Modules:GetName(obj), "ERROR", ...)
	end,
}