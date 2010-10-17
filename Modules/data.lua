-- ------------------------------------------------------------------------------------- --
-- 					Scroll Master - AddOn by Sapu (sapu94@gmail.com)			 		 --
--             http://wow.curse.com/downloads/wow-addons/details/slippy.aspx             --
-- ------------------------------------------------------------------------------------- --

-- The following functions are contained attached to this file:
-- Data:LoadFromSavedDB() - initialize all the data tables
-- Data:CalcPrices() - calulates the cost, buyout, and profit for an enchant's scroll
-- Data:GetMats() - returns a table containing a list of materials that excludes those only needed for hidden enchants
-- Data:ResetData() - resets all of the data when the "Reset Craft Queue" button is pressed
-- Data:GetAPMGroupName() - gets the name of the APM group that corresponds with a passed itemID
-- Data:ExportDataToAPM() - exports all of Scroll Master's enchant costs (how much it cost to make every enchant) to APM's threshold values
-- Data:GetDataByGroups() - returns the Data.crafts table as a 2D array with a slot index (chants[slot][chant] instead of chants[chant])
-- Data:UpdateInventoryInfo() - gets the number of mats / scrolls in the players inventory and stores the results in Data.inventory

-- The following "global" (within the addon) variables are initialized in this file:
-- Data.matList - contains the itemIDs for all the materials
-- Data.crafts - stores information about every enchant (see below for more info)
-- Data.inventory - stores information about what's in the player's bags.

-- ===================================================================================== --


-- load the parent file (ScrollMaster) into a local variable and register this file as a module
local TSM = select(2, ...)
local Data = TSM:NewModule("Data", "AceEvent-3.0")

local aceL = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local debug = function(...) TSM:Debug(...) end -- for debugging
local VELLUM_ID = 38682

local function L(phrase)
	--TSM.lTable[phrase] = true
	return aceL[phrase]
end

-- initialize all the data tables
function Data:Initialize()
	Data.inventory = {}
	local tradeSkills = {"Enchanting", "Blacksmithing"}
	
	for _, skill in pairs(tradeSkills) do
		-- load all the enchants into Data.crafts
		Data[skill] = TSM.db.profile[skill] or {}
		Data[skill].mats = Data[skill].mats or {}
		Data[skill].crafts = Data[skill].crafts or {}
		
		-- add any materials that aren't in the default table to the data table
		for id in pairs(Data[skill].mats) do
			id = tonumber(id)
			-- the id is going to be the key (and the value is the cost of that material which we don't care about)
			local NeedToAdd = nil -- keep track of whether or not this needs to be added to the data table
			for itemID, chant in pairs(Data[skill].crafts) do
				-- for every enchant in the data table...
				for mat in pairs(chant.mats) do
					-- check to see if the mat (corresponding to the 'id' variable) is used by the enchant
					if id == tonumber(mat) then
						-- if so, we must add it to TSM's internal list of itemIDs for materials
						NeedToAdd = true
					end
				end
			end
			
			-- remove the mat from the savedDB if it is unused
			if not NeedToAdd then
				Data[skill].mats[id] = nil
			end
		end
	end
end

-- calulates the cost, buyout, and profit for an enchant's scroll
function Data:CalcPrices(enchant)
	if not enchant then return end

	if type(enchant) == "number" then
		debug("got number in calcprices")
		enchant = Data[TSM.mode].crafts[enchant]
	end

	-- first, we calculate the cost of crafting that scroll based off the cost of the individual materials
	local cost = 0
	for id, matQuantity in pairs(enchant.mats) do
		-- this if statement excludes vellums in the cost calculations if that option is unchecked
		-- if it's not a vellum or we want to include vellums...we want to include this item
		if (not (TSM.mode == "Enchanting" and itemID == VELLUM_ID)) or TSM.db.profile.vellums then
			TSM.db.profile[TSM.mode].mats[tonumber(id)].cost = TSM.db.profile[TSM.mode].mats[tonumber(id)].cost or 1
			cost = cost + matQuantity*TSM.db.profile[TSM.mode].mats[tonumber(id)].cost
		end
	end
	cost = math.floor(cost + 0.5) --rounds to nearest gold
	
	-- next, we get the buyout from the auction scan data table and calculate the profit
	local buyout, profit
	if TSM.db.factionrealm.ScanStatus.scrolls then -- make sure the auction scan data exists first
		if enchant.sell and not (enchant.sell==(1/0)) then
			-- grab the buyout price and calculate the profit if the buyout price exists and is a valid number
			buyout = enchant.sell
			profit = buyout - buyout*TSM.db.profile.profitPercent - cost
			profit = math.floor(profit + 0.5) -- rounds to the nearest gold
		end
	end
	
	-- return the results
	return cost, buyout, profit
end

-- returns a table containing a list of materials that excludes those only needed for hidden enchants
function Data:GetMats()
	local matTemp = {} -- stores boolean values corresponding to whether or not each material is valid (being used)
	local returnTbl = {} -- properly formatted table to be returned
	
	-- check each enchant and make sure it is shown in the 'manage enchants' section of the options
	-- if it is, set all of its materials to valid because they are being used by the addon
	for _, chant in pairs(Data[TSM.mode].crafts) do
		for matID in pairs(chant.mats) do
			matTemp[matID] = true 
		end
	end
	
	local num = 1
	
	-- the matTemp table is indexed by itemID of the materials
	-- this must be changed to remain consistent with the Data.matList table so that the itemID is the value
	-- this loop does that
	for matID in pairs(matTemp) do
		returnTbl[num] = tonumber(matID)
		num = num + 1
	end
	
	-- sort the table so that the mats are displayed in a somewhat logical order (by itemID)
	sort(returnTbl)
	
	return returnTbl
end

-- resets all of the data when the "Reset Craft Queue" button is pressed
function Data:ResetData()
	-- reset the number queued of every enchant back to 0
	for _, data in pairs(TSM.Data[TSM.mode].crafts) do
		data.queued = 0
	end
	
	CloseTradeSkill() -- close the enchanting trade skill window
	TSM.Enchanting:TRADE_SKILL_CLOSE() -- cleans up the Enchanting module
	wipe(TSM.GUI.queueList) -- clears the craft queue data table
	TSM:Print(L("Craft Queue Reset")) -- prints out a nice message
end

-- gets the name of the APM group that corresponds with a passed itemID
function Data:GetAPMGroupName(itemID)
	for groupName, v in pairs(TSM.APMdb.global.groups) do
		for itemIDString in pairs(v) do
			if itemIDString == "item:" .. itemID then
				return groupName
			end
		end
	end
end

-- exports all of Scroll Master's enchant costs (how much it cost to make every enchant) to APM's threshold values
function Data:ExportDataToAPM()
	for itemID, data in pairs(Data[TSM.mode].crafts) do
		if TSM.db.profile.exportList[itemID] then
			local groupName = Data:GetAPMGroupName(itemID)
			local cost = Data:CalcPrices(data)
			if groupName then
				local thresholdPrice = (cost + cost*TSM.db.profile.APMIncrease) * 10000
				if thresholdPrice < (TSM.db.profile.minThreshold*10000) then
					thresholdPrice = TSM.db.profile.minThreshold*10000
				end
				TSM.APMdb.profile.threshold[groupName] = thresholdPrice
				if TSM.db.profile.APMFallback>0 then
					TSM.APMdb.profile.fallback[groupName] = thresholdPrice * TSM.db.profile.APMFallback
				end
			end
		end
	end
	
	TSM:Print(L("Selected enchant costs were successfully exported to APM."))
end

-- returns the Data.crafts table as a 2D array with a slot index (chants[slot][chant] instead of chants[chant])
function Data:GetDataByGroups()
	local craftsByGroup = {}
	for itemID, data in pairs(Data[TSM.mode].crafts) do
		if data.group then
			craftsByGroup[group] = craftsByGroup[group] or {}
			craftsByGroup[group][itemID] = data
		end
	end
	
	return craftsByGroup
end

-- gets the number of mats / scrolls in the players inventory and stores the results in Data.inventory
function Data:UpdateInventoryInfo(updateType)
	local matList = Data:GetMats() -- get an up-to-date list of the materials TSM is using

	if updateType == "mats" then -- check the player's bags for any mats
		for mat=1, #(matList) do
			Data.inventory[matList[mat]] = 0
			for bag=0, 4 do
				for slot=1, GetContainerNumSlots(bag) do
					if GetContainerItemID(bag, slot) == tonumber(matList[mat]) then
						Data.inventory[matList[mat]] = Data.inventory[matList[mat]] + select(2, GetContainerItemInfo(bag, slot))
					end
				end
			end
		end
		for i, itemID in pairs({43146, 39350, 39349, 43145, 37602, 38682}) do
			Data.inventory[itemID] = 0
			for bag=0, 4 do
				for slot=1, GetContainerNumSlots(bag) do
					if GetContainerItemID(bag, slot) == tonumber(itemID) then
						Data.inventory[itemID] = Data.inventory[itemID] + select(2, GetContainerItemInfo(bag, slot))
					end
				end
			end
		end
		for mat=1, #(matList) do
			Data.inventory[matList[mat]] = Data.inventory[matList[mat]] or 0
		end
	elseif updateType == "scrolls" then -- check the player's bags for any scrolls
		for itemID in pairs(Data[TSM.mode].crafts) do
			Data.inventory[itemID] = 0
		end
		for bag=0, 4 do
			for slot=1, GetContainerNumSlots(bag) do
				local bagItemID = GetContainerItemID(bag, slot)
				if Data[TSM.mode].crafts[bagItemID] then
					local num = select(2, GetContainerItemInfo(bag, slot))
					Data.inventory[bagItemID] = Data.inventory[bagItemID] + num
				end
			end
		end
	end
end