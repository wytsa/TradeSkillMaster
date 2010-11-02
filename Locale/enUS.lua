-- ------------------------------------------------------------------------------------- --
-- 					Trade Skill Master - AddOn by Sapu (sapu94@gmail.com)		 		 --
--                http://wow.curseforge.com/addons/tradeskillmaster_shopping/            --
--                  TSM_Shopping - Extension by Xubera (xubera@gmail.com)                --
-- ------------------------------------------------------------------------------------- --

-- Trade Skill Master - Shopping - enUS
-- Please use the Localization App on CurseForge to Update this
-- http://wow.curseforge.com/addons/tradeskillmaster_shopping/localization/

local AceLocale = LibStub:GetLibrary("AceLocale-3.0")
local L = AceLocale:NewLocale("TradeSkillMaster_Shopping", "enUS", true)

-- ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
L["Buy!"] = true
L["Next"] = true
L["%d (%s per)"] = true --format "Quantity (price per)"
L["You have %d of your own."] = true --format "You have 'quantity' of your own."
L["You have %d of your own. (%d is in the bank.)"] = true
L["Spent: %s (Session: %s)"] = true --Spent: 'gold' (Session: 'goldSession')
L["\124cFFFF0000You have %d of this item on the AH!\124r"] = true
L["Searches the AH for materials you require."] = true -- Addon description
L["Shows the Shopping Frame."] = true --slash command
L["\124cFFFF0000No Auctions Found!\124r"] = true
L["Talk to an Auctioneer"] = true
L["Requires to search for some item."] = true