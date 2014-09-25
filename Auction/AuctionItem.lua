-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file contains code for the AuctionItem objects
local TSM = select(2, ...)

local AuctionRecord = {}
setmetatable(AuctionRecord, {
	__index = {
		Initialize = function(self)
			self.objType = "AuctionRecord"
		end,
		
		SetData = function(self, parent, count, minBid, minIncrement, buyout, bid, highBidder, seller, timeLeft)
			self.parent = parent
			self.count = count
			self.minBid = minBid
			self.minIncrement = minIncrement
			self.buyout = buyout
			self.bid = bid
			self.highBidder = highBidder
			self.seller = seller
			self.timeLeft = timeLeft
		end,
		
		IsPlayer = function(self)
			return TSMAPI:IsPlayer(self.seller) or self.parent.alts[self.seller]
		end,
		
		GetPercent = function(self)
			local itemBuyout = self:GetItemBuyout()
			local marketValue = self.parent.marketValue
			if itemBuyout and marketValue then
				return (itemBuyout / marketValue) * 100
			end
		end,
		
		GetDisplayedBid = function(self)
			local displayedBid
			if self.bid == 0 then
				displayedBid = self.minBid
			else
				displayedBid = self.bid
			end
			return displayedBid
		end,
		
		GetRequiredBid = function(self)
			local requiredBid
			if self.bid == 0 then
				requiredBid = self.minBid
			else
				requiredBid = self.bid + self.minIncrement
			end
			return requiredBid
		end,
		
		GetItemBuyout = function(self)
			if not self.buyout or self.buyout == 0 then return end
			return floor(self.buyout / self.count)
		end,
		
		GetItemDisplayedBid = function(self)
			return floor(self:GetDisplayedBid() / self.count)
		end,
		
		GetItemDestroyingBuyout = function(self)
			local itemBuyout = self:GetItemBuyout()
			if itemBuyout then
				return itemBuyout * self.parent.destroyingNum
			end
		end,
		
		GetItemDestroyingDisplayedBid = function(self)
			local itemBid = self:GetItemDisplayedBid()
			if itemBid then
				return itemBid * self.parent.destroyingNum
			end
		end,
	},
	
	__call = function(self, copyObj)
		local new = setmetatable(CopyTable(AuctionRecord), getmetatable(AuctionRecord))
		new:Initialize()
		if copyObj then
			new:SetData(copyObj.parent, copyObj.count, copyObj.minBid, copyObj.minIncrement, copyObj.buyout, copyObj.bid, copyObj.highBidder, copyObj.seller, copyObj.timeLeft)
			new.uniqueID = copyObj.uniqueID
		end
		return new
	end,
	
	__eq = function(a, b)
		local params = a.parent.recordParams
		for _, key in ipairs(params) do
			if type(a[key]) == "function" then
				if a[key](a) ~= b[key](b) then
					return false
				end
			else
				if a[key] ~= b[key] then
					return false
				end
			end
		end
		return true
	end,
	
	__lt = function(a, b)
		local aBuyout = a:GetItemBuyout()
		local bBuyout = b:GetItemBuyout()
		if not aBuyout or aBuyout == 0 then
			return false
		end
		if not bBuyout or bBuyout == 0 then
			return true
		end
		if aBuyout == bBuyout then
			if a.seller == b.seller then
				if a.count == b.count then
					local aBid = a:GetItemDisplayedBid()
					local bBid = b:GetItemDisplayedBid()
					return aBid < bBid
				end
				return a.count < b.count
			end
			return a.seller < b.seller
		end
		return aBuyout < bBuyout
	end,
	
	__lte = function(a, b)
		return a < b or a == b
	end,
})


local AuctionItem = {}
setmetatable(AuctionItem, {
	__index = {
		Initialize = function(self)
			self.objType = "AuctionItem"
			self.itemLink = nil
			self.itemString = nil
			self.itemID = nil
			self.marketValue = nil
			self.playerAuctions = 0
			self.records = {}
			self.alts = {}
			self.recordParams = {"buyout", "count", "seller"}
			self.shouldCompact = true
			self.texture = ""
		end,
		
		-- sets the item (or battle pet's) texture
		SetTexture = function(self, texture)
			self.texture = texture
		end,
		
		-- gets the item (or battle pet's) texture
		GetTexture = function(self)
			return self.texture
		end,
		
		-- sets the alts table used for making other players count as the current player
		SetAlts = function(self, alts)
			self.alts = alts
		end,
		
		-- sets the list of params we care about
		SetRecordParams = function(self, params)
			self.recordParams = params
		end,
		
		-- sets the itemLink
		SetItemLink = function(self, itemLink)
			self.itemLink = itemLink
			self.itemString = nil
			self.itemID = nil
		end,
		
		-- returns the itemString
		GetItemString = function(self)
			self.itemString = self.itemString or TSMAPI:GetItemString(self.itemLink)
			return self.itemString
		end,
		
		-- returns the itemID
		GetItemID = function(self)
			self.itemID = self.itemID or TSMAPI:GetItemID(self.itemLink)
			return self.itemID
		end,
		
		-- sets the destroyingNum
		SetDestroyingNum = function(self, num)
			self.destroyingNum = num
		end,
		
		-- adds a record
		AddAuctionRecord = function(self, ...)
			local record = AuctionRecord()
			record:SetData(self, ...)
			if strfind(self.itemLink, "battlepet") then
				record.uniqueID = table.concat({TSMAPI:Select({2, 3, 4, 5, 6, 7}, (":"):split(self.itemLink))}, ".")
			else
				record.uniqueID = select(9, (":"):split(self.itemLink))
			end
			self:AddRecord(record)
		end,
		
		-- adds a record
		AddRecord = function(self, record)
			self.shouldCompact = true
			if record:IsPlayer() then
				self.playerAuctions = self.playerAuctions + 1
			end
			tinsert(self.records, record)
		end,
		
		-- sets the market value of this item
		SetMarketValue = function(self, value)
			self.marketValue = value
		end,
		
		-- populates the compactRecords table
		PopulateCompactRecords = function(self)
			if self.shouldCompact then
				self.shouldCompact = false
				self.compactRecords = {}
				sort(self.records)
				local currentRecord
				for _, record in ipairs(self.records) do
					local temp = AuctionRecord(record)
					if not currentRecord or temp ~= currentRecord then
						currentRecord = temp
						currentRecord.numAuctions = 1
						currentRecord.totalQuantity = currentRecord.count
						tinsert(self.compactRecords, currentRecord)
					else
						currentRecord.numAuctions = currentRecord.numAuctions + 1
						currentRecord.totalQuantity = currentRecord.totalQuantity + temp.count
					end
				end
			end
		end,
		
		-- removes all records for which shouldFilter(record) returns true
		FilterRecords = function(self, shouldFilter)
			self.shouldCompact = true
			local toRemove = {}
			for index, record in ipairs(self.records) do
				if shouldFilter(record) then
					tinsert(toRemove, index)
				end
			end
			
			for i=#toRemove, 1, -1 do
				self:RemoveRecord(toRemove[i])
			end
		end,
		
		-- removes a record at the given index
		RemoveRecord = function(self, index)
			local toRemove = self.records[index]
			if not toRemove then return end
			self.shouldCompact = true
			
			if self.compactRecords then
				for i, record in ipairs(self.compactRecords) do
					if record ~= toRemove then
						if record.numAuctions > 1 then
							record.numAuctions = record.numAuctions - 1
						else
							tremove(self.compactRecords, i)
						end
						break
					end
				end
			end
			
			if toRemove:IsPlayer() then
				self.playerAuctions = self.playerAuctions - 1
			end
			
			tremove(self.records, index)
		end,
		
		-- adds up all the counts from all the records
		GetTotalItemQuantity = function(self)
			local totalQuantity = 0
			for _, record in ipairs(self.records) do
				totalQuantity = totalQuantity + record.count
			end
			return totalQuantity
		end,
		
		-- counts up the number of items (not auctions) the player has
		GetPlayerItemQuantity = function(self)
			local totalQuantity = 0
			for _, record in ipairs(self.records) do
				if record:IsPlayer() then
					totalQuantity = totalQuantity + record.count
				end
			end
			return totalQuantity
		end,
		
		IsPlayerOnly = function(self)
			for _, record in ipairs(self.records) do
				if not record:IsPlayer() then
					return false
				end
			end
			return true
		end,
	},
	
	__call = function(self, link, texture)
		local new = setmetatable(CopyTable(AuctionItem), getmetatable(AuctionItem))
		new:Initialize()
		if link then
			new:SetItemLink(link)
		end
		if texture then
			new:SetTexture(texture)
		end
		return new
	end,
})

function TSMAPI.AuctionScan:NewAuctionItem(link, texture)
	return AuctionItem(link, texture)
end