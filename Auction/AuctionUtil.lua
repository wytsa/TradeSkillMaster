-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)


local AUCTION_PCT_COLORS = {
	{color="|cff2992ff", value=50}, -- blue
	{color="|cff16ff16", value=80}, -- green
	{color="|cffffff00", value=110}, -- yellow
	{color="|cffff9218", value=135}, -- orange
	{color="|cffff0000", value=math.huge}, -- red
}
function TSMAPI:GetAuctionPercentColor(percent)
	for i=1, #AUCTION_PCT_COLORS do
		if percent < AUCTION_PCT_COLORS[i].value then
			return AUCTION_PCT_COLORS[i].color
		end
	end
	
	return "|cffffffff"
end

local TIME_LEFT_STRINGS = {
	"|cffff000030m|r", -- Short
	"|cffff92182h|r", -- Medium
	"|cffffff0012h|r", -- Long
	"|cff2992ff48h|r", -- Very Long
}
function TSMAPI:GetAuctionTimeLeftText(timeLeft)
	return TIME_LEFT_STRINGS[timeLeft or 0] or "---"
end