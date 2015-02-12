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


local AuctionCountDatabase = setmetatable({}, {
	__call = function(self)
		local new = setmetatable({}, getmetatable(self))
		new.data = {}
		new.lastScanData = TSMAPI:ModuleAPI("AuctionDB", "lastCompleteScan")
		new:PopulateData()
		return new
	end,
	
	__index = {
		objType = "AuctionCountDatabase",
		INDEX_LOOKUP = {itemID=1, quantity=2, name=3, rarity=4, minLevel=5, class=6, subclass=7},
		
		PopulateData = function(self)
			if self.isComplete then return end
			if self.lastPopulateAttempt == time() then return end
			
			local classLookup, subClassLookup = {}, {}
			for i, class in pairs({GetAuctionItemClasses()}) do
				classLookup[class] = i
				subClassLookup[class] = {}
				for j, subClass in pairs({GetAuctionItemSubClasses(i)}) do
					subClassLookup[class][subClass] = j
				end
			end
			self.lastPopulateAttempt = time()
			self.isComplete = true
			wipe(self.data)
			for itemID, data in pairs(self.lastScanData) do
				if data.quantity then
					local name, _, rarity, _, minLevel, class, subclass = GetItemInfo(itemID)
					if name then
						classIndex = classLookup[class] or 0
						subclassIndex = subClassLookup[class] and subClassLookup[class][subClass] or 0
						tinsert(self.data, {itemID, data.quantity, name, rarity, minLevel, classIndex, subclassIndex})
					else
						self.isComplete = nil
					end
				end
			end
			sort(self.data, function(a,b) return a[self.INDEX_LOOKUP.name] < b[self.INDEX_LOOKUP.name] end)
		end,
		
		GetNumAuctions = function(self, query)
			local count = 0
			for i, row in ipairs(self.data) do
				local isMatch = true
				for key, value in pairs(query) do
					if row[self.INDEX_LOOKUP[key]] ~= value then
						isMatch = false
						break
					end
				end
				if isMatch then
					count = count + row[self.INDEX_LOOKUP.quantity]
				end
			end
			return count
		end,
	},
})

function TSMTEST()
	local st = debugprofilestop()
	local db = AuctionCountDatabase()
	
	print("----------RARITY----------")
	for i=0, 5 do
		print(i, db:GetNumAuctions({rarity=i}))
	end
	print("-----------CLASS-----------")
	for i=0, 10 do
		print(i, db:GetNumAuctions({class=i}))
	end
	print(db:GetNumAuctions({class=2, rarity=3}))
	print(debugprofilestop()-st)
end

local ITEM_CLASS_LOOKUP = {}
for i, class in ipairs({GetAuctionItemClasses()}) do
	ITEM_CLASS_LOOKUP[class] = {}
	ITEM_CLASS_LOOKUP[class].index = i
	for j, subclass in pairs({GetAuctionItemSubClasses(i)}) do
		ITEM_CLASS_LOOKUP[class][subclass] = j
	end
end

function private:GetItemClasses(itemString)
	local class, subClass = TSMAPI:Select({6, 7}, TSMAPI:GetSafeItemInfo(itemString))
	if not class or not ITEM_CLASS_LOOKUP[class] then return end
	return ITEM_CLASS_LOOKUP[class].index, ITEM_CLASS_LOOKUP[class][subClass]
end

function TSMAPI:GetAuctionQueryInfo(itemString)
	local name, rarity, minLevel = TSMAPI:Select({1, 3, 5}, TSMAPI:GetSafeItemInfo(itemString))
	if not name then return end
	local class, subClass = private:GetItemClasses(itemString)
	return {name=name, minLevel=minLevel, maxLevel=minLevel, invType=0, class=class, subClass=subClass, quality=rarity}
end


function private:GetGreatestSubstring(str1, str2)
	local parts1 = {(" "):split(str1)}
	local parts2 = {(" "):split(str2)}
	for i=1, #parts1 do
		if parts1[i] ~= parts2[i] then
			local subStr = table.concat(parts1, " ", 1, i-1)
			return subStr ~= "" and subStr
		end
	end
	return table.concat(parts1, " ")
end

function private:ReduceStringsThread(self, strList)
	sort(strList)
	local didReduction = true
	while didReduction do
		didReduction = false
		for i=1, #strList-1 do
			if i > #strList-1 then break end
			local subStr = private:GetGreatestSubstring(strList[i], strList[i+1])
			if subStr then
				strList[i] = subStr
				tremove(strList, i+1)
				didReduction = true
			end
			self:Yield()
		end
	end
	return true
end

function private:GenerateSearchTermsThread(self, names, itemList, isReversed)
	-- run the reduction
	private:ReduceStringsThread(self, names)
	
	-- create a table associating all the reduced names to a list of items
	local temp = {}
	for i, filterName in ipairs(names) do
		for j, itemString in ipairs(itemList) do
			local itemName = TSMAPI:GetSafeItemInfo(itemString)
			itemName = itemName and isReversed and strrev(itemName) or itemName -- reverse item name if necessary
			if itemName and strfind(itemName, "^"..TSMAPI:StrEscape(filterName)) then
				temp[filterName] = temp[filterName] or {}
				tinsert(temp[filterName], itemString)
			end
			self:Yield()
		end
	end
	
	return temp
end

function private:GenerateFiltersThread(self, itemList, reverse)
	-- create a list of all item names
	local names = {}
	for _, itemString in ipairs(itemList) do
		local name = TSMAPI:GetSafeItemInfo(itemString)
		if type(name) == "string" and name ~= "" then
			tinsert(names, reverse and strrev(name) or name)
		end
	end

	local filters, tempFilters, tempItems  = {}, {}, {}
	local numFilters = 0
	local tbl = private:GenerateSearchTermsThread(self, names, itemList, reverse)
	if not tbl then return end
	for filterName, items in pairs(tbl) do
		if #items > 1 then
			filters[reverse and strrev(filterName) or filterName] = items
			numFilters = numFilters + 1
		else
			tinsert(tempFilters, strrev(filterName)) -- reverse name for second pass
			for _, itemString in ipairs(items) do
				tinsert(tempItems, itemString)
			end
		end
	end
	
	-- try to find common search terms of reversed item names
	local tbl = private:GenerateSearchTermsThread(self, tempFilters, tempItems, not reverse)
	if not tbl then return end
	for filterName, items in pairs(tbl) do
		if filters[reverse and filterName or strrev(filterName)] then
			for _, itemString in ipairs(items) do
				tinsert(filters[reverse and filterName or strrev(filterName)], itemString)
			end
		else
			filters[reverse and filterName or strrev(filterName)] = items
		end
		numFilters = numFilters + 1
	end
	
	return filters, numFilters
end


function private:GetCommonQueryInfoThread(self, name, items)
	local queries = {}
	for _, itemString in ipairs(items) do
		local itemQuery = TSMAPI:GetAuctionQueryInfo(itemString)
		local existingQuery
		for _, query in ipairs(queries) do
			if query.class == itemQuery.class then
				existingQuery = query
				break
			end
			self:Yield()
		end
		if existingQuery then
			existingQuery.minLevel = min(existingQuery.minLevel, itemQuery.minLevel)
			existingQuery.maxLevel = max(existingQuery.maxLevel, itemQuery.maxLevel)
			existingQuery.quality = min(existingQuery.quality, itemQuery.quality)
			if existingQuery.subClass ~= itemQuery.subClass then
				existingQuery.subClass = nil
			end
			tinsert(existingQuery.items, itemString)
		else
			itemQuery.name = name
			itemQuery.items = {itemString}
			tinsert(queries, itemQuery)
		end
	end
	return queries
end

function private:GetCommonQueryInfoClassThread(self, class, items)
	local resultQuery = TSMAPI:GetAuctionQueryInfo(items[1])
	resultQuery.name = ""
	resultQuery.class = class
	for i=2, #items do
		local itemQuery = TSMAPI:GetAuctionQueryInfo(items[i])
		resultQuery.minLevel = min(resultQuery.minLevel, itemQuery.minLevel)
		resultQuery.maxLevel = max(resultQuery.maxLevel, itemQuery.maxLevel)
		resultQuery.quality = min(resultQuery.quality, itemQuery.quality)
		if resultQuery.subClass ~= itemQuery.subClass then resultQuery.subClass = nil end
		self:Yield()
	end
	resultQuery.items = items
	return {resultQuery}
end

function private.GenerateQueriesThread(self, itemList)
	-- get all the item info into the game's cache
	local endTime = debugprofilestop() + 10000
	while debugprofilestop() < endTime do
		local tryAgain = false
		for _, itemString in ipairs(itemList) do
			if not TSMAPI:GetSafeItemInfo(itemString) then
				tryAgain = true
			end
		end
		if not tryAgain then break end
		self:Sleep(0.1)
	end
	
	-- generate filters for the items both forwards and reversed and use
	-- the result with the lower number of filters
	local filters1, num1 = private:GenerateFiltersThread(self, itemList)
	local filters2, num2 = private:GenerateFiltersThread(self, itemList, true)
	if not filters1 or not filters2 then return end
	local filters = num2 < num1 and filters2 or filters1
	self:Yield()
	
	-- generate class filters
	local itemClasses = {}
	local classes = {GetAuctionItemClasses()}
	for _, itemString in ipairs(itemList) do
		local classIndex = private:GetItemClasses(itemString)
		if classIndex then
			itemClasses[classIndex] = itemClasses[classIndex] or {}
			tinsert(itemClasses[classIndex], itemString)
		end
		self:Yield()
	end
	
	-- create the actual queries
	local queries, combinedQueries = {}, {}
	for filterName, items in pairs(filters) do
		for _, query in ipairs(private:GetCommonQueryInfoThread(self, filterName, items)) do
			if #query.items > 1 then
				tinsert(combinedQueries, query)
			else
				tinsert(queries, query)
			end
		end
		self:Yield()
	end
	for class, items in pairs(itemClasses) do
		for _, query in ipairs(private:GetCommonQueryInfoClassThread(self, class, items)) do
			if #query.items > 1 then
				tinsert(combinedQueries, query)
			end
		end
		self:Yield()
	end
	
	--- check num pages for each query
	local totalQueries = #combinedQueries
	while #combinedQueries > 0 do
		local combinedQuery = tremove(combinedQueries, 1)
		local numPages
		for _, itemString in ipairs(combinedQuery.items) do
			if strlower(combinedQuery.name) == strlower(TSMAPI:GetSafeItemInfo(itemString)) then
				-- One of the items in this combined query is the same as the common search term,
				-- so it's always worth using this common search term.
				numPages = 1
				break
			end
		end
		
		if not numPages then
			local threadId = private.threadId
			-- prevent this thread from being killed while auction code runs
			private.threadId = nil
			-- start scanning for the number of pages and wait for it to finish
			TSMAPI.AuctionScan2:ScanNumPages(combinedQuery, function(...) TSMAPI.Threading:SendMsg(threadId, {...}) end)
			local scanThreadId = TSM:GetScanThreadId()
			if scanThreadId then
				self:WaitForThread(scanThreadId)
			end
			private.threadId = threadId
			
			local event, arg = unpack(self:ReceiveMsg())
			if event == "NUM_PAGES" then
				numPages = arg
			elseif event == "INTERRUPTED" then
				-- we were interrupted, so kill this thread
				TSM:StopGeneratingQueries()
				self:Yield(true)
				-- we should never get here
				return
			else
				assert(false, "Unexpected event from scan thread: "..tostring(event))
			end
		end
		
		local skippedItems = {}
		local score = max(#combinedQuery.items-numPages, 0)
		if combinedQuery.name == "" then
			-- This is a common class term so determine if we should use this or not.
			local cost = 0
			for _, query in ipairs(queries) do
				if query.score and query.class == combinedQuery.class then
					cost = cost + query.score
				end
			end
			if score >= cost and score > 0 then
				-- use the common class term
				for i=#queries, 1, -1 do
					local query = queries[i]
					local shouldRemove = (query.class == combinedQuery.class)
					if shouldRemove then
						tremove(queries, i)
					end
				end
				tinsert(queries, combinedQuery)
			end
		else
			if numPages > #combinedQuery.items then
				for _, itemString in ipairs(combinedQuery.items) do
					local query = TSMAPI:GetAuctionQueryInfo(itemString)
					query.items = {itemString}
					query.score = 0
					tinsert(queries, query)
				end
			elseif numPages == 0 then
				for _, itemString in ipairs(combinedQuery.items) do
					tinsert(skippedItems, itemString)
				end
			else
				-- use the common search term
				combinedQuery.score = score
				tinsert(queries, combinedQuery)
			end
		end
		private.callback("QUERY_UPDATE", totalQueries-#combinedQueries, totalQueries, skippedItems)
		self:Yield()
	end
	
	-- we're done
	sort(queries, function(a, b) return a.name < b.name end)
	private.callback("QUERY_COMPLETE", queries)
	private.threadDone = true
end

function private:ThreadDone()
	private.threadDone = nil
	private.threadId = nil
end

function TSMAPI:GenerateQueries(itemList, callback)
	TSM:StopGeneratingQueries()
	private.callback = callback
	private.threadId = TSMAPI.Threading:Start(private.GenerateQueriesThread, 0.5, private.ThreadDone, itemList)
end

function TSM:StopGeneratingQueries()
	if private.threadId and not private.threadDone then
		TSMAPI.Threading:Kill(private.threadId)
		private.threadId = nil
	end
end