-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster")
local private = {}
local WEAPON, ARMOR = GetAuctionItemClasses()



-- ============================================================================
-- TSMAPI Functions
-- ============================================================================

function TSMAPI.Disenchant:IsDisenchantable(itemString)
	itemString = TSMAPI:GetBaseItemString2(itemString)
	if not itemString or private.notDisenchantable[itemString] then return end
	local iType = select(6, TSMAPI:GetSafeItemInfo(itemString))
	return iType == ARMOR or iType == WEAPON
end


function TSMAPI.Disenchant:GetSourceInfo(targetItem)
	targetItem = TSMAPI:GetBaseItemString2(targetItem)
	if not targetItem then return end
	for _, data in ipairs(private.disenchantInfo) do
		if data[targetItem] then
			return data[targetItem]
		end
	end
end

function TSMAPI.Disenchant:GetConversionNum(targetItem, sourceItem)
	if targetItem == sourceItem then return 1 end

	sourceItem = TSMAPI:GetBaseItemString2(sourceItem)
	targetItem = TSMAPI:GetBaseItemString2(targetItem)
	if not targetItem or not TSMAPI.Disenchant:IsDisenchantable(sourceItem) then return end
	local rarity, ilvl, _, iType = select(3, TSMAPI:GetSafeItemInfo(sourceItem))
	for _, data in ipairs(private.disenchantInfo) do
		for itemString, itemData in pairs(data) do
			if itemString ~= "desc" then
				for _, deData in ipairs(itemData.sourceInfo) do
					if deData.itemType == class and deData.rarity == rarity and ilvl >= deData.minItemLevel and ilvl <= deData.maxItemLevel then
						return deData.amountOfMats
					end
				end
			end
		end
	end
end

function TSMAPI.Disenchant:GetTargetItemByName(itemName)
	itemName = strlower(itemName)
	for _, data in pairs(private.disenchantInfo) do
		for itemString in pairs(data) do
			if itemString ~= "desc" then
				local name = TSMAPI:GetSafeItemInfo(itemString)
				if name and strlower(name) == itemName then
					return TSMAPI:GetItemString(itemString)
				end
			end
		end
	end
end

function TSMAPI.Disenchant:GetTargetItemNames()
	local result = {}
	local isComplete = true
	for _, data in pairs(private.disenchantInfo) do
		for itemString in pairs(data) do
			if itemString ~= "desc" then
				local name = TSMAPI:GetSafeItemInfo(itemString)
				if name then
					tinsert(result, strlower(name))
				else
					isComplete = false
				end
			end
		end
	end
	return result, isComplete
end

function TSMAPI.Disenchant:GetValue(sourceItem, customPrice)
	if not customPrice then return end
	local rarity, ilvl, _, iType = select(3, TSMAPI:GetSafeItemInfo(sourceItem))
	if not TSMAPI.Disenchant:IsDisenchantable(sourceItem) then return end

	local value = 0
	for _, data in ipairs(private.disenchantInfo) do
		for itemString, itemData in pairs(data) do
			if itemString ~= "desc" then
				for _, deData in ipairs(itemData.sourceInfo) do
					if deData.itemType == iType and deData.rarity == rarity and ilvl >= deData.minItemLevel and ilvl <= deData.maxItemLevel then
						local matValue = TSMAPI:GetCustomPriceValue(customPrice, itemString)
						if not matValue or matValue == 0 then return end
						value = value + matValue * deData.amountOfMats
					end
				end
			end
		end
	end
	
	value = floor(value)
	return value > 0 and value or nil
end



-- ============================================================================
-- Module Functions
-- ============================================================================

function TSM:GetDetailedDisenchantTooltip(sourceItem, tooltipText, moneyCoinsTooltip)
	local rarity, ilvl, _, iType = select(3, TSMAPI:GetSafeItemInfo(sourceItem))

	for _, data in ipairs(private.disenchantInfo) do
		for itemString, itemData in pairs(data) do
			if itemString ~= "desc" then
				for _, deData in ipairs(itemData.sourceInfo) do
					if deData.itemType == iType and deData.rarity == rarity and ilvl >= deData.minItemLevel and ilvl <= deData.maxItemLevel then
						local matValue = (TSMAPI:GetCustomPriceValue(TSM.db.profile.destroyValueSource, itemString) or 0) * deData.amountOfMats
						local name, _, matQuality = TSMAPI:GetSafeItemInfo(itemString)
						if matQuality and matValue > 0 then
							local colorName = format("|c%s%s x %s|r", select(4, GetItemQualityColor(matQuality)), name, deData.amountOfMats)
							if moneyCoinsTooltip then
								tinsert(tooltipText, { left = "    " .. colorName, right = TSMAPI:FormatTextMoneyIcon(matValue, "|cffffffff", true) })
							else
								tinsert(tooltipText, { left = "    " .. colorName, right = TSMAPI:FormatTextMoney(matValue, "|cffffffff", true) })
							end
						end
					end
				end
			end
		end
	end
end



-- ============================================================================
-- Static Disenchanting Data Tables
-- ============================================================================

private.disenchantInfo = {
	{
		desc = L["Dust"],
		["i:10940"] = { -- Strange Dust
			minLevel = 0,
			maxLevel = 24,
			sourceInfo = {
				{itemType = ARMOR, rarity = 2, minItemLevel = 5, maxItemLevel = 15, amountOfMats = 1.2},
				{itemType = ARMOR, rarity = 2, minItemLevel = 16, maxItemLevel = 20, amountOfMats = 1.875},
				{itemType = ARMOR, rarity = 2, minItemLevel = 21, maxItemLevel = 25, amountOfMats = 3.75},
				{itemType = WEAPON, rarity = 2, minItemLevel = 5, maxItemLevel = 15, amountOfMats = 0.3},
				{itemType = WEAPON, rarity = 2, minItemLevel = 16, maxItemLevel = 20, amountOfMats = 0.5},
				{itemType = WEAPON, rarity = 2, minItemLevel = 21, maxItemLevel = 25, amountOfMats = 0.75},
			},
		},
		["i:11083"] = { -- Soul Dust
			minLevel = 20,
			maxLevel = 30,
			sourceInfo = {
				{itemType = ARMOR, rarity = 2, minItemLevel = 26, maxItemLevel = 30, amountOfMats = 1.125},
				{itemType = ARMOR, rarity = 2, minItemLevel = 31, maxItemLevel = 35, amountOfMats = 2.625},
				{itemType = WEAPON, rarity = 2, minItemLevel = 26, maxItemLevel = 30, amountOfMats = 0.3},
				{itemType = WEAPON, rarity = 2, minItemLevel = 31, maxItemLevel = 35, amountOfMats = 0.7},
			},
		},
		["i:11137"] = { -- Vision Dust
			minLevel = 30,
			maxLevel = 40,
			sourceInfo = {
				{itemType = ARMOR, rarity = 2, minItemLevel = 36, maxItemLevel = 40, amountOfMats = 1.125},
				{itemType = ARMOR, rarity = 2, minItemLevel = 41, maxItemLevel = 45, amountOfMats = 2.625},
				{itemType = WEAPON, rarity = 2, minItemLevel = 36, maxItemLevel = 40, amountOfMats = 0.3},
				{itemType = WEAPON, rarity = 2, minItemLevel = 41, maxItemLevel = 45, amountOfMats = 0.7},
			},
		},
		["i:11176"] = { -- Dream Dust
			minLevel = 41,
			maxLevel = 50,
			sourceInfo = {
				{itemType = ARMOR, rarity = 2, minItemLevel = 46, maxItemLevel = 50, amountOfMats = 1.125},
				{itemType = ARMOR, rarity = 2, minItemLevel = 51, maxItemLevel = 55, amountOfMats = 2.625},
				{itemType = WEAPON, rarity = 2, minItemLevel = 46, maxItemLevel = 50, amountOfMats = 0.3},
				{itemType = WEAPON, rarity = 2, minItemLevel = 51, maxItemLevel = 55, amountOfMats = 0.77},
			},
		},
		["i:16204"] = { -- Illusion Dust
			minLevel = 51,
			maxLevel = 60,
			sourceInfo = {
				{itemType = ARMOR, rarity = 2, minItemLevel = 56, maxItemLevel = 60, amountOfMats = 1.125},
				{itemType = ARMOR, rarity = 2, minItemLevel = 61, maxItemLevel = 65, amountOfMats = 2.625},
				{itemType = WEAPON, rarity = 2, minItemLevel = 56, maxItemLevel = 60, amountOfMats = 0.33},
				{itemType = WEAPON, rarity = 2, minItemLevel = 61, maxItemLevel = 65, amountOfMats = 0.77},
			},
		},
		["i:22445"] = { -- Arcane Dust
			minLevel = 57,
			maxLevel = 70,
			sourceInfo = {
				{itemType = ARMOR, rarity = 2, minItemLevel = 79, maxItemLevel = 79, amountOfMats = 1.5},
				{itemType = ARMOR, rarity = 2, minItemLevel = 80, maxItemLevel = 99, amountOfMats = 1.875},
				{itemType = ARMOR, rarity = 2, minItemLevel = 100, maxItemLevel = 120, amountOfMats = 2.625},
				{itemType = WEAPON, rarity = 2, minItemLevel = 80, maxItemLevel = 99, amountOfMats = 0.55},
				{itemType = WEAPON, rarity = 2, minItemLevel = 100, maxItemLevel = 120, amountOfMats = 0.77},
			},
		},
		["i:34054"] = { -- Infinite Dust
			minLevel = 67,
			maxLevel = 80,
			sourceInfo = {
				{itemType = ARMOR, rarity = 2, minItemLevel = 130, maxItemLevel = 151, amountOfMats = 1.5},
				{itemType = ARMOR, rarity = 2, minItemLevel = 152, maxItemLevel = 200, amountOfMats = 3.375},
				{itemType = WEAPON, rarity = 2, minItemLevel = 130, maxItemLevel = 151, amountOfMats = 0.55},
				{itemType = WEAPON, rarity = 2, minItemLevel = 152, maxItemLevel = 200, amountOfMats = 1.1},
			},
		},
		["i:52555"] = { -- Hypnotic Dust
			minLevel = 77,
			maxLevel = 85,
			sourceInfo = {
				{itemType = ARMOR, rarity = 2, minItemLevel = 272, maxItemLevel = 275, amountOfMats = 1.125},
				{itemType = ARMOR, rarity = 2, minItemLevel = 276, maxItemLevel = 290, amountOfMats = 1.5},
				{itemType = ARMOR, rarity = 2, minItemLevel = 291, maxItemLevel = 305, amountOfMats = 1.875},
				{itemType = ARMOR, rarity = 2, minItemLevel = 306, maxItemLevel = 315, amountOfMats = 2.25},
				{itemType = ARMOR, rarity = 2, minItemLevel = 316, maxItemLevel = 325, amountOfMats = 2.625},
				{itemType = ARMOR, rarity = 2, minItemLevel = 326, maxItemLevel = 350, amountOfMats = 3},
				{itemType = WEAPON, rarity = 2, minItemLevel = 272, maxItemLevel = 275, amountOfMats = 0.375},
				{itemType = WEAPON, rarity = 2, minItemLevel = 276, maxItemLevel = 290, amountOfMats = 0.5},
				{itemType = WEAPON, rarity = 2, minItemLevel = 291, maxItemLevel = 305, amountOfMats = 0.625},
				{itemType = WEAPON, rarity = 2, minItemLevel = 306, maxItemLevel = 315, amountOfMats = 0.75},
				{itemType = WEAPON, rarity = 2, minItemLevel = 316, maxItemLevel = 325, amountOfMats = 0.875},
				{itemType = WEAPON, rarity = 2, minItemLevel = 326, maxItemLevel = 350, amountOfMats = 1},
			},
		},
		["i:74249"] = { -- Spirit Dust
			minLevel = 83,
			maxLevel = 88,
			sourceInfo = {
				{itemType = ARMOR, rarity = 2, minItemLevel = 364, maxItemLevel = 390, amountOfMats = 2.125},
				{itemType = ARMOR, rarity = 2, minItemLevel = 391, maxItemLevel = 410, amountOfMats = 2.55},
				{itemType = ARMOR, rarity = 2, minItemLevel = 411, maxItemLevel = 450, amountOfMats = 3.4},
				{itemType = WEAPON, rarity = 2, minItemLevel = 377, maxItemLevel = 390, amountOfMats = 2.125},
				{itemType = WEAPON, rarity = 2, minItemLevel = 391, maxItemLevel = 410, amountOfMats = 2.55},
				{itemType = WEAPON, rarity = 2, minItemLevel = 411, maxItemLevel = 450, amountOfMats = 3.4},
			},
		},
		["i:109693"] = { -- Draenic Dust
			minLevel = 90,
			maxLevel = 100,
			sourceInfo = {
				{itemType = ARMOR, rarity = 2, minItemLevel = 483, maxItemLevel = 593, amountOfMats = 2.125},
				{itemType = ARMOR, rarity = 3, minItemLevel = 505, maxItemLevel = 593, amountOfMats = 8.1},
				{itemType = ARMOR, rarity = 3, minItemLevel = 594, maxItemLevel = 630, amountOfMats = 12},
				{itemType = WEAPON, rarity = 2, minItemLevel = 483, maxItemLevel = 593, amountOfMats = 2.125},
				{itemType = WEAPON, rarity = 3, minItemLevel = 505, maxItemLevel = 593, amountOfMats = 8.1},
				{itemType = WEAPON, rarity = 3, minItemLevel = 594, maxItemLevel = 630, amountOfMats = 12},
			},
		},
	},
	{
		desc = L["Essences"],
		["i:10939"] = { -- Greater Magic Essence
			minLevel = 1,
			maxLevel = 15,
			sourceInfo = {
				{itemType = ARMOR, rarity = 2, minItemLevel = 5, maxItemLevel = 15, amountOfMats = 0.1},
				{itemType = ARMOR, rarity = 2, minItemLevel = 16, maxItemLevel = 20, amountOfMats = 0.3},
				{itemType = WEAPON, rarity = 2, minItemLevel = 5, maxItemLevel = 15, amountOfMats = 0.4},
				{itemType = WEAPON, rarity = 2, minItemLevel = 16, maxItemLevel = 20, amountOfMats = 1.125},
			},
		},
		["i:11082"] = { -- Greater Astral Essence
			minLevel = 16,
			maxLevel = 25,
			sourceInfo = {
				{itemType = ARMOR, rarity = 2, minItemLevel = 21, maxItemLevel = 25, amountOfMats = .075},
				{itemType = ARMOR, rarity = 2, minItemLevel = 26, maxItemLevel = 30, amountOfMats = 0.3},
				{itemType = WEAPON, rarity = 2, minItemLevel = 21, maxItemLevel = 25, amountOfMats = 0.375},
				{itemType = WEAPON, rarity = 2, minItemLevel = 26, maxItemLevel = 30, amountOfMats = 1.125},
			},
		},
		["i:11135"] = { -- Greater Mystic Essence
			minLevel = 26,
			maxLevel = 35,
			sourceInfo = {
				{itemType = ARMOR, rarity = 2, minItemLevel = 31, maxItemLevel = 35, amountOfMats = 0.1},
				{itemType = ARMOR, rarity = 2, minItemLevel = 36, maxItemLevel = 40, amountOfMats = 0.3},
				{itemType = WEAPON, rarity = 2, minItemLevel = 31, maxItemLevel = 35, amountOfMats = 0.375},
				{itemType = WEAPON, rarity = 2, minItemLevel = 36, maxItemLevel = 40, amountOfMats = 1.125},
			},
		},
		["i:11175"] = { -- Greater Nether Essence
			minLevel = 36,
			maxLevel = 45,
			sourceInfo = {
				{itemType = ARMOR, rarity = 2, minItemLevel = 41, maxItemLevel = 45, amountOfMats = 0.1},
				{itemType = ARMOR, rarity = 2, minItemLevel = 46, maxItemLevel = 50, amountOfMats = 0.3},
				{itemType = WEAPON, rarity = 2, minItemLevel = 41, maxItemLevel = 45, amountOfMats = 0.375},
				{itemType = WEAPON, rarity = 2, minItemLevel = 46, maxItemLevel = 50, amountOfMats = 1.125},
			},
		},
		["i:16203"] = { -- Greater Eternal Essence
			minLevel = 46,
			maxLevel = 60,
			sourceInfo = {
				{itemType = ARMOR, rarity = 2, minItemLevel = 51, maxItemLevel = 55, amountOfMats = 0.1},
				{itemType = ARMOR, rarity = 2, minItemLevel = 56, maxItemLevel = 60, amountOfMats = 0.3},
				{itemType = ARMOR, rarity = 2, minItemLevel = 61, maxItemLevel = 65, amountOfMats = 0.5},
				{itemType = WEAPON, rarity = 2, minItemLevel = 51, maxItemLevel = 55, amountOfMats = 0.375},
				{itemType = WEAPON, rarity = 2, minItemLevel = 56, maxItemLevel = 60, amountOfMats = 0.125},
				{itemType = WEAPON, rarity = 2, minItemLevel = 61, maxItemLevel = 65, amountOfMats = 1.875},
			},
		},
		["i:22446"] = { -- Greater Planar Essence
			minLevel = 58,
			maxLevel = 70,
			sourceInfo = {
				{itemType = ARMOR, rarity = 2, minItemLevel = 66, maxItemLevel = 99, amountOfMats = 0.167},
				{itemType = ARMOR, rarity = 2, minItemLevel = 100, maxItemLevel = 120, amountOfMats = 0.3},
				{itemType = WEAPON, rarity = 2, minItemLevel = 79, maxItemLevel = 79, amountOfMats = 0.625},
				{itemType = WEAPON, rarity = 2, minItemLevel = 80, maxItemLevel = 99, amountOfMats = 0.625},
				{itemType = WEAPON, rarity = 2, minItemLevel = 100, maxItemLevel = 120, amountOfMats = 1.125},
			},
		},
		["i:34055"] = { -- Greater Cosmic Essence
			minLevel = 67,
			maxLevel = 80,
			sourceInfo = {
				{itemType = ARMOR, rarity = 2, minItemLevel = 130, maxItemLevel = 151, amountOfMats = 0.1},
				{itemType = ARMOR, rarity = 2, minItemLevel = 152, maxItemLevel = 200, amountOfMats = 0.3},
				{itemType = WEAPON, rarity = 2, minItemLevel = 130, maxItemLevel = 151, amountOfMats = 0.375},
				{itemType = WEAPON, rarity = 2, minItemLevel = 152, maxItemLevel = 200, amountOfMats = 1.125},
			},
		},
		["i:52719"] = { -- Greater Celestial Essence
			minLevel = 77,
			maxLevel = 85,
			sourceInfo = {
				{itemType = ARMOR, rarity = 2, minItemLevel = 201, maxItemLevel = 275, amountOfMats = 0.125},
				{itemType = ARMOR, rarity = 2, minItemLevel = 276, maxItemLevel = 290, amountOfMats = 0.167},
				{itemType = ARMOR, rarity = 2, minItemLevel = 291, maxItemLevel = 305, amountOfMats = 0.208},
				{itemType = ARMOR, rarity = 2, minItemLevel = 306, maxItemLevel = 315, amountOfMats = 0.375},
				{itemType = ARMOR, rarity = 2, minItemLevel = 316, maxItemLevel = 325, amountOfMats = 0.625},
				{itemType = ARMOR, rarity = 2, minItemLevel = 326, maxItemLevel = 350, amountOfMats = 0.75},
				{itemType = WEAPON, rarity = 2, minItemLevel = 201, maxItemLevel = 275, amountOfMats = 0.375},
				{itemType = WEAPON, rarity = 2, minItemLevel = 276, maxItemLevel = 290, amountOfMats = 0.5},
				{itemType = WEAPON, rarity = 2, minItemLevel = 291, maxItemLevel = 305, amountOfMats = 0.625},
				{itemType = WEAPON, rarity = 2, minItemLevel = 306, maxItemLevel = 315, amountOfMats = 1.125},
				{itemType = WEAPON, rarity = 2, minItemLevel = 316, maxItemLevel = 325, amountOfMats = 1.875},
				{itemType = WEAPON, rarity = 2, minItemLevel = 326, maxItemLevel = 350, amountOfMats = 2.25},
			},
		},
		["i:74250"] = { -- Mysterious Essence
			minLevel = 83,
			maxLevel = 88,
			sourceInfo = {
				{itemType = ARMOR, rarity = 2, minItemLevel = 364, maxItemLevel = 390, amountOfMats = 0.15},
				{itemType = ARMOR, rarity = 2, minItemLevel = 391, maxItemLevel = 410, amountOfMats = 0.225},
				{itemType = ARMOR, rarity = 2, minItemLevel = 411, maxItemLevel = 450, amountOfMats = 0.3},
				{itemType = WEAPON, rarity = 2, minItemLevel = 377, maxItemLevel = 390, amountOfMats = 0.15},
				{itemType = WEAPON, rarity = 2, minItemLevel = 391, maxItemLevel = 410, amountOfMats = 0.225},
				{itemType = WEAPON, rarity = 2, minItemLevel = 411, maxItemLevel = 450, amountOfMats = 0.3},
			},
		},
	},
	{
		desc = L["Shards"],
		["i:10978"] = { -- Small Glimmering Shard
			minLevel = 1,
			maxLevel = 20,
			sourceInfo = {
				{itemType = ARMOR, rarity = 2, minItemLevel = 1, maxItemLevel = 20, amountOfMats = 0.05},
				{itemType = ARMOR, rarity = 2, minItemLevel = 21, maxItemLevel = 25, amountOfMats = 0.1},
				{itemType = ARMOR, rarity = 3, minItemLevel = 1, maxItemLevel = 25, amountOfMats = 1.000},
				{itemType = WEAPON, rarity = 3, minItemLevel = 1, maxItemLevel = 25, amountOfMats = 1.000},
			},
		},
		["i:11084"] = { -- Large Glimmering Shard
			minLevel = 16,
			maxLevel = 25,
			sourceInfo = {
				{itemType = ARMOR, rarity = 2, minItemLevel = 26, maxItemLevel = 30, amountOfMats = 0.05},
				{itemType = ARMOR, rarity = 3, minItemLevel = 26, maxItemLevel = 30, amountOfMats = 1.000},
				{itemType = WEAPON, rarity = 3, minItemLevel = 26, maxItemLevel = 30, amountOfMats = 1.000},
			},
		},
		["i:11138"] = { -- Small Glowing Shard
			minLevel = 26,
			maxLevel = 30,
			sourceInfo = {
				{itemType = ARMOR, rarity = 2, minItemLevel = 31, maxItemLevel = 35, amountOfMats = 0.05},
				{itemType = ARMOR, rarity = 3, minItemLevel = 31, maxItemLevel = 35, amountOfMats = 1.000},
				{itemType = WEAPON, rarity = 2, minItemLevel = 31, maxItemLevel = 35, amountOfMats = 0.05},
				{itemType = WEAPON, rarity = 3, minItemLevel = 31, maxItemLevel = 35, amountOfMats = 1.000},
			},
		},
		["i:11139"] = { -- Large Glowing Shard
			minLevel = 31,
			maxLevel = 35,
			sourceInfo = {
				{itemType = ARMOR, rarity = 2, minItemLevel = 36, maxItemLevel = 40, amountOfMats = 0.05},
				{itemType = ARMOR, rarity = 3, minItemLevel = 36, maxItemLevel = 40, amountOfMats = 1.000},
				{itemType = WEAPON, rarity = 2, minItemLevel = 36, maxItemLevel = 40, amountOfMats = 0.05},
				{itemType = WEAPON, rarity = 3, minItemLevel = 36, maxItemLevel = 40, amountOfMats = 1.000},
			},
		},
		["i:11177"] = { -- Small Radiant Shard
			minLevel = 36,
			maxLevel = 40,
			sourceInfo = {
				{itemType = ARMOR, rarity = 2, minItemLevel = 41, maxItemLevel = 45, amountOfMats = 0.05},
				{itemType = ARMOR, rarity = 3, minItemLevel = 41, maxItemLevel = 45, amountOfMats = 1.000},
				{itemType = ARMOR, rarity = 4, minItemLevel = 36, maxItemLevel = 40, amountOfMats = 3},
				{itemType = ARMOR, rarity = 4, minItemLevel = 41, maxItemLevel = 45, amountOfMats = 3.5},
				{itemType = WEAPON, rarity = 2, minItemLevel = 41, maxItemLevel = 45, amountOfMats = 0.05},
				{itemType = WEAPON, rarity = 3, minItemLevel = 41, maxItemLevel = 45, amountOfMats = 1.000},
				{itemType = WEAPON, rarity = 4, minItemLevel = 36, maxItemLevel = 40, amountOfMats = 3},
				{itemType = WEAPON, rarity = 4, minItemLevel = 41, maxItemLevel = 45, amountOfMats = 3.5},
			},
		},
		["i:11178"] = { -- Large Radiant Shard
			minLevel = 41,
			maxLevel = 45,
			sourceInfo = {
				{itemType = ARMOR, rarity = 2, minItemLevel = 46, maxItemLevel = 50, amountOfMats = 0.05},
				{itemType = ARMOR, rarity = 3, minItemLevel = 46, maxItemLevel = 50, amountOfMats = 1.000},
				{itemType = ARMOR, rarity = 4, minItemLevel = 46, maxItemLevel = 50, amountOfMats = 3.5},
				{itemType = WEAPON, rarity = 2, minItemLevel = 46, maxItemLevel = 50, amountOfMats = 0.05},
				{itemType = WEAPON, rarity = 3, minItemLevel = 46, maxItemLevel = 50, amountOfMats = 1.000},
				{itemType = WEAPON, rarity = 4, minItemLevel = 46, maxItemLevel = 50, amountOfMats = 3.5},
			},
		},
		["i:14343"] = { -- Small Brilliant Shard
			minLevel = 46,
			maxLevel = 50,
			sourceInfo = {
				{itemType = ARMOR, rarity = 2, minItemLevel = 51, maxItemLevel = 55, amountOfMats = 0.05},
				{itemType = ARMOR, rarity = 3, minItemLevel = 51, maxItemLevel = 55, amountOfMats = 1.000},
				{itemType = ARMOR, rarity = 4, minItemLevel = 51, maxItemLevel = 55, amountOfMats = 3.5},
				{itemType = WEAPON, rarity = 2, minItemLevel = 51, maxItemLevel = 55, amountOfMats = 0.05},
				{itemType = WEAPON, rarity = 3, minItemLevel = 51, maxItemLevel = 55, amountOfMats = 1.000},
				{itemType = WEAPON, rarity = 4, minItemLevel = 51, maxItemLevel = 55, amountOfMats = 3.5},
			},
		},
		["i:14344"] = { -- Large Brilliant Shard
			minLevel = 56,
			maxLevel = 75,
			sourceInfo = {
				{itemType = ARMOR, rarity = 2, minItemLevel = 56, maxItemLevel = 65, amountOfMats = 0.05},
				{itemType = ARMOR, rarity = 3, minItemLevel = 56, maxItemLevel = 65, amountOfMats = 0.995},
				{itemType = WEAPON, rarity = 2, minItemLevel = 56, maxItemLevel = 65, amountOfMats = 0.05},
				{itemType = WEAPON, rarity = 3, minItemLevel = 56, maxItemLevel = 65, amountOfMats = 0.995},
			},
		},
		["i:22449"] = { -- Large Prismatic Shard
			minLevel = 56,
			maxLevel = 70,
			sourceInfo = {
				{itemType = ARMOR, rarity = 2, minItemLevel = 66, maxItemLevel = 99, amountOfMats = 0.0167},
				{itemType = ARMOR, rarity = 2, minItemLevel = 100, maxItemLevel = 120, amountOfMats = 0.05},
				{itemType = ARMOR, rarity = 3, minItemLevel = 66, maxItemLevel = 99, amountOfMats = 0.33},
				{itemType = ARMOR, rarity = 3, minItemLevel = 100, maxItemLevel = 120, amountOfMats = 1},
				{itemType = WEAPON, rarity = 2, minItemLevel = 66, maxItemLevel = 99, amountOfMats = 0.0167},
				{itemType = WEAPON, rarity = 2, minItemLevel = 100, maxItemLevel = 120, amountOfMats = 0.05},
				{itemType = WEAPON, rarity = 3, minItemLevel = 66, maxItemLevel = 99, amountOfMats = 0.33},
				{itemType = WEAPON, rarity = 3, minItemLevel = 100, maxItemLevel = 120, amountOfMats = 1},
			},
		},
		["i:34052"] = { -- Dream Shard
			minLevel = 68,
			maxLevel = 80,
			sourceInfo = {
				{itemType = ARMOR, rarity = 2, minItemLevel = 121, maxItemLevel = 151, amountOfMats = 0.0167},
				{itemType = ARMOR, rarity = 2, minItemLevel = 152, maxItemLevel = 200, amountOfMats = 0.05},
				{itemType = ARMOR, rarity = 3, minItemLevel = 121, maxItemLevel = 164, amountOfMats = 0.33},
				{itemType = ARMOR, rarity = 3, minItemLevel = 165, maxItemLevel = 200, amountOfMats = 1},
				{itemType = WEAPON, rarity = 2, minItemLevel = 121, maxItemLevel = 151, amountOfMats = 0.0167},
				{itemType = WEAPON, rarity = 2, minItemLevel = 152, maxItemLevel = 200, amountOfMats = 0.05},
				{itemType = WEAPON, rarity = 3, minItemLevel = 121, maxItemLevel = 164, amountOfMats = 0.33},
				{itemType = WEAPON, rarity = 3, minItemLevel = 165, maxItemLevel = 200, amountOfMats = 1},
			},
		},
		["i:52720"] = { -- Small Heavenly Shard
			minLevel = 78,
			maxLevel = 85,
			sourceInfo = {
				{itemType = ARMOR, rarity = 3, minItemLevel = 282, maxItemLevel = 316, amountOfMats = 1},
				{itemType = WEAPON, rarity = 3, minItemLevel = 282, maxItemLevel = 316, amountOfMats = 1},
			},
		},
		["i:52721"] = { -- Heavenly Shard
			minLevel = 78,
			maxLevel = 85,
			sourceInfo = {
				{itemType = ARMOR, rarity = 3, minItemLevel = 282, maxItemLevel = 316, amountOfMats = 0.33},
				{itemType = ARMOR, rarity = 3, minItemLevel = 317, maxItemLevel = 377, amountOfMats = 1},
				{itemType = WEAPON, rarity = 3, minItemLevel = 282, maxItemLevel = 316, amountOfMats = 0.33},
				{itemType = WEAPON, rarity = 3, minItemLevel = 317, maxItemLevel = 377, amountOfMats = 1},
			},
		},
		["i:74252"] = { --Small Ethereal Shard
			minLevel = 85,
			maxLevel = 90,
			sourceInfo = {
				{itemType = ARMOR, rarity = 3, minItemLevel = 384, maxItemLevel = 429, amountOfMats = 1},
				{itemType = WEAPON, rarity = 3, minItemLevel = 384, maxItemLevel = 429, amountOfMats = 1},
			},
		},
		["i:74247"] = { -- Ethereal Shard
			minLevel = 85,
			maxLevel = 90,
			sourceInfo = {
				{itemType = ARMOR, rarity = 3, minItemLevel = 384, maxItemLevel = 429, amountOfMats = 0.33},
				{itemType = ARMOR, rarity = 3, minItemLevel = 430, maxItemLevel = 500, amountOfMats = 1},
				{itemType = WEAPON, rarity = 3, minItemLevel = 384, maxItemLevel = 429, amountOfMats = 0.33},
				{itemType = WEAPON, rarity = 3, minItemLevel = 430, maxItemLevel = 500, amountOfMats = 1},
			},
		},
		["i:111245"] = { -- Luminous Shard
			minLevel = 90,
			maxLevel = 100,
			sourceInfo = {
				{itemType = ARMOR, rarity = 3, minItemLevel = 505, maxItemLevel = 569, amountOfMats = 0.14},
				{itemType = ARMOR, rarity = 3, minItemLevel = 570, maxItemLevel = 630, amountOfMats = 0.14},
				{itemType = WEAPON, rarity = 3, minItemLevel = 505, maxItemLevel = 569, amountOfMats = 0.14},
				{itemType = WEAPON, rarity = 3, minItemLevel = 570, maxItemLevel = 630, amountOfMats = 0.14},
			},
		},
	},
	{
		desc = L["Crystals"],
		["i:20725"] = { -- Nexus Crystal
			minLevel = 56,
			maxLevel = 60,
			sourceInfo = {
				{itemType = ARMOR, rarity = 4, minItemLevel = 56, maxItemLevel = 60, amountOfMats = 1.000},
				{itemType = ARMOR, rarity = 4, minItemLevel = 61, maxItemLevel = 94, amountOfMats = 1.5},
				{itemType = WEAPON, rarity = 4, minItemLevel = 56, maxItemLevel = 60, amountOfMats = 1.000},
				{itemType = WEAPON, rarity = 4, minItemLevel = 61, maxItemLevel = 94, amountOfMats = 1.5},
			},
		},
		["i:22450"] = { -- Void Crystal
			minLevel = 70,
			maxLevel = 70,
			sourceInfo = {
				{itemType = ARMOR, rarity = 4, minItemLevel = 95, maxItemLevel = 99, amountOfMats = 1},
				{itemType = ARMOR, rarity = 4, minItemLevel = 100, maxItemLevel = 164, amountOfMats = 1.5},
				{itemType = WEAPON, rarity = 4, minItemLevel = 95, maxItemLevel = 99, amountOfMats = 1},
				{itemType = WEAPON, rarity = 4, minItemLevel = 100, maxItemLevel = 164, amountOfMats = 1.5},
			},
		},
		["i:34057"] = { -- Abyss Crystal
			minLevel = 80,
			maxLevel = 80,
			sourceInfo = {
				{itemType = ARMOR, rarity = 4, minItemLevel = 165, maxItemLevel = 299, amountOfMats = 1.000},
				{itemType = WEAPON, rarity = 4, minItemLevel = 165, maxItemLevel = 299, amountOfMats = 1.000},
			},
		},
		["i:52722"] = { -- Maelstrom Crystal
			minLevel = 85,
			maxLevel = 85,
			sourceInfo = {
				{itemType = ARMOR, rarity = 4, minItemLevel = 300, maxItemLevel = 419, amountOfMats = 1.000},
				{itemType = WEAPON, rarity = 4, minItemLevel = 285, maxItemLevel = 419, amountOfMats = 1.000},
			},
		},
		["i:74248"] = { -- Sha Crystal
			minLevel = 85,
			maxLevel = 90,
			sourceInfo = {
				{itemType = ARMOR, rarity = 4, minItemLevel = 420, maxItemLevel = 600, amountOfMats = 1.000},
				{itemType = WEAPON, rarity = 4, minItemLevel = 420, maxItemLevel = 600, amountOfMats = 1.000},
			},
		},
		["i:115504"] = { -- Fractured Temporal Crystal
			minLevel = 90,
			maxLevel = 100,
			sourceInfo = {
				{itemType = ARMOR, rarity = 4, minItemLevel = 630, maxItemLevel = 655, amountOfMats = 5},
				{itemType = WEAPON, rarity = 4, minItemLevel = 630, maxItemLevel = 655, amountOfMats = 5},
			},
		},
		["i:113588"] = { -- Temporal Crystal
			minLevel = 90,
			maxLevel = 100,
			sourceInfo = {
				{itemType = ARMOR, rarity = 4, minItemLevel = 630, maxItemLevel = 655, amountOfMats = 0.13},
				{itemType = WEAPON, rarity = 4, minItemLevel = 630, maxItemLevel = 655, amountOfMats = 0.13},
			},
		},
	},
}

private.notDisenchantable = {
	["i:11290"] = true,
	["i:11289"] = true,
	["i:11288"] = true,
	["i:11287"] = true,
	["i:60223"] = true,
	["i:52252"] = true,
	["i:20406"] = true,
	["i:20407"] = true,
	["i:20408"] = true,
	["i:21766"] = true,
	["i:52485"] = true,
	["i:52486"] = true,
	["i:52487"] = true,
	["i:52488"] = true,
	["i:75274"] = true,
	["i:97826"] = true,
	["i:97827"] = true,
	["i:97828"] = true,
	["i:97829"] = true,
	["i:97830"] = true,
	["i:97831"] = true,
	["i:97832"] = true,
	["i:109262"] = true,
}

do
	for _, data in pairs(private.disenchantInfo) do
		for itemString in pairs(data) do
			if itemString ~= "desc" then
				TSMAPI:QueryItemInfo(itemString)
			end
		end
	end
end