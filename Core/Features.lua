-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file contains all the code for the new tooltip options

local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local Features = TSM:NewModule("Features", "AceHook-3.0", "AceEvent-3.0")
local private = {isLoaded={vendorBuy=nil, auctionSale=nil, auctionBuy=nil}, lastPurchase=nil, prevLineId=nil, prevLineResult=nil}


-- ============================================================================
-- Module Functions
-- ============================================================================

function Features:OnEnable()
	if TSM.db.global.vendorBuyEnabled then
		Features:SecureHookScript(StackSplitFrame, "OnShow", function() TSMAPI:CreateTimeDelay("featuresSplitStackShowDelay", 0.05, private.HookSplitStack) end)
		Features:SecureHookScript(StackSplitFrame, "OnHide", function() TSMAPI:CreateTimeDelay("featuresSplitStackHideDelay", 0.05, private.UnhookSplitStack) end)
		private.isLoaded.vendorBuy = true
	end
	if TSM.db.global.auctionSaleEnabled then
		ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", private.FilterSystemMsg)
		Features:RegisterEvent("AUCTION_OWNED_LIST_UPDATE", private.OnAuctionOwnedListUpdate)
		private.isLoaded.auctionSale = true
	end
	if TSM.db.global.auctionBuyEnabled then
		TSM:Hook("PlaceAuctionBid", private.OnAuctionBidPlaced, true)
		ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", private.FilterSystemMsg)
		private.isLoaded.auctionBuy = true
	end
end

function Features:DisableAll()
	-- disable all features
	Features:UnhookAll()
	if private.isLoaded.vendorBuy then
		-- disable vendor buy feature
		TSMAPI:CancelFrame("featuresSplitStackShowDelay")
		TSMAPI:CancelFrame("featuresSplitStackHideDelay")
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
		local itemString = TSMAPI:GetItemString(link)
		local name, stackSize, buyout, wasSold = TSMAPI:Select({1, 3, 10, 16}, GetAuctionItemInfo("owner", i))
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
	local name, stackSize, buyout = TSMAPI:Select({1, 3, 10}, GetAuctionItemInfo("list", index))
	if amountPaid == buyout then
		private.lastPurchase = {name=name, link=link, stackSize=stackSize, buyout=buyout, buyout=buyout}
	end
end



-- ============================================================================
-- Common Functions
-- ============================================================================

function private.FilterSystemMsg(_, _, msg, ...)
	local lineID = select(10, ...)
	if lineID ~= private.prevLineId then
		private.prevLineId = lineID
		private.prevLineResult = nil
		local link = TSM.db.char.auctionMessages and TSM.db.char.auctionMessages[msg]
		if private.lastPurchase and msg == format(ERR_AUCTION_WON_S, private.lastPurchase.name) then
			-- we just bought an auction
			private.prevLineResult = format("You won an auction for %sx%d for %s", private.lastPurchase.link, private.lastPurchase.stackSize, TSMAPI:FormatTextMoney(private.lastPurchase.buyout, "|cffffffff"))
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
			private.prevLineResult = format("Your auction of %s has sold for %s!", link, TSMAPI:FormatTextMoney(price, "|cffffffff"))
			if TSM.db.global.soundEnabled then
				if TSM.db.global.auctionSaleSound == "TSM_REGISTER_SOUND" then
					PlaySoundFile("Interface\\AddOns\\TradeSkillMaster_Additions\\register.mp3", "Master")
				else
					PlaySound(TSM.db.global.auctionSaleSound)
				end
			end
			return nil, private.prevLineResult, ...
		else
			return
		end
	end
end