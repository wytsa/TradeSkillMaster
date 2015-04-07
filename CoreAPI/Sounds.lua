-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--          http://www.curse.com/addons/wow/tradeskillmaster_warehousing          --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file contains sound-related APIs

local TSM = select(2, ...)



-- ============================================================================
-- TSMAPI Functions
-- ============================================================================

function TSMAPI:GetNoSoundKey()
	return TSM.NO_SOUND_KEY
end

function TSMAPI:GetSounds()
	return {[TSM.NO_SOUND_KEY]="No Sound", ["AuctionWindowOpen"]="Auction Window Open", ["Fishing Reel in"]="Fishing Reel in", ["HumanExploration"]="Exploration", ["LEVELUP"]="Level Up", ["MapPing"]="Map Ping", ["MONEYFRAMEOPEN"]="Money Frame Open", ["QUESTCOMPLETED"]="Quest Completed", ["ReadyCheck"]="Ready Check", ["TSM_CASH_REGISTER"]="Cash Register"}
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