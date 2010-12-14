-- This module creates and provides API functions for the TSM remote frame.
-- These functions support the table format for building AceGUI pages created by Sapu94.

local TSM = select(2, ...)
local lib = TSMAPI
local private = {functions={}}
local AceGUI = LibStub("AceGUI-3.0")
local version = GetAddOnMetadata("TradeSkillMaster","X-Curse-Packaged-Version") or GetAddOnMetadata("TradeSkillMaster", "Version")

local FRAME_WIDTH = 350
local FRAME_HEIGHT = 430
local MAX_FUNCTIONS = 11


-- ====================================================================== --
-- helper functions for creating the frame

local function CreateRemoteFrame()
	-- Queue Frame GUI
	local frame = CreateFrame("Frame", nil, AuctionFrame)
	frame:SetWidth(FRAME_WIDTH)
	frame:SetHeight(FRAME_HEIGHT)
	frame:SetScript("OnShow", function() private:ShowFunctionPage(0) end)
	frame:SetScript("OnHide", function() private:HideFunctionPage(private.currentPage) end)
	frame:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		tile = false,
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 24,
		insets = {left = 4, right = 4, top = 4, bottom = 4},
	})
	frame:SetBackdropColor(0, 0, 0.05, 1)
	frame:SetBackdropBorderColor(0,0,0.7,1)
	return frame
end

local function ApplyTexturesToButton(btn, isOpenCloseButton)
	local texture = "Interface\\TokenFrame\\UI-TokenFrame-CategoryButton"
	local offset = 6
	if isopenCloseButton then
		offset = 5
		texture = "Interface\\Buttons\\UI-AttributeButton-Encourage-Hilight"
	end
	
	local normalTex = btn:CreateTexture()
	normalTex:SetTexture(texture)
	normalTex:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -offset, -offset)
	normalTex:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", offset, offset)
	
	local disabledTex = btn:CreateTexture()
	disabledTex:SetTexture(texture)
	disabledTex:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -offset, -offset)
	disabledTex:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", offset, offset)
	disabledTex:SetVertexColor(0.1, 0.1, 0.1, 1)
	
	local highlightTex = btn:CreateTexture()
	highlightTex:SetTexture(texture)
	highlightTex:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -offset, -offset)
	highlightTex:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", offset, offset)
	
	local pressedTex = btn:CreateTexture()
	pressedTex:SetTexture(texture)
	pressedTex:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -offset, -offset)
	pressedTex:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", offset, offset)
	pressedTex:SetVertexColor(1, 1, 1, 0.5)
	
	if isopenCloseButton then
		normalTex:SetTexCoord(0.041, 0.975, 0.129, 1.00)
		disabledTex:SetTexCoord(0.049, 0.931, 0.008, 0.121)
		highlightTex:SetTexCoord(0, 1, 0, 1)
		highlightTex:SetVertexColor(0.9, 0.9, 0.9, 0.9)
		pressedTex:SetTexCoord(0.035, 0.981, 0.014, 0.670)
	btn:SetPushedTextOffset(0, -1)
	else
		normalTex:SetTexCoord(0.049, 0.958, 0.066, 0.244)
		disabledTex:SetTexCoord(0.049, 0.958, 0.066, 0.244)
		highlightTex:SetTexCoord(0.005, 0.994, 0.613, 0.785)
		highlightTex:SetVertexColor(0.3, 0.3, 0.3, 0.7)
		pressedTex:SetTexCoord(0.0256, 0.743, 0.017, 0.158)
	btn:SetPushedTextOffset(0, -3)
	end
	
	btn:SetNormalTexture(normalTex)
	btn:SetDisabledTexture(disabledTex)
	btn:SetHighlightTexture(highlightTex)
	btn:SetPushedTexture(pressedTex)
end

local function CreateButton(text, parentFrame, frameName, inheritsFrame, height, baseFont, textSize)
	local btn = CreateFrame("Button", frameName, parentFrame, inheritsFrame)
	btn:SetHeight(height)
	btn:SetText(text)
	btn:GetFontString():SetPoint("CENTER")
	local tFile, tSize = baseFont:GetFont()
	btn:GetFontString():SetFont(tFile, tSize + textSize, "OUTLINE")
	btn:GetFontString():SetTextColor(1, 1, 1, 1)
	return btn
end

local function CreateWhiteButton(text, frameName, inheritsFrame, height, textSize, relativeFrame, topLeftRelativePoint, topLeftXOffset, topRightRelativePoint, topRightXOffset, topYOffset)
	local btn = CreateButton(text, private,frame, frameName, inheritsFrame, height, ZoneTextFont, textSize)
	btn:GetFontString():SetTextColor(1, 1, 1, 1)
	btn:SetPushedTextOffset(0, 0)
	btn:SetBackdrop({
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 24,
		insets = {left = 2, right = 2, top = 4, bottom = 4},
	})
	btn:SetScript("OnDisable", function(self) self:GetFontString():SetTextColor(0.5, 0.5, 0.5, 1) end)
	btn:SetScript("OnEnable", function(self) self:GetFontString():SetTextColor(1, 1, 1, 1) end)	
	btn:SetPoint("TOPLEFT", relativeFrame, topLeftRelativePoint, topLeftXOffset, topYOffset)
	btn:SetPoint("TOPRIGHT", relativeFrame, topRightRelativePoint, topRightXOffset, topYOffset)
	ApplyTexturesToButton(btn)	
	return btn
end

local function CreateOpenCloseButton()
	-- button to open / close the remote frame
	local btn = CreateButton("TSM>>", AuctionFrame, nil, "UIPanelButtonTemplate", 25, GameFontHighlight, 0)
	btn:SetWidth(70)
	btn:SetPoint("TOPRIGHT", -25, -11)
	btn:SetFrameStrata("HIGH")
	btn:SetScript("OnClick", function(self)
		if private.frame:IsVisible() then
			self:SetText("TSM>>")
			private.frame:Hide()
		else
			self:SetText("<<TSM")
			private.frame:Show()
		end
	end)
	btn:SetBackdrop({
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 18,
		insets = {left = 0, right = 0, top = 0, bottom = 0},
	})
	ApplyTexturesToButton(btn, true)
	return btn
end

local function AddVerticalBarTexture(frame)
	local verticalBarTex = frame:CreateTexture()
	verticalBarTex:SetAllPoints(frame)
	verticalBarTex:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
	verticalBarTex:SetTexCoord(0.254, 0.301, 0.083, 0.928)
	verticalBarTex:SetVertexColor(0, 0, 0.7, 1)
end

local function AddHorizontalBarTexture(frame)
	local horizontalBarTex = frame:CreateTexture()
	horizontalBarTex:SetAllPoints(frame)
	horizontalBarTex:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
	horizontalBarTex:SetTexCoord(0.577, 0.683, 0.145, 0.309)
	horizontalBarTex:SetVertexColor(0, 0, 0.7, 1)
end

local function CreateBarFrame(bType, parent, point1, point2)
	local barFrame = CreateFrame("Frame", nil, private.frame)
	barFrame:SetPoint(unpack(point1))
	barFrame:SetPoint(unpack(point2))
	if bType == "vertical" then
		barFrame:SetWidth(8)
		AddVerticalBarTexture(barFrame)
	elseif bType == "horizontal" then
		barFrame:SetHeight(8)
		AddHorizontalBarTexture(barFrame)
	end
	return verticalBarFrame
end

local function CreateIconContainerFrame()
	-- frame to contain all the function icons
	local frame = CreateFrame("Frame", nil, private.frame)
	frame:SetWidth(50)
	frame:SetHeight(FRAME_HEIGHT-12)
	frame:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		tile = false,
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 10,
		insets = {left = 1, right = 1, top = 1, bottom = 1},
	})
	frame:SetBackdropColor(0, 0, 0.05, 1)
	frame:SetBackdropBorderColor(0,0,0.7,1)
	frame:SetPoint("TOPLEFT", private.frame, "TOPRIGHT", -5, -6)
	return frame
end

local function CreateIconFrame(parent)
	-- frame to contain one icon
	local frame = CreateFrame("frame", nil, parent)
	frame:SetWidth(32)
	frame:SetHeight(32)
	frame:SetBackdrop({
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 12,
		insets = {left = 4, right = 4, top = 4, bottom = 4},
	})
	frame:SetBackdropBorderColor(0,0,0.7,1)
	
	return frame
end

local function AddTexture(frame, texture)
	if not texture then return end
	if frame.icon then
		frame.icon:SetTexture(texture)
	else
		local tex = frame:CreateTexture()
		tex:SetTexture(texture)
		tex:SetAllPoints(frame)
		frame.icon = tex
	end
end

local function AddTooltip(frame, tooltip)
	frame:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
			GameTooltip:SetText(tooltip, nil, nil, nil, nil, true)
			GameTooltip:Show()
		end)
	frame:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
end

local function CreateIconFrames()
	local function OnClick(buttonNum, self, button)
		if button == "LeftButton" then
			private:ShowFunctionPage(buttonNum)
		end
	end
	
	local icons = {icon={}}
	
	local container = CreateIconContainerFrame()
	icons.container = container

	for i=1, MAX_FUNCTIONS do
		icons.icon[i] = CreateIconFrame(container)
		icons.icon[i]:SetPoint("TOPLEFT", 10, -8-((i-1)*36))
		icons.icon[i]:SetScript("OnMouseUp", function(...) OnClick(i, ...) end)
	end
	return icons
end

local function UpdateIconFrame()
	for i=1, MAX_FUNCTIONS do
		if private.functions[i] then
			AddTexture(private.frame.icons.icon[i], private.functions[i].icon)
			AddTooltip(private.frame.icons.icon[i], private.functions[i].tooltip)
		end
	end
end

local function ShowDefaultPage(frame)
	if not private.defaultPage then
		local container = CreateFrame("Frame", nil, frame)
		container:SetAllPoints(frame)
		container:SetFrameStrata("HIGH")
		
		local label = container:CreateFontString(nil, "Overlay", "GameFontHighlight")
		local tFile, tSize = GameFontNormalLarge:GetFont()
		label:SetFont(tFile, tSize-1, "OUTLINE")
		label:SetTextColor(1, 1, 1, 1)
		label:SetPoint("TOP", container, "TOP", 0, -20)
		label:SetWidth(300)
		label:SetText("TradeSkillMaster Sidebar")
		container.title = label
		
		local label = container:CreateFontString(nil, "Overlay", "GameFontHighlight")
		local tFile, tSize = GameFontNormalLarge:GetFont()
		label:SetFont(tFile, tSize-4, "OUTLINE")
		label:SetTextColor(1, 1, 1, 1)
		label:SetPoint("TOP", container, "TOP", 0, -50)
		label:SetWidth(300)
		label:SetHeight(100)
		label:SetText("You can use the icons on the right side of this frame to quickly access auction house related functions for TradeSkillMaster modules.")
		container.text = label
		
		private.defaultPage = container
	end
	
	private.defaultPage:Show()
end

local function HideDefaultPage()
	private.defaultPage:Hide()
end


-- ====================================================================== --
-- functions for initializing the addon and creating the frame

function private.AUCTION_HOUSE_SHOW()
	if not private.frame then
		private:Create()
	end
	
	private.frame:SetPoint("TOPLEFT", AuctionFrame, "TOPRIGHT", -4, -10)
end

do
	LibStub("AceEvent-3.0").RegisterEvent(private, "AUCTION_HOUSE_SHOW")
end

function private:Create()
	private.frame = CreateRemoteFrame()
	private.frame.toggleButton = CreateOpenCloseButton()
	private.frame.icons = CreateIconFrames()
	UpdateIconFrame()
	private.frame:Hide()
	
	private.functions[0] = {module="TradeSkillMaster", icon="", tooltip="", show=ShowDefaultPage, hide=HideDefaultPage}
end

function private:ShowFunctionPage(num)
	if not private.functions[num] then return end
	
	private:HideFunctionPage(private.currentPage)
	private.functions[num].show(private.frame)
	private.currentPage = num
end

function private:HideFunctionPage(num)
	if not (num and private.functions[num]) then return end
	
	private.functions[num].hide(private.frame)
end

function lib:RegisterRemoteFunction(moduleName, iconTexture, tooltip, loadFunc, closeFunc)
	if not (moduleName and iconTexture and tooltip and loadFunc and closeFunc) then
		return nil, "invalid args", moduleName, iconTexture, tooltip, loadFunc, closeFunc
	end
	
	if not TSM:CheckModuleName(moduleName) then
		return nil, "No module registered under name: " .. moduleName
	end
	
	tinsert(private.functions, {module=moduleName, icon=iconTexture, tooltip=tooltip, show=loadFunc, hide=closeFunc})
	if private.frame then
		UpdateIconFrame()
	end
end