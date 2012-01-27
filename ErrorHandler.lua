-- TSM's error handler.

local TSM = select(2, ...)
local AceGUI = LibStub("AceGUI-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster")


local origErrorHandler
local ignoreErrors
local isErrorFrameVisible
TSMERRORLOG = {}

local addonSuites = {
	{name="Auc-Advanced", commonTerm="Auc-"},
	{name="Bagnon"},
	{name="Prat-3.0"},
	{name="DBM"},
	{name="Dominos"},
	{name="Titan"},
}

local function StrStartCmp(str, startStr)
	local startLen = strlen(startStr)

	if startLen <= strlen(str) then
		return strsub(str, 1, startLen) == startStr
	end
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

local function GetDebugStack()
	local stackInfo = {}
	local stackString = ""
	local stack = debugstack(2) or debugstack(1)
	
	if type(stack) == "string" then
		local lines = {("\n"):split(stack)}
		if lines then
			for _, line in ipairs(lines) do
				local fileName, funcName, strStart, strEnd
				
				strStart, strEnd = strfind(line, "\\TradeSkillMaster.*\\[^:]*:[^:]*")
				if strStart then
					fileName = strsub(line, strStart, strEnd)
				end

				strStart, strEnd = strfind(line, "in function `.*\'")
				if strStart then
					funcName = strsub(line, strStart+13, strEnd-1)
					tinsert(stackInfo, {func=funcName, file=fileName})
				end
			end
		end
	end
	
	for i, info in ipairs(stackInfo) do
		local info = (info.file or "") .. " <" .. info.func .. ">"
		if i == #stackInfo then
			stackString = stackString .. "    " .. info
		else
			stackString = stackString .. "    " .. info .. "\n"
		end
	end
	
	return stackString
end

local function GetVariableList(errorMsg)
	local real =
		errorMsg:find("^.-([^\\]+\\)([^\\]-)(:%d+):(.*)$") or
		errorMsg:find("^%[string \".-([^\\]+\\)([^\\]-)\"%](:%d+):(.*)$") or
		errorMsg:find("^%[string (\".-\")%](:%d+):(.*)$") or errorMsg:find("^%[C%]:(.*)$")
		
	local localsTable = {}
	local variableList = ""
	
	local function ProcessLine(line, nextLine)
		local numTabs = strfind(line, "[^ ]")
		if not numTabs or numTabs > 5 then
			return
		end
		
		for i = 1, numTabs do
			line = "  " .. line
		end
		
		if strfind(line, "([ ]*).\*temporary. = ") then
			return
		end
		
		line = gsub(line, "<table> ", "")
		line = gsub(line, "<unnamed> ", "")
		
		if strfind(line, "{") and nextLine and strfind(nextLine, "}") then
			line = line .. "}"
			return line, true
		end
		
		local funcStrStart, funcStrEnd = strfind(line,  "<function>")
		if funcStrStart then
			local fileStart = strfind(line, "\\([^\\]*)[\.lua|\.xml]", funcStrStart)
			local functionInfo
			if fileStart then
				local temp = strfind(line, "AceGUI")
				if temp then
					functionInfo = strsub(line, temp)
				else
					functionInfo = strsub(line, fileStart+1)
				end
			else
				functionInfo = "?"
			end
			line = strsub(line, 1, funcStrEnd+1) .. "(" .. functionInfo .. ")"
		end
		
		return line
	end
	
	local lines = {("\n"):split(debuglocals(real and 4 or 3) or "")}
	local skipLine
	for i, line in ipairs(lines) do
		if skipLine ~= i then
			local processedLine, noNextLine = ProcessLine(line, lines[i+1])
			if noNextLine then
				skipLine = i + 1
			end
			if processedLine then
				variableList = variableList .. processedLine .. "\n"
			end
		end
	end

	return variableList
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

local function ShowError(msg)
	if not AceGUI then
		TSMAPI:CreateTimeDelay("errHandlerShowDelay", 0.1, function()
				if AceGUI and UIParent then
					CancelFrame("errHandlerShowDelay")
					ShowError(msg)
				end
			end, 0.1)
		return
	end

	local f = AceGUI:Create("TSMWindow")
	f:SetCallback("OnClose", function(self) isErrorFrameVisible = false AceGUI:Release(self) end)
	f:SetTitle(L["TradeSkillMaster Error Window"])
	f:SetLayout("Flow")
	f:SetWidth(500)
	f:SetHeight(400)
	
	local l = AceGUI:Create("Label")
	l:SetFullWidth(true)
	l:SetFontObject(GameFontNormal)
	l:SetText(L["Looks like TradeSkillMaster has encountered an error. Please help the author fix this error by copying the entire error below and following the instructions for reporting bugs listed here (unless told elsewhere by the author):"].." |cffffff00http://www.curse.com/addons/wow/tradeskill-master|r")
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
	f:AddChild(eb)
	
	f.frame:SetFrameStrata("FULLSCREEN_DIALOG")
	f.frame:SetFrameLevel(100)
	isErrorFrameVisible = true
end

function TSMAPI:IsValidError(...)
	if ignoreErrors then return end
	ignoreErrors = true
	local msg = ExtractErrorMessage(...)
	ignoreErrors = false
	if not strfind(msg, "TradeSkillMaster") then return end
	return msg
end

local function TSMErrorHandler(msg)
	-- ignore errors while we are handling this error
	ignoreErrors = true
	
	local errorMessage = "|cff99ffff"..L["Date:"].."|r " .. date("%m/%d/%y %H:%M:%S") .. "\n"
	errorMessage = errorMessage .. "|cff99ffff"..L["Message:"].."|r " .. msg .. "\n"
	errorMessage = errorMessage .. "|cff99ffff"..L["Stack:"].."|r\n".. GetDebugStack() .. "\n"
	errorMessage = errorMessage .. "|cff99ffff"..L["Variables:"].."|r\n" .. GetVariableList(msg)
	errorMessage = errorMessage .. "|cff99ffff"..L["Addons:"].."|r\n" .. GetAddonList() .. "\n"
	tinsert(TSMERRORLOG, errorMessage)
	if not isErrorFrameVisible then
		TSM:Print(L["Looks like TradeSkillMaster has encountered an error. Please help the author fix this error by following the instructions shown."])
		ShowError(errorMessage)
	else
		if isErrorFrameVisible == true then
			TSM:Print(L["Additional error suppressed"])
			isErrorFrameVisible = 1
		end
	end

	ignoreErrors = false
end

do
	origErrorHandler = geterrorhandler()
	local errHandlerFrame = CreateFrame("Frame", nil, nil, "TSMErrorHandlerTemplate")
	errHandlerFrame.errorHandler = TSMErrorHandler
	errHandlerFrame.origErrorHandler = origErrorHandler
	seterrorhandler(errHandlerFrame.handler)
end

function TSMAPI:DisableErrorHandler()
	seterrorhandler(origErrorHandler)
end