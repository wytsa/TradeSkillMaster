-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--          http://www.curse.com/addons/wow/tradeskillmaster_warehousing          --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file contains sound-related APIs

local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local SOUNDS = {
	[TSM.NO_SOUND_KEY] = "|cff99ffff"..L["No Sound"].."|r",
	["AuctionWindowOpen"] = L["Auction Window Open"],
	["AuctionWindowClose"] = L["Auction Window Close"],
	["RaidWarning"] = L["Raid Warning"],
	["UnwrapGift"] = L["Unwrap Gift"],
	["Fishing Reel in"] = L["Fishing Reel In"],
	["HumanExploration"] = L["Exploration"],
	["LevelUp"] = L["Level Up"],
	["MapPing"] = L["Map Ping"],
	["MONEYFRAMEOPEN"] = L["Money Frame Open"],
	["QUESTCOMPLETED"] = L["Quest Completed"],
	["ReadyCheck"] = L["Ready Check"],
	["TSM_CASH_REGISTER"] = L["Cash Register"],
	["UI_QuestObjectivesComplete"] = L["Quest Objectives Complete"],
	["IgPlayerInviteAccept"] = L["Player Invite Accept"],
	["UI_AutoQuestComplete"] = L["Auto Quest Complete"],
	["QUESTADDED"] = L["Quest Added"],
}



-- ============================================================================
-- TSMAPI Functions
-- ============================================================================

function TSMAPI:GetNoSoundKey()
	return TSM.NO_SOUND_KEY
end

function TSMAPI:GetSounds()
	return SOUNDS
end

function TSMAPI:DoPlaySound(soundKey)
	if soundKey == TSM.NO_SOUND_KEY then
		-- do nothing
	elseif soundKey == "TSM_CASH_REGISTER" then
		PlaySoundFile("Interface\\Addons\\TradeSkillMaster\\Media\\register.mp3", "Master")
	else
		PlaySound(soundKey, "Master")
	end
end