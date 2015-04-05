-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- general item lookup tables and other item data functions

local TSM = select(2, ...)
local ItemData = TSM:NewModule("ItemData", "AceEvent-3.0")
local private = {}



-- ============================================================================
-- TSMAPI Functions
-- ============================================================================

function TSMAPI.Item:IsSoulboundMat(itemString)
	itemString = TSMAPI:GetItemString2(itemString)
	return itemString and private.soulboundMats[itemString]
end

function TSMAPI.Item:GetVendorCost(itemString)
	itemString = TSMAPI:GetItemString2(itemString)
	return itemString and TSM.db.global.vendorItems[itemString]
end



-- ============================================================================
-- Module Functions
-- ============================================================================

function ItemData:OnEnable()
	ItemData:RegisterEvent("MERCHANT_SHOW", "ScanMerchant")
	local itemString = next(TSM.db.global.vendorItems)
	if itemString and TSMAPI:GetItemString2(itemString) ~= itemString then
		-- they just upgraded to TSM3, so wipe the table
		wipe(TSM.db.global.vendorItems)
	end
	
	for itemString, cost in pairs(private.preloadedVendorCosts) do
		TSM.db.global.vendorItems[itemString] = TSM.db.global.vendorItems[itemString] or cost
	end
end

function ItemData:ScanMerchant(event)
	for i=1, GetMerchantNumItems() do
		local itemString = TSMAPI:GetItemString2(GetMerchantItemLink(i))
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
		TSMAPI:CreateTimeDelay("scanMerchantDelay", 1, ItemData.ScanMerchant)
	end
end



-- ============================================================================
-- Static Item Data Tables
-- ============================================================================

private.preloadedVendorCosts = {
	["i:80433"] = 2000000, -- Blood Spirit
	["i:83092"] = 200000000, -- Orb of Mystery
	["i:65893"] = 30000000, -- Sands of Time
	["i:58265"] = 20000, -- Highland Pomegranate
	["i:65892"] = 50000000, -- Pyrium-Laced Crystalline Vial
	["i:67319"] = 328990, -- Preserved Ogre Eye
	["i:67335"] = 445561, -- Silver Charm Bracelet
	["i:74659"] = 30000, -- Farm Chicken
	["i:74660"] = 15000, -- Pandaren Peach
	["i:74832"] = 12000, -- Barley
	["i:74845"] = 35000, -- Ginseng
	["i:74851"] = 14000, -- Rice
	["i:74852"] = 16000, -- Yak Milk
	["i:74854"] = 7000, -- Instant Noodles
	["i:85583"] = 12000, -- Needle Mushrooms
	["i:85584"] = 17000, -- Silkworm Pupa
	["i:85585"] = 27000, -- Red Beans
	["i:102539"] = 5000, -- Fresh Strawberries
	["i:102540"] = 5000, -- Fresh Mangos
	["i:52188"] = 15000, -- Jeweler's Setting
	["i:62323"] = 60000, -- Deathwing Scale Fragment
	["i:43102"] = 750000, -- Frozen Orb
	["i:44499"] = 30000000, -- Salvaged Iron Golem Parts
	["i:44500"] = 15000000, -- Elementium-Plated Exhaust Pipe
	["i:44501"] = 10000000, -- Goblin-Machined Piston
	["i:45087"] = 1000000, -- Runed Orb
	["i:47556"] = 1250000, -- Crusader Orb
	["i:49908"] = 1500000, -- Primordial Saronite
	["i:40533"] = 50000, -- Walnut Stock
	["i:30183"] = 700000, -- Nether Vortex
	["i:35948"] = 16000, -- Savory Snowplum
	["i:58278"] = 16000, -- Tropical Sunfruit
	["i:39684"] = 9000, -- Hair Trigger
	["i:34249"] = 1000000, -- Hula Girl Doll
	["i:38426"] = 30000, -- Eternium Thread
	["i:23572"] = 500000, -- Primal Nether
	["i:27860"] = 6400, -- Purified Draenic Water
	["i:35949"] = 8500, -- Tundra Berries
	["i:18567"] = 30000, -- Elemental Flux
	["i:90146"] = 20000, -- Tinker's Kit
	["i:4342"] = 2500, -- Purple Dye
	["i:10290"] = 2500, -- Pink Dye
	["i:10647"] = 2000, -- Engineer's Ink
	["i:14341"] = 5000, -- Rune Thread
	["i:34412"] = 1000, -- Sparkling Apple Cider
	["i:2325"] = 1000, -- Black Dye
	["i:8343"] = 2000, -- Heavy Silken Thread
	["i:2595"] = 2000, -- Jug of Badlands Bourbon
	["i:6261"] = 1000, -- Orange Dye
	["i:3857"] = 500, -- Coal
	["i:4291"] = 500, -- Silken Thread
	["i:11291"] = 4500, -- Star Wood
	["i:2594"] = 1500, -- Flagon of Dwarven Mead
	["i:3466"] = 2000, -- Strong Flux
	["i:4340"] = 350, -- Gray Dye
	["i:4341"] = 500, -- Yellow Dye
	["i:4400"] = 2000, -- Heavy Stock
	["i:2321"] = 100, -- Fine Thread
	["i:6530"] = 100, -- Nightcrawlers
	["i:2593"] = 150, -- Flask of Stormwind Tawny
	["i:2596"] = 120, -- Skin of Dwarven Stout
	["i:2605"] = 100, -- Green Dye
	["i:2604"] = 50, -- Red Dye
	["i:4289"] = 50, -- Salt
	["i:4399"] = 200, -- Wooden Stock
	["i:6260"] = 50, -- Blue Dye
	["i:1179"] = 125, -- Ice Cold Milk
	["i:2320"] = 10, -- Coarse Thread
	["i:2324"] = 25, -- Bleach
	["i:2678"] = 10, -- Mild Spices
	["i:2880"] = 100, -- Weak Flux
	["i:4470"] = 38, -- Simple Wood
	["i:4537"] = 125, -- Tel'Abim Banana
	["i:6217"] = 124, -- Copper Rod
	["i:17194"] = 10, -- Holiday Spices
	["i:17202"] = 10, -- Snowball
	["i:30817"] = 25, -- Simple Flour
	["i:44835"] = 10, -- Autumnal Herbs
	["i:2901"] = 81, -- Mining Pick
	["i:7005"] = 82, -- Skinning Knife
	["i:159"] = 25, -- Refreshing Spring Water
	["i:3371"] = 100, -- Crystal Vial
	["i:5956"] = 18, -- Blacksmith Hammer
	["i:17196"] = 50, -- Holiday Spirits
	["i:39354"] = 15, -- Light Parchment
	["i:44853"] = 25, -- Honey
	["i:44854"] = 25, -- Tangy Wetland Cranberries
	["i:44855"] = 25, -- Teldrassil Sweet Potato
	["i:46784"] = 25, -- Ripe Elwynn Pumpkin
	["i:46793"] = 25, -- Tangy Southfury Cranberries
	["i:46796"] = 25, -- Ripe Tirisfal Pumpkin
	["i:46797"] = 25, -- Mulgore Sweet Potato
	["i:79740"] = 23, -- Plain Wooden Staff
}

private.soulboundMats = {
	["i:79731"] = true, -- Scroll of Wisdom
	["i:82447"] = true, -- Imperial Silk
	["i:54440"] = true, -- Dreamcloth
	["i:94111"] = true, -- Lightning Steel Ingot
	["i:94113"] = true, -- Jard's Peculiar Energy Source
	["i:98717"] = true, -- Balanced Trillium Ingot
	["i:98619"] = true, -- Celestial Cloth
	["i:98617"] = true, -- Hardened Magnificent Hide
	["i:108257"] = true, -- Truesteel Ingot
	["i:108995"] = true, -- Metamorphic Crystal
	["i:110611"] = true, -- Burnished Leather
	["i:111366"] = true, -- Gearspring Parts
	["i:111556"] = true, -- Hexweave Cloth
	["i:112377"] = true, -- War Paints
	["i:115524"] = true, -- Taladite Crystal
}