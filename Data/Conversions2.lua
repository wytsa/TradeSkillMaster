-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local private = {data={}, targetItemNameLookup=nil, sourceItemCache=nil}
TSMAPI.Conversions2 = {}


function TSMAPI.Conversions2:Add(targetItem, sourceItem, rate, method)
	private.data[targetItem] = private.data[targetItem] or {}
	if private.data[targetItem][sourceItem] then
		TSMAPI:Assert(false, format("Assertion failed! (oldMethod=%s, newMethod=%s)", private.data[targetItem][sourceItem].method, method))
	end
	private.data[targetItem][sourceItem] = {rate=rate, method=method, hasItemInfo=nil}
	TSMAPI:QueryItemInfo(targetItem)
	TSMAPI:QueryItemInfo(sourceItem)
	private.targetItemNameLookup = nil
	private.sourceItemCache = nil
end

function TSMAPI.Conversions2:GetData(targetItem)
	return private.data[targetItem]
end

function TSMAPI.Conversions2:GetTargetItemByName(targetItemName)
	targetItemName = strlower(targetItemName)
	for itemString, data in pairs(private.data) do
		local name = TSMAPI:GetSafeItemInfo(itemString)
		if strlower(name) == targetItemName then
			return itemString
		end
	end
end

function TSMAPI.Conversions2:GetTargetItemNames()
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
function TSMAPI.Conversions2:GetSourceItems(targetItem)
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


-- pre-defined conversions
do
	-- ====================================== Common Pigments ======================================
	-- Alabaster Pigment (Ivory / Moonglow Ink)
	TSMAPI.Conversions2:Add("item:39151:0:0:0:0:0:0", "item:765:0:0:0:0:0:0", 0.5, "mill")
	TSMAPI.Conversions2:Add("item:39151:0:0:0:0:0:0", "item:2447:0:0:0:0:0:0", 0.5, "mill")
	TSMAPI.Conversions2:Add("item:39151:0:0:0:0:0:0", "item:2449:0:0:0:0:0:0", 0.6, "mill")
	-- Azure Pigment (Ink of the Sea)
	TSMAPI.Conversions2:Add("item:39343:0:0:0:0:0:0", "item:39969:0:0:0:0:0:0", 0.5, "mill")
	TSMAPI.Conversions2:Add("item:39343:0:0:0:0:0:0", "item:36904:0:0:0:0:0:0", 0.5, "mill")
	TSMAPI.Conversions2:Add("item:39343:0:0:0:0:0:0", "item:36907:0:0:0:0:0:0", 0.5, "mill")
	TSMAPI.Conversions2:Add("item:39343:0:0:0:0:0:0", "item:36901:0:0:0:0:0:0", 0.5, "mill")
	TSMAPI.Conversions2:Add("item:39343:0:0:0:0:0:0", "item:39970:0:0:0:0:0:0", 0.5, "mill")
	TSMAPI.Conversions2:Add("item:39343:0:0:0:0:0:0", "item:37921:0:0:0:0:0:0", 0.5, "mill")
	TSMAPI.Conversions2:Add("item:39343:0:0:0:0:0:0", "item:36905:0:0:0:0:0:0", 0.6, "mill")
	TSMAPI.Conversions2:Add("item:39343:0:0:0:0:0:0", "item:36906:0:0:0:0:0:0", 0.6, "mill")
	TSMAPI.Conversions2:Add("item:39343:0:0:0:0:0:0", "item:36903:0:0:0:0:0:0", 0.6, "mill")
	 -- Ashen Pigment (Blackfallow Ink)
	TSMAPI.Conversions2:Add("item:61979:0:0:0:0:0:0", "item:52983:0:0:0:0:0:0", 0.5, "mill")
	TSMAPI.Conversions2:Add("item:61979:0:0:0:0:0:0", "item:52984:0:0:0:0:0:0", 0.5, "mill")
	TSMAPI.Conversions2:Add("item:61979:0:0:0:0:0:0", "item:52985:0:0:0:0:0:0", 0.5, "mill")
	TSMAPI.Conversions2:Add("item:61979:0:0:0:0:0:0", "item:52986:0:0:0:0:0:0", 0.5, "mill")
	TSMAPI.Conversions2:Add("item:61979:0:0:0:0:0:0", "item:52987:0:0:0:0:0:0", 0.6, "mill")
	TSMAPI.Conversions2:Add("item:61979:0:0:0:0:0:0", "item:52988:0:0:0:0:0:0", 0.6, "mill")
	 -- Dusky Pigment (Midnight Ink)
	TSMAPI.Conversions2:Add("item:39334:0:0:0:0:0:0", "item:785:0:0:0:0:0:0", 0.5, "mill")
	TSMAPI.Conversions2:Add("item:39334:0:0:0:0:0:0", "item:2450:0:0:0:0:0:0", 0.5, "mill")
	TSMAPI.Conversions2:Add("item:39334:0:0:0:0:0:0", "item:2452:0:0:0:0:0:0", 0.5, "mill")
	TSMAPI.Conversions2:Add("item:39334:0:0:0:0:0:0", "item:2453:0:0:0:0:0:0", 0.6, "mill")
	TSMAPI.Conversions2:Add("item:39334:0:0:0:0:0:0", "item:3820:0:0:0:0:0:0", 0.6, "mill")
	-- Emerald Pigment (Jadefire Ink)
	TSMAPI.Conversions2:Add("item:39339:0:0:0:0:0:0", "item:3818:0:0:0:0:0:0", 0.5, "mill")
	TSMAPI.Conversions2:Add("item:39339:0:0:0:0:0:0", "item:3821:0:0:0:0:0:0", 0.5, "mill")
	TSMAPI.Conversions2:Add("item:39339:0:0:0:0:0:0", "item:3358:0:0:0:0:0:0", 0.6, "mill")
	TSMAPI.Conversions2:Add("item:39339:0:0:0:0:0:0", "item:3819:0:0:0:0:0:0", 0.6, "mill")
	-- Golden Pigment (Lion's Ink)
	TSMAPI.Conversions2:Add("item:39338:0:0:0:0:0:0", "item:3355:0:0:0:0:0:0", 0.5, "mill")
	TSMAPI.Conversions2:Add("item:39338:0:0:0:0:0:0", "item:3369:0:0:0:0:0:0", 0.5, "mill")
	TSMAPI.Conversions2:Add("item:39338:0:0:0:0:0:0", "item:3356:0:0:0:0:0:0", 0.6, "mill")
	TSMAPI.Conversions2:Add("item:39338:0:0:0:0:0:0", "item:3357:0:0:0:0:0:0", 0.6, "mill")
	-- Nether Pigment (Ethereal Ink)
	TSMAPI.Conversions2:Add("item:39342:0:0:0:0:0:0", "item:22785:0:0:0:0:0:0", 0.5, "mill")
	TSMAPI.Conversions2:Add("item:39342:0:0:0:0:0:0", "item:22786:0:0:0:0:0:0", 0.5, "mill")
	TSMAPI.Conversions2:Add("item:39342:0:0:0:0:0:0", "item:22787:0:0:0:0:0:0", 0.5, "mill")
	TSMAPI.Conversions2:Add("item:39342:0:0:0:0:0:0", "item:22789:0:0:0:0:0:0", 0.5, "mill")
	TSMAPI.Conversions2:Add("item:39342:0:0:0:0:0:0", "item:22790:0:0:0:0:0:0", 0.6, "mill")
	TSMAPI.Conversions2:Add("item:39342:0:0:0:0:0:0", "item:22791:0:0:0:0:0:0", 0.6, "mill")
	TSMAPI.Conversions2:Add("item:39342:0:0:0:0:0:0", "item:22792:0:0:0:0:0:0", 0.6, "mill")
	TSMAPI.Conversions2:Add("item:39342:0:0:0:0:0:0", "item:22793:0:0:0:0:0:0", 0.6, "mill")
	-- Shadow Pigment (Ink of Dreams)
	TSMAPI.Conversions2:Add("item:79251:0:0:0:0:0:0", "item:72237:0:0:0:0:0:0", 0.5, "mill")
	TSMAPI.Conversions2:Add("item:79251:0:0:0:0:0:0", "item:72234:0:0:0:0:0:0", 0.5, "mill")
	TSMAPI.Conversions2:Add("item:79251:0:0:0:0:0:0", "item:79010:0:0:0:0:0:0", 0.5, "mill")
	TSMAPI.Conversions2:Add("item:79251:0:0:0:0:0:0", "item:72235:0:0:0:0:0:0", 0.5, "mill")
	TSMAPI.Conversions2:Add("item:79251:0:0:0:0:0:0", "item:89639:0:0:0:0:0:0", 0.5, "mill")
	TSMAPI.Conversions2:Add("item:79251:0:0:0:0:0:0", "item:79011:0:0:0:0:0:0", 0.6, "mill")
	-- Silvery Pigment (Shimmering Ink)
	TSMAPI.Conversions2:Add("item:39341:0:0:0:0:0:0", "item:13463:0:0:0:0:0:0", 0.5, "mill")
	TSMAPI.Conversions2:Add("item:39341:0:0:0:0:0:0", "item:13464:0:0:0:0:0:0", 0.5, "mill")
	TSMAPI.Conversions2:Add("item:39341:0:0:0:0:0:0", "item:13465:0:0:0:0:0:0", 0.6, "mill")
	TSMAPI.Conversions2:Add("item:39341:0:0:0:0:0:0", "item:13466:0:0:0:0:0:0", 0.6, "mill")
	TSMAPI.Conversions2:Add("item:39341:0:0:0:0:0:0", "item:13467:0:0:0:0:0:0", 0.6, "mill")
	-- Violet Pigment (Celestial Ink)
	TSMAPI.Conversions2:Add("item:39340:0:0:0:0:0:0", "item:4625:0:0:0:0:0:0", 0.5, "mill")
	TSMAPI.Conversions2:Add("item:39340:0:0:0:0:0:0", "item:8831:0:0:0:0:0:0", 0.5, "mill")
	TSMAPI.Conversions2:Add("item:39340:0:0:0:0:0:0", "item:8838:0:0:0:0:0:0", 0.5, "mill")
	TSMAPI.Conversions2:Add("item:39340:0:0:0:0:0:0", "item:8839:0:0:0:0:0:0", 0.6, "mill")
	TSMAPI.Conversions2:Add("item:39340:0:0:0:0:0:0", "item:8845:0:0:0:0:0:0", 0.6, "mill")
	TSMAPI.Conversions2:Add("item:39340:0:0:0:0:0:0", "item:8846:0:0:0:0:0:0", 0.6, "mill")
	-- Cerulean Pigment (Warbinder's Ink)
	TSMAPI.Conversions2:Add("item:114931:0:0:0:0:0:0", "item:109124:0:0:0:0:0:0", 0.4, "mill")
	TSMAPI.Conversions2:Add("item:114931:0:0:0:0:0:0", "item:109125:0:0:0:0:0:0", 0.4, "mill")
	TSMAPI.Conversions2:Add("item:114931:0:0:0:0:0:0", "item:109126:0:0:0:0:0:0", 0.4, "mill")
	TSMAPI.Conversions2:Add("item:114931:0:0:0:0:0:0", "item:109127:0:0:0:0:0:0", 0.4, "mill")
	TSMAPI.Conversions2:Add("item:114931:0:0:0:0:0:0", "item:109128:0:0:0:0:0:0", 0.4, "mill")
	TSMAPI.Conversions2:Add("item:114931:0:0:0:0:0:0", "item:109129:0:0:0:0:0:0", 0.4, "mill")
	-- ======================================= Rare Pigments =======================================
	-- Icy Pigment (Snowfall Ink)
	TSMAPI.Conversions2:Add("item:43109:0:0:0:0:0:0", "item:39969:0:0:0:0:0:0", 0.05, "mill")
	TSMAPI.Conversions2:Add("item:43109:0:0:0:0:0:0", "item:36904:0:0:0:0:0:0", 0.05, "mill")
	TSMAPI.Conversions2:Add("item:43109:0:0:0:0:0:0", "item:36907:0:0:0:0:0:0", 0.05, "mill")
	TSMAPI.Conversions2:Add("item:43109:0:0:0:0:0:0", "item:36901:0:0:0:0:0:0", 0.05, "mill")
	TSMAPI.Conversions2:Add("item:43109:0:0:0:0:0:0", "item:39970:0:0:0:0:0:0", 0.05, "mill")
	TSMAPI.Conversions2:Add("item:43109:0:0:0:0:0:0", "item:37921:0:0:0:0:0:0", 0.05, "mill")
	TSMAPI.Conversions2:Add("item:43109:0:0:0:0:0:0", "item:36905:0:0:0:0:0:0", 0.1, "mill")
	TSMAPI.Conversions2:Add("item:43109:0:0:0:0:0:0", "item:36906:0:0:0:0:0:0", 0.1, "mill")
	TSMAPI.Conversions2:Add("item:43109:0:0:0:0:0:0", "item:36903:0:0:0:0:0:0", 0.1, "mill")
	-- Burning Embers (Inferno Ink)
	TSMAPI.Conversions2:Add("item:61980:0:0:0:0:0:0", "item:52983:0:0:0:0:0:0", 0.05, "mill")
	TSMAPI.Conversions2:Add("item:61980:0:0:0:0:0:0", "item:52984:0:0:0:0:0:0", 0.05, "mill")
	TSMAPI.Conversions2:Add("item:61980:0:0:0:0:0:0", "item:52985:0:0:0:0:0:0", 0.05, "mill")
	TSMAPI.Conversions2:Add("item:61980:0:0:0:0:0:0", "item:52986:0:0:0:0:0:0", 0.05, "mill")
	TSMAPI.Conversions2:Add("item:61980:0:0:0:0:0:0", "item:52987:0:0:0:0:0:0", 0.1, "mill")
	TSMAPI.Conversions2:Add("item:61980:0:0:0:0:0:0", "item:52988:0:0:0:0:0:0", 0.1, "mill")
	-- Burnt Pigment (Dawnstar Ink)
	TSMAPI.Conversions2:Add("item:43104:0:0:0:0:0:0", "item:3356:0:0:0:0:0:0", 0.1, "mill")
	TSMAPI.Conversions2:Add("item:43104:0:0:0:0:0:0", "item:3357:0:0:0:0:0:0", 0.1, "mill")
	TSMAPI.Conversions2:Add("item:43104:0:0:0:0:0:0", "item:3369:0:0:0:0:0:0", 0.05, "mill")
	TSMAPI.Conversions2:Add("item:43104:0:0:0:0:0:0", "item:3355:0:0:0:0:0:0", 0.05, "mill")
	-- Ebon Pigment (Darkflame Ink)
	TSMAPI.Conversions2:Add("item:43108:0:0:0:0:0:0", "item:22792:0:0:0:0:0:0", 0.1, "mill")
	TSMAPI.Conversions2:Add("item:43108:0:0:0:0:0:0", "item:22790:0:0:0:0:0:0", 0.1, "mill")
	TSMAPI.Conversions2:Add("item:43108:0:0:0:0:0:0", "item:22791:0:0:0:0:0:0", 0.1, "mill")
	TSMAPI.Conversions2:Add("item:43108:0:0:0:0:0:0", "item:22793:0:0:0:0:0:0", 0.1, "mill")
	TSMAPI.Conversions2:Add("item:43108:0:0:0:0:0:0", "item:22786:0:0:0:0:0:0", 0.05, "mill")
	TSMAPI.Conversions2:Add("item:43108:0:0:0:0:0:0", "item:22785:0:0:0:0:0:0", 0.05, "mill")
	TSMAPI.Conversions2:Add("item:43108:0:0:0:0:0:0", "item:22787:0:0:0:0:0:0", 0.05, "mill")
	TSMAPI.Conversions2:Add("item:43108:0:0:0:0:0:0", "item:22789:0:0:0:0:0:0", 0.05, "mill")
	-- Indigo Pigment (Royal Ink)
	TSMAPI.Conversions2:Add("item:43105:0:0:0:0:0:0", "item:3358:0:0:0:0:0:0", 0.1, "mill")
	TSMAPI.Conversions2:Add("item:43105:0:0:0:0:0:0", "item:3819:0:0:0:0:0:0", 0.1, "mill")
	TSMAPI.Conversions2:Add("item:43105:0:0:0:0:0:0", "item:3821:0:0:0:0:0:0", 0.05, "mill")
	TSMAPI.Conversions2:Add("item:43105:0:0:0:0:0:0", "item:3818:0:0:0:0:0:0", 0.05, "mill")
	-- Misty Pigment (Starlight Ink)
	TSMAPI.Conversions2:Add("item:79253:0:0:0:0:0:0", "item:72237:0:0:0:0:0:0", 0.05, "mill")
	TSMAPI.Conversions2:Add("item:79253:0:0:0:0:0:0", "item:72234:0:0:0:0:0:0", 0.05, "mill")
	TSMAPI.Conversions2:Add("item:79253:0:0:0:0:0:0", "item:79010:0:0:0:0:0:0", 0.05, "mill")
	TSMAPI.Conversions2:Add("item:79253:0:0:0:0:0:0", "item:72235:0:0:0:0:0:0", 0.05, "mill")
	TSMAPI.Conversions2:Add("item:79253:0:0:0:0:0:0", "item:79011:0:0:0:0:0:0", 0.1, "mill")
	TSMAPI.Conversions2:Add("item:79253:0:0:0:0:0:0", "item:89639:0:0:0:0:0:0", 0.05, "mill")
	-- Ruby Pigment (Fiery Ink)
	TSMAPI.Conversions2:Add("item:43106:0:0:0:0:0:0", "item:4625:0:0:0:0:0:0", 0.05, "mill")
	TSMAPI.Conversions2:Add("item:43106:0:0:0:0:0:0", "item:8838:0:0:0:0:0:0", 0.05, "mill")
	TSMAPI.Conversions2:Add("item:43106:0:0:0:0:0:0", "item:8831:0:0:0:0:0:0", 0.05, "mill")
	TSMAPI.Conversions2:Add("item:43106:0:0:0:0:0:0", "item:8845:0:0:0:0:0:0", 0.1, "mill")
	TSMAPI.Conversions2:Add("item:43106:0:0:0:0:0:0", "item:8846:0:0:0:0:0:0", 0.1, "mill")
	TSMAPI.Conversions2:Add("item:43106:0:0:0:0:0:0", "item:8839:0:0:0:0:0:0", 0.1, "mill")
	-- Sapphire Pigment (Ink of the Sky)
	TSMAPI.Conversions2:Add("item:43107:0:0:0:0:0:0", "item:13463:0:0:0:0:0:0", 0.05, "mill")
	TSMAPI.Conversions2:Add("item:43107:0:0:0:0:0:0", "item:13464:0:0:0:0:0:0", 0.05, "mill")
	TSMAPI.Conversions2:Add("item:43107:0:0:0:0:0:0", "item:13465:0:0:0:0:0:0", 0.1, "mill")
	TSMAPI.Conversions2:Add("item:43107:0:0:0:0:0:0", "item:13466:0:0:0:0:0:0", 0.1, "mill")
	TSMAPI.Conversions2:Add("item:43107:0:0:0:0:0:0", "item:13467:0:0:0:0:0:0", 0.1, "mill")
	-- Verdant Pigment (Hunter's Ink)
	TSMAPI.Conversions2:Add("item:43103:0:0:0:0:0:0", "item:2453:0:0:0:0:0:0", 0.1, "mill")
	TSMAPI.Conversions2:Add("item:43103:0:0:0:0:0:0", "item:3820:0:0:0:0:0:0", 0.1, "mill")
	TSMAPI.Conversions2:Add("item:43103:0:0:0:0:0:0", "item:2450:0:0:0:0:0:0", 0.05, "mill")
	TSMAPI.Conversions2:Add("item:43103:0:0:0:0:0:0", "item:785:0:0:0:0:0:0", 0.05, "mill")
	TSMAPI.Conversions2:Add("item:43103:0:0:0:0:0:0", "item:2452:0:0:0:0:0:0", 0.05, "mill")
	-- ======================================== Vanilla Gems =======================================
	-- Malachite
	TSMAPI.Conversions2:Add("item:774:0:0:0:0:0:0", "item:2770:0:0:0:0:0:0", 0.5, "prospect")
	-- Tigerseye
	TSMAPI.Conversions2:Add("item:818:0:0:0:0:0:0", "item:2770:0:0:0:0:0:0", 0.5, "prospect")
	-- Shadowgem
	TSMAPI.Conversions2:Add("item:1210:0:0:0:0:0:0", "item:2771:0:0:0:0:0:0", 0.4, "prospect")
	TSMAPI.Conversions2:Add("item:1210:0:0:0:0:0:0", "item:2770:0:0:0:0:0:0", 0.1, "prospect")
	-- Moss Agate
	TSMAPI.Conversions2:Add("item:1206:0:0:0:0:0:0", "item:2771:0:0:0:0:0:0", 0.3, "prospect")
	-- Lesser moonstone
	TSMAPI.Conversions2:Add("item:1705:0:0:0:0:0:0", "item:2771:0:0:0:0:0:0", 0.4, "prospect")
	TSMAPI.Conversions2:Add("item:1705:0:0:0:0:0:0", "item:2772:0:0:0:0:0:0", 0.3, "prospect")
	-- Jade
	TSMAPI.Conversions2:Add("item:1529:0:0:0:0:0:0", "item:2772:0:0:0:0:0:0", 0.4, "prospect")
	TSMAPI.Conversions2:Add("item:1529:0:0:0:0:0:0", "item:2771:0:0:0:0:0:0", 0.03, "prospect")
	-- Citrine
	TSMAPI.Conversions2:Add("item:3864:0:0:0:0:0:0", "item:2772:0:0:0:0:0:0", 0.4, "prospect")
	TSMAPI.Conversions2:Add("item:3864:0:0:0:0:0:0", "item:3858:0:0:0:0:0:0", 0.3, "prospect")
	TSMAPI.Conversions2:Add("item:3864:0:0:0:0:0:0", "item:2771:0:0:0:0:0:0", 0.03, "prospect")
	-- Aquamarine
	TSMAPI.Conversions2:Add("item:7909:0:0:0:0:0:0", "item:3858:0:0:0:0:0:0", 0.3, "prospect")
	TSMAPI.Conversions2:Add("item:7909:0:0:0:0:0:0", "item:2772:0:0:0:0:0:0", 0.05, "prospect")
	TSMAPI.Conversions2:Add("item:7909:0:0:0:0:0:0", "item:2771:0:0:0:0:0:0", 0.03, "prospect")
	-- Star Ruby
	TSMAPI.Conversions2:Add("item:7910:0:0:0:0:0:0", "item:3858:0:0:0:0:0:0", 0.4, "prospect")
	TSMAPI.Conversions2:Add("item:7910:0:0:0:0:0:0", "item:10620:0:0:0:0:0:0", 0.1, "prospect")
	TSMAPI.Conversions2:Add("item:7910:0:0:0:0:0:0", "item:2772:0:0:0:0:0:0", 0.05, "prospect")
	-- Blue Sapphire
	TSMAPI.Conversions2:Add("item:12361:0:0:0:0:0:0", "item:10620:0:0:0:0:0:0", 0.3, "prospect")
	TSMAPI.Conversions2:Add("item:12361:0:0:0:0:0:0", "item:3858:0:0:0:0:0:0", 0.03, "prospect")
	-- Large Opal
	TSMAPI.Conversions2:Add("item:12799:0:0:0:0:0:0", "item:10620:0:0:0:0:0:0", 0.3, "prospect")
	TSMAPI.Conversions2:Add("item:12799:0:0:0:0:0:0", "item:3858:0:0:0:0:0:0", 0.03, "prospect")
	-- Azerothian Diamond
	TSMAPI.Conversions2:Add("item:12800:0:0:0:0:0:0", "item:10620:0:0:0:0:0:0", 0.3, "prospect")
	TSMAPI.Conversions2:Add("item:12800:0:0:0:0:0:0", "item:3858:0:0:0:0:0:0", 0.02, "prospect")
	-- Huge Emerald
	TSMAPI.Conversions2:Add("item:12364:0:0:0:0:0:0", "item:10620:0:0:0:0:0:0", 0.3, "prospect")
	TSMAPI.Conversions2:Add("item:12364:0:0:0:0:0:0", "item:3858:0:0:0:0:0:0", 0.02, "prospect")
	-- ======================================== Uncommon Gems ======================================
	-- Azure Moonstone
	TSMAPI.Conversions2:Add("item:23117:0:0:0:0:0:0", "item:23424:0:0:0:0:0:0", 0.2, "prospect")
	TSMAPI.Conversions2:Add("item:23117:0:0:0:0:0:0", "item:23425:0:0:0:0:0:0", 0.2, "prospect")
	-- Blood Garnet
	TSMAPI.Conversions2:Add("item:23077:0:0:0:0:0:0", "item:23424:0:0:0:0:0:0", 0.2, "prospect")
	TSMAPI.Conversions2:Add("item:23077:0:0:0:0:0:0", "item:23425:0:0:0:0:0:0", 0.2, "prospect")
	-- Deep Peridot
	TSMAPI.Conversions2:Add("item:23079:0:0:0:0:0:0", "item:23424:0:0:0:0:0:0", 0.2, "prospect")
	TSMAPI.Conversions2:Add("item:23079:0:0:0:0:0:0", "item:23425:0:0:0:0:0:0", 0.2, "prospect")
	-- Flame Spessarite
	TSMAPI.Conversions2:Add("item:21929:0:0:0:0:0:0", "item:23424:0:0:0:0:0:0", 0.2, "prospect")
	TSMAPI.Conversions2:Add("item:21929:0:0:0:0:0:0", "item:23425:0:0:0:0:0:0", 0.2, "prospect")
	-- Golden Draenite
	TSMAPI.Conversions2:Add("item:23112:0:0:0:0:0:0", "item:23424:0:0:0:0:0:0", 0.2, "prospect")
	TSMAPI.Conversions2:Add("item:23112:0:0:0:0:0:0", "item:23425:0:0:0:0:0:0", 0.2, "prospect")
	-- Shadow Draenite
	TSMAPI.Conversions2:Add("item:23107:0:0:0:0:0:0", "item:23424:0:0:0:0:0:0", 0.2, "prospect")
	TSMAPI.Conversions2:Add("item:23107:0:0:0:0:0:0", "item:23425:0:0:0:0:0:0", 0.2, "prospect")
	-- Bloodstone
	TSMAPI.Conversions2:Add("item:36917:0:0:0:0:0:0", "item:36909:0:0:0:0:0:0", 0.25, "prospect")
	TSMAPI.Conversions2:Add("item:36917:0:0:0:0:0:0", "item:36912:0:0:0:0:0:0", 0.2, "prospect")
	TSMAPI.Conversions2:Add("item:36917:0:0:0:0:0:0", "item:36910:0:0:0:0:0:0", 0.25, "prospect")
	-- Chalcedony
	TSMAPI.Conversions2:Add("item:36923:0:0:0:0:0:0", "item:36909:0:0:0:0:0:0", 0.25, "prospect")
	TSMAPI.Conversions2:Add("item:36923:0:0:0:0:0:0", "item:36912:0:0:0:0:0:0", 0.2, "prospect")
	TSMAPI.Conversions2:Add("item:36923:0:0:0:0:0:0", "item:36910:0:0:0:0:0:0", 0.25, "prospect")
	-- Dark Jade
	TSMAPI.Conversions2:Add("item:36932:0:0:0:0:0:0", "item:36909:0:0:0:0:0:0", 0.25, "prospect")
	TSMAPI.Conversions2:Add("item:36932:0:0:0:0:0:0", "item:36912:0:0:0:0:0:0", 0.2, "prospect")
	TSMAPI.Conversions2:Add("item:36932:0:0:0:0:0:0", "item:36910:0:0:0:0:0:0", 0.25, "prospect")
	-- Huge Citrine
	TSMAPI.Conversions2:Add("item:36929:0:0:0:0:0:0", "item:36909:0:0:0:0:0:0", 0.25, "prospect")
	TSMAPI.Conversions2:Add("item:36929:0:0:0:0:0:0", "item:36912:0:0:0:0:0:0", 0.2, "prospect")
	TSMAPI.Conversions2:Add("item:36929:0:0:0:0:0:0", "item:36910:0:0:0:0:0:0", 0.25, "prospect")
	-- Shadow Crystal
	TSMAPI.Conversions2:Add("item:36926:0:0:0:0:0:0", "item:36909:0:0:0:0:0:0", 0.25, "prospect")
	TSMAPI.Conversions2:Add("item:36926:0:0:0:0:0:0", "item:36912:0:0:0:0:0:0", 0.2, "prospect")
	TSMAPI.Conversions2:Add("item:36926:0:0:0:0:0:0", "item:36910:0:0:0:0:0:0", 0.25, "prospect")
	-- Sun Crystal
	TSMAPI.Conversions2:Add("item:36920:0:0:0:0:0:0", "item:36909:0:0:0:0:0:0", 0.25, "prospect")
	TSMAPI.Conversions2:Add("item:36920:0:0:0:0:0:0", "item:36912:0:0:0:0:0:0", 0.2, "prospect")
	TSMAPI.Conversions2:Add("item:36920:0:0:0:0:0:0", "item:36910:0:0:0:0:0:0", 0.2, "prospect")
	-- Jasper
	TSMAPI.Conversions2:Add("item:52182:0:0:0:0:0:0", "item:53038:0:0:0:0:0:0", 0.25, "prospect")
	TSMAPI.Conversions2:Add("item:52182:0:0:0:0:0:0", "item:52185:0:0:0:0:0:0", 0.2, "prospect")
	TSMAPI.Conversions2:Add("item:52182:0:0:0:0:0:0", "item:52183:0:0:0:0:0:0", 0.2, "prospect")
	
	TSMAPI.Conversions2:Add("item:52180:0:0:0:0:0:0", "item:53038:0:0:0:0:0:0", 0.25, "prospect")
	TSMAPI.Conversions2:Add("item:52180:0:0:0:0:0:0", "item:52185:0:0:0:0:0:0", 0.2, "prospect")
	TSMAPI.Conversions2:Add("item:52180:0:0:0:0:0:0", "item:52183:0:0:0:0:0:0", 0.2, "prospect")
	-- Zephyrite
	TSMAPI.Conversions2:Add("item:52178:0:0:0:0:0:0", "item:53038:0:0:0:0:0:0", 0.25, "prospect")
	TSMAPI.Conversions2:Add("item:52178:0:0:0:0:0:0", "item:52185:0:0:0:0:0:0", 0.2, "prospect")
	TSMAPI.Conversions2:Add("item:52178:0:0:0:0:0:0", "item:52183:0:0:0:0:0:0", 0.2, "prospect")
	-- Alicite
	TSMAPI.Conversions2:Add("item:52179:0:0:0:0:0:0", "item:53038:0:0:0:0:0:0", 0.25, "prospect")
	TSMAPI.Conversions2:Add("item:52179:0:0:0:0:0:0", "item:52185:0:0:0:0:0:0", 0.2, "prospect")
	TSMAPI.Conversions2:Add("item:52179:0:0:0:0:0:0", "item:52183:0:0:0:0:0:0", 0.2, "prospect")
	-- Carnelian
	TSMAPI.Conversions2:Add("item:52177:0:0:0:0:0:0", "item:53038:0:0:0:0:0:0", 0.25, "prospect")
	TSMAPI.Conversions2:Add("item:52177:0:0:0:0:0:0", "item:52185:0:0:0:0:0:0", 0.2, "prospect")
	TSMAPI.Conversions2:Add("item:52177:0:0:0:0:0:0", "item:52183:0:0:0:0:0:0", 0.2, "prospect")
	-- Hessonite
	TSMAPI.Conversions2:Add("item:52181:0:0:0:0:0:0", "item:53038:0:0:0:0:0:0", 0.25, "prospect")
	TSMAPI.Conversions2:Add("item:52181:0:0:0:0:0:0", "item:52185:0:0:0:0:0:0", 0.2, "prospect")
	TSMAPI.Conversions2:Add("item:52181:0:0:0:0:0:0", "item:52183:0:0:0:0:0:0", 0.2, "prospect")
	-- Tiger Opal
	TSMAPI.Conversions2:Add("item:76130:0:0:0:0:0:0", "item:72092:0:0:0:0:0:0", 0.25, "prospect")
	TSMAPI.Conversions2:Add("item:76130:0:0:0:0:0:0", "item:72093:0:0:0:0:0:0", 0.25, "prospect")
	TSMAPI.Conversions2:Add("item:76130:0:0:0:0:0:0", "item:72103:0:0:0:0:0:0", 0.2, "prospect")
	TSMAPI.Conversions2:Add("item:76130:0:0:0:0:0:0", "item:72094:0:0:0:0:0:0", 0.2, "prospect")
	-- Lapis Lazuli
	TSMAPI.Conversions2:Add("item:76133:0:0:0:0:0:0", "item:72092:0:0:0:0:0:0", 0.25, "prospect")
	TSMAPI.Conversions2:Add("item:76133:0:0:0:0:0:0", "item:72093:0:0:0:0:0:0", 0.25, "prospect")
	TSMAPI.Conversions2:Add("item:76133:0:0:0:0:0:0", "item:72103:0:0:0:0:0:0", 0.2, "prospect")
	TSMAPI.Conversions2:Add("item:76133:0:0:0:0:0:0", "item:72094:0:0:0:0:0:0", 0.2, "prospect")
	-- Sunstone
	TSMAPI.Conversions2:Add("item:76134:0:0:0:0:0:0", "item:72092:0:0:0:0:0:0", 0.25, "prospect")
	TSMAPI.Conversions2:Add("item:76134:0:0:0:0:0:0", "item:72093:0:0:0:0:0:0", 0.25, "prospect")
	TSMAPI.Conversions2:Add("item:76134:0:0:0:0:0:0", "item:72103:0:0:0:0:0:0", 0.2, "prospect")
	TSMAPI.Conversions2:Add("item:76134:0:0:0:0:0:0", "item:72094:0:0:0:0:0:0", 0.2, "prospect")
	-- Roguestone
	TSMAPI.Conversions2:Add("item:76135:0:0:0:0:0:0", "item:72092:0:0:0:0:0:0", 0.25, "prospect")
	TSMAPI.Conversions2:Add("item:76135:0:0:0:0:0:0", "item:72093:0:0:0:0:0:0", 0.25, "prospect")
	TSMAPI.Conversions2:Add("item:76135:0:0:0:0:0:0", "item:72103:0:0:0:0:0:0", 0.2, "prospect")
	TSMAPI.Conversions2:Add("item:76135:0:0:0:0:0:0", "item:72094:0:0:0:0:0:0", 0.2, "prospect")
	-- Pandarian Garnet
	TSMAPI.Conversions2:Add("item:76136:0:0:0:0:0:0", "item:72092:0:0:0:0:0:0", 0.25, "prospect")
	TSMAPI.Conversions2:Add("item:76136:0:0:0:0:0:0", "item:72093:0:0:0:0:0:0", 0.25, "prospect")
	TSMAPI.Conversions2:Add("item:76136:0:0:0:0:0:0", "item:72103:0:0:0:0:0:0", 0.2, "prospect")
	TSMAPI.Conversions2:Add("item:76136:0:0:0:0:0:0", "item:72094:0:0:0:0:0:0", 0.2, "prospect")
	-- Alexandrite
	TSMAPI.Conversions2:Add("item:76137:0:0:0:0:0:0", "item:72092:0:0:0:0:0:0", 0.25, "prospect")
	TSMAPI.Conversions2:Add("item:76137:0:0:0:0:0:0", "item:72093:0:0:0:0:0:0", 0.25, "prospect")
	TSMAPI.Conversions2:Add("item:76137:0:0:0:0:0:0", "item:72103:0:0:0:0:0:0", 0.2, "prospect")
	TSMAPI.Conversions2:Add("item:76137:0:0:0:0:0:0", "item:72094:0:0:0:0:0:0", 0.2, "prospect")
	-- ========================================== Rare Gems ========================================
	-- Dawnstone
	TSMAPI.Conversions2:Add("item:23440:0:0:0:0:0:0", "item:23424:0:0:0:0:0:0", 0.01, "prospect")
	TSMAPI.Conversions2:Add("item:23440:0:0:0:0:0:0", "item:23425:0:0:0:0:0:0", 0.04, "prospect")
	-- Living Ruby
	TSMAPI.Conversions2:Add("item:23436:0:0:0:0:0:0", "item:23424:0:0:0:0:0:0", 0.01, "prospect")
	TSMAPI.Conversions2:Add("item:23436:0:0:0:0:0:0", "item:23425:0:0:0:0:0:0", 0.04, "prospect")
	-- Nightseye
	TSMAPI.Conversions2:Add("item:23441:0:0:0:0:0:0", "item:23424:0:0:0:0:0:0", 0.01, "prospect")
	TSMAPI.Conversions2:Add("item:23441:0:0:0:0:0:0", "item:23425:0:0:0:0:0:0", 0.04, "prospect")
	-- Noble Topaz
	TSMAPI.Conversions2:Add("item:23439:0:0:0:0:0:0", "item:23424:0:0:0:0:0:0", 0.01, "prospect")
	TSMAPI.Conversions2:Add("item:23439:0:0:0:0:0:0", "item:23425:0:0:0:0:0:0", 0.04, "prospect")
	-- Star of Elune
	TSMAPI.Conversions2:Add("item:23438:0:0:0:0:0:0", "item:23424:0:0:0:0:0:0", 0.01, "prospect")
	TSMAPI.Conversions2:Add("item:23438:0:0:0:0:0:0", "item:23425:0:0:0:0:0:0", 0.04, "prospect")
	-- Talasite
	TSMAPI.Conversions2:Add("item:23437:0:0:0:0:0:0", "item:23424:0:0:0:0:0:0", 0.01, "prospect")
	TSMAPI.Conversions2:Add("item:23437:0:0:0:0:0:0", "item:23425:0:0:0:0:0:0", 0.04, "prospect")
	-- Autumn's Glow
	TSMAPI.Conversions2:Add("item:36921:0:0:0:0:0:0", "item:36909:0:0:0:0:0:0", 0.01, "prospect")
	TSMAPI.Conversions2:Add("item:36921:0:0:0:0:0:0", "item:36912:0:0:0:0:0:0", 0.04, "prospect")
	TSMAPI.Conversions2:Add("item:36921:0:0:0:0:0:0", "item:36910:0:0:0:0:0:0", 0.04, "prospect")
	-- Forest Emerald
	TSMAPI.Conversions2:Add("item:36933:0:0:0:0:0:0", "item:36909:0:0:0:0:0:0", 0.01, "prospect")
	TSMAPI.Conversions2:Add("item:36933:0:0:0:0:0:0", "item:36912:0:0:0:0:0:0", 0.04, "prospect")
	TSMAPI.Conversions2:Add("item:36933:0:0:0:0:0:0", "item:36910:0:0:0:0:0:0", 0.04, "prospect")
	-- Monarch Topaz
	TSMAPI.Conversions2:Add("item:36930:0:0:0:0:0:0", "item:36909:0:0:0:0:0:0", 0.01, "prospect")
	TSMAPI.Conversions2:Add("item:36930:0:0:0:0:0:0", "item:36912:0:0:0:0:0:0", 0.04, "prospect")
	TSMAPI.Conversions2:Add("item:36930:0:0:0:0:0:0", "item:36910:0:0:0:0:0:0", 0.04, "prospect")
	-- Scarlet Ruby
	TSMAPI.Conversions2:Add("item:36918:0:0:0:0:0:0", "item:36909:0:0:0:0:0:0", 0.01, "prospect")
	TSMAPI.Conversions2:Add("item:36918:0:0:0:0:0:0", "item:36912:0:0:0:0:0:0", 0.04, "prospect")
	TSMAPI.Conversions2:Add("item:36918:0:0:0:0:0:0", "item:36910:0:0:0:0:0:0", 0.04, "prospect")
	-- Sky Sapphire
	TSMAPI.Conversions2:Add("item:36924:0:0:0:0:0:0", "item:36909:0:0:0:0:0:0", 0.01, "prospect")
	TSMAPI.Conversions2:Add("item:36924:0:0:0:0:0:0", "item:36912:0:0:0:0:0:0", 0.04, "prospect")
	TSMAPI.Conversions2:Add("item:36924:0:0:0:0:0:0", "item:36910:0:0:0:0:0:0", 0.04, "prospect")
	-- Twilight Opal
	TSMAPI.Conversions2:Add("item:36927:0:0:0:0:0:0", "item:36909:0:0:0:0:0:0", 0.01, "prospect")
	TSMAPI.Conversions2:Add("item:36927:0:0:0:0:0:0", "item:36912:0:0:0:0:0:0", 0.04, "prospect")
	TSMAPI.Conversions2:Add("item:36927:0:0:0:0:0:0", "item:36910:0:0:0:0:0:0", 0.04, "prospect")
	-- Dream Emerald
	TSMAPI.Conversions2:Add("item:52192:0:0:0:0:0:0", "item:53038:0:0:0:0:0:0", 0.08, "prospect")
	TSMAPI.Conversions2:Add("item:52192:0:0:0:0:0:0", "item:52185:0:0:0:0:0:0", 0.05, "prospect")
	TSMAPI.Conversions2:Add("item:52192:0:0:0:0:0:0", "item:52183:0:0:0:0:0:0", 0.04, "prospect")
	-- Ember Topaz
	TSMAPI.Conversions2:Add("item:52193:0:0:0:0:0:0", "item:53038:0:0:0:0:0:0", 0.08, "prospect")
	TSMAPI.Conversions2:Add("item:52193:0:0:0:0:0:0", "item:52185:0:0:0:0:0:0", 0.05, "prospect")
	TSMAPI.Conversions2:Add("item:52193:0:0:0:0:0:0", "item:52183:0:0:0:0:0:0", 0.04, "prospect")
	-- Inferno Ruby
	TSMAPI.Conversions2:Add("item:52190:0:0:0:0:0:0", "item:53038:0:0:0:0:0:0", 0.08, "prospect")
	TSMAPI.Conversions2:Add("item:52190:0:0:0:0:0:0", "item:52185:0:0:0:0:0:0", 0.05, "prospect")
	TSMAPI.Conversions2:Add("item:52190:0:0:0:0:0:0", "item:52183:0:0:0:0:0:0", 0.04, "prospect")
	-- Amberjewel
	TSMAPI.Conversions2:Add("item:52195:0:0:0:0:0:0", "item:53038:0:0:0:0:0:0", 0.08, "prospect")
	TSMAPI.Conversions2:Add("item:52195:0:0:0:0:0:0", "item:52185:0:0:0:0:0:0", 0.05, "prospect")
	TSMAPI.Conversions2:Add("item:52195:0:0:0:0:0:0", "item:52183:0:0:0:0:0:0", 0.04, "prospect")
	-- Demonseye
	TSMAPI.Conversions2:Add("item:52194:0:0:0:0:0:0", "item:53038:0:0:0:0:0:0", 0.08, "prospect")
	TSMAPI.Conversions2:Add("item:52194:0:0:0:0:0:0", "item:52185:0:0:0:0:0:0", 0.05, "prospect")
	TSMAPI.Conversions2:Add("item:52194:0:0:0:0:0:0", "item:52183:0:0:0:0:0:0", 0.04, "prospect")
	-- Ocean Sapphire
	TSMAPI.Conversions2:Add("item:52191:0:0:0:0:0:0", "item:53038:0:0:0:0:0:0", 0.08, "prospect")
	TSMAPI.Conversions2:Add("item:52191:0:0:0:0:0:0", "item:52185:0:0:0:0:0:0", 0.05, "prospect")
	TSMAPI.Conversions2:Add("item:52191:0:0:0:0:0:0", "item:52183:0:0:0:0:0:0", 0.04, "prospect")
	-- Primordial Ruby
	TSMAPI.Conversions2:Add("item:76131:0:0:0:0:0:0", "item:72092:0:0:0:0:0:0", 0.04, "prospect")
	TSMAPI.Conversions2:Add("item:76131:0:0:0:0:0:0", "item:72093:0:0:0:0:0:0", 0.04, "prospect")
	TSMAPI.Conversions2:Add("item:76131:0:0:0:0:0:0", "item:72103:0:0:0:0:0:0", 0.15, "prospect")
	TSMAPI.Conversions2:Add("item:76131:0:0:0:0:0:0", "item:72094:0:0:0:0:0:0", 0.15, "prospect")
	-- River's Heart
	TSMAPI.Conversions2:Add("item:76138:0:0:0:0:0:0", "item:72092:0:0:0:0:0:0", 0.04, "prospect")
	TSMAPI.Conversions2:Add("item:76138:0:0:0:0:0:0", "item:72093:0:0:0:0:0:0", 0.04, "prospect")
	TSMAPI.Conversions2:Add("item:76138:0:0:0:0:0:0", "item:72103:0:0:0:0:0:0", 0.15, "prospect")
	TSMAPI.Conversions2:Add("item:76138:0:0:0:0:0:0", "item:72094:0:0:0:0:0:0", 0.15, "prospect")
	-- Wild Jade
	TSMAPI.Conversions2:Add("item:76139:0:0:0:0:0:0", "item:72092:0:0:0:0:0:0", 0.04, "prospect")
	TSMAPI.Conversions2:Add("item:76139:0:0:0:0:0:0", "item:72093:0:0:0:0:0:0", 0.04, "prospect")
	TSMAPI.Conversions2:Add("item:76139:0:0:0:0:0:0", "item:72103:0:0:0:0:0:0", 0.15, "prospect")
	TSMAPI.Conversions2:Add("item:76139:0:0:0:0:0:0", "item:72094:0:0:0:0:0:0", 0.15, "prospect")
	-- Vermillion Onyx
	TSMAPI.Conversions2:Add("item:76140:0:0:0:0:0:0", "item:72092:0:0:0:0:0:0", 0.04, "prospect")
	TSMAPI.Conversions2:Add("item:76140:0:0:0:0:0:0", "item:72093:0:0:0:0:0:0", 0.04, "prospect")
	TSMAPI.Conversions2:Add("item:76140:0:0:0:0:0:0", "item:72103:0:0:0:0:0:0", 0.15, "prospect")
	TSMAPI.Conversions2:Add("item:76140:0:0:0:0:0:0", "item:72094:0:0:0:0:0:0", 0.15, "prospect")
	-- Imperial Amethyst
	TSMAPI.Conversions2:Add("item:76141:0:0:0:0:0:0", "item:72092:0:0:0:0:0:0", 0.04, "prospect")
	TSMAPI.Conversions2:Add("item:76141:0:0:0:0:0:0", "item:72093:0:0:0:0:0:0", 0.04, "prospect")
	TSMAPI.Conversions2:Add("item:76141:0:0:0:0:0:0", "item:72103:0:0:0:0:0:0", 0.15, "prospect")
	TSMAPI.Conversions2:Add("item:76141:0:0:0:0:0:0", "item:72094:0:0:0:0:0:0", 0.15, "prospect")
	-- Sun's Radiance
	TSMAPI.Conversions2:Add("item:76142:0:0:0:0:0:0", "item:72092:0:0:0:0:0:0", 0.04, "prospect")
	TSMAPI.Conversions2:Add("item:76142:0:0:0:0:0:0", "item:72093:0:0:0:0:0:0", 0.04, "prospect")
	TSMAPI.Conversions2:Add("item:76142:0:0:0:0:0:0", "item:72103:0:0:0:0:0:0", 0.15, "prospect")
	TSMAPI.Conversions2:Add("item:76142:0:0:0:0:0:0", "item:72094:0:0:0:0:0:0", 0.15, "prospect")
	-- =========================================== Essences ========================================
	-- Celestial Essence
	TSMAPI.Conversions2:Add("item:52719:0:0:0:0:0:0", "item:52718:0:0:0:0:0:0", 1/3, "transform")
	TSMAPI.Conversions2:Add("item:52718:0:0:0:0:0:0", "item:52719:0:0:0:0:0:0", 3, "transform")
	-- Cosmic Essence
	TSMAPI.Conversions2:Add("item:34055:0:0:0:0:0:0", "item:34056:0:0:0:0:0:0", 1/3, "transform")
	TSMAPI.Conversions2:Add("item:34056:0:0:0:0:0:0", "item:34055:0:0:0:0:0:0", 3, "transform")
	-- Planar Essence
	TSMAPI.Conversions2:Add("item:22446:0:0:0:0:0:0", "item:22447:0:0:0:0:0:0", 1/3, "transform")
	TSMAPI.Conversions2:Add("item:22447:0:0:0:0:0:0", "item:22446:0:0:0:0:0:0", 3, "transform")
	-- Eternal Essence
	TSMAPI.Conversions2:Add("item:16203:0:0:0:0:0:0", "item:16202:0:0:0:0:0:0", 1/3, "transform")
	TSMAPI.Conversions2:Add("item:16202:0:0:0:0:0:0", "item:16203:0:0:0:0:0:0", 3, "transform")
	-- Nether Essence
	TSMAPI.Conversions2:Add("item:11175:0:0:0:0:0:0", "item:11174:0:0:0:0:0:0", 1/3, "transform")
	TSMAPI.Conversions2:Add("item:11174:0:0:0:0:0:0", "item:11175:0:0:0:0:0:0", 3, "transform")
	-- Mystic Essence
	TSMAPI.Conversions2:Add("item:11135:0:0:0:0:0:0", "item:11134:0:0:0:0:0:0", 1/3, "transform")
	TSMAPI.Conversions2:Add("item:11134:0:0:0:0:0:0", "item:11135:0:0:0:0:0:0", 3, "transform")
	-- Astral Essence
	TSMAPI.Conversions2:Add("item:11082:0:0:0:0:0:0", "item:10998:0:0:0:0:0:0", 1/3, "transform")
	TSMAPI.Conversions2:Add("item:10998:0:0:0:0:0:0", "item:11082:0:0:0:0:0:0", 3, "transform")
	-- Magic Essence
	TSMAPI.Conversions2:Add("item:10939:0:0:0:0:0:0", "item:10938:0:0:0:0:0:0", 1/3, "transform")
	TSMAPI.Conversions2:Add("item:10938:0:0:0:0:0:0", "item:10939:0:0:0:0:0:0", 3, "transform")
	-- =========================================== Essences ========================================
	-- Heavenly Shard
	TSMAPI.Conversions2:Add("item:52721:0:0:0:0:0:0", "item:52720:0:0:0:0:0:0", 1/3, "transform")
	-- Dream Shard
	TSMAPI.Conversions2:Add("item:34052:0:0:0:0:0:0", "item:34053:0:0:0:0:0:0", 1/3, "transform")
	-- Ethereal Shard
	TSMAPI.Conversions2:Add("item:74247:0:0:0:0:0:0", "item:74252:0:0:0:0:0:0", 1/3, "transform")
	-- Luminous Shard
	TSMAPI.Conversions2:Add("item:111245:0:0:0:0:0:0", "item:115502:0:0:0:0:0:0", 0.1, "transform")
	-- =========================================== Crystals ========================================
	-- Temporal Crystal
	TSMAPI.Conversions2:Add("item:113588:0:0:0:0:0:0", "item:115504:0:0:0:0:0:0", 0.1, "transform")
	-- ======================================== Primals / Motes ====================================
	-- Water
	TSMAPI.Conversions2:Add("item:21885:0:0:0:0:0:0", "item:22578:0:0:0:0:0:0", 0.1, "transform")
	-- Shadow
	TSMAPI.Conversions2:Add("item:22456:0:0:0:0:0:0", "item:22577:0:0:0:0:0:0", 0.1, "transform")
	-- Mana
	TSMAPI.Conversions2:Add("item:22457:0:0:0:0:0:0", "item:22576:0:0:0:0:0:0", 0.1, "transform")
	-- Life
	TSMAPI.Conversions2:Add("item:21886:0:0:0:0:0:0", "item:22575:0:0:0:0:0:0", 0.1, "transform")
	-- Fire
	TSMAPI.Conversions2:Add("item:21884:0:0:0:0:0:0", "item:22574:0:0:0:0:0:0", 0.1, "transform")
	-- Earth
	TSMAPI.Conversions2:Add("item:22452:0:0:0:0:0:0", "item:22573:0:0:0:0:0:0", 0.1, "transform")
	-- Air
	TSMAPI.Conversions2:Add("item:22451:0:0:0:0:0:0", "item:22572:0:0:0:0:0:0", 0.1, "transform")
	-- ===================================== Crystalized / Eternal =================================
	-- Air
	TSMAPI.Conversions2:Add("item:37700:0:0:0:0:0:0", "item:35623:0:0:0:0:0:0", 10, "transform")
	TSMAPI.Conversions2:Add("item:35623:0:0:0:0:0:0", "item:37700:0:0:0:0:0:0", 0.1, "transform")
	-- Earth
	TSMAPI.Conversions2:Add("item:37701:0:0:0:0:0:0", "item:35624:0:0:0:0:0:0", 10, "transform")
	TSMAPI.Conversions2:Add("item:35624:0:0:0:0:0:0", "item:37701:0:0:0:0:0:0", 0.1, "transform")
	-- Fire
	TSMAPI.Conversions2:Add("item:37702:0:0:0:0:0:0", "item:36860:0:0:0:0:0:0", 10, "transform")
	TSMAPI.Conversions2:Add("item:36860:0:0:0:0:0:0", "item:37702:0:0:0:0:0:0", 0.1, "transform")
	-- Shadow
	TSMAPI.Conversions2:Add("item:37703:0:0:0:0:0:0", "item:35627:0:0:0:0:0:0", 10, "transform")
	TSMAPI.Conversions2:Add("item:35627:0:0:0:0:0:0", "item:37703:0:0:0:0:0:0", 0.1, "transform")
	-- Life
	TSMAPI.Conversions2:Add("item:37704:0:0:0:0:0:0", "item:35625:0:0:0:0:0:0", 10, "transform")
	TSMAPI.Conversions2:Add("item:35625:0:0:0:0:0:0", "item:37704:0:0:0:0:0:0", 0.1, "transform")
	-- Water
	TSMAPI.Conversions2:Add("item:37705:0:0:0:0:0:0", "item:35622:0:0:0:0:0:0", 10, "transform")
	TSMAPI.Conversions2:Add("item:35622:0:0:0:0:0:0", "item:37705:0:0:0:0:0:0", 0.1, "transform")
	-- ========================================= Vendor Trades =====================================
	-- Ivory Ink
	TSMAPI.Conversions2:Add("item:37101:0:0:0:0:0:0", "item:113111:0:0:0:0:0:0", 1, "vendortrade")
	-- Moonglow Ink
	TSMAPI.Conversions2:Add("item:39469:0:0:0:0:0:0", "item:113111:0:0:0:0:0:0", 1, "vendortrade")
	-- Midnight Ink
	TSMAPI.Conversions2:Add("item:39774:0:0:0:0:0:0", "item:113111:0:0:0:0:0:0", 1, "vendortrade")
	-- Lion's Ink
	TSMAPI.Conversions2:Add("item:43116:0:0:0:0:0:0", "item:113111:0:0:0:0:0:0", 1, "vendortrade")
	-- Jadefire Ink
	TSMAPI.Conversions2:Add("item:43118:0:0:0:0:0:0", "item:113111:0:0:0:0:0:0", 1, "vendortrade")
	-- Celestial Ink
	TSMAPI.Conversions2:Add("item:43120:0:0:0:0:0:0", "item:113111:0:0:0:0:0:0", 1, "vendortrade")
	-- Shimmering Ink
	TSMAPI.Conversions2:Add("item:43122:0:0:0:0:0:0", "item:113111:0:0:0:0:0:0", 1, "vendortrade")
	-- Ethereal Ink
	TSMAPI.Conversions2:Add("item:43124:0:0:0:0:0:0", "item:113111:0:0:0:0:0:0", 1, "vendortrade")
	-- Ink of the Sea
	TSMAPI.Conversions2:Add("item:43126:0:0:0:0:0:0", "item:113111:0:0:0:0:0:0", 1, "vendortrade")
	-- Snowfall Ink
	TSMAPI.Conversions2:Add("item:43127:0:0:0:0:0:0", "item:113111:0:0:0:0:0:0", 0.1, "vendortrade")
	-- Blackfallow Ink
	TSMAPI.Conversions2:Add("item:61978:0:0:0:0:0:0", "item:113111:0:0:0:0:0:0", 1, "vendortrade")
	-- Inferno Ink
	TSMAPI.Conversions2:Add("item:61981:0:0:0:0:0:0", "item:113111:0:0:0:0:0:0", 0.1, "vendortrade")
	-- Ink of Dreams
	TSMAPI.Conversions2:Add("item:79254:0:0:0:0:0:0", "item:113111:0:0:0:0:0:0", 1, "vendortrade")
	-- Starlight Ink
	TSMAPI.Conversions2:Add("item:79255:0:0:0:0:0:0", "item:113111:0:0:0:0:0:0", 0.1, "vendortrade")
end