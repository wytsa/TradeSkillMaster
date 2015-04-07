-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--          http://www.curse.com/addons/wow/tradeskillmaster_warehousing          --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file contains APIs related to items (itemLinks/itemStrings/etc)

local TSM = select(2, ...)
local Items = TSM:NewModule("Items", "AceEvent-3.0")
local private = {itemInfoCache=setmetatable({}, {__mode="kv"}), scanTooltip=nil, pendingItems={}}
local PET_CAGE_ITEM_INFO = {isDefault=true, 0, "Battle Pets", "", 1, "", "", 0}



-- ============================================================================
-- TSMAPI Functions
-- ============================================================================

function TSMAPI.Item:ToItemString2(item)
	if not item then return end
	TSMAPI:Assert(type(item) == "number" or type(item) == "string")
	local result = nil
	
	if tonumber(item) then
		-- assume this is an itemId
		return "i:"..item
	else
		item = item:trim()
	end
	
	-- test if it's already (likely) an item string or battle pet string
	if strmatch(item, "^i:([0-9%-:]+)$") or strmatch(item, "^p:([0-9%-:]+)$") then
		return item
	end
	
	result = strmatch(item, "^\124cff[0-9a-z]+\124H(.+)\124h%[.+%]\124h\124r$")
	if result then
		-- it was a full item link which we've extracted the itemString from
		item = result
	end
	
	-- test if it's an old style item string
	result = strjoin(":", strmatch(item, "^(i)tem:([0-9%-]+):0:0:0:0:0:([0-9%-]+)$"))
	if result then
		result = gsub(gsub(result, ":0$", ""), ":0$", "") -- remove extra zeroes
		return result
	end
	
	-- test if it's an old style battle pet string
	result = strjoin(":", strmatch(item, "^battle(p)et:(%d+:%d+:%d+)$"))
	if result then
		return result
	end
	result = strjoin(":", strmatch(item, "^battle(p)et:(%d+)$"))
	if result then
		return result
	end
	
	-- test if it's an item
	result = strjoin(":", strmatch(item, "(i)tem:([0-9%-]+):[0-9%-]+:[0-9%-]+:[0-9%-]+:[0-9%-]+:[0-9%-]+:([0-9%-]+):[0-9%-]+:[0-9%-]+:[0-9%-]+:[0-9%-]+:([0-9%-:]+)"))
	if result and result ~= "" then
		result = gsub(gsub(result, ":0$", ""), ":0$", "") -- remove extra zeroes
		return result
	end
end

function TSMAPI.Item:ToBaseItemString2(itemString)
	-- make sure it's a valid itemString
	itemString = TSMAPI.Item:ToItemString2(itemString)
	if not itemString then return end
	local itemStringType = strsub(itemString, 1, 1)
	return strmatch(itemString, "([ip]:%d+)")
end

function TSMAPI.Item:ToItemString(item)
	if type(item) == "string" then
		-- see if we can do a quick regex for the itemString
		local result = strmatch(item, "item:%d+:0:0:0:0:0:%-?%d+")
		if result then return result end
		item = item:trim()
		
		if strmatch(item, "^[ip]:") then
			-- it's the new style of itemString so convert back
			if strmatch(item, "^p") then
				return gsub(item, "^p", "battlepet")
			else
				local _, itemId, rand = (":"):split(item)
				rand = rand or 0
				return strjoin(":", "item", itemId, 0, 0, 0, 0, 0, rand)
			end
		end
	end

	if type(item) ~= "string" and type(item) ~= "number" then
		return nil, "invalid arg type"
	end
	item = select(2, TSMAPI.Item:GetInfo(item)) or item
	if tonumber(item) then
		return "item:" .. item .. ":0:0:0:0:0:0"
	end

	local itemInfo = { strfind(item, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%-?%d*):?(%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?") }
	if not itemInfo[11] then return nil, "invalid link" end
	itemInfo[11] = tonumber(itemInfo[11]) or 0

	if itemInfo[4] == "item" then
		for i = 6, 10 do itemInfo[i] = 0 end
		return table.concat(itemInfo, ":", 4, 11)
	else
		return table.concat(itemInfo, ":", 4, 7)
	end
end

function TSMAPI.Item:ToBaseItemString(itemString, doGroupLookup)
	if type(itemString) ~= "string" then return end
	if strsub(itemString, 1, 2) == "|c" then
		-- this is an itemLink so get the itemString first
		itemString = TSMAPI.Item:ToItemString(itemString)
		if not itemString then return end
	end

	local parts = { (":"):split(itemString) }
	for i = 3, #parts do
		parts[i] = 0
	end
	local baseItemString = table.concat(parts, ":")
	if not doGroupLookup then return baseItemString end
	
	if TSM.db.profile.items[baseItemString] and not TSM.db.profile.items[itemString] then
		-- base item is in a group and the specific item is not, so use the base item
		return baseItemString
	end
	return itemString
end

--- Attempts to get the itemID from a given itemLink/itemString.
-- @param itemLink The link or itemString for the item.
-- @return Returns the itemID as the first parameter. On error, will return nil as the first parameter and an error message as the second.
function TSMAPI.Item:ToItemID(itemString)
	itemString = TSMAPI.Item:ToItemString2(itemString)
	if type(itemString) ~= "string" then return end
	return tonumber(strmatch(itemString, "^i:(%d+)"))
end

function TSMAPI.Item:ToItemLink(itemString)
	itemString = TSMAPI.Item:ToItemString2(itemString)
	if not itemString then return "?" end
	local link = select(2, TSMAPI.Item:GetInfo(itemString))
	if link then return link end
	if strmatch(itemString, "p:") then
		local _, speciesId, level, quality = (":"):split(itemString)
		return "|cffff0000|Hbattlepet"..strjoin(":", speciesId, level or 0, quality or 0).."|h[Unknown Pet]|h|r"
	elseif strmatch(itemString, "i:") then
		return "|cffff0000|H"..gsub(itemString, "i:", "item:").."|h[Unknown Item]|h|r"
	end
	return "?"
end

function TSMAPI.Item:QueryInfo(itemString)
	tinsert(private.pendingItems, itemString)
end

function TSMAPI.Item:HasInfo(info)
	if type(info) == "string" then
		return TSMAPI.Item:GetInfo(info) and true
	elseif type(info) == "table" then
		TSMAPI:Assert(#info > 0)
		local result = true
		-- don't stop when we find one that doesn't have info so that we
		-- still query the info from the server for every item
		for _, itemString in ipairs(info) do
			if not TSMAPI.Item:HasInfo(itemString) then
				result = false
			end
		end
		return result
	else
		TSMAPI:Assert(false, "Invalid argument")
	end
end

function TSMAPI.Item:GetInfo(item)
	if not item then return end
	local itemString = TSMAPI.Item:ToItemString2(item) or TSMAPI.Item:ToItemString2(select(2, GetItemInfo(item)))
	if not itemString then return end

	if not private.itemInfoCache[itemString] then
		-- check if it's a new itemString
		if strmatch(itemString, "^i:") then
			local itemId = strmatch(itemString, "^i:([0-9]+)$")
			if itemId then
				-- just the itemId is specified, so simply extract that
				private.itemInfoCache[itemString] = {GetItemInfo(itemId)}
			else
				-- there is a random enchant or bonusId, so extract those (with a max of 10 bonuses
				local _, itemId, rand, numBonus = (":"):split(itemString)
				if numBonus then
					private.itemInfoCache[itemString] = {GetItemInfo(strjoin(":", "item", itemId, 0, 0, 0, 0, 0, rand, 0, 0, 0, 0, select(3, (":"):split(itemString))))}
				elseif rand then
					private.itemInfoCache[itemString] = {GetItemInfo(strjoin(":", "item", itemId, 0, 0, 0, 0, 0, rand))}
				else
					private.itemInfoCache[itemString] = {GetItemInfo(itemId)}
				end
			end
		elseif strmatch(itemString, "^p:") then
			local _, speciesID, level, quality, health, power, speed, petID = strsplit(":", itemString)
			if not tonumber(speciesID) then return end
			level, quality, health, power, speed, petID = level or 0, quality or 0, health or 0, power or 0, speed or 0, petID or "0"

			local name, texture = C_PetJournal.GetPetInfoBySpeciesID(tonumber(speciesID))
			if name == "" then return end
			level, quality = tonumber(level), tonumber(quality)
			petID = strsub(petID, 1, (strfind(petID, "|") or #petID) - 1)
			local itemLink = ITEM_QUALITY_COLORS[quality].hex .. "|Hbattlepet:" .. speciesID .. ":" .. level .. ":" .. quality .. ":" .. health .. ":" .. power .. ":" .. speed .. ":" .. petID .. "|h[" .. name .. "]|h|r"
			if PET_CAGE_ITEM_INFO.isDefault then
				local data = {select(5, GetItemInfo(82800))}
				if #data > 0 then
					PET_CAGE_ITEM_INFO = data
				end
			end
			local minLvl, iType, _, stackSize, _, _, vendorPrice = unpack(PET_CAGE_ITEM_INFO)
			private.itemInfoCache[itemString] = {name, itemLink, quality, level, minLvl, iType, 0, stackSize, "", texture, vendorPrice}
		else
			TSMAPI:Assert(format("Invalid item string: '%s'", tostring(itemString)))
		end
		if private.itemInfoCache[itemString] and #private.itemInfoCache[itemString] == 0 then private.itemInfoCache[itemString] = nil end
	end
	if not private.itemInfoCache[itemString] then return end
	return unpack(private.itemInfoCache[itemString])
end

function TSMAPI.Item:IsSoulbound(...)
	local numArgs = select('#', ...)
	if numArgs == 0 then return end
	local bag, slot, itemString, ignoreBOA
	local firstArg = ...
	if type(firstArg) == "string" then
		TSMAPI:Assert(numArgs <= 2, "Too many arguments provided with itemString")
		itemString, ignoreBOA = ...
		itemString = TSMAPI.Item:ToItemString(itemString)
		if strmatch(itemString, "^battlepet:") then
			-- battle pets are not soulbound
			return
		end
	elseif type(firstArg) == "number" then
		bag, slot, ignoreBOA = ...
		TSMAPI:Assert(slot, "Second argument must be slot within bag")
		TSMAPI:Assert(numArgs <= 3, "Too many arguments provided with bag / slot")
	else
		TSMAPI:Assert(false, "Invalid arguments")
	end
	
	if not TSMScanTooltip then
		CreateFrame("GameTooltip", "TSMScanTooltip", UIParent, "GameTooltipTemplate")
	end
	TSMScanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
	TSMScanTooltip:ClearLines()
	
	local result = nil
	if itemString then
		-- it's an itemString
		TSMScanTooltip:SetHyperlink(bag)
	elseif bag and slot then
		local itemID = GetContainerItemID(bag, slot)
		local maxCharges
		if itemID then
			TSMScanTooltip:SetItemByID(itemID)
			maxCharges = private:GetTooltipCharges(TSMScanTooltip)
		end
		if bag == -1 then
			TSMScanTooltip:SetInventoryItem("player", slot + 39)
		else
			TSMScanTooltip:SetBagItem(bag, slot)
		end
		if maxCharges then
			if private:GetTooltipCharges(TSMScanTooltip) ~= maxCharges then
				result = true
			end
		end
	else
		TSMAPI:Assert(false) -- should never get here
	end
	
	if result then
		TSMScanTooltip:Hide()
		return result
	end
	for id=1, TSMScanTooltip:NumLines() do
		local text = _G["TSMScanTooltipTextLeft" .. id]
		text = text and text:GetText()
		if text then
			if (text == ITEM_BIND_ON_PICKUP and id < 4) or text == ITEM_SOULBOUND or text == ITEM_BIND_QUEST then
				result = true
			elseif not ignoreBOA and (text == ITEM_ACCOUNTBOUND or text == ITEM_BIND_TO_ACCOUNT or text == ITEM_BIND_TO_BNETACCOUNT or text == ITEM_BNETACCOUNTBOUND) then
				result = true
			end
		end
	end
	TSMScanTooltip:Hide()
	return result
end

function TSMAPI.Item:IsCraftingReagent(itemLink)
	if not TSMScanTooltip then
		CreateFrame("GameTooltip", "TSMScanTooltip", UIParent, "GameTooltipTemplate")
	end
	TSMScanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
	TSMScanTooltip:ClearLines()
	TSMScanTooltip:SetHyperlink(itemLink)

	local result = nil
	for id = 1, TSMScanTooltip:NumLines() do
		local text = _G["TSMReagentTooltipTextLeft" .. id]
		text = text and text:GetText()
		if text and (text == PROFESSIONS_USED_IN_COOKING) then
			result = true
			break
		end
	end
	TSMScanTooltip:Hide()
	return result
end

function TSMAPI.Item:IsSoulboundMat(itemString)
	itemString = TSMAPI.Item:ToItemString2(itemString)
	return itemString and TSM.STATIC_DATA.soulboundMats[itemString]
end

function TSMAPI.Item:GetVendorCost(itemString)
	itemString = TSMAPI.Item:ToItemString2(itemString)
	return itemString and TSM.db.global.vendorItems[itemString]
end

function TSMAPI.Item:IsDisenchantable(itemString)
	itemString = TSMAPI.Item:ToBaseItemString2(itemString)
	if not itemString or TSM.STATIC_DATA.notDisenchantable[itemString] then return end
	local iType = select(6, TSMAPI.Item:GetInfo(itemString))
	return iType == ARMOR or iType == WEAPON
end



-- ============================================================================
-- Module Functions
-- ============================================================================

function Items:OnEnable()
	Items:RegisterEvent("MERCHANT_SHOW", "ScanMerchant")
	local itemString = next(TSM.db.global.vendorItems)
	if itemString and TSMAPI.Item:ToItemString2(itemString) ~= itemString then
		-- they just upgraded to TSM3, so wipe the table
		wipe(TSM.db.global.vendorItems)
	end
	
	for itemString, cost in pairs(TSM.STATIC_DATA.preloadedVendorCosts) do
		TSM.db.global.vendorItems[itemString] = TSM.db.global.vendorItems[itemString] or cost
	end
	TSMAPI.Threading:Start(private.ItemInfoThread, 0.1)
end

function Items:ScanMerchant(event)
	for i=1, GetMerchantNumItems() do
		local itemString = TSMAPI.Item:ToItemString2(GetMerchantItemLink(i))
		if itemString then
			local _, _, price, _, numAvailable, _, extendedCost = GetMerchantItemInfo(i)
			if price > 0 and not extendedCost and numAvailable == -1 then
				TSM.db.global.vendorItems[itemString] = price
			else
				TSM.db.global.vendorItems[itemString] = nil
			end
		end
	end
	if event then
		TSMAPI.Delay:AfterTime("scanMerchantDelay", 1, Items.ScanMerchant)
	end
end



-- ============================================================================
-- Item Info Thread
-- ============================================================================

function private.ItemInfoThread(self)
	self:SetThreadName("QUERY_ITEM_INFO")
	local yieldPeriod = 50
	local targetItemInfo = {}
	while true do
		for i=#private.pendingItems, 1, -1 do
			if TSMAPI.Item:GetInfo(private.pendingItems[i]) then
				tremove(private.pendingItems, i)
			end
			if i % yieldPeriod == 0 then
				self:Yield(true)
				yieldPeriod = min(yieldPeriod + 10, 300)
			else
				self:Yield()
			end
		end
		self:Sleep(1)
	end
end

do
	TSMAPI.Threading:Start(private.ItemInfoThread, 0.1)
end



-- ============================================================================
-- Helper Functions
-- ============================================================================

function private:GetTooltipCharges()
	for id=1, TSMScanTooltip:NumLines() do
		local text = _G["TSMScanTooltipTextLeft" .. id]
		if text and text:GetText() then
			local maxCharges = strmatch(text:GetText(), "^([0-9]+) Charges?$")
			if maxCharges then
				return maxCharges
			end
		end
	end
end