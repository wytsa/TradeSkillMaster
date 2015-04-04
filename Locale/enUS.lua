-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- TradeSkillMaster Locale - enUS
-- Please use the localization app on CurseForge to update this
-- http://wow.curseforge.com/addons/TradeSkill-Master/localization/

local isDebug = false
--@debug@
isDebug = true
--@end-debug@
local L = LibStub("AceLocale-3.0"):NewLocale("TradeSkillMaster", "enUS", true, isDebug)
if not L then return end

--@localization(locale="enUS", format="lua_additive_table", same-key-is-true=true)@