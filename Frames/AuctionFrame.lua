-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local private = {auctionTabs={}, queuedTabs={}, previousTab=nil, showCallbacks={}}
LibStub("AceEvent-3.0"):Embed(private)
LibStub("AceHook-3.0"):Embed(private)



-- ============================================================================
-- TSMAPI Functions
-- ============================================================================

function TSMAPI:IsAHTabVisible(module)
	if not AuctionFrame or not module then return end
	local tab = private:GetAuctionFrame(_G["AuctionFrameTab"..AuctionFrame.selectedTab])
	return module and tab and tab.module == module
end

function TSMAPI:GetShowAHTabCallback(moduleName)
	TSMAPI:Assert(not private.showCallbacks[moduleName])
	private.showCallbacks[moduleName] = true
	return function()
		for _, tabFrame in ipairs(private.auctionTabs) do
			if tabFrame.module == moduleName then
				tabFrame.tab:Click()
			end
		end
	end
end



-- ============================================================================
-- Module Functions
-- ============================================================================

function TSM:GetAuctionPlayer(player, player_full)
	if not player then return end
	local realm = GetRealmName() or ""
	if player_full and strjoin("-", player, realm) ~= player_full then
		return player_full
	else
		return player
	end
end

function TSM:SetAuctionTabFlashing(moduleName, flashing)
	if not moduleName then return end
	local moduleTab = nil
	for _, tabFrame in ipairs(private.auctionTabs) do
		if tabFrame.module == moduleName then
			moduleTab = tabFrame
			break
		end
	end
	moduleTab.flashing = flashing
	private:UpdateFlashing()
end

local registeredModules = {}
function TSM:RegisterAuctionFunction(moduleName, callbackShow, callbackHide)
	if registeredModules[moduleName] then return end
	registeredModules[moduleName] = true
	if AuctionFrame then
		private:CreateTSMAHTab(moduleName, callbackShow, callbackHide)
	else
		tinsert(private.queuedTabs, {moduleName, callbackShow, callbackHide})
	end
end



-- ============================================================================
-- Tab Creation Function
-- ============================================================================

function private:CreateTSMAHTab(moduleName, callbackShow, callbackHide)
	local auctionTab = CreateFrame("Frame", nil, AuctionFrame)
	auctionTab:Hide()
	auctionTab:SetAllPoints()
	auctionTab:EnableMouse(true)
	auctionTab:SetMovable(true)
	auctionTab:SetScript("OnMouseDown", function() if AuctionFrame:IsMovable() then AuctionFrame:StartMoving() end end)
	auctionTab:SetScript("OnMouseUp", function() if AuctionFrame:IsMovable() then AuctionFrame:StopMovingOrSizing() end end)
	auctionTab.module = moduleName

	TSMAPI.Delay:Cancel("blizzAHLoadedDelay")
	local n = AuctionFrame.numTabs + 1

	local tab = CreateFrame("Button", "AuctionFrameTab"..n, AuctionFrame, "AuctionTabTemplate")
	tab:Hide()
	tab:SetID(n)
	tab:SetText(TSMAPI.Design:GetInlineColor("link2")..moduleName.."|r")
	tab:SetNormalFontObject(GameFontHighlightSmall)
	tab:SetPoint("LEFT", _G["AuctionFrameTab"..n-1], "RIGHT", -8, 0)
	tab:Show()
	PanelTemplates_SetNumTabs(AuctionFrame, n)
	PanelTemplates_EnableTab(AuctionFrame, n)
	auctionTab.tab = tab
	
	local ag = tab:CreateAnimationGroup()
	local flash = ag:CreateAnimation("Alpha")
	flash:SetOrder(1)
	flash:SetChange(-0.5)
	flash:SetDuration(0.5)
	local flash = ag:CreateAnimation("Alpha")
	flash:SetOrder(2)
	flash:SetChange(0.5)
	flash:SetDuration(0.5)
	ag:SetLooping("REPEAT")
	auctionTab.flash = ag
	
	local closeBtn = TSMAPI.GUI:CreateButton(auctionTab, 18)
	closeBtn:SetPoint("BOTTOMRIGHT", -5, 5)
	closeBtn:SetWidth(75)
	closeBtn:SetHeight(24)
	closeBtn:SetText(CLOSE)
	closeBtn:SetScript("OnClick", CloseAuctionHouse)
	
	local iconFrame = CreateFrame("Frame", nil, auctionTab)
	iconFrame:SetPoint("CENTER", auctionTab, "TOPLEFT", 30, -30)
	iconFrame:SetHeight(100)
	iconFrame:SetWidth(100)
	local icon = iconFrame:CreateTexture(nil, "ARTWORK")
	icon:SetAllPoints()
	icon:SetTexture("Interface\\Addons\\TradeSkillMaster\\Media\\TSM_Icon_Big")
	local textFrame = CreateFrame("Frame", nil, auctionTab)
	local iconText = textFrame:CreateFontString(nil, "OVERLAY")
	iconText:SetPoint("CENTER", iconFrame)
	iconText:SetHeight(15)
	iconText:SetJustifyH("CENTER")
	iconText:SetJustifyV("CENTER")
	iconText:SetFont(TSMAPI.Design:GetContentFont("normal"))
	iconText:SetTextColor(165/255, 168/255, 188/255, .7)
	iconText:SetText(TSM._version)
	local ag = iconFrame:CreateAnimationGroup()
	local spin = ag:CreateAnimation("Rotation")
	spin:SetOrder(1)
	spin:SetDuration(2)
	spin:SetDegrees(90)
	local spin = ag:CreateAnimation("Rotation")
	spin:SetOrder(2)
	spin:SetDuration(4)
	spin:SetDegrees(-180)
	local spin = ag:CreateAnimation("Rotation")
	spin:SetOrder(3)
	spin:SetDuration(2)
	spin:SetDegrees(90)
	ag:SetLooping("REPEAT")
	iconFrame:SetScript("OnEnter", function() ag:Play() end)
	iconFrame:SetScript("OnLeave", function() ag:Stop() end)
	
	local moneyText = TSMAPI.GUI:CreateTitleLabel(auctionTab, 16)
	moneyText:SetJustifyH("CENTER")
	moneyText:SetJustifyV("CENTER")
	moneyText:SetPoint("CENTER", auctionTab, "BOTTOMLEFT", 85, 17)
	TSMAPI.Design:SetIconRegionColor(moneyText)
	moneyText.SetMoney = function(self, money)
		self:SetText(TSMAPI:MoneyToString(money, "OPT_ICON"))
	end
	auctionTab.moneyText = moneyText
	
	local moneyTextFrame = CreateFrame("Frame", nil, auctionTab)
	moneyTextFrame:SetAllPoints(moneyText)
	moneyTextFrame:EnableMouse(true)
	moneyTextFrame:SetScript("OnEnter", function(self)
		local currentTotal = 0
		local incomingTotal = 0
		for i=1, GetNumAuctionItems("owner") do
			local count, _, _, _, _, _, _, buyoutAmount = select(3, GetAuctionItemInfo("owner", i))
			if count == 0 then
				incomingTotal = incomingTotal + buyoutAmount
			else
				currentTotal = currentTotal + buyoutAmount
			end
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine("Gold Info:")
		GameTooltip:AddDoubleLine("Player Gold", TSMAPI:MoneyToString(GetMoney(), "OPT_ICON"), 1, 1, 1, 1, 1, 1)
		GameTooltip:AddDoubleLine("Incoming Auction Sales", TSMAPI:MoneyToString(incomingTotal, "OPT_ICON"), 1, 1, 1, 1, 1, 1)
		GameTooltip:AddDoubleLine("Current Auctions Value", TSMAPI:MoneyToString(currentTotal, "OPT_ICON"), 1, 1, 1, 1, 1, 1)
		GameTooltip:Show()
	end)
	moneyTextFrame:SetScript("OnLeave", function()
		GameTooltip:ClearLines()
		GameTooltip:Hide()
	end)
	
	auctionTab:SetScript("OnShow", function(self)
		self:SetAllPoints()
		self.shown = true
		if not self.minimized then
			callbackShow(self)
		end
	end)
	auctionTab:SetScript("OnHide", function(self)
		if not self.minimized and self.shown then
			self.shown = nil
			callbackHide()
		end
	end)
		
	local contentFrame = CreateFrame("Frame", nil, auctionTab)
	contentFrame:SetPoint("TOPLEFT", 4, -80)
	contentFrame:SetPoint("BOTTOMRIGHT", -4, 35)
	TSMAPI.Design:SetContentColor(contentFrame)
	auctionTab.content = contentFrame

	tinsert(private.auctionTabs, auctionTab)
end



-- ============================================================================
-- Initialization Functions
-- ============================================================================

function private:InitializeAHTab()
	if not TSM.db then
		return TSMAPI.Delay:AfterTime(0.2, private.InitializeAHTab)
	end
	for _, info in ipairs(private.queuedTabs) do
		private:CreateTSMAHTab(unpack(info))
	end
	private.queuedTabs = {}
	private:InitializeAuctionFrame()
	private.isInitialized = true
	if AuctionHouse and AuctionHouse:IsVisible() then
		private:AUCTION_HOUSE_SHOW()
	end
end

function private:InitializeAuctionFrame()
	-- make the AH movable if this option is enabled
	AuctionFrame:SetMovable(TSM.db.profile.auctionFrameMovable)
	AuctionFrame:EnableMouse(true)
	AuctionFrame:SetScript("OnMouseDown", function(self) if self:IsMovable() then self:StartMoving() end end)
	AuctionFrame:SetScript("OnMouseUp", function(self) if self:IsMovable() then self:StopMovingOrSizing() end end)
	
	-- scale the auction frame according to the TSM option
	if AuctionFrame:GetScale() ~= 1 and TSM.db.profile.auctionFrameScale == 1 then TSM.db.profile.auctionFrameScale = AuctionFrame:GetScale() end
	AuctionFrame:SetScale(TSM.db.profile.auctionFrameScale)
	
	private:Hook("AuctionFrameTab_OnClick", private.TabChangeHook, true)
	
	-- Makes sure the TSM tab hides correctly when used with addons that hook this function to change tabs (ie Auctionator)
	-- This probably doesn't have to be a SecureHook, but does need to be a Post-Hook.
	private:SecureHook("ContainerFrameItemButton_OnModifiedClick", function()
		local currentTab = _G["AuctionFrameTab"..PanelTemplates_GetSelectedTab(AuctionFrame)]
		if private:IsTSMTab(currentTab) then return end
		private.TabChangeHook(currentTab)
	end)
end



-- ============================================================================
-- Tab Changing Functions
-- ============================================================================

function private.TabChangeHook(selectedTab)
	if private.previousTab and private:IsTSMTab(private.previousTab) then
		-- we are switching away from a TSM tab to a non-TSM tab, so minimize the TSM tab
		private:MinimizeTab(private:GetAuctionFrame(private.previousTab))
	end
	if private:IsTSMTab(selectedTab) then
		private:ShowTab(private:GetAuctionFrame(selectedTab))
	end
	private.previousTab = selectedTab
	private:UpdateFlashing()
end

function private:ShowTab(tab)
	AuctionFrameTopLeft:Hide()
	AuctionFrameTop:Hide()
	AuctionFrameTopRight:Hide()
	AuctionFrameBotLeft:Hide()
	AuctionFrameBot:Hide()
	AuctionFrameBotRight:Hide()
	AuctionFrameMoneyFrame:Hide()
	AuctionFrameCloseButton:Hide()
	private:RegisterEvent("PLAYER_MONEY", "OnEvent")
	
	TSMAPI.Delay:AfterTime(0.1, function() AuctionFrameMoneyFrame:Hide() end)
	
	TSMAPI.Design:SetFrameBackdropColor(tab)
	AuctionFrameTab1:SetPoint("TOPLEFT", AuctionFrame, "BOTTOMLEFT", 15, 1)
	AuctionFrame:SetFrameLevel(1)
	
	tab:Show()
	tab.minimized = nil
	tab.moneyText:SetMoney(GetMoney())
	tab:SetFrameStrata(AuctionFrame:GetFrameStrata())
	tab:SetFrameLevel(AuctionFrame:GetFrameLevel() + 1)
end

function private:MinimizeTab(tab)
	tab.minimized = true
	tab:Hide()
		
	AuctionFrameTopLeft:Show()
	AuctionFrameTop:Show()
	AuctionFrameTopRight:Show()
	AuctionFrameBotLeft:Show()
	AuctionFrameBot:Show()
	AuctionFrameBotRight:Show()
	AuctionFrameMoneyFrame:Show()
	AuctionFrameCloseButton:Show()
	AuctionFrameTab1:SetPoint("TOPLEFT", AuctionFrame, "BOTTOMLEFT", 15, 12)
end



-- ============================================================================
-- Helper Functions
-- ============================================================================

function private:IsTSMTab(auctionTab)
	return private:GetAuctionFrame(auctionTab) and true or false
end

function private:GetAuctionFrame(targetTab)
	for _, tabFrame in ipairs(private.auctionTabs) do
		if tabFrame.tab == targetTab then
			return tabFrame
		end
	end
end

function private:UpdateFlashing()
	for _, tabFrame in ipairs(private.auctionTabs) do
		if tabFrame.flashing and tabFrame.minimized then
			tabFrame.flash:Play()
		else
			tabFrame.flash:Stop()
		end
	end
end



-- ============================================================================
-- Event Handler
-- ============================================================================

function private:OnEvent(event, ...)
	if event == "ADDON_LOADED" then
		-- watch for the AH to be loaded
		local addonName = ...
		if addonName == "Blizzard_AuctionUI" then
			private:UnregisterEvent("ADDON_LOADED")
			private:InitializeAHTab()
		end
	elseif event == "PLAYER_MONEY" then
		-- update player money text on AH tabs
		for _, tab in ipairs(private.auctionTabs) do
			if tab:IsVisible() then
				tab.moneyText:SetMoney(GetMoney())
			end
		end
	elseif event == "AUCTION_HOUSE_SHOW" then
		-- AH frame was shown
		if private.isInitialized then
			if TSM.db.profile.protectAH and not private.hasShown then
				AuctionFrame.Hide = function() end
				HideUIPanel(AuctionFrame)
				AuctionFrame.Hide = nil
				SetUIPanelAttribute(AuctionFrame, "area", nil)
				private.hasShown = true
			end
			if TSM.db.profile.openAllBags then
				OpenAllBags()
			end
			for i = AuctionFrame.numTabs, 1, -1 do
				local text = gsub(_G["AuctionFrameTab"..i]:GetText(), "|r", "")
				text = gsub(text, "|c[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]", "")
				if text == TSM.db.profile.defaultAuctionTab then
					_G["AuctionFrameTab"..i]:Click()
					return
				end
			end
			_G["AuctionFrameTab1"]:Click()
		end
	elseif event == "AUCTION_HOUSE_CLOSED" then
		-- AH frame was closed
		for _, tab in ipairs(private.auctionTabs) do
			tab.minimized = nil
			tab:GetScript("OnHide")(tab)
		end
	end
end

do
	private:RegisterEvent("AUCTION_HOUSE_SHOW", "OnEvent")
	private:RegisterEvent("AUCTION_HOUSE_CLOSED", "OnEvent")
	if IsAddOnLoaded("Blizzard_AuctionUI") then
		private:InitializeAHTab()
	else
		private:RegisterEvent("ADDON_LOADED", "OnEvent")
	end
end