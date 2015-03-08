-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--          http://www.curse.com/addons/wow/tradeskillmaster_warehousing          --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file contains various money APIs

local TSM = select(2, ...)
TSM.GOLD_TEXT = "|cffffd700g|r"
TSM.SILVER_TEXT = "|cffc7c7cfs|r"
TSM.COPPER_TEXT = "|cffeda55fc|r"

local GOLD_ICON = "|TInterface\\MoneyFrame\\UI-GoldIcon:0|t"
local SILVER_ICON = "|TInterface\\MoneyFrame\\UI-SilverIcon:0|t"
local COPPER_ICON = "|TInterface\\MoneyFrame\\UI-CopperIcon:0|t"


local function PadNumber(num, pad)
	if pad and num < 10 then
		return "0"..num
	end
	
	return num
end

local function FormatNumber(num, pad, color)
	if num < 10 and pad then
		num = "0"..num
	end
	
	if color then
		return color..num.."|r"
	else
		return num
	end
end

local textMoneyParts = {}
local function FormatMoneyInternal(money, color, pad, trim, disabled, isIcon)
	local isNegative = money < 0
	money = abs(money)
	local gold = floor(money / COPPER_PER_GOLD)
	local silver = floor((money - (gold * COPPER_PER_GOLD)) / COPPER_PER_SILVER)
	local copper = floor(money%COPPER_PER_SILVER)
	local shouldPad = false
	local goldText, silverText, copperText = nil, nil, nil
	if isIcon then
		goldText = GOLD_ICON
		silverText = SILVER_ICON
		copperText = COPPER_ICON
	else
		goldText = disabled and "g" or TSM.GOLD_TEXT
		silverText = disabled and "s" or TSM.SILVER_TEXT
		copperText = disabled and "c" or TSM.COPPER_TEXT
	end
	local text = nil
	
	if money == 0 then
		return FormatNumber(0, false, color)..copperText
	end
	
	if trim then
		wipe(textMoneyParts) -- avoid creating a new table every time
		-- add gold
		if gold > 0 then
			tinsert(textMoneyParts, FormatNumber(gold, false, color)..goldText)
			shouldPad = pad
		end
		-- add silver
		if silver > 0 then
			tinsert(textMoneyParts, FormatNumber(silver, shouldPad, color)..silverText)
			shouldPad = pad
		end
		-- add copper
		if copper > 0 then
			tinsert(textMoneyParts, FormatNumber(copper, shouldPad, color)..copperText)
			shouldPad = pad
		end
		text = table.concat(textMoneyParts, " ")
	else
		if gold > 0 then
			text = FormatNumber(gold, false, color)..goldText.." "..FormatNumber(silver, pad, color)..silverText.." "..FormatNumber(copper, pad, color)..copperText
		elseif silver > 0 then
			text = FormatNumber(silver, pad, color)..silverText.." "..FormatNumber(copper, pad, color)..copperText
		else
			text = FormatNumber(copper, pad, color)..copperText
		end
	end
	
	if isNegative then
		if color then
			return color.."-|r"..text
		else
			return "-"..text
		end
	else
		return text
	end
end

--- Creates a formatted money string from a copper value.
-- @param money The money value in copper.
-- @param color The color to make the money text (minus the 'g'/'s'/'c'). If nil, will not add any extra color formatting.
-- @param pad If true, the formatted string will be left padded.
-- @param trim If true, will remove any 0 valued tokens. For example, "1g" instead of "1g0s0c". If money is zero, will return "0c".
-- @param disabled If true, the g/s/c text will not be colored.
-- @return Returns the formatted money text according to the parameters.
function TSMAPI:FormatTextMoney(money, color, pad, trim, disabled)
	money = tonumber(money)
	if not money then return end
	return FormatMoneyInternal(money, color, pad, trim, disabled, nil)
end

--- Creates a formatted money string from a copper value and uses coin icon.
-- @param money The money value in copper.
-- @param color The color to make the money text (minus the coin icons). If nil, will not add any extra color formatting.
-- @param pad If true, the formatted string will be left padded.
-- @param trim If true, will not remove any 0 valued tokens. For example, "1g" instead of "1g0s0c". If money is zero, will return "0c".
-- @return Returns the formatted money text according to the parameters.
function TSMAPI:FormatTextMoneyIcon(money, color, pad, trim)
	local money = tonumber(money)
	if not money then return end
	return FormatMoneyInternal(money, color, pad, trim, nil, true)
end

-- Converts a formated money string back to the copper value
function TSMAPI:UnformatTextMoney(value)
	value = value:trim()
	-- remove any colors
	value = gsub(gsub(value, "\124cff([0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])", ""), "\124r", "")
	
	-- extract gold/silver/copper values
	local gold = tonumber(strmatch(value, "([0-9]+)g"))
	local silver = tonumber(strmatch(value, "([0-9]+)s"))
	local copper = tonumber(strmatch(value, "([0-9]+)c"))
	
	-- test that there's no extra characters (other than spaces)
	value = gsub(value, "[0-9]+g", "", 1)
	value = gsub(value, "[0-9]+s", "", 1)
	value = gsub(value, "[0-9]+c", "", 1)
	if value:trim() ~= "" then return end
	
	if gold or silver or copper then
		-- Convert it all into copper
		copper = (copper or 0) + ((gold or 0) * COPPER_PER_GOLD) + ((silver or 0) * COPPER_PER_SILVER)
	end

	return copper
end