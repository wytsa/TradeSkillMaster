-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file contains all the code for TSM's standalone features

local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local Features = TSM:NewModule("Features", "AceHook-3.0", "AceEvent-3.0")
local private = {isLoaded={vendorBuy=nil, auctionSale=nil, auctionBuy=nil}, lastPurchase=nil, prevLineId=nil, prevLineResult=nil, twitterHookRegistered=nil, origChatFrame_OnEvent}



-- ============================================================================
-- Module Functions
-- ============================================================================

function Features:OnEnable()
	if TSM.db.global.vendorBuyEnabled then
		Features:SecureHookScript(StackSplitFrame, "OnShow", function() TSMAPI.Delay:AfterTime("featuresSplitStackShowDelay", 0.05, private.HookSplitStack) end)
		Features:SecureHookScript(StackSplitFrame, "OnHide", function() TSMAPI.Delay:AfterTime("featuresSplitStackHideDelay", 0.05, private.UnhookSplitStack) end)
		private.isLoaded.vendorBuy = true
	end
	if TSM.db.global.auctionSaleEnabled then
		ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", private.FilterSystemMsg)
		Features:RegisterEvent("AUCTION_OWNED_LIST_UPDATE", private.OnAuctionOwnedListUpdate)
		private.isLoaded.auctionSale = true
	end
	if TSM.db.global.auctionBuyEnabled then
		Features:Hook("PlaceAuctionBid", private.OnAuctionBidPlaced, true)
		ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", private.FilterSystemMsg)
		private.isLoaded.auctionBuy = true
	end
	if SocialPrefillItemText then
		private:CreateTwitterHooks()
	else
		Features:RegisterEvent("ADDON_LOADED", function()
			if SocialPrefillItemText then
				Features:UnregisterEvent("ADDON_LOADED")
				private:CreateTwitterHooks()
			end
		end)
	end
	
	-- setup BMAH scanning
	Features:RegisterEvent("BLACK_MARKET_ITEM_UPDATE", private.ScanBMAH)
	-- setup auction created / cancelled filtering
	private.origChatFrame_OnEvent = ChatFrame_OnEvent
	ChatFrame_OnEvent = private.ChatFrame_OnEvent
end

function Features:DisableAll()
	-- disable all features
	Features:UnhookAll()
	if private.isLoaded.vendorBuy then
		-- disable vendor buy feature
		TSMAPI.Delay:Cancel("featuresSplitStackShowDelay")
		TSMAPI.Delay:Cancel("featuresSplitStackHideDelay")
		private.isLoaded.vendorBuy = nil
	end
	if private.isLoaded.auctionSale then
		-- disable auction sale feature
		ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SYSTEM", private.FilterSystemMsg)
		Features:UnregisterEvent("AUCTION_OWNED_LIST_UPDATE")
		private.isLoaded.auctionSale = nil
	end
	if private.isLoaded.auctionBuy then
		-- disable auction buy feature
		Features:UnhookAll()
		ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SYSTEM", private.FilterSystemMsg)
		private.isLoaded.auctionBuy = nil
	end
end

function Features:ReloadStatus()
	Features:DisableAll()
	Features:OnEnable()
end



-- ============================================================================
-- Vendor Buy Functions
-- ============================================================================

function private:OnSplit(num)
	-- unhook SplitStack
	private:UnhookSplitStack()
	
	-- call original SplitStack accordingly
	while (num > 0) do
		local stackSize = min(num, StackSplitFrame.maxStack)
		num = num - stackSize
		StackSplitFrame.owner:SplitStack(stackSize)
	end
end

function private:HookSplitStack()
	if StackSplitFrame.owner:GetParent():GetParent() ~= MerchantFrame then return end
	StackSplitFrame._maxStack = StackSplitFrame.maxStack
	StackSplitFrame.maxStack = math.huge
	StackSplitFrame.owner._SplitStack = StackSplitFrame.owner.SplitStack
	StackSplitFrame.owner.SplitStack = private.OnSplit
end

function private:UnhookSplitStack()
	if not StackSplitFrame.owner._SplitStack then return end
	StackSplitFrame.owner.SplitStack = StackSplitFrame.owner._SplitStack
	StackSplitFrame.owner._SplitStack = nil
	StackSplitFrame.maxStack = StackSplitFrame._maxStack
	StackSplitFrame._maxStack = nil
end



-- ============================================================================
-- Auction Sale Functions
-- ============================================================================

function private:OnAuctionOwnedListUpdate()
	wipe(TSM.db.char.auctionPrices)
	wipe(TSM.db.char.auctionMessages)

	local auctionPrices = {}
	for i = 1, GetNumAuctionItems("owner") do
		local link = GetAuctionItemLink("owner", i)
		local itemString = TSMAPI.Item:ToItemString(link)
		local name, stackSize, buyout, wasSold = TSMAPI.Util:Select({1, 3, 10, 16}, GetAuctionItemInfo("owner", i))
		if wasSold == 0 and itemString then
			if buyout and buyout > 0 then
				auctionPrices[link] = auctionPrices[link] or { name = name }
				tinsert(auctionPrices[link], {buyout=buyout, stackSize=stackSize})
			end
		end
	end
	for link, auctions in pairs(auctionPrices) do
		-- make sure all auctions are the same stackSize
		local stackSize = auctions[1].stackSize
		for i = 2, #auctions do
			if stackSize ~= auctions[i].stackSize then
				stackSize = nil
				break
			end
		end
		if stackSize then
			local prices = {}
			for _, data in ipairs(auctions) do
				tinsert(prices, data.buyout)
			end
			sort(prices)
			TSM.db.char.auctionPrices[link] = prices
			TSM.db.char.auctionMessages[format(ERR_AUCTION_SOLD_S, auctions.name)] = link
		end
	end
end



-- ============================================================================
-- Auction Buy Functions
-- ============================================================================

function private.OnAuctionBidPlaced(_, index, amountPaid)
	local link = GetAuctionItemLink("list", index)
	local name, stackSize, buyout = TSMAPI.Util:Select({1, 3, 10}, GetAuctionItemInfo("list", index))
	if amountPaid == buyout then
		private.lastPurchase = {name=name, link=link, stackSize=stackSize, buyout=buyout, buyout=buyout}
	end
end



-- ============================================================================
-- Twitter Functions
-- ============================================================================

-- most of this code is based on Blizzard's code and inspired by the Disarmament addon
local TSM_ITEM_URL_FORMAT = "|cff3b94d9http://tradeskillmaster.com/items/%d|r"
function private:CreateTwitterHooks()
	if private.twitterHookRegistered then return end
	private.twitterHookRegistered = true
	hooksecurefunc("SocialPrefillItemText", function(itemID, earned, context, name, quality)
		if not TSM.db.global.tsmItemTweetEnabled then return end
		if name == nil or quality == nil then
			local ignored
			name, ignored, quality = GetItemInfo(itemID)
		end

		local tsmType, tsmItemId, tsmStackSize, tsmBuyout = strmatch(context or "", "^TSM_([A-Z]+)_(%d+)_(%d+)_(%d+)$")
		tsmItemId = tonumber(tsmItemId)
		tsmStackSize = tonumber(tsmStackSize)
		tsmBuyout = tonumber(tsmBuyout)
		if tsmType and tsmItemId and tsmStackSize and tsmBuyout then
			TSMAPI:Assert(tsmType == "BUY" or tsmType == "SELL")
			local url = format(TSM_ITEM_URL_FORMAT, tsmItemId)
			local text = nil
			if tsmType == "BUY" then
				text = format("I just bought [%s]x%d for %s! %s #TSM3 #warcraft", name, tsmStackSize, TSMAPI:MoneyToString(tsmBuyout, "OPT_TRIM"), url)
			elseif tsmType == "SELL" then
				text = format("I just sold [%s] for %s! %s #TSM3 #warcraft", name, TSMAPI:MoneyToString(tsmBuyout, "OPT_TRIM"), url)
			else
				TSMAPI:Assert(false)
			end
			SocialPostFrame:SetAttribute("settext", text)
		else
			local prefillText = earned and SOCIAL_ITEM_PREFILL_TEXT_EARNED or SOCIAL_ITEM_PREFILL_TEXT_GENERIC
			local r, g, b, colorString = GetItemQualityColor(quality)
			local text = format(SOCIAL_ITEM_PREFILL_TEXT_ALL, prefillText, format("|c%s[%s]|r", colorString, name), format(TSM_ITEM_URL_FORMAT, itemID))
			SocialPostFrame:SetAttribute("settext", text)
		end
	end)
end



-- ============================================================================
-- Passive Features
-- ============================================================================

function private.ChatFrame_OnEvent(self, event, msg, ...)
	-- surpress auction created / cancelled spam
	if event == "CHAT_MSG_SYSTEM" and (msg == ERR_AUCTION_STARTED or msg == ERR_AUCTION_REMOVED) then
		return
	end
	return private.origChatFrame_OnEvent(self, event, msg, ...)
end

function private.ScanBMAH()
	TSM.appDB.realm.bmah = nil
	local items = {}
	for i=1, C_BlackMarket.GetNumItems() do
		local quantity, minBid, minIncr, currBid, numBids, timeLeft, itemLink, bmId = TSMAPI.Util:Select({3, 9, 10, 11, 13, 14, 15, 16}, C_BlackMarket.GetItemInfoByIndex(i))
		local itemID = TSMAPI.Item:ToItemID(itemLink)
		if itemID then
			minBid = floor(minBid/COPPER_PER_GOLD)
			minIncr = floor(minIncr/COPPER_PER_GOLD)
			currBid = floor(currBid/COPPER_PER_GOLD)
			tinsert(items, {bmId, itemID, quantity, timeLeft, minBid, minIncr, currBid, numBids, time()})
		end
	end
	TSM.appDB.realm.blackMarket = items
end



-- ============================================================================
-- Helper Functions
-- ============================================================================

function private.FilterSystemMsg(_, _, msg, ...)
	local lineID = select(10, ...)
	if lineID ~= private.prevLineId then
		private.prevLineId = lineID
		private.prevLineResult = nil
		local link = TSM.db.char.auctionMessages and TSM.db.char.auctionMessages[msg]
		if private.lastPurchase and msg == format(ERR_AUCTION_WON_S, private.lastPurchase.name) then
			-- we just bought an auction
			private.prevLineResult = format("You won an auction for %sx%d for %s", private.lastPurchase.link, private.lastPurchase.stackSize, TSMAPI:MoneyToString(private.lastPurchase.buyout, "|cffffffff"))
			local itemId = TSMAPI.Item:ToItemID(private.lastPurchase.link)
			if C_Social.IsSocialEnabled() and itemId then
				-- add tweet icon
				local context = format("TSM_BUY_%s_%s_%s", itemId, private.lastPurchase.stackSize, private.lastPurchase.buyout)
				private.prevLineResult = private.prevLineResult..Social_GetShareItemLink(itemId, context, true)
			end
			return nil, private.prevLineResult, ...
		elseif link then
			-- we may have just sold an auction
			local price = tremove(TSM.db.char.auctionPrices[link], 1)
			local numAuctions = #TSM.db.char.auctionPrices[link]
			if not price then
				-- couldn't determine the price, so just replace the link
				private.prevLineResult = format(ERR_AUCTION_SOLD_S, link)
				return nil, private.prevLineResult, ...
			end

			if numAuctions == 1 then -- this was the last auction
				TSM.db.char.auctionMessages[msg] = nil
			end
			private.prevLineResult = format("Your auction of %s has sold for %s!", link, TSMAPI:MoneyToString(price, "|cffffffff"))
			TSMAPI:DoPlaySound(TSM.db.global.auctionSaleSound)
			local itemId = TSMAPI.Item:ToItemID(link)
			if C_Social.IsSocialEnabled() and itemId then
				-- add tweet icon
				local context = format("TSM_SELL_%s_1_%s", itemId, price)
				private.prevLineResult = private.prevLineResult..Social_GetShareItemLink(itemId, context, true)
			end
			return nil, private.prevLineResult, ...
		else
			return
		end
	end
end