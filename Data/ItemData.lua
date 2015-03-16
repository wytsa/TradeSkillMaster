-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- random lookup tables and other functions that don't have a home go in here

local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster")

TSMAPI.SOULBOUND_MATS = {
	["item:79731:0:0:0:0:0:0"] = true, -- Scroll of Wisdom
	["item:82447:0:0:0:0:0:0"] = true, -- Imperial Silk
	["item:54440:0:0:0:0:0:0"] = true, -- Dreamcloth
	["item:94111:0:0:0:0:0:0"] = true, -- Lightning Steel Ingot
	["item:94113:0:0:0:0:0:0"] = true, -- Jard's Peculiar Energy Source
	["item:98717:0:0:0:0:0:0"] = true, -- Balanced Trillium Ingot
	["item:98619:0:0:0:0:0:0"] = true, -- Celestial Cloth
	["item:98617:0:0:0:0:0:0"] = true, -- Hardened Magnificent Hide
	["item:108257:0:0:0:0:0:0"] = true, -- Truesteel Ingot
	["item:108995:0:0:0:0:0:0"] = true, -- Metamorphic Crystal
	["item:110611:0:0:0:0:0:0"] = true, -- Burnished Leather
	["item:111366:0:0:0:0:0:0"] = true, -- Gearspring Parts
	["item:111556:0:0:0:0:0:0"] = true, -- Hexweave Cloth
	["item:112377:0:0:0:0:0:0"] = true, -- War Paints
	["item:115524:0:0:0:0:0:0"] = true, -- Taladite Crystal
}