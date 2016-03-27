-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file contains code used for TSM integration testing

local TSM = select(2, ...)
local Testing = TSM:NewModule("Testing")
local private = {exportedFunctions=TSM.exportedForTesting}



-- ============================================================================
-- Module Functions
-- ============================================================================

function Testing:SlashCommandHandler(arg)
	if arg == "init" then
		private.PrepareScreen()
		Testing:CommsSetup()
		Testing:CommsSend("OK")
	elseif arg == "comms_test" then
		Testing:CommsSend(strrep("0123456789", 1000))
	elseif strmatch(arg, "^dump ") then
		local cmd = strmatch(arg, "^dump (.+)")
		Testing:CommsSend(loadstring(cmd)())
	elseif arg == "reset_profile" then
		TSM.db:ResetProfile()
		Testing:CommsSend("OK")
	elseif strmatch(arg, "^db ") then
		arg = strmatch(arg, "^db (.+)")
		local parts = {(' '):split(arg)}
		if #parts == 1 then
			local keys = {('.'):split(parts[1])}
			local var = TSM.db
			for i=1, #keys do
				var = var[keys[i]]
			end
			Testing:CommsSend(tostring(var))
		elseif #parts == 2 then
			local value = parts[2]
			if value == "true" then
				value = true
			elseif value == "false" then
				value = false
			elseif tonumber(value) then
				value = tonumber(value)
			end
			local keys = {('.'):split(parts[1])}
			local var = TSM.db
			for i=1, #keys - 1 do
				var = var[keys[i]]
			end
			var[keys[#keys]] = value
			Testing:CommsSend("OK")
		end
	elseif strmatch(arg, "^func ") then
		TSM_TEST_INFRA_FUNCTIONS = private.exportedFunctions
		local code = strmatch(arg, "^func (.+)")
		code = format("return TSM_TEST_INFRA_FUNCTIONS.%s", code)
		Testing:CommsSend(loadstring(code)())
		TSM_TEST_INFRA_FUNCTIONS = nil
	elseif strmatch(arg, "^click_button ") then
		local buttonText = strmatch(arg, "^click_button (.+)")
		if private.ClickButtonByText(buttonText) then
			Testing:CommsSend("OK")
		end
	elseif strmatch(arg, "^focus_editbox ") then
		local editboxLabel = strmatch(arg, "^focus_editbox (.+)")
		if private.FocusEditBoxByLabel(editboxLabel) then
			Testing:CommsSend("OK")
		end
	end
end


function private.PrepareScreen()
	-- show a black frame to hide the world
	local testBtn = CreateFrame("Button")
	testBtn:SetNormalTexture("Interface\\Buttons\\WHITE8X8")
	testBtn:SetFrameStrata("BACKGROUND")
	testBtn:SetPoint("TOPLEFT")
	testBtn:SetPoint("BOTTOMRIGHT")
	testBtn:Show()
	testBtn:GetNormalTexture():SetTexture(0, 0, 0, 1)

	-- hide extra frames we don't need
	StaticPopup4:Hide()
	PlayerFrame:Hide()
	MinimapCluster:Hide()
	MainMenuBar:Hide()
	ChatFrame3Tab:Click()
	ChatFrameMenuButton:Hide()
	FriendsMicroButton:Hide()
	ChatFrame3ButtonFrame:Hide()
	ChatFrame1Tab.Show = function() end
	ChatFrame2Tab.Show = function() end
	ChatFrame3Tab.Show = function() end
	ChatFrame1Tab:Hide()
	ChatFrame2Tab:Hide()
	ChatFrame3Tab:Hide()
	BuffFrame:Hide()
end


function private.VisibleFrameIterator(visited, callback, ...)
	for i=1, select('#', ...) do
		local obj = select(i, ...)
		if not visited[obj] then
			visited[obj] = true
			if obj:IsVisible() then
				if callback(obj) then
					return obj
				end
				local found = private.VisibleFrameIterator(visited, callback, obj:GetChildren())
				if found then return found end
			end
		end
	end
end

function private.ClickButtonByText(text)
	if not TSMMainFrame1 then return end
	local function callback(obj)
		return obj:IsObjectType("Button") and obj:GetText() == text
	end
	local btn = private.VisibleFrameIterator({}, callback, TSMMainFrame1:GetChildren())
	if not btn then return end

	btn:Click()
	return true
end

function private.FocusEditBoxByLabel(label)
	if not TSMMainFrame1 then return end
	local function callback(obj)
		return obj:IsObjectType("EditBox") and obj.obj and obj.obj.label and obj.obj.label:GetText() == label
	end
	local editbox = private.VisibleFrameIterator({}, callback, TSMMainFrame1:GetChildren())
	if not editbox then return end

	editbox:SetFocus()
	return true
end
