-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file contains code for the AuctionItemDatabase and AuctionRecord objects
local TSM = select(2, ...)


local AuctionRecord2 = setmetatable({}, {
	__call = function(self, ...)
		local new = setmetatable({}, getmetatable(self))
		local arg1 = ...
		if type(arg1) == "table" and arg1.objType == new.objType then
			local copyObj, newKeys = ...
			local temp = {}
			for i, key in ipairs(copyObj.dataKeys) do
				temp[i] = newKeys[key] or copyObj[key]
			end
			new:SetData(unpack(temp))
		else
			new:SetData(...)
		end
		return new
	end,
	
	__index = {
		objType = "AuctionRecord2",
		dataKeys = {"itemLink", "texture", "stackSize", "minBid", "minIncrement", "buyout", "bid", "seller", "timeLeft", "isHighBidder"},
	
		SetData = function(self, ...)
			TSMAPI:Assert(select('#', ...) == #self.dataKeys)
			-- set dataKeys from the passed parameters
			for i, key in ipairs(self.dataKeys) do
				self[key] = select(i, ...)
			end
			-- generate keys from otherKeys which we can
			self.displayedBid = self.bid == 0 and self.minBid or self.bid
			self.itemDisplayedBid = floor(self.displayedBid / self.stackSize)
			self.requiredBid = self.bid == 0 and self.minBid or (self.bid + self.minIncrement)
			self.itemBuyout = (self.buyout > 0 and floor(self.buyout / self.stackSize)) or 0
			self.itemString = TSMAPI:GetItemString(self.itemLink)
			self.baseItemString = TSMAPI:GetBaseItemString(self.itemString)
			local name, itemLevel = TSMAPI:Select({1, 4}, TSMAPI:GetSafeItemInfo(self.itemLink))
			self.name = name
			self.itemLevel = itemLevel or 1
		end,
		
		ValidateIndex = function(self, auctionType, index)
			-- validate the index
			if not auctionType or not index then return end
			local texture, stackSize, minBid, minIncrement, buyout, bid, isHighBidder, seller, seller_full = TSMAPI:Select({2, 3, 8, 9, 10, 11, 12, 14, 15}, GetAuctionItemInfo(auctionType, index))
			local timeLeft = GetAuctionItemTimeLeft(auctionType, index)
			local itemLink = TSMAPI:GetItemLink(TSMAPI:GetItemString(GetAuctionItemLink(auctionType, index))) -- generalize the link
			seller = TSM:GetAuctionPlayer(seller, seller_full) or "?"
			isHighBidder = isHighBidder and true or false
			local testAuction = {itemLink=itemLink, texture=texture, stackSize=stackSize, minBid=minBid, minIncrement=minIncrement, buyout=buyout, bid=bid, seller=seller, timeLeft=timeLeft, isHighBidder=isHighBidder}
			for _, key in ipairs(self.dataKeys) do
				if self[key] ~= testAuction[key] then
					return
				end
			end
			return true
		end,
		
		DoBuyout = function(self, index)
			if self:ValidateIndex("list", index) then
				-- buy the auction
				PlaceAuctionBid("list", index, self.buyout)
				return true
			end
		end,
		
		DoBid = function(self, index, bid)
			if self:ValidateIndex("list", index) then
				TSMAPI:Assert((self.buyout == 0 or bid < self.buyout) and bid >= self.requiredBid)
				-- bid on the auction
				PlaceAuctionBid("list", index, bid)
				return true
			end
		end,
		
		DoCancel = function(self, index)
			if self:ValidateIndex("owner", index) then
				CancelAuction(index)
				return true
			end
		end,
	},
})

local AuctionRecordDatabaseView = setmetatable({}, {
	__call = function(self, database)
		local new = setmetatable({}, getmetatable(self))
		new.database = database
		new._records = {}
		new._sorts = {}
		new._result = {}
		new._lastUpdate = 0
		new._hasResult = nil
		return new
	end,
	
	__index = {
		objType = "AuctionRecordDatabase",
		
		OrderBy = function(self, key, descending)
			tinsert(self._sorts, {key=key, descending=descending})
			self._hasResult = nil
			return self
		end,
		
		SetFilter = function(self, filterFunc)
			self._filterFunc = filterFunc
			self._hasResult = nil
			return self
		end,
		
		CompareRecords = function(self, a, b)
			for _, info in ipairs(self._sorts) do
				local aVal = a[info.key]
				local bVal = b[info.key]
				if info.key == "isHighBidder" then
					aVal = aVal and 1 or 0
					bVal = bVal and 1 or 0
				end
				if aVal > bVal then
					return info.descending and -1 or 1
				elseif aVal < bVal then
					return info.descending and 1 or -1
				end
			end
			return 0
		end,
		
		Execute = function(self)
			-- update the local copy of the results if necessary
			if self.database.updateCounter > self._lastUpdate then
				wipe(self._result)
				for _, record in ipairs(self.database.records) do
					if not self._filterFunc or self._filterFunc(record) then
						tinsert(self._result, record)
					end
				end
				self._lastUpdate = self.database.updateCounter
				self._hasResult = nil
			end
			
			if self._hasResult then return self._result end
			
			-- sort the result
			local function SortHelper(a, b)
				local cmp = self:CompareRecords(a, b)
				if cmp == 0 then
					return tostring(a) < tostring(b)
				end
				return cmp < 0
			end
			sort(self._result, SortHelper)
			self._hasResult = true
			return self._result
		end,
		
		Remove = function(self, index)
			TSMAPI:Assert(self._hasResult)
			self.database:RemoveAuctionRecord(self._result[index])
			tremove(self._result, index)
		end,
	},
})

local AuctionRecordDatabase = setmetatable({}, {
	__call = function(self)
		local new = setmetatable({records={}}, getmetatable(self))
		new.records = {}
		new.updateCounter = 0
		new.marketValueFunc = nil
		return new
	end,
	
	__index = {
		objType = "AuctionRecordDatabase",
		
		InsertAuctionRecord = function(self, ...)
			self.updateCounter = self.updateCounter + 1
			local arg1 = ...
			if type(arg1) == "table" and arg1.objType == "AuctionRecord2" then
				tinsert(self.records, arg1)
			else
				tinsert(self.records, AuctionRecord2(...))
			end
		end,
		
		RemoveAuctionRecord = function(self, toRemove)
			self.updateCounter = self.updateCounter + 1
			for i, record in ipairs(self.records) do
				if record == toRemove then
					tremove(self.records, i)
					return
				end
			end
			TSMAPI:Assert(false) -- shouldn't get here
		end,
		
		CreateView = function(self)
			return AuctionRecordDatabaseView(self)
		end,
		
		SetMarketValueCustomPrice = function(self, marketValueFunc)
			self.marketValueFunc = marketValueFunc
		end,
	},
})

function TSMAPI:NewAuctionRecord2(...)
	return AuctionRecord2(...)
end

function TSMAPI:NewAuctionRecordDatabase()
	return AuctionRecordDatabase()
end



local AuctionRecord = {}
setmetatable(AuctionRecord, {
	__index = {
		Initialize = function(self)
			self.objType = "AuctionRecord"
		end,
		
		SetData = function(self, count, minBid, minIncrement, buyout, bid, highBidder, seller, timeLeft, itemLink, texture)
			self.count = count
			self.minBid = minBid
			self.minIncrement = minIncrement
			self.buyout = buyout
			self.bid = bid
			self.highBidder = highBidder
			self.seller = seller
			self.timeLeft = timeLeft
			self.itemLink = itemLink
			self.texture = texture
		end,
		
		SetParent = function(self, parent)
			self.parent = parent
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
	
	__call = function(self, ...)
		local new = setmetatable(CopyTable(AuctionRecord), getmetatable(AuctionRecord))
		new:Initialize()
		if select('#', ...) == 1 then
			local copyObj = ...
			new:SetData(copyObj.count, copyObj.minBid, copyObj.minIncrement, copyObj.buyout, copyObj.bid, copyObj.highBidder, copyObj.seller, copyObj.timeLeft, copyObj.itemLink, copyObj.texture)
			new:SetParent(copyObj.parent)
		elseif select('#', ...) > 1 then
			new:SetData(...)
		end
		return new
	end,
	
	__eq = function(a, b)
		local params = a.parent and a.parent.recordParams or {"buyout", "count", "seller", "timeLeft", "bid", "minBid", "link"}
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
			local record
			if select('#', ...) == 1 then
				record = ...
			elseif select('#', ...) > 1 then
				record = AuctionRecord(...)
			end
			record.itemLink = record.itemLink or self.itemLink
			record.texture = record.texture or self.texture
			record:SetParent(self)
			self.shouldCompact = true
			if record:IsPlayer() then
				self.playerAuctions = self.playerAuctions + 1
			end
			tinsert(self.records, record)
		end,
		
		-- adds a record
		AddRecord = function(self, record)
			-- TODO: Remove this once Shopping is updated to use AddAuctionRecord
			self:AddAuctionRecord(record)
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
					if record == toRemove then
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

function TSM:NewAuctionRecord(...)
	return AuctionRecord(...)
end