-- load the parent file (ScrollMaster) into a local variable and register this file as a module
local TSM = select(2, ...)
local Scan = TSM:NewModule("Scan", "AceEvent-3.0")

local aceL = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local debug = function(...) TSM:Debug(...) end -- for debugging

local BASE_DELAY = 0.10 -- time to delay for before trying to scan a page again when it isn't fully loaded

local lib = TSMAPI

-- initialize a bunch of variables and frames used throughout the module and register some events
function Scan:OnEnable()
	Scan.status = {page=0, retries=0, timeDelay=0, hardRetry=nil, data=nil, AH=false,
		queued=nil, timeLeft=0, filterlist = {}, filter=nil, data=nil, timeLeft, isScanning=nil, numItems, scantime=nil}
	Scan.AucData = {}
	Scan.returnFunction = nil

	-- Scan delay for soft reset
	Scan.frame2 = CreateFrame("Frame")
	Scan.frame2:Hide()
	Scan.frame2:SetScript("OnUpdate", function(_, elapsed)
		Scan.status.timeLeft = Scan.status.timeLeft - elapsed
		if Scan.status.timeLeft < 0 then
			Scan.status.timeLeft = 0
			Scan.frame2:Hide()

			Scan:ScanAuctions()
		end
	end)

	-- Scan delay for hard reset
	Scan.frame = CreateFrame("Frame")
	Scan.frame.timeElapsed = 0
	Scan.frame:Hide()
	Scan.frame:SetScript("OnUpdate", function(_, elapsed)
		Scan.frame.timeElapsed = Scan.frame.timeElapsed + elapsed
		if Scan.frame.timeElapsed >= 0.05 then
			Scan.frame.timeElapsed = Scan.frame.timeElapsed - 0.05
			Scan:SendQuery()
		end
	end)

	Scan:RegisterEvent("AUCTION_HOUSE_CLOSED")
	Scan:RegisterEvent("AUCTION_HOUSE_SHOW")
end

-- fires when the AH is openned and adds the "Scroll Master - Run Scan" button to the AH frame
function Scan:AUCTION_HOUSE_SHOW()
	Scan.status.AH = true
	
	-- delay to make sure the AH frame is completely loaded before we try and attach the scan button to it
	local delay = CreateFrame("Frame")
	delay:Show()
	delay:SetScript("OnUpdate", function()
		if AuctionFrameBrowse:GetPoint() then
			Scan:ShowScanButton()
			delay:Hide()
		end
	end)
end

-- gets called when the AH is closed
function Scan:AUCTION_HOUSE_CLOSED()
	if Scan.AHFrame then Scan.AHFrame:Hide() end -- hide the statusbar
	Scan:UnregisterEvent("AUCTION_ITEM_LIST_UPDATE")
	Scan.status.AH = false
	if Scan.status.isScanning then -- stop scanning if we were scanning (pass true to specify it was interupted)
		Scan:StopScanning(true)
	end
end

-- prepares everything to start running a scan
function lib:RunScan(scanQueue, finishedFunc)
	Scan.returnFunction = finishedFunc
	
	if not Scan.status.AH then
		TSM:Print(L("Auction house must be open in order to scan."))
		return
	end

	if #(scanQueue) == 0 then
		return TSM:Print("Nothing to scan")
	end
	
	if not CanSendAuctionQuery() then
		TSM:Print(L("Error: AuctionHouse window busy."))
		return
	end
	
	-- sets up the non-function-local variables
	-- filter = current item being scanned for
	-- filterList = queue of items to scan for
	wipe(Scan.AucData)
	Scan.status.page = 0
	Scan.status.retries = 0
	Scan.status.hardRetry = nil
	Scan.status.filterList = scanQueue
	Scan.status.filter = scanQueue[1]
	Scan.status.isScanning = true
	Scan.status.numItems = #(scanQueue)
	
	--starts scanning
	Scan:SendQuery()
end

-- sends a query to the AH frame once it is ready to be queried (uses Scan.frame as a delay)
function Scan:SendQuery(forceQueue)
	Scan.status.queued = not CanSendAuctionQuery()
	if (not Scan.status.queued and not forceQueue) then
		-- stop delay timer
		Scan.frame:Hide()
		Scan:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
		
		-- Query the auction house (then waits for AUCTION_ITEM_LIST_UPDATE to fire)
		QueryAuctionItems(Scan.status.filter, nil, nil, 0, 0, 0, Scan.status.page, 0, 0, 0)
	else
		-- run delay timer then try again to scan
		Scan.frame:Show()
	end
end

-- gets called whenever the AH window is updated (something is shown in the results section)
function Scan:AUCTION_ITEM_LIST_UPDATE()
	if Scan.status.isScanning then
		Scan.status.timeDelay = 0

		Scan.frame2:Hide()
		
		-- now that our query was successful we can get our data
		Scan:ScanAuctions()
	else
		Scan:UnregisterEvent("AUCTION_ITEM_LIST_UPDATE")
		Scan.AHFrame:Hide()
	end
end

-- scans the currently shown page of auctions and collects all the data
function Scan:ScanAuctions()
	-- collects data on the query:
		-- # of auctions on current page
		-- # of pages total
	local shown, total = GetNumAuctionItems("list")
	local totalPages = math.ceil(total / 50)
	local name, quantity, bid, buyout, owner = {}, {}, {}, {}, {}
	
	-- Check for bad data
	if Scan.status.retries < 3 then
		local badData
		for i=1, shown do
			-- checks whether or not the name and owner of the auctions are valid
			-- if either are invalid, the data is bad
			name[i], _, quantity[i], _, _, _, bid[i], _, buyout[i], _, _, owner[i] = GetAuctionItemInfo("list", i)
			if not name[i] or not owner[i] then
				badData = true
			end
		end
		
		if badData then
			if Scan.status.hardRetry then
				-- Hard retry
				-- re-sends the entire query
				Scan.status.retries = Scan.status.retries + 1
				Scan:SendQuery()
			else
				-- Soft retry
				-- runs a delay and then tries to scan the query again
				Scan.status.timeDelay = Scan.status.timeDelay + BASE_DELAY
				Scan.status.timeLeft = BASE_DELAY
				Scan.frame2:Show()
	
				-- If after 4 seconds of retrying we still don't have data, will go and requery to try and solve the issue
				-- if we still don't have data, we try to scan it anyway and move on.
				if Scan.status.timeDelay >= 4 then
					Scan.status.hardRetry = true
					Scan.status.retries = 0
				end
			end
			
			return
		end
	end
	
	Scan.status.hardRetry = nil
	Scan.status.retries = 0
	
	-- now that we know our query is good, time to verify and then store our data
	-- ex. "Eternal Earthsiege Diamond" will not get stored when we search for "Eternal Earth"
	for i=1, shown do
		if (name[i] == Scan.status.filter) then
			Scan:AddAuctionRecord(name[i], owner[i], quantity[i], bid[i], buyout[i])
		end
	end
	
	-- we are done scanning so add this data to the main table
	if (Scan.status.page == 0 and shown == 0) then
		Scan:AddAuctionRecord(Scan.status.filter, "", 0, 0, 0.1)
	end

	-- This query has more pages to scan
	-- increment the page # and send the new query
	if shown == 50 then
		Scan.status.page = Scan.status.page + 1
		Scan:SendQuery()
		return
	end
	
	-- Removes the current filter from the filterList as we are done scanning for that item
	for i=#(Scan.status.filterList), 1, -1 do
		if Scan.status.filterList[i] == Scan.status.filter then
			tremove(Scan.status.filterList, i)
			break
		end
	end
	Scan.status.filter = Scan.status.filterList[1]
	
	-- Query the next filter if we have one
	if Scan.status.filter then
		Scan.status.page = 0
		Scan:SendQuery()
		return
	end
	
	-- we are done scanning!
	Scan:StopScanning()
end

-- Add a new record to the Scan.AucData table
function Scan:AddAuctionRecord(name, owner, quantity, bid, buyout)
	-- Don't add this data if it has no buyout
	if (not buyout) or (buyout <= 0) then return end

	Scan.AucData[name] = Scan.AucData[name] or {quantity = 0, onlyPlayer = 0, records = {}}
	Scan.AucData[name].quantity = Scan.AucData[name].quantity + quantity

	-- Keeps track of how many the player has on the AH
	if owner == select(1, UnitName("player")) then
		Scan.AucData[name].onlyPlayer = Scan.AucData[name].onlyPlayer + quantity
	end
	
	-- Calculate the bid / buyout per 1 item
	buyout = buyout / quantity
	bid = bid / quantity
	
	-- No sense in using a record for each entry if they are all the exact same data
	for _, record in pairs(Scan.AucData[name].records) do
		if (record.owner == owner and record.buyout == buyout and record.bid == bid) then
			record.buyout = buyout
			record.bid = bid
			record.owner = owner
			record.quantity = record.quantity + quantity
			record.isPlayer = (owner==select(1,UnitName("player")))
			return
		end
	end
	
	-- Create a new entry in the table
	tinsert(Scan.AucData[name].records, {owner = owner, buyout = buyout, bid = bid,
		isPlayer = (owner==select(1,UnitName("player"))), quantity = quantity})
end

-- stops the scan because it was either interupted or it was completed successfully
function Scan:StopScanning(interupted)
	Scan.status.isScanning = nil
	Scan.status.queued = nil
	
	Scan.frame:Hide()
	Scan.frame2:Hide()
	
	if interupted then
		-- fires if the scan was interupted (auction house was closed while scanning)
		TSM:Print(L("Scan interupted due to auction house being closed."))
	else
		-- fires if the scan completed sucessfully
		-- validates the scan data
		if Scan.AHFrame then 
			Scan.AHFrame:Hide()
		end
		
		Scan.returnFunction(Scan.AucData)
	end
end