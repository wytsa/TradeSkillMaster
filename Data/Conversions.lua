-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)
local private = {data={}, targetItemNameLookup=nil, sourceItemCache=nil, skippedConversions={}}



-- ============================================================================
-- TSMAPI Functions
-- ============================================================================

function TSMAPI.Conversions:Add(targetItem, sourceItem, rate, method)
	targetItem = TSMAPI:GetBaseItemString2(targetItem)
	sourceItem = TSMAPI:GetBaseItemString2(sourceItem)
	private.data[targetItem] = private.data[targetItem] or {}
	if private.data[targetItem][sourceItem] then
		-- if there is more than one way to go from source to target, then just skip all conversions between these items
		private.skippedConversions[targetItem..sourceItem] = true
		private.data[targetItem][sourceItem] = nil
	end
	if private.skippedConversions[targetItem..sourceItem] then return end
	private.data[targetItem][sourceItem] = {rate=rate, method=method, hasItemInfo=nil}
	TSMAPI:QueryItemInfo(targetItem)
	TSMAPI:QueryItemInfo(sourceItem)
	private.targetItemNameLookup = nil
	private.sourceItemCache = nil
end

function TSMAPI.Conversions:GetData(targetItem)
	targetItem = TSMAPI:GetBaseItemString2(targetItem)
	return private.data[targetItem]
end

function TSMAPI.Conversions:GetTargetItemByName(targetItemName)
	targetItemName = strlower(targetItemName)
	for itemString, data in pairs(private.data) do
		local name = TSMAPI:GetSafeItemInfo(itemString)
		if strlower(name) == targetItemName then
			return TSMAPI:GetItemString(itemString)
		end
	end
end

function TSMAPI.Conversions:GetTargetItemNames()
	if private.targetItemNameLookup then return private.targetItemNameLookup, true end
	local result = {}
	local completeResult = true
	for itemString in pairs(private.data) do
		local name = TSMAPI:GetSafeItemInfo(itemString)
		if name then
			tinsert(result, strlower(name))
		else
			completeResult = false
		end
	end
	if completeResult then
		private.targetItemNameLookup = result
	end
	sort(result)
	return result, completeResult
end

local MAX_CONVERSION_DEPTH = 3
local function GetSourceItemsHelper(targetItem, result, depth, currentRate)
	if depth >= MAX_CONVERSION_DEPTH then return end
	if not private.data[targetItem] then return end
	for sourceItem, info in pairs(private.data[targetItem]) do
		if not result[sourceItem] or result[sourceItem].depth > depth then
			result[sourceItem] = result[sourceItem] or {}
			result[sourceItem].rate = info.rate * currentRate
			result[sourceItem].method = (depth == 0) and info.method or "multiple"
			result[sourceItem].depth = depth
			if info.method == "mill" or info.method == "prospect" then
				result[sourceItem].requiresFive = true
			end
			GetSourceItemsHelper(sourceItem, result, depth+1, result[sourceItem].rate)
		end
	end
end
function TSMAPI.Conversions:GetSourceItems(targetItem)
	targetItem = TSMAPI:GetBaseItemString2(targetItem)
	if not private.data[targetItem] then return end
	private.sourceItemCache = private.sourceItemCache or {}
	if not private.sourceItemCache[targetItem] then
		private.sourceItemCache[targetItem] = {}
		private.sourceItemCache[targetItem][targetItem] = {depth=-1} -- temporarily set this so we don't loop back through the target item
		GetSourceItemsHelper(targetItem, private.sourceItemCache[targetItem], 0, 1)
		private.sourceItemCache[targetItem][targetItem] = nil
	end
	return private.sourceItemCache[targetItem]
end

function TSMAPI.Conversions:GetConvertCost(targetItem, priceSource)
	local conversions = TSMAPI.Conversions:GetSourceItems(targetItem)
	if not conversions then return end
	
	local minPrice = nil
	for itemString, info in pairs(conversions) do
		local price = TSMAPI:GetItemValue(itemString, priceSource)
		if price then
			price = price / info.rate
			minPrice = min(minPrice or price, price)
		end
	end
	return minPrice
end

function TSMAPI.Conversions:GetTargetItemsByMethod(method)
	local result = {}
	for itemString, items in pairs(private.data) do
		for _, info in pairs(items) do
			if info.method == method then
				tinsert(result, TSMAPI:GetItemString(itemString))
				break
			end
		end
	end
	return result
end

function TSMAPI.Conversions:GetValue(itemString, priceSource, method)
	itemString = TSMAPI:GetBaseItemString2(itemString)
	local value = 0
	for targetItem, items in pairs(private.data) do
		if items[itemString] and (not method or items[itemString].method == method) then
			local matValue = TSMAPI:GetCustomPriceValue(TSM.db.profile.destroyValueSource, targetItem)
			value = value + (matValue or 0) * items[itemString].rate
		end
	end
	
	value = TSMAPI:Round(value)
	return value > 0 and value or nil
end



-- ============================================================================
-- Static Pre-Defined Conversions
-- ============================================================================

-- ====================================== Common Pigments ======================================
-- Alabaster Pigment (Ivory / Moonglow Ink)
TSMAPI.Conversions:Add("i:39151", "i:765", 0.5, "mill")
TSMAPI.Conversions:Add("i:39151", "i:2447", 0.5, "mill")
TSMAPI.Conversions:Add("i:39151", "i:2449", 0.6, "mill")
-- Azure Pigment (Ink of the Sea)
TSMAPI.Conversions:Add("i:39343", "i:39969", 0.5, "mill")
TSMAPI.Conversions:Add("i:39343", "i:36904", 0.5, "mill")
TSMAPI.Conversions:Add("i:39343", "i:36907", 0.5, "mill")
TSMAPI.Conversions:Add("i:39343", "i:36901", 0.5, "mill")
TSMAPI.Conversions:Add("i:39343", "i:39970", 0.5, "mill")
TSMAPI.Conversions:Add("i:39343", "i:37921", 0.5, "mill")
TSMAPI.Conversions:Add("i:39343", "i:36905", 0.6, "mill")
TSMAPI.Conversions:Add("i:39343", "i:36906", 0.6, "mill")
TSMAPI.Conversions:Add("i:39343", "i:36903", 0.6, "mill")
 -- Ashen Pigment (Blackfallow Ink)
TSMAPI.Conversions:Add("i:61979", "i:52983", 0.5, "mill")
TSMAPI.Conversions:Add("i:61979", "i:52984", 0.5, "mill")
TSMAPI.Conversions:Add("i:61979", "i:52985", 0.5, "mill")
TSMAPI.Conversions:Add("i:61979", "i:52986", 0.5, "mill")
TSMAPI.Conversions:Add("i:61979", "i:52987", 0.6, "mill")
TSMAPI.Conversions:Add("i:61979", "i:52988", 0.6, "mill")
 -- Dusky Pigment (Midnight Ink)
TSMAPI.Conversions:Add("i:39334", "i:785", 0.5, "mill")
TSMAPI.Conversions:Add("i:39334", "i:2450", 0.5, "mill")
TSMAPI.Conversions:Add("i:39334", "i:2452", 0.5, "mill")
TSMAPI.Conversions:Add("i:39334", "i:2453", 0.6, "mill")
TSMAPI.Conversions:Add("i:39334", "i:3820", 0.6, "mill")
-- Emerald Pigment (Jadefire Ink)
TSMAPI.Conversions:Add("i:39339", "i:3818", 0.5, "mill")
TSMAPI.Conversions:Add("i:39339", "i:3821", 0.5, "mill")
TSMAPI.Conversions:Add("i:39339", "i:3358", 0.6, "mill")
TSMAPI.Conversions:Add("i:39339", "i:3819", 0.6, "mill")
-- Golden Pigment (Lion's Ink)
TSMAPI.Conversions:Add("i:39338", "i:3355", 0.5, "mill")
TSMAPI.Conversions:Add("i:39338", "i:3369", 0.5, "mill")
TSMAPI.Conversions:Add("i:39338", "i:3356", 0.6, "mill")
TSMAPI.Conversions:Add("i:39338", "i:3357", 0.6, "mill")
-- Nether Pigment (Ethereal Ink)
TSMAPI.Conversions:Add("i:39342", "i:22785", 0.5, "mill")
TSMAPI.Conversions:Add("i:39342", "i:22786", 0.5, "mill")
TSMAPI.Conversions:Add("i:39342", "i:22787", 0.5, "mill")
TSMAPI.Conversions:Add("i:39342", "i:22789", 0.5, "mill")
TSMAPI.Conversions:Add("i:39342", "i:22790", 0.6, "mill")
TSMAPI.Conversions:Add("i:39342", "i:22791", 0.6, "mill")
TSMAPI.Conversions:Add("i:39342", "i:22792", 0.6, "mill")
TSMAPI.Conversions:Add("i:39342", "i:22793", 0.6, "mill")
-- Shadow Pigment (Ink of Dreams)
TSMAPI.Conversions:Add("i:79251", "i:72237", 0.5, "mill")
TSMAPI.Conversions:Add("i:79251", "i:72234", 0.5, "mill")
TSMAPI.Conversions:Add("i:79251", "i:79010", 0.5, "mill")
TSMAPI.Conversions:Add("i:79251", "i:72235", 0.5, "mill")
TSMAPI.Conversions:Add("i:79251", "i:89639", 0.5, "mill")
TSMAPI.Conversions:Add("i:79251", "i:79011", 0.6, "mill")
-- Silvery Pigment (Shimmering Ink)
TSMAPI.Conversions:Add("i:39341", "i:13463", 0.5, "mill")
TSMAPI.Conversions:Add("i:39341", "i:13464", 0.5, "mill")
TSMAPI.Conversions:Add("i:39341", "i:13465", 0.6, "mill")
TSMAPI.Conversions:Add("i:39341", "i:13466", 0.6, "mill")
TSMAPI.Conversions:Add("i:39341", "i:13467", 0.6, "mill")
-- Violet Pigment (Celestial Ink)
TSMAPI.Conversions:Add("i:39340", "i:4625", 0.5, "mill")
TSMAPI.Conversions:Add("i:39340", "i:8831", 0.5, "mill")
TSMAPI.Conversions:Add("i:39340", "i:8838", 0.5, "mill")
TSMAPI.Conversions:Add("i:39340", "i:8839", 0.6, "mill")
TSMAPI.Conversions:Add("i:39340", "i:8845", 0.6, "mill")
TSMAPI.Conversions:Add("i:39340", "i:8846", 0.6, "mill")
-- Cerulean Pigment (Warbinder's Ink)
TSMAPI.Conversions:Add("i:114931", "i:109124", 0.4, "mill")
TSMAPI.Conversions:Add("i:114931", "i:109125", 0.4, "mill")
TSMAPI.Conversions:Add("i:114931", "i:109126", 0.4, "mill")
TSMAPI.Conversions:Add("i:114931", "i:109127", 0.4, "mill")
TSMAPI.Conversions:Add("i:114931", "i:109128", 0.4, "mill")
TSMAPI.Conversions:Add("i:114931", "i:109129", 0.4, "mill")
-- ======================================= Rare Pigments =======================================
-- Icy Pigment (Snowfall Ink)
TSMAPI.Conversions:Add("i:43109", "i:39969", 0.05, "mill")
TSMAPI.Conversions:Add("i:43109", "i:36904", 0.05, "mill")
TSMAPI.Conversions:Add("i:43109", "i:36907", 0.05, "mill")
TSMAPI.Conversions:Add("i:43109", "i:36901", 0.05, "mill")
TSMAPI.Conversions:Add("i:43109", "i:39970", 0.05, "mill")
TSMAPI.Conversions:Add("i:43109", "i:37921", 0.05, "mill")
TSMAPI.Conversions:Add("i:43109", "i:36905", 0.1, "mill")
TSMAPI.Conversions:Add("i:43109", "i:36906", 0.1, "mill")
TSMAPI.Conversions:Add("i:43109", "i:36903", 0.1, "mill")
-- Burning Embers (Inferno Ink)
TSMAPI.Conversions:Add("i:61980", "i:52983", 0.05, "mill")
TSMAPI.Conversions:Add("i:61980", "i:52984", 0.05, "mill")
TSMAPI.Conversions:Add("i:61980", "i:52985", 0.05, "mill")
TSMAPI.Conversions:Add("i:61980", "i:52986", 0.05, "mill")
TSMAPI.Conversions:Add("i:61980", "i:52987", 0.1, "mill")
TSMAPI.Conversions:Add("i:61980", "i:52988", 0.1, "mill")
-- Burnt Pigment (Dawnstar Ink)
TSMAPI.Conversions:Add("i:43104", "i:3356", 0.1, "mill")
TSMAPI.Conversions:Add("i:43104", "i:3357", 0.1, "mill")
TSMAPI.Conversions:Add("i:43104", "i:3369", 0.05, "mill")
TSMAPI.Conversions:Add("i:43104", "i:3355", 0.05, "mill")
-- Ebon Pigment (Darkflame Ink)
TSMAPI.Conversions:Add("i:43108", "i:22792", 0.1, "mill")
TSMAPI.Conversions:Add("i:43108", "i:22790", 0.1, "mill")
TSMAPI.Conversions:Add("i:43108", "i:22791", 0.1, "mill")
TSMAPI.Conversions:Add("i:43108", "i:22793", 0.1, "mill")
TSMAPI.Conversions:Add("i:43108", "i:22786", 0.05, "mill")
TSMAPI.Conversions:Add("i:43108", "i:22785", 0.05, "mill")
TSMAPI.Conversions:Add("i:43108", "i:22787", 0.05, "mill")
TSMAPI.Conversions:Add("i:43108", "i:22789", 0.05, "mill")
-- Indigo Pigment (Royal Ink)
TSMAPI.Conversions:Add("i:43105", "i:3358", 0.1, "mill")
TSMAPI.Conversions:Add("i:43105", "i:3819", 0.1, "mill")
TSMAPI.Conversions:Add("i:43105", "i:3821", 0.05, "mill")
TSMAPI.Conversions:Add("i:43105", "i:3818", 0.05, "mill")
-- Misty Pigment (Starlight Ink)
TSMAPI.Conversions:Add("i:79253", "i:72237", 0.05, "mill")
TSMAPI.Conversions:Add("i:79253", "i:72234", 0.05, "mill")
TSMAPI.Conversions:Add("i:79253", "i:79010", 0.05, "mill")
TSMAPI.Conversions:Add("i:79253", "i:72235", 0.05, "mill")
TSMAPI.Conversions:Add("i:79253", "i:79011", 0.1, "mill")
TSMAPI.Conversions:Add("i:79253", "i:89639", 0.05, "mill")
-- Ruby Pigment (Fiery Ink)
TSMAPI.Conversions:Add("i:43106", "i:4625", 0.05, "mill")
TSMAPI.Conversions:Add("i:43106", "i:8838", 0.05, "mill")
TSMAPI.Conversions:Add("i:43106", "i:8831", 0.05, "mill")
TSMAPI.Conversions:Add("i:43106", "i:8845", 0.1, "mill")
TSMAPI.Conversions:Add("i:43106", "i:8846", 0.1, "mill")
TSMAPI.Conversions:Add("i:43106", "i:8839", 0.1, "mill")
-- Sapphire Pigment (Ink of the Sky)
TSMAPI.Conversions:Add("i:43107", "i:13463", 0.05, "mill")
TSMAPI.Conversions:Add("i:43107", "i:13464", 0.05, "mill")
TSMAPI.Conversions:Add("i:43107", "i:13465", 0.1, "mill")
TSMAPI.Conversions:Add("i:43107", "i:13466", 0.1, "mill")
TSMAPI.Conversions:Add("i:43107", "i:13467", 0.1, "mill")
-- Verdant Pigment (Hunter's Ink)
TSMAPI.Conversions:Add("i:43103", "i:2453", 0.1, "mill")
TSMAPI.Conversions:Add("i:43103", "i:3820", 0.1, "mill")
TSMAPI.Conversions:Add("i:43103", "i:2450", 0.05, "mill")
TSMAPI.Conversions:Add("i:43103", "i:785", 0.05, "mill")
TSMAPI.Conversions:Add("i:43103", "i:2452", 0.05, "mill")
-- ======================================== Vanilla Gems =======================================
-- Malachite
TSMAPI.Conversions:Add("i:774", "i:2770", 0.5, "prospect")
-- Tigerseye
TSMAPI.Conversions:Add("i:818", "i:2770", 0.5, "prospect")
-- Shadowgem
TSMAPI.Conversions:Add("i:1210", "i:2771", 0.4, "prospect")
TSMAPI.Conversions:Add("i:1210", "i:2770", 0.1, "prospect")
-- Moss Agate
TSMAPI.Conversions:Add("i:1206", "i:2771", 0.3, "prospect")
-- Lesser moonstone
TSMAPI.Conversions:Add("i:1705", "i:2771", 0.4, "prospect")
TSMAPI.Conversions:Add("i:1705", "i:2772", 0.3, "prospect")
-- Jade
TSMAPI.Conversions:Add("i:1529", "i:2772", 0.4, "prospect")
TSMAPI.Conversions:Add("i:1529", "i:2771", 0.03, "prospect")
-- Citrine
TSMAPI.Conversions:Add("i:3864", "i:2772", 0.4, "prospect")
TSMAPI.Conversions:Add("i:3864", "i:3858", 0.3, "prospect")
TSMAPI.Conversions:Add("i:3864", "i:2771", 0.03, "prospect")
-- Aquamarine
TSMAPI.Conversions:Add("i:7909", "i:3858", 0.3, "prospect")
TSMAPI.Conversions:Add("i:7909", "i:2772", 0.05, "prospect")
TSMAPI.Conversions:Add("i:7909", "i:2771", 0.03, "prospect")
-- Star Ruby
TSMAPI.Conversions:Add("i:7910", "i:3858", 0.4, "prospect")
TSMAPI.Conversions:Add("i:7910", "i:10620", 0.1, "prospect")
TSMAPI.Conversions:Add("i:7910", "i:2772", 0.05, "prospect")
-- Blue Sapphire
TSMAPI.Conversions:Add("i:12361", "i:10620", 0.3, "prospect")
TSMAPI.Conversions:Add("i:12361", "i:3858", 0.03, "prospect")
-- Large Opal
TSMAPI.Conversions:Add("i:12799", "i:10620", 0.3, "prospect")
TSMAPI.Conversions:Add("i:12799", "i:3858", 0.03, "prospect")
-- Azerothian Diamond
TSMAPI.Conversions:Add("i:12800", "i:10620", 0.3, "prospect")
TSMAPI.Conversions:Add("i:12800", "i:3858", 0.02, "prospect")
-- Huge Emerald
TSMAPI.Conversions:Add("i:12364", "i:10620", 0.3, "prospect")
TSMAPI.Conversions:Add("i:12364", "i:3858", 0.02, "prospect")
-- ======================================== Uncommon Gems ======================================
-- Azure Moonstone
TSMAPI.Conversions:Add("i:23117", "i:23424", 0.2, "prospect")
TSMAPI.Conversions:Add("i:23117", "i:23425", 0.2, "prospect")
-- Blood Garnet
TSMAPI.Conversions:Add("i:23077", "i:23424", 0.2, "prospect")
TSMAPI.Conversions:Add("i:23077", "i:23425", 0.2, "prospect")
-- Deep Peridot
TSMAPI.Conversions:Add("i:23079", "i:23424", 0.2, "prospect")
TSMAPI.Conversions:Add("i:23079", "i:23425", 0.2, "prospect")
-- Flame Spessarite
TSMAPI.Conversions:Add("i:21929", "i:23424", 0.2, "prospect")
TSMAPI.Conversions:Add("i:21929", "i:23425", 0.2, "prospect")
-- Golden Draenite
TSMAPI.Conversions:Add("i:23112", "i:23424", 0.2, "prospect")
TSMAPI.Conversions:Add("i:23112", "i:23425", 0.2, "prospect")
-- Shadow Draenite
TSMAPI.Conversions:Add("i:23107", "i:23424", 0.2, "prospect")
TSMAPI.Conversions:Add("i:23107", "i:23425", 0.2, "prospect")
-- Bloodstone
TSMAPI.Conversions:Add("i:36917", "i:36909", 0.25, "prospect")
TSMAPI.Conversions:Add("i:36917", "i:36912", 0.2, "prospect")
TSMAPI.Conversions:Add("i:36917", "i:36910", 0.25, "prospect")
-- Chalcedony
TSMAPI.Conversions:Add("i:36923", "i:36909", 0.25, "prospect")
TSMAPI.Conversions:Add("i:36923", "i:36912", 0.2, "prospect")
TSMAPI.Conversions:Add("i:36923", "i:36910", 0.25, "prospect")
-- Dark Jade
TSMAPI.Conversions:Add("i:36932", "i:36909", 0.25, "prospect")
TSMAPI.Conversions:Add("i:36932", "i:36912", 0.2, "prospect")
TSMAPI.Conversions:Add("i:36932", "i:36910", 0.25, "prospect")
-- Huge Citrine
TSMAPI.Conversions:Add("i:36929", "i:36909", 0.25, "prospect")
TSMAPI.Conversions:Add("i:36929", "i:36912", 0.2, "prospect")
TSMAPI.Conversions:Add("i:36929", "i:36910", 0.25, "prospect")
-- Shadow Crystal
TSMAPI.Conversions:Add("i:36926", "i:36909", 0.25, "prospect")
TSMAPI.Conversions:Add("i:36926", "i:36912", 0.2, "prospect")
TSMAPI.Conversions:Add("i:36926", "i:36910", 0.25, "prospect")
-- Sun Crystal
TSMAPI.Conversions:Add("i:36920", "i:36909", 0.25, "prospect")
TSMAPI.Conversions:Add("i:36920", "i:36912", 0.2, "prospect")
TSMAPI.Conversions:Add("i:36920", "i:36910", 0.2, "prospect")
-- Jasper
TSMAPI.Conversions:Add("i:52182", "i:53038", 0.25, "prospect")
TSMAPI.Conversions:Add("i:52182", "i:52185", 0.2, "prospect")
TSMAPI.Conversions:Add("i:52182", "i:52183", 0.2, "prospect")

TSMAPI.Conversions:Add("i:52180", "i:53038", 0.25, "prospect")
TSMAPI.Conversions:Add("i:52180", "i:52185", 0.2, "prospect")
TSMAPI.Conversions:Add("i:52180", "i:52183", 0.2, "prospect")
-- Zephyrite
TSMAPI.Conversions:Add("i:52178", "i:53038", 0.25, "prospect")
TSMAPI.Conversions:Add("i:52178", "i:52185", 0.2, "prospect")
TSMAPI.Conversions:Add("i:52178", "i:52183", 0.2, "prospect")
-- Alicite
TSMAPI.Conversions:Add("i:52179", "i:53038", 0.25, "prospect")
TSMAPI.Conversions:Add("i:52179", "i:52185", 0.2, "prospect")
TSMAPI.Conversions:Add("i:52179", "i:52183", 0.2, "prospect")
-- Carnelian
TSMAPI.Conversions:Add("i:52177", "i:53038", 0.25, "prospect")
TSMAPI.Conversions:Add("i:52177", "i:52185", 0.2, "prospect")
TSMAPI.Conversions:Add("i:52177", "i:52183", 0.2, "prospect")
-- Hessonite
TSMAPI.Conversions:Add("i:52181", "i:53038", 0.25, "prospect")
TSMAPI.Conversions:Add("i:52181", "i:52185", 0.2, "prospect")
TSMAPI.Conversions:Add("i:52181", "i:52183", 0.2, "prospect")
-- Tiger Opal
TSMAPI.Conversions:Add("i:76130", "i:72092", 0.25, "prospect")
TSMAPI.Conversions:Add("i:76130", "i:72093", 0.25, "prospect")
TSMAPI.Conversions:Add("i:76130", "i:72103", 0.2, "prospect")
TSMAPI.Conversions:Add("i:76130", "i:72094", 0.2, "prospect")
-- Lapis Lazuli
TSMAPI.Conversions:Add("i:76133", "i:72092", 0.25, "prospect")
TSMAPI.Conversions:Add("i:76133", "i:72093", 0.25, "prospect")
TSMAPI.Conversions:Add("i:76133", "i:72103", 0.2, "prospect")
TSMAPI.Conversions:Add("i:76133", "i:72094", 0.2, "prospect")
-- Sunstone
TSMAPI.Conversions:Add("i:76134", "i:72092", 0.25, "prospect")
TSMAPI.Conversions:Add("i:76134", "i:72093", 0.25, "prospect")
TSMAPI.Conversions:Add("i:76134", "i:72103", 0.2, "prospect")
TSMAPI.Conversions:Add("i:76134", "i:72094", 0.2, "prospect")
-- Roguestone
TSMAPI.Conversions:Add("i:76135", "i:72092", 0.25, "prospect")
TSMAPI.Conversions:Add("i:76135", "i:72093", 0.25, "prospect")
TSMAPI.Conversions:Add("i:76135", "i:72103", 0.2, "prospect")
TSMAPI.Conversions:Add("i:76135", "i:72094", 0.2, "prospect")
-- Pandarian Garnet
TSMAPI.Conversions:Add("i:76136", "i:72092", 0.25, "prospect")
TSMAPI.Conversions:Add("i:76136", "i:72093", 0.25, "prospect")
TSMAPI.Conversions:Add("i:76136", "i:72103", 0.2, "prospect")
TSMAPI.Conversions:Add("i:76136", "i:72094", 0.2, "prospect")
-- Alexandrite
TSMAPI.Conversions:Add("i:76137", "i:72092", 0.25, "prospect")
TSMAPI.Conversions:Add("i:76137", "i:72093", 0.25, "prospect")
TSMAPI.Conversions:Add("i:76137", "i:72103", 0.2, "prospect")
TSMAPI.Conversions:Add("i:76137", "i:72094", 0.2, "prospect")
-- ========================================== Rare Gems ========================================
-- Dawnstone
TSMAPI.Conversions:Add("i:23440", "i:23424", 0.01, "prospect")
TSMAPI.Conversions:Add("i:23440", "i:23425", 0.04, "prospect")
-- Living Ruby
TSMAPI.Conversions:Add("i:23436", "i:23424", 0.01, "prospect")
TSMAPI.Conversions:Add("i:23436", "i:23425", 0.04, "prospect")
-- Nightseye
TSMAPI.Conversions:Add("i:23441", "i:23424", 0.01, "prospect")
TSMAPI.Conversions:Add("i:23441", "i:23425", 0.04, "prospect")
-- Noble Topaz
TSMAPI.Conversions:Add("i:23439", "i:23424", 0.01, "prospect")
TSMAPI.Conversions:Add("i:23439", "i:23425", 0.04, "prospect")
-- Star of Elune
TSMAPI.Conversions:Add("i:23438", "i:23424", 0.01, "prospect")
TSMAPI.Conversions:Add("i:23438", "i:23425", 0.04, "prospect")
-- Talasite
TSMAPI.Conversions:Add("i:23437", "i:23424", 0.01, "prospect")
TSMAPI.Conversions:Add("i:23437", "i:23425", 0.04, "prospect")
-- Autumn's Glow
TSMAPI.Conversions:Add("i:36921", "i:36909", 0.01, "prospect")
TSMAPI.Conversions:Add("i:36921", "i:36912", 0.04, "prospect")
TSMAPI.Conversions:Add("i:36921", "i:36910", 0.04, "prospect")
-- Forest Emerald
TSMAPI.Conversions:Add("i:36933", "i:36909", 0.01, "prospect")
TSMAPI.Conversions:Add("i:36933", "i:36912", 0.04, "prospect")
TSMAPI.Conversions:Add("i:36933", "i:36910", 0.04, "prospect")
-- Monarch Topaz
TSMAPI.Conversions:Add("i:36930", "i:36909", 0.01, "prospect")
TSMAPI.Conversions:Add("i:36930", "i:36912", 0.04, "prospect")
TSMAPI.Conversions:Add("i:36930", "i:36910", 0.04, "prospect")
-- Scarlet Ruby
TSMAPI.Conversions:Add("i:36918", "i:36909", 0.01, "prospect")
TSMAPI.Conversions:Add("i:36918", "i:36912", 0.04, "prospect")
TSMAPI.Conversions:Add("i:36918", "i:36910", 0.04, "prospect")
-- Sky Sapphire
TSMAPI.Conversions:Add("i:36924", "i:36909", 0.01, "prospect")
TSMAPI.Conversions:Add("i:36924", "i:36912", 0.04, "prospect")
TSMAPI.Conversions:Add("i:36924", "i:36910", 0.04, "prospect")
-- Twilight Opal
TSMAPI.Conversions:Add("i:36927", "i:36909", 0.01, "prospect")
TSMAPI.Conversions:Add("i:36927", "i:36912", 0.04, "prospect")
TSMAPI.Conversions:Add("i:36927", "i:36910", 0.04, "prospect")
-- Dream Emerald
TSMAPI.Conversions:Add("i:52192", "i:53038", 0.08, "prospect")
TSMAPI.Conversions:Add("i:52192", "i:52185", 0.05, "prospect")
TSMAPI.Conversions:Add("i:52192", "i:52183", 0.04, "prospect")
-- Ember Topaz
TSMAPI.Conversions:Add("i:52193", "i:53038", 0.08, "prospect")
TSMAPI.Conversions:Add("i:52193", "i:52185", 0.05, "prospect")
TSMAPI.Conversions:Add("i:52193", "i:52183", 0.04, "prospect")
-- Inferno Ruby
TSMAPI.Conversions:Add("i:52190", "i:53038", 0.08, "prospect")
TSMAPI.Conversions:Add("i:52190", "i:52185", 0.05, "prospect")
TSMAPI.Conversions:Add("i:52190", "i:52183", 0.04, "prospect")
-- Amberjewel
TSMAPI.Conversions:Add("i:52195", "i:53038", 0.08, "prospect")
TSMAPI.Conversions:Add("i:52195", "i:52185", 0.05, "prospect")
TSMAPI.Conversions:Add("i:52195", "i:52183", 0.04, "prospect")
-- Demonseye
TSMAPI.Conversions:Add("i:52194", "i:53038", 0.08, "prospect")
TSMAPI.Conversions:Add("i:52194", "i:52185", 0.05, "prospect")
TSMAPI.Conversions:Add("i:52194", "i:52183", 0.04, "prospect")
-- Ocean Sapphire
TSMAPI.Conversions:Add("i:52191", "i:53038", 0.08, "prospect")
TSMAPI.Conversions:Add("i:52191", "i:52185", 0.05, "prospect")
TSMAPI.Conversions:Add("i:52191", "i:52183", 0.04, "prospect")
-- Primordial Ruby
TSMAPI.Conversions:Add("i:76131", "i:72092", 0.04, "prospect")
TSMAPI.Conversions:Add("i:76131", "i:72093", 0.04, "prospect")
TSMAPI.Conversions:Add("i:76131", "i:72103", 0.15, "prospect")
TSMAPI.Conversions:Add("i:76131", "i:72094", 0.15, "prospect")
-- River's Heart
TSMAPI.Conversions:Add("i:76138", "i:72092", 0.04, "prospect")
TSMAPI.Conversions:Add("i:76138", "i:72093", 0.04, "prospect")
TSMAPI.Conversions:Add("i:76138", "i:72103", 0.15, "prospect")
TSMAPI.Conversions:Add("i:76138", "i:72094", 0.15, "prospect")
-- Wild Jade
TSMAPI.Conversions:Add("i:76139", "i:72092", 0.04, "prospect")
TSMAPI.Conversions:Add("i:76139", "i:72093", 0.04, "prospect")
TSMAPI.Conversions:Add("i:76139", "i:72103", 0.15, "prospect")
TSMAPI.Conversions:Add("i:76139", "i:72094", 0.15, "prospect")
-- Vermillion Onyx
TSMAPI.Conversions:Add("i:76140", "i:72092", 0.04, "prospect")
TSMAPI.Conversions:Add("i:76140", "i:72093", 0.04, "prospect")
TSMAPI.Conversions:Add("i:76140", "i:72103", 0.15, "prospect")
TSMAPI.Conversions:Add("i:76140", "i:72094", 0.15, "prospect")
-- Imperial Amethyst
TSMAPI.Conversions:Add("i:76141", "i:72092", 0.04, "prospect")
TSMAPI.Conversions:Add("i:76141", "i:72093", 0.04, "prospect")
TSMAPI.Conversions:Add("i:76141", "i:72103", 0.15, "prospect")
TSMAPI.Conversions:Add("i:76141", "i:72094", 0.15, "prospect")
-- Sun's Radiance
TSMAPI.Conversions:Add("i:76142", "i:72092", 0.04, "prospect")
TSMAPI.Conversions:Add("i:76142", "i:72093", 0.04, "prospect")
TSMAPI.Conversions:Add("i:76142", "i:72103", 0.15, "prospect")
TSMAPI.Conversions:Add("i:76142", "i:72094", 0.15, "prospect")
-- =========================================== Essences ========================================
-- Celestial Essence
TSMAPI.Conversions:Add("i:52719", "i:52718", 1/3, "transform")
TSMAPI.Conversions:Add("i:52718", "i:52719", 3, "transform")
-- Cosmic Essence
TSMAPI.Conversions:Add("i:34055", "i:34056", 1/3, "transform")
TSMAPI.Conversions:Add("i:34056", "i:34055", 3, "transform")
-- Planar Essence
TSMAPI.Conversions:Add("i:22446", "i:22447", 1/3, "transform")
TSMAPI.Conversions:Add("i:22447", "i:22446", 3, "transform")
-- Eternal Essence
TSMAPI.Conversions:Add("i:16203", "i:16202", 1/3, "transform")
TSMAPI.Conversions:Add("i:16202", "i:16203", 3, "transform")
-- Nether Essence
TSMAPI.Conversions:Add("i:11175", "i:11174", 1/3, "transform")
TSMAPI.Conversions:Add("i:11174", "i:11175", 3, "transform")
-- Mystic Essence
TSMAPI.Conversions:Add("i:11135", "i:11134", 1/3, "transform")
TSMAPI.Conversions:Add("i:11134", "i:11135", 3, "transform")
-- Astral Essence
TSMAPI.Conversions:Add("i:11082", "i:10998", 1/3, "transform")
TSMAPI.Conversions:Add("i:10998", "i:11082", 3, "transform")
-- Magic Essence
TSMAPI.Conversions:Add("i:10939", "i:10938", 1/3, "transform")
TSMAPI.Conversions:Add("i:10938", "i:10939", 3, "transform")
-- =========================================== Essences ========================================
-- Heavenly Shard
TSMAPI.Conversions:Add("i:52721", "i:52720", 1/3, "transform")
-- Dream Shard
TSMAPI.Conversions:Add("i:34052", "i:34053", 1/3, "transform")
-- Ethereal Shard
TSMAPI.Conversions:Add("i:74247", "i:74252", 1/3, "transform")
-- Luminous Shard
TSMAPI.Conversions:Add("i:111245", "i:115502", 0.1, "transform")
-- =========================================== Crystals ========================================
-- Temporal Crystal
TSMAPI.Conversions:Add("i:113588", "i:115504", 0.1, "transform")
-- ======================================== Primals / Motes ====================================
-- Water
TSMAPI.Conversions:Add("i:21885", "i:22578", 0.1, "transform")
-- Shadow
TSMAPI.Conversions:Add("i:22456", "i:22577", 0.1, "transform")
-- Mana
TSMAPI.Conversions:Add("i:22457", "i:22576", 0.1, "transform")
-- Life
TSMAPI.Conversions:Add("i:21886", "i:22575", 0.1, "transform")
-- Fire
TSMAPI.Conversions:Add("i:21884", "i:22574", 0.1, "transform")
-- Earth
TSMAPI.Conversions:Add("i:22452", "i:22573", 0.1, "transform")
-- Air
TSMAPI.Conversions:Add("i:22451", "i:22572", 0.1, "transform")
-- ===================================== Crystalized / Eternal =================================
-- Air
TSMAPI.Conversions:Add("i:37700", "i:35623", 10, "transform")
TSMAPI.Conversions:Add("i:35623", "i:37700", 0.1, "transform")
-- Earth
TSMAPI.Conversions:Add("i:37701", "i:35624", 10, "transform")
TSMAPI.Conversions:Add("i:35624", "i:37701", 0.1, "transform")
-- Fire
TSMAPI.Conversions:Add("i:37702", "i:36860", 10, "transform")
TSMAPI.Conversions:Add("i:36860", "i:37702", 0.1, "transform")
-- Shadow
TSMAPI.Conversions:Add("i:37703", "i:35627", 10, "transform")
TSMAPI.Conversions:Add("i:35627", "i:37703", 0.1, "transform")
-- Life
TSMAPI.Conversions:Add("i:37704", "i:35625", 10, "transform")
TSMAPI.Conversions:Add("i:35625", "i:37704", 0.1, "transform")
-- Water
TSMAPI.Conversions:Add("i:37705", "i:35622", 10, "transform")
TSMAPI.Conversions:Add("i:35622", "i:37705", 0.1, "transform")
-- ========================================= Vendor Trades =====================================
-- Ivory Ink
TSMAPI.Conversions:Add("i:37101", "i:113111", 1, "vendortrade")
-- Moonglow Ink
TSMAPI.Conversions:Add("i:39469", "i:113111", 1, "vendortrade")
-- Midnight Ink
TSMAPI.Conversions:Add("i:39774", "i:113111", 1, "vendortrade")
-- Lion's Ink
TSMAPI.Conversions:Add("i:43116", "i:113111", 1, "vendortrade")
-- Jadefire Ink
TSMAPI.Conversions:Add("i:43118", "i:113111", 1, "vendortrade")
-- Celestial Ink
TSMAPI.Conversions:Add("i:43120", "i:113111", 1, "vendortrade")
-- Shimmering Ink
TSMAPI.Conversions:Add("i:43122", "i:113111", 1, "vendortrade")
-- Ethereal Ink
TSMAPI.Conversions:Add("i:43124", "i:113111", 1, "vendortrade")
-- Ink of the Sea
TSMAPI.Conversions:Add("i:43126", "i:113111", 1, "vendortrade")
-- Snowfall Ink
TSMAPI.Conversions:Add("i:43127", "i:113111", 0.1, "vendortrade")
-- Blackfallow Ink
TSMAPI.Conversions:Add("i:61978", "i:113111", 1, "vendortrade")
-- Inferno Ink
TSMAPI.Conversions:Add("i:61981", "i:113111", 0.1, "vendortrade")
-- Ink of Dreams
TSMAPI.Conversions:Add("i:79254", "i:113111", 1, "vendortrade")
-- Starlight Ink
TSMAPI.Conversions:Add("i:79255", "i:113111", 0.1, "vendortrade")