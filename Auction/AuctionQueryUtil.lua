-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file contains code for scanning the auction house
local TSM = select(2, ...)
local private = {threadId=nil, db=nil}



local ITEM_CLASS_LOOKUP = {}
for i, class in ipairs({GetAuctionItemClasses()}) do
	ITEM_CLASS_LOOKUP[class] = {}
	ITEM_CLASS_LOOKUP[class].index = i
	for j, subClass in pairs({GetAuctionItemSubClasses(i)}) do
		ITEM_CLASS_LOOKUP[class][subClass] = j
	end
end

local AuctionCountDatabase = setmetatable({}, {
	__call = function(self)
		local new = setmetatable({}, getmetatable(self))
		new.data = {}
		new.lastScanData = TSMAPI:ModuleAPI("AuctionDB", "lastCompleteScan")
		return new
	end,
	
	__index = {
		objType = "AuctionCountDatabase",
		INDEX_LOOKUP = {itemString=1, numAuctions=2, name=3, quality=4, level=5, class=6, subClass=7},
		
		PopulateData = function(self, threadObj)
			if self.isComplete or not self.lastScanData then return end
			if self.lastPopulateAttempt == time() then return end
			self.lastPopulateAttempt = time()
			self.isComplete = true
			wipe(self.data)
			for itemString, data in pairs(self.lastScanData) do
				if data.minBuyout > 0 then
					TSMAPI:Assert(data.numAuctions)
					local name, _, quality, _, level, class, subClass = TSMAPI:GetSafeItemInfo(itemString)
					if name then
						local classIndex = ITEM_CLASS_LOOKUP[class] and ITEM_CLASS_LOOKUP[class].index or 0
						local subClassIndex = ITEM_CLASS_LOOKUP[class] and ITEM_CLASS_LOOKUP[class][subClass] or 0
						tinsert(self.data, {TSMAPI:GetItemString(itemString), data.numAuctions, strlower(name), quality, level, classIndex, subClassIndex})
					else
						self.isComplete = nil
					end
					threadObj:Yield()
				end
			end
			local sortKeys = {"class", "subClass", "quality", "level", "name"}
			local function SortHelper(a, b)
				for _, key in ipairs(sortKeys) do
					if a[self.INDEX_LOOKUP[key]] ~= b[self.INDEX_LOOKUP[key]] then
						return a[self.INDEX_LOOKUP[key]] < b[self.INDEX_LOOKUP[key]]
					end
				end
				return tostring(a) < tostring(b)
			end
			threadObj:Yield()
			sort(self.data, SortHelper)
		end,
		
		GetNumAuctions = function(self, query)
			TSMAPI:Assert(query.class)
			query.minLevel = query.minLevel or 0
			query.maxLevel = query.maxLevel or math.huge
			query.quality = query.quality or 0
			local count = 0
			local startIndex = 1
			local function CompareFunc(row)
				if row[self.INDEX_LOOKUP.class] == query.class then
					if not query.subClass or row[self.INDEX_LOOKUP.subClass] == query.subClass then
						return 0
					else
						return row[self.INDEX_LOOKUP.subClass] - query.subClass
					end
				else
					return row[self.INDEX_LOOKUP.class] - query.class
				end
			end
			
			-- binary search for starting index
			local low, mid, high = 1, 0, #self.data
			while low <= high do
				mid = floor((low + high) / 2)
				local cmpValue = CompareFunc(self.data[mid])
				if cmpValue == 0 then
					if mid == 1 or CompareFunc(self.data[mid-1]) ~= 0 then
						-- we've found the row we want
						startIndex = mid
						break
					else
						-- we're too high
						high = mid - 1
					end
				elseif cmpValue < 0 then
					-- we're too low
					low = mid + 1
				else
					-- we're too high
					high = mid - 1
				end
			end
			
			for i=startIndex, #self.data do
				local row = self.data[i]
				if CompareFunc(row) ~= 0 then
					break
				end
				if row[self.INDEX_LOOKUP.quality] >= query.quality and row[self.INDEX_LOOKUP.class] == query.class and (not query.subClass or row[self.INDEX_LOOKUP.subClass] == query.subClass) and row[self.INDEX_LOOKUP.level] >= query.minLevel and row[self.INDEX_LOOKUP.level] <= query.maxLevel then
					count = count + row[self.INDEX_LOOKUP.numAuctions]
				end
			end
			return count
		end,
		
		GetNumAuctionsByItem = function(self, itemList)
			local counts = {}
			for _, itemString in ipairs(itemList) do
				counts[itemString] = 0
			end
			for _, row in ipairs(self.data) do
				if counts[row[self.INDEX_LOOKUP.itemString]] then
					counts[row[self.INDEX_LOOKUP.itemString]] = counts[row[self.INDEX_LOOKUP.itemString]] + row[self.INDEX_LOOKUP.numAuctions]
				end
			end
			return counts
		end,
	},
})

function private:GetItemClasses(itemString)
	local class, subClass = TSMAPI:Select({6, 7}, TSMAPI:GetSafeItemInfo(itemString))
	if not class or not ITEM_CLASS_LOOKUP[class] then return end
	return ITEM_CLASS_LOOKUP[class].index, ITEM_CLASS_LOOKUP[class][subClass]
end

function private:NumAuctionsToNumPages(score)
	return max(ceil(score / 50), 1)
end

function private:GetCommonInfo(items)
	local minQuality, minLevel, maxLevel = nil, nil, nil
	for _, itemString in ipairs(items) do
		local name, quality, level = TSMAPI:Select({1, 3, 5}, TSMAPI:GetSafeItemInfo(itemString))
		minQuality = min(minQuality or quality, quality)
		minLevel = min(minLevel or level, level)
		maxLevel = max(maxLevel or level, level)
	end
	return minQuality or 0, minLevel or 0, maxLevel or 0
end

function private.GenerateQueriesThread(self, itemList)
	self:SetThreadName("GENERATE_QUERIES")
	private.db = private.db or AuctionCountDatabase()
	private.db:PopulateData(self)
	local queries = {}
	
	-- get all the item info into the game's cache
	self:Yield()
	self:WaitForItemInfo(itemList, 30)
	
	-- if the DB is not fully populated, just do individual scans
	if not private.db.isComplete then
		TSM:LOG_ERR("Auction count database not complete")
		for _, itemString in ipairs(itemList) do
			if TSMAPI:HasItemInfo(itemString) then
				local query = TSMAPI:GetAuctionQueryInfo(itemString)
				query.items = {itemString}
				tinsert(queries, query)
			end
		end
		private.callback("QUERY_COMPLETE", queries)
		return
	end
	self:Yield()
	
	-- get the number of auctions for all the individual items
	local itemNumAuctions = private.db:GetNumAuctionsByItem(itemList)
	self:Yield()
	
	-- organize by class
	local badItems = {}
	local itemListByClass = {}
	for _, itemString in ipairs(itemList) do
		local classIndex = private:GetItemClasses(itemString)
		if classIndex then
			itemListByClass[classIndex] = itemListByClass[classIndex] or {}
			tinsert(itemListByClass[classIndex], itemString)
		elseif TSMAPI:HasItemInfo(itemString) then
			local query = TSMAPI:GetAuctionQueryInfo(itemString)
			query.items = {itemString}
			tinsert(queries, query)
		else
			badItems[itemString] = true
		end
		self:Yield()
	end
	for classIndex, items in pairs(itemListByClass) do
		local totalPages = {raw=0, class=0, subClass=0}
		local tempQueries = {raw={}, class={}, subClass={}}
		local itemListBySubClass = {}
		-- get the number of pages for this class if we don't group on anything
		for _, itemString in ipairs(items) do
			local score = private:NumAuctionsToNumPages(itemNumAuctions[itemString])
			totalPages.raw = totalPages.raw + score
			local query = TSMAPI:GetAuctionQueryInfo(itemString)
			query.items = {itemString}
			tinsert(tempQueries.raw, query)
			-- group by subClass
			local subClassIndex = select(2, private:GetItemClasses(itemString)) or 0
			itemListBySubClass[subClassIndex] = itemListBySubClass[subClassIndex] or {}
			tinsert(itemListBySubClass[subClassIndex], itemString)
			self:Yield()
		end
		if totalPages.raw > 0 then
			-- get the number of pages if we group by class
			local minQuality, minLevel, maxLevel = private:GetCommonInfo(items)
			totalPages.class = private:NumAuctionsToNumPages(private.db:GetNumAuctions({class=classIndex, quality=minQuality, minLevel=minLevel, maxLevel=maxLevel}))
			tinsert(tempQueries.class, {items=items, name="", class=classIndex, subClass=0, invType=0, quality=minQuality, minLevel=minLevel, maxLevel=maxLevel})
			self:Yield()
		end
		if totalPages.class > 0 then
			-- get the number of pages if we group by class+subClass
			for subClassIndex, items2 in pairs(itemListBySubClass) do
				if subClassIndex == 0 then
					for _, itemString in ipairs(items2) do
						local query = TSMAPI:GetAuctionQueryInfo(itemString)
						query.items = {itemString}
						tinsert(tempQueries.subClass, query)
						totalPages.subClass = totalPages.subClass + 1
					end
				else
					local minQuality, minLevel, maxLevel = private:GetCommonInfo(items2)
					local score = private:NumAuctionsToNumPages(private.db:GetNumAuctions({class=classIndex, subClass=subClassIndex, quality=minQuality, minLevel=minLevel, maxLevel=maxLevel}))
					totalPages.subClass = totalPages.subClass + score
					tinsert(tempQueries.subClass, {items=items2, name="", class=classIndex, subClass=subClassIndex, invType=0, quality=minQuality, minLevel=minLevel, maxLevel=maxLevel})
					self:Yield()
				end
			end
		end
		TSM:LOG_INFO("Scanning %d items by class (%d) would be %d pages and by subclass would be %d pages instead of %d", #items, classIndex, totalPages.class, totalPages.subClass, totalPages.raw)
		totalPages.raw = totalPages.raw > 0 and totalPages.raw or math.huge
		totalPages.class = totalPages.class > 0 and totalPages.class or math.huge
		totalPages.subClass = totalPages.subClass > 0 and totalPages.subClass or math.huge
		local minNumPages = min(totalPages.raw, totalPages.class, totalPages.subClass)
		if minNumPages == totalPages.raw then
			TSM:LOG_INFO("Shouldn't group by anything!")
			for _, query in ipairs(tempQueries.raw) do
				tinsert(queries, query)
			end
		elseif minNumPages == totalPages.class then
			TSM:LOG_INFO("Should group by class")
			for _, query in ipairs(tempQueries.class) do
				tinsert(queries, query)
			end
		elseif minNumPages == totalPages.subClass then
			TSM:LOG_INFO("Should group by subClass")
			for _, query in ipairs(tempQueries.subClass) do
				tinsert(queries, query)
			end
		else
			TSMAPI:Assert(false) -- should never happen
		end
		self:Yield()
	end
	
	-- do a final sanity check to make sure we didn't miss any items
	local haveItems = {}
	for _, itemString in ipairs(itemList) do
		haveItems[itemString] = 0
	end
	for _, query in ipairs(queries) do
		for _, itemString in ipairs(query.items) do
			haveItems[itemString] = haveItems[itemString] + 1
		end
	end
	for itemString, num in pairs(haveItems) do
		TSMAPI:Assert(badItems[itemString] or num == 1)
	end
	private.callback("QUERY_COMPLETE", queries)
end

function private:ThreadDone()
	private.threadId = nil
	private.callback = nil
end

function TSMAPI:GenerateQueries(itemList, callback)
	TSM:StopGeneratingQueries()
	private.callback = callback
	private.threadId = TSMAPI.Threading:Start(private.GenerateQueriesThread, 0.5, private.ThreadDone, itemList)
end

function TSM:StopGeneratingQueries()
	if private.threadId then
		TSMAPI.Threading:Kill(private.threadId)
		private.threadId = nil
		if private.callback then
			private.callback("INTERRUPTED")
		end
		private.callback = nil
	end
end

function TSMAPI:GetAuctionQueryInfo(itemString)
	local name, quality, level = TSMAPI:Select({1, 3, 5}, TSMAPI:GetSafeItemInfo(itemString))
	if not name then return end
	local class, subClass = private:GetItemClasses(itemString)
	return {name=name, minLevel=level, maxLevel=level, invType=0, class=class, subClass=subClass, quality=quality}
end