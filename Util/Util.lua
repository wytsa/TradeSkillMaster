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
	return CopyTable(TSM.db.factionrealm.characters)
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

function TSMAPI:IsPlayer(target, includeAlts, includeOtherFaction)
	target = strlower(target)
	local player = strlower(UnitName("player"))
	local faction = strlower(UnitFactionGroup("player"))
	local realm = strlower(GetRealmName())
	local factionrealm = faction.." - "..realm
	
	if target == player then
		return true
	elseif strfind(target, " %- ") and target == (player.." - "..realm) then
		return true
	end
	if includeAlts then
		local isConnectedRealm = {[realm]=true}
		for _, realmName in ipairs(TSMAPI:GetConnectedRealms() or {}) do
			isConnectedRealm[strlower(realmName)] = true
		end
		for factionrealmKey, data in pairs(TSM.db.sv.factionrealm) do
			local factionKey, realmKey = strmatch(factionrealmKey, "(.+) %- (.+)")
			factionKey = strlower(factionKey)
			realmKey = strlower(realmKey)
			if (includeOtherFaction or factionKey == faction) and isConnectedRealm[realmKey] then
				for charKey in pairs(data.characters) do
					if target == (strlower(charKey).." - "..realmKey) then
						return true
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
	TSMAPI:Assert(type(data) == "table", "Invalid parameter")
	local encodeTbl = isChat and LibCompressChatEncodeTable or LibCompressAddonEncodeTable
	
	-- We will compress using Huffman, LZW, and no compression separately, validate each one, and pick the shortest valid one.
	-- This is to deal with a bug in the compression code.
	local serialized = LibAceSerializer:Serialize(data)
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
	-- Deserialize
	local success
	success, data = LibAceSerializer:Deserialize(data)
	if not success or not data then return end
	return data
end