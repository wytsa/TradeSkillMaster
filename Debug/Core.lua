-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- core debug code

local TSM = select(2, ...)
local Debug = TSM:NewModule("Debug")
local dumpDefaults = {
	DEVTOOLS_MAX_ENTRY_CUTOFF = 30,    -- Maximum table entries shown
	DEVTOOLS_LONG_STRING_CUTOFF = 200, -- Maximum string size shown
	DEVTOOLS_DEPTH_CUTOFF = 10,        -- Maximum table depth
}



-- ============================================================================
-- TSMAPI Functions
-- ============================================================================

function TSMAPI.Debug:DumpTable(tbl, returnResult)
	DEVTOOLS_DEPTH_CUTOFF = dumpDefaults.DEVTOOLS_DEPTH_CUTOFF
	DEVTOOLS_MAX_ENTRY_CUTOFF = dumpDefaults.DEVTOOLS_MAX_ENTRY_CUTOFF
	DEVTOOLS_DEPTH_CUTOFF = dumpDefaults.DEVTOOLS_DEPTH_CUTOFF
	
	if not IsAddOnLoaded("Blizzard_DebugTools") then
		LoadAddOn("Blizzard_DebugTools")
	end
	
	local result = {}
	local tempChatFrame = {
		AddMessage = function(self, msg)
			tinsert(result, msg)
		end
	}
	
	local prevDefault = DEFAULT_CHAT_FRAME
	DEFAULT_CHAT_FRAME = tempChatFrame
	DevTools_Dump(tbl)
	DEFAULT_CHAT_FRAME = prevDefault
	
	for i, v in pairs(dumpDefaults) do
		_G[i] = v
	end
	
	if returnResult then
		return result
	else
		for _, msg in ipairs(result) do
			print(msg)
		end
	end
end



-- ============================================================================
-- Module Functions
-- ============================================================================

function Debug:SlashCommandHandler(arg)
	if arg == "view_log" then
		Debug:ShowLogViewer()
	elseif arg == "gui_helper" then
		Debug:ShowGUIHelper()
	elseif arg == "error" then
		TSM:ShowError("Manually triggered error")
	else
		local chatFrame = TSMAPI:GetChatFrame()
		TSM:Print("Debug Commands:")
		chatFrame:AddMessage("|cffffaa00/tsm debug view_log|r - Show the debug log viewer")
		chatFrame:AddMessage("|cffffaa00/tsm debug gui_helper|r - Show the GUI helper")
		chatFrame:AddMessage("|cffffaa00/tsm debug error|r - Throw a lua error")
	end
end