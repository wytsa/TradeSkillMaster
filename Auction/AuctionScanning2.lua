-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file contains code for scanning the auction house
local TSM = select(2, ...)
TSMAPI.AuctionScan2 = {}

local SCAN_THREAD_PCT = 0.8
local SCAN_RESULT_DELAY = 0.1
local MAX_SOFT_RETRIES = 20
local MAX_HARD_RETRIES = 4
local private = {callbackHandler=nil, scanThreadId=nil}
TSMAPI:RegisterForTracing(private, "TradeSkillMaster.AuctionScanning2_private")


local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("AUCTION_HOUSE_CLOSED")
eventFrame:SetScript("OnEvent", function(self, event)
	if event == "AUCTION_HOUSE_CLOSED" then
		-- auction house was closed, so make sure all stop scanning
		TSMAPI.AuctionScan2:StopScan()
	end
end)

function private:DoCallback(...)
	if type(private.callbackHandler) == "function" then
		private.callbackHandler(...)
	end
end

-- returns (numPages, lastPage)
function private:GetNumPages()
	local _, total = GetNumAuctionItems("list")
	return ceil(total / NUM_AUCTION_ITEMS_PER_PAGE), floor(total / NUM_AUCTION_ITEMS_PER_PAGE)
end

function private:IsAuctionPageValid(resolveSellers)
	local isDuplicatePage = (private.pageTemp and GetNumAuctionItems("list") > 0)
	local numLinks, prevLink = 0, nil
	for i=1, GetNumAuctionItems("list") do
		-- checks to make sure all the data has been sent to the client
		-- if not, the data is bad and we'll wait / try again
		local count, minBid, minInc, buyout, bid, seller = TSMAPI:Select({3, 8, 9, 10, 11, 14}, GetAuctionItemInfo("list", i))
		local link = GetAuctionItemLink("list", i)
		local itemString = TSMAPI:GetItemString(link)
		if not itemString or not buyout or not count or (not seller and resolveSellers and buyout ~= 0) then
			return false
		end
		if isDuplicatePage then
			local link = GetAuctionItemLink("list", i)
			local temp = private.pageTemp[i]

			if not prevLink then
				prevLink = link
			elseif prevLink ~= link then
				prevLink = link
				numLinks = numLinks + 1
			end

			if not temp or temp.count ~= count or temp.minBid ~= minBid or temp.minInc ~= minInc or temp.buyout ~= buyout or temp.bid ~= bid or temp.seller ~= seller or temp.link ~= link then
				isDuplicatePage = false
			end
		end
	end

	if isDuplicatePage and numLinks > 1 and private.pageTemp.shown == GetNumAuctionItems("list") then
		-- this is a duplicate page
		return false
	end

	return true
end

-- fires off a query and waits for the AH to update (without any retries)
function private.ScanThreadDoQuery(self, query)
	-- wait for the AH to be ready
	while not CanSendAuctionQuery() do self:Yield(true) end
	-- send the query
	QueryAuctionItems(query.name, query.minLevel, query.maxLevel, query.invType, query.class, query.subClass, query.page, query.usable, query.quality)
	-- wait for the update event
	self:WaitForEvent("AUCTION_ITEM_LIST_UPDATE")
end

-- does a query until it's successful (or we run out of retries)
function private.ScanThreadDoQueryAndScan(self, query)
	for i=1, MAX_HARD_RETRIES do
		-- make the query
		private.ScanThreadDoQuery(self, query)
		-- check the result
		for j=1, MAX_SOFT_RETRIES do
			-- wait a small delay and then try and get the result
			self:Sleep(SCAN_RESULT_DELAY)
			-- get result
			if private:IsAuctionPageValid(query.resolveSellers) then
				-- result is valid, so we're done
				return
			end
		end
		self:Yield()
	end
	-- ran out of retries
end

-- scans the current page and stores the results
function private.StorePageResults(resultTbl)
	local shown = GetNumAuctionItems("list")
	private.pageTemp = {numShown=shown}
	for i=1, shown do
		local name, texture, count, minBid, minIncrement, buyout, bid, highBidder, seller, seller_full = TSMAPI:Select({1, 2, 3, 8, 9, 10, 11, 12, 14, 15}, GetAuctionItemInfo("list", i))
		local timeLeft = GetAuctionItemTimeLeft("list", i)
		local link = GetAuctionItemLink("list", i)
		local itemString = TSMAPI:GetItemString(link)
		
		-- store in pageTemp to detect duplicate pages in the future
		private.pageTemp[i] = {count=count, minBid=minBid, minInc=minIncrement, buyout=buyout, bid=bid, seller=seller, link=link}
		
		-- store the data in resultTbl
		if itemString then
			seller = TSM:GetAuctionPlayer(seller, seller_full) or "?"
			resultTbl[itemString] = resultTbl[itemString] or TSMAPI.AuctionScan:NewAuctionItem(link, texture)
			resultTbl[itemString]:AddAuctionRecord(count, minBid, minIncrement, buyout, bid, highBidder, seller, timeLeft)
			-- add the base item if necessary
			local baseItemString = TSMAPI:GetBaseItemString(itemString)
			if baseItemString ~= itemString then
				resultTbl[baseItemString] = resultTbl[baseItemString] or TSMAPI.AuctionScan:NewAuctionItem(link, texture)
				resultTbl[baseItemString].isBaseItem = true
				resultTbl[baseItemString]:AddAuctionRecord(count, minBid, minIncrement, buyout, bid, highBidder, seller, timeLeft)
			end
		end
	end
end


function private.ScanAllPagesThread(self, query)
	-- wait for the AH to be ready
	self:Sleep(0.1)
	while not CanSendAuctionQuery() do self:Yield(true) end

	-- loop until we're through all the pages, at which point we'll break out
	local scanData = {}
	local totalPages = math.huge
	while query.page < totalPages do
		-- query until we get good data or run out of retries
		private.ScanThreadDoQueryAndScan(self, query)
		-- set the atomic flag so we don't yield and have the data potentially change on us
		self:SetAtomic()
		-- do the callback for this page
		totalPages = private:GetNumPages()
		query.page = query.page + 1
		private:DoCallback("SCAN_PAGE_UPDATE", query.page, totalPages)
		-- we've made the query, now scan the page
		private.StorePageResults(scanData)
		self:ClearAtomic()
	end
	
	private:DoCallback("SCAN_COMPLETE", scanData)
end

function private.ScanLastPageThread(self)
	-- wait for the AH to be ready
	self:Sleep(0.1)
	while not CanSendAuctionQuery() do self:Yield(true) end
	
	
	-- get to the last page of the AH
	local _, lastPage = private:GetNumPages()
	local query = {name="", page=lastPage}
	local onLastPage = false
	while not onLastPage do
		-- make the query
		private.ScanThreadDoQuery(self, query)
		local _, lastPage = private:GetNumPages()
		onLastPage = (query.page == lastPage)
		query.page = lastPage
	end
	
	-- scan the page and store the results then do the callback
	local scanData = {}
	private.StorePageResults(scanData)
	private:DoCallback("SCAN_COMPLETE", scanData)
end

function private.ScanThreadDone()
	private.scanThreadId = nil
	TSMAPI.AuctionScan2:StopScan()
end


function TSMAPI.AuctionScan2:RunQuery(query, callbackHandler, resolveSellers)
	assert(type(query) == "table", "Invalid query type: "..type(query))
	assert(type(callbackHandler) == "function", "Invalid callbackHandler type: "..type(callbackHandler))
	if not AuctionFrame:IsVisible() then return end
	TSMAPI.AuctionScan2:StopScan() -- stop any scan in progress
	private.callbackHandler = callbackHandler
	
	-- set up the query
	query = CopyTable(query)
	query.resolveSellers = resolveSellers
	query.page = 0
	
	-- sort by buyout
	SortAuctionItems("list", "buyout")
	if IsAuctionSortReversed("list", "buyout") then
		SortAuctionItems("list", "buyout")
	end
	
	private.scanThreadId = TSMAPI.Threading:Start(private.ScanAllPagesThread, SCAN_THREAD_PCT, private.ScanThreadDone, query)
end

function TSMAPI.AuctionScan2:ScanLastPage(callbackHandler)
	assert(type(callbackHandler) == "function", "Invalid callbackHandler type: "..type(callbackHandler))
	if not AuctionFrame:IsVisible() then return end
	TSMAPI.AuctionScan2:StopScan() -- stop any scan in progress
	private.callbackHandler = callbackHandler
	
	-- clear the auction sort
	SortAuctionClearSort("list")
	
	private.scanThreadId = TSMAPI.Threading:Start(private.ScanLastPageThread, SCAN_THREAD_PCT, private.ScanThreadDone)
end

-- API for stopping the scan
function TSMAPI.AuctionScan2:StopScan()
	-- if the scanning thread is active, kill it
	if private.scanThreadId then
		-- the scan was interrupted by something
		private:DoCallback("INTERRUPTED")
		TSMAPI.Threading:Kill(private.scanThreadId)
	end
	
	private.scanThreadId = nil
	private.callbackHandler = nil
	private.pageTemp = nil
	TSM:StopGeneratingQueries()
end