-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- TSM's error handler.

local TSM = select(2, ...)
local AceGUI = LibStub("AceGUI-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster")

local private = {}
TSMERRORLOG = {}

local addonSuites = {
	{name="ArkInventory"},
	{name="AtlasLoot"},
	{name="Altoholic"},
	{name="Auc-Advanced", commonTerm="Auc-"},
	{name="Bagnon"},
	{name="BigWigs"},
	{name="Broker"},
	{name="ButtonFacade"},
	{name="Carbonite"},
	{name="DataStore"},
	{name="DBM"},
	{name="Dominos"},
	{name="DXE"},
	{name="EveryQuest"},
	{name="Forte"},
	{name="FuBar"},
	{name="GatherMate2"},
	{name="Grid"},
	{name="LightHeaded"},
	{name="LittleWigs"},
	{name="Masque"},
	{name="MogIt"},
	{name="Odyssey"},
	{name="Overachiever"},
	{name="PitBull4"},
	{name="Prat-3.0"},
	{name="RaidAchievement"},
	{name="Skada"},
	{name="SpellFlash"},
	{name="TidyPlates"},
	{name="TipTac"},
	{name="Titan"},
	{name="UnderHood"},
	{name="WowPro"},
	{name="ZOMGBuffs"},
}

local function StrStartCmp(str, startStr)
	local startLen = strlen(startStr)

	if startLen <= strlen(str) then
		return strsub(str, 1, startLen) == startStr
	end
end


local function GetModule(msg)
	if strfind(msg, "TradeSkillMaster_") then
		return strmatch(msg, "TradeSkillMaster_[A-Za-z]+")
	elseif strfind(msg, "TradeSkillMaster\\") then
		return "TradeSkillMaster"
	end
	return "?"
end

local function ExtractErrorMessage(...)
	local msg = ""

	for _, var in ipairs({...}) do
		local varStr
		local varType = type(var)

		if	varType == "boolean" then
			varStr = var and "true" or "false"
		elseif varType == "table" then
			varStr = "<table>"
		elseif varType == "function" then
			varStr = "<function>"
		elseif var == nil then
			varStr = "<nil>"
		else
			varStr = var
		end

		msg = msg.." "..varStr
	end
	
	return msg
end

local function GetDebugStack(thread, isAssert)
	local stackInfo = {}
	local stack
	if thread then
		stack = debugstack(thread, 1) or debugstack(thread, 2)
	elseif isAssert then
		stack = debugstack(4) or debugstack(3)
	else
		stack = debugstack(2) or debugstack(1)
	end
	
	if type(stack) == "string" then
		local lines = {("\n"):split(stack)}
		for _, line in ipairs(lines) do
			local strStart = strfind(line, "in function")
			if strStart and not strfind(line, "ErrorHandler.lua") then
				line = gsub(line, "`", "<", 1)
				line = gsub(line, "'", ">", 1)
				local inFunction = strmatch(line, "<[^>]*>", strStart)
				if inFunction then
					inFunction = gsub(gsub(inFunction, ".*\\", ""), "<", "")
					if inFunction ~= "" then
						local str = strsub(line, 1, strStart-2)
						str = strsub(str, strfind(str, "TradeSkillMaster") or 1)
						if strfind(inFunction, "`") then
							inFunction = strsub(inFunction, 2, -2)..">"
						end
						str = gsub(str, "TradeSkillMaster", "TSM")
						tinsert(stackInfo, str.." <"..inFunction)
					end
				end
			end
		end
	end
	
	return table.concat(stackInfo, "\n")
end

local function GetAddonList()
	local hasAddonSuite = {}
	local addons = {}
	local addonString = ""
	
	for i = 1, GetNumAddOns() do
		local name, _, _, enabled = GetAddOnInfo(i)
		local version = GetAddOnMetadata(name, "X-Curse-Packaged-Version") or GetAddOnMetadata(name, "Version") or ""
		if enabled then
			local isSuite
		
			for _, addonSuite in ipairs(addonSuites) do
				local commonTerm = addonSuite.commonTerm or addonSuite.name
				
				if StrStartCmp(name, commonTerm) then
					isSuite = commonTerm
					break
				end
			end
			
			if isSuite then
				if not hasAddonSuite[isSuite] then
					tinsert(addons, {name=name, version=version})
					hasAddonSuite[isSuite] = true
				end
			elseif StrStartCmp(name, "TradeSkillMaster") then
				tinsert(addons, {name=gsub(name, "TradeSkillMaster", "TSM"), version=version})
			else
				tinsert(addons, {name=name, version=version})
			end
		end
	end
	
	for i, addonInfo in ipairs(addons) do
		local info = addonInfo.name .. " (" .. addonInfo.version .. ")"
		if i == #addons then
			addonString = addonString .. "    " .. info
		else
			addonString = addonString .. "    " .. info .. "\n"
		end
	end
	
	return addonString
end

function private:ShowError(msg, isVerify)
	if not AceGUI or not TSM.db then
		private.isErrorFrameVisible = true
		-- can't use TSMAPI:CreateTimeDelay here since we can't rely on that being loaded
		C_Timer.After(0.1, function() private:ShowError(msg, isVerify) end)
		return
	end

	local f = AceGUI:Create("TSMWindow")
	f:SetCallback("OnClose", function(self) private.isErrorFrameVisible = false AceGUI:Release(self) end)
	f:SetTitle(L["TradeSkillMaster Error Window"])
	f:SetLayout("Flow")
	f:SetWidth(500)
	f:SetHeight(400)
	
	local l = AceGUI:Create("Label")
	l:SetFullWidth(true)
	l:SetFontObject(GameFontNormal)
	if isVerify then
		l:SetText(L["Looks like TradeSkillMaster has detected an error with your configuration. Please address this in order to ensure TSM remains functional."].."\n"..L["|cffffff00DO NOT report this as an error to the developers.|r If you require assistance with this, make a post on the TSM forums instead."].."|r")
	else
		l:SetText(L["Looks like TradeSkillMaster has encountered an error. Please help the author fix this error by copying the entire error below and following the instructions for reporting lua errors listed here (unless told elsewhere by the author):"].." |cffffff00http://tradeskillmaster.com/site/getting-help|r")
	end
	f:AddChild(l)
	
	local heading = AceGUI:Create("Heading")
	heading:SetText("")
	heading:SetFullWidth(true)
	f:AddChild(heading)
	
	local eb = AceGUI:Create("MultiLineEditBox")
	eb:SetLabel(L["Error Info:"])
	eb:SetMaxLetters(0)
	eb:SetFullWidth(true)
	eb:SetText(msg)
	eb:DisableButton(true)
	eb:SetFullHeight(true)
	eb:SetCallback("OnTextChanged", function(self) self:SetText(msg) end) -- hacky way to make it read-only
	f:AddChild(eb)
	
	f.frame:SetFrameStrata("FULLSCREEN_DIALOG")
	f.frame:SetFrameLevel(100)
	private.isErrorFrameVisible = true
end

function private:IsValidError(...)
	if private.ignoreErrors then return end
	private.ignoreErrors = true
	local msg = ExtractErrorMessage(...):trim()
	private.ignoreErrors = false
	local isTSMError
	if strmatch(msg, "auc%-stat%-wowuction") then
		isTSMError = false
	elseif strmatch(msg, "TradeSkillMaster") then
		isTSMError = true
	elseif strmatch(msg, "^%.%.%.T?r?a?d?e?SkillMaster_[A-Z][a-z]+[\\/]") then 
		-- the first part of the path may get cut off for modules so match at least "SkillMaster_<Module>\"
		isTSMError = true
	else
		isTSMError = false
	end
	return isTSMError and msg or nil
end

function TSMAPI:ConfigVerify(cond, err)
	if cond then return end
	
	private.ignoreErrors = true
	
	tinsert(TSMERRORLOG, err)
	if not private.isErrorFrameVisible then
		TSM:Print(L["Looks like TradeSkillMaster has detected an error with your configuration. Please address this in order to ensure TSM remains functional."])
		private:ShowError(err, true)
	elseif private.isErrorFrameVisible == true then
		TSM:Print(L["Additional error suppressed"])
		private.isErrorFrameVisible = 1
	end
	
	private.ignoreErrors = false
end

local function TSMErrorHandler(msg, thread)
	-- ignore errors while we are handling this error
	private.ignoreErrors = true
	local isAssert = private.isAssert
	private.isAssert = nil
	
	if type(thread) ~= "thread" then thread = nil end
	
	local num
	if thread then
		msg, num = gsub(msg, ".+TradeSkillMaster\\Core\\Threading%.lua:%d+:", "")
	end
	
	local color = "|cff99ffff"
	local color2 = "|cffff1e00"
	local errorMessage = ""
	errorMessage = errorMessage..color.."Addon:|r "..color2..GetModule(msg).."|r\n"
	errorMessage = errorMessage..color.."Message:|r "..msg.."\n"
	errorMessage = errorMessage..color.."Date:|r "..date("%m/%d/%y %H:%M:%S").."\n"
	errorMessage = errorMessage..color.."Client:|r "..GetBuildInfo().."\n"
	errorMessage = errorMessage..color.."Locale:|r "..GetLocale().."\n"
	errorMessage = errorMessage..color.."Stack:|r\n"..GetDebugStack(thread, isAssert).."\n"
	errorMessage = errorMessage..color.."TSM Thread Info:|r\n"..table.concat(TSMAPI.Debug:GetThreadInfo(true), "\n").."\n"
	-- errorMessage = errorMessage..color.."Debug Log:|r\n"..table.concat(TSMAPI.Debug:GetThreadInfo(true), "\n").."\n"
	errorMessage = errorMessage..color.."Addons:|r\n"..GetAddonList().."\n"
	tinsert(TSMERRORLOG, errorMessage)
	if not private.isErrorFrameVisible then
		TSM:Print(L["Looks like TradeSkillMaster has encountered an error. Please help the author fix this error by following the instructions shown."])
		private:ShowError(errorMessage)
	elseif private.isErrorFrameVisible == true then
		TSM:Print(L["Additional error suppressed"])
		private.isErrorFrameVisible = 1
	end

	private.ignoreErrors = false
end

do
	private.origErrorHandler = geterrorhandler()
	seterrorhandler(function(...)
		local msg = private:IsValidError(...)
		if msg then
			local status, ret = pcall(TSMErrorHandler, msg, ...)
			if status then
				return ret
			else
				private.origErrorHandler(...)
			end
		elseif private.origErrorHandler then
			return private.origErrorHandler(...)
		end
	end)
end



function TSMAPI:Assert(cond, err)
	if cond then return cond end
	private.isAssert = true
	error(err or "Assertion failure!", 2)
end

function TSM:SilentAssert(cond, err, thread)
	-- show an error, but don't cause an exception to be thrown
	if cond then return cond end
	private.isAssert = true
	TSMErrorHandler(err or "Assertion failure!", thread)
end

--@debug@
-- Disables TSM's error handler until the game is reloaded.
-- This is mainly used for debugging errors with TSM's error handler and should not be used in actual code.
function TSMAPI.Debug:DisableErrorHandler()
	seterrorhandler(private.origErrorHandler)
end
--@end-debug@