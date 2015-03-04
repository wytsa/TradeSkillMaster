-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--          http://www.curse.com/addons/wow/tradeskillmaster_warehousing          --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file contains various utility APIs

local TSM = select(2, ...)
local private = {}


--- Shows a popup dialog with the given name and ensures it's visible over the TSM frame by setting the frame strata to TOOLTIP.
-- @param name The name of the static popup dialog to be shown.
function TSMAPI:ShowStaticPopupDialog(name)
	StaticPopupDialogs[name].preferredIndex = 4
	StaticPopup_Show(name)
	for i=1, 100 do
		if _G["StaticPopup" .. i] and _G["StaticPopup" .. i].which == name then
			_G["StaticPopup" .. i]:SetFrameStrata("TOOLTIP")
			break
		end
	end
end

function TSMAPI:GetCharacters()
	local characters = {}
	for name in pairs(TSM.db.factionrealm.characters) do
		characters[name] = true
	end
	return characters
end

function TSMAPI:GetGuilds(includeIgnored)
	local guilds = {}
	for name in pairs(TSM.db.factionrealm.guildVaults) do
		if includeIgnored or not TSM.db.factionrealm.ignoreGuilds[name] then
			guilds[name] = true
		end
	end
	return guilds
end

function TSMAPI:GetPlayerGuild(player)
	return player and TSM.db.factionrealm.characterGuilds[player] or nil
end


local orig = ChatFrame_OnEvent
function ChatFrame_OnEvent(self, event, ...)
	local msg = select(1, ...)
	if (event == "CHAT_MSG_SYSTEM") then
		if (msg == ERR_AUCTION_STARTED) then -- absorb the Auction Created message
			return
		end
		if (msg == ERR_AUCTION_REMOVED) then -- absorb the Auction Cancelled message
			return
		end
	end
	return orig(self, event, ...)
end


-- A more versitile replacement for lua's select() function
-- If a list of indices is passed as the first parameter, only
-- those values will be returned, otherwise, the default select()
-- behavior will be followed.
function private:SelectHelper(positions, ...)
	if #positions == 0 then return end
	return select(tremove(positions, 1), ...), private:SelectHelper(positions, ...)
end
function TSMAPI:Select(positions, ...)
	if type(positions) == "number" then
		return select(positions, ...)
	elseif type(positions) == "table" then
		return private:SelectHelper(positions, ...)
	else
		error(format("Bad argument #1. Expected number or table, got %s", type(positions)))
	end
end

-- custom string splitting function that doesn't stack overflow
function TSMAPI:SafeStrSplit(str, sep)
	local parts = {}
	local s = 1
	while true do
		local e = strfind(str, sep, s)
		if not e then
			tinsert(parts, strsub(str, s))
			break
		end
		tinsert(parts, strsub(str, s, e-1))
		s = e + 1
	end
	return parts
end

local MAGIC_CHARACTERS = {'[', ']', '(', ')', '.', '+', '-', '*', '?', '^', '$'}
function TSMAPI:StrEscape(str)
	str = gsub(str, "%%", "\001")
	for _, char in ipairs(MAGIC_CHARACTERS) do
		str = gsub(str, "%"..char, "%%"..char)
	end
	str = gsub(str, "\001", "%%%%")
	return str
end

function TSMAPI:IsPlayer(target, includeAlts, includeOtherFaction, includeOtherAccounts)
	target = strlower(target)
	if not strfind(target, " %- ") then
		target = gsub(target, "%-", " - ", 1)
	end
	local player = strlower(UnitName("player"))
	local faction = strlower(UnitFactionGroup("player"))
	local realm = strlower(GetRealmName())
	local factionrealm = faction.." - "..realm
	
	if target == player then
		return true
	elseif strfind(target, " %- ") and target == (player.." - "..realm) then
		return true
	end
	if not strfind(target, " %- ") then
		target = target.." - "..realm
	end
	if includeAlts then
		local isConnectedRealm = {[realm]=true}
		for _, realmName in ipairs(TSMAPI:GetConnectedRealms()) do
			isConnectedRealm[strlower(realmName)] = true
		end
		for factionrealmKey, data in pairs(TSM.db.sv.factionrealm) do
			local factionKey, realmKey = strmatch(factionrealmKey, "(.+) %- (.+)")
			factionKey = strlower(factionKey)
			realmKey = strlower(realmKey)
			if (includeOtherFaction or factionKey == faction) and isConnectedRealm[realmKey] then
				for charKey in pairs(data.characters) do
					if includeOtherAccounts or not data.syncMetadata.TSM_CHARACTERS or (data.syncMetadata.TSM_CHARACTERS[charKey].owner == TSMAPI.Sync:GetAccountKey()) then
						if target == (strlower(charKey).." - "..realmKey) then
							return true
						end
					end
				end
			end
		end
	end
end

function TSMAPI:Round(value, sig)
	sig = sig or 1
	return floor((value / sig) + 0.5) * sig
end


-- Load the libraries needed for TSMAPI:Compress and TSMAPI:Decompress
local LibAceSerializer = LibStub:GetLibrary("AceSerializer-3.0")
local LibCompress = LibStub:GetLibrary("LibCompress")
local LibCompressAddonEncodeTable = LibCompress:GetAddonEncodeTable()
local LibCompressChatEncodeTable = LibCompress:GetAddonEncodeTable()

function TSMAPI:Compress(data, isChat)
	TSMAPI:Assert(type(data) == "table" or type(data) == "string", "Invalid parameter")
	local encodeTbl = isChat and LibCompressChatEncodeTable or LibCompressAddonEncodeTable
	
	-- We will compress using Huffman, LZW, and no compression separately, validate each one, and pick the shortest valid one.
	-- This is to deal with a bug in the compression code.
	local serialized = nil
	if type(data) == "table" then
		serialized = LibAceSerializer:Serialize(data)
	elseif type(data) == "string" then
		serialized = "\240"..data
	end
	local encodedData = {}
	encodedData[1] = encodeTbl:Encode(LibCompress:CompressHuffman(serialized))
	encodedData[2] = encodeTbl:Encode(LibCompress:CompressLZW(serialized))
	encodedData[3] = encodeTbl:Encode("\001"..serialized)
	
	-- verify each compresion and pick the shortest valid one
	local minIndex = -1
	local minLen = math.huge
	for i=3, 1, -1 do
		local test = LibCompress:Decompress(encodeTbl:Decode(encodedData[i]))
		if test and test == serialized and #encodedData[i] < minLen then
			minLen = #encodedData[i]
			minIndex = i
		end
	end
	
	TSMAPI:Assert(encodedData[minIndex], "Could not compress data")
	return encodedData[minIndex]
end

function TSMAPI:Decompress(data, isChat)
	local encodeTbl = isChat and LibCompressChatEncodeTable or LibCompressAddonEncodeTable
	-- Decode
	data = encodeTbl:Decode(data)
	if not data then return end
	-- Decompress
	data = LibCompress:Decompress(data)
	if not data then return end
	if type(data) == "string" and strsub(data, 1, 1) == "\240" then
		-- original data was a string, so we're done
		return strsub(data, 2)
	end
	-- Deserialize
	local success
	success, data = LibAceSerializer:Deserialize(data)
	if not success or not data then return end
	return data
end



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