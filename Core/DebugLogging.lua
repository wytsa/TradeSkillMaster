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
local private = {}
local embeds = {"LOG_TRACE", "LOG_DEBUG", "LOG_INFO", "LOG_WARNING", "LOG_ERROR"}

function DebugLogging:Embed(obj)
	for key, func in pairs(private.embeds) do
		obj[key] = func
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
	local caller = strmatch(debugstack(3, 1, 0), "[A-Za-z]+\.lua:[0-9]+")
	local module = "TSM_Crafting"
	local timeDiff = floor(debugprofilestop()-private.startTime2) / 1000
	print(format("[%10.3f] [%s] %s - %s: %s", timeDiff, severity, module, caller, format(unpack(args))))
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