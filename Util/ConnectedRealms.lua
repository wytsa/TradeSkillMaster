-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--          http://www.curse.com/addons/wow/tradeskillmaster_warehousing          --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file contains various utility related to connected realms

local TSM = select(2, ...)
local lib = TSMAPI

local CONNECTED_REALMS = {
	US = {
		{"Aegwynn", "Daggerspine", "Gurubashi", "Hakkar"},
		{"Aggramar", "Fizzcrank"},
		{"Akama", "Dragonmaw"},
		{"Anetheron", "Magtheridon", "Ysondre"},
		{"Andorhal", "Scilla", "Ursin"},
		{"Anub'arak", "Chromaggus", "Crushridge", "Garithos", "Nathrezim", "Smolderthorn"},
		{"Arygos", "Llane"},
		{"Auchindoun", "Laughing Skull"},
		{"Azgalor", "Azshara"},
		{"Balnazzar", "Gorgonnash", "The Forgotten Coast", "Warsong"},
		{"Black Dragonflight", "Gul'dan", "Skullcrusher"},
		{"Blackhand", "Galakrond"},
		{"Blackwing Lair", "Dethecus", "Detheroc", "Haomarush", "Lethon"},
		{"Bladefist", "Kul Tiras"},
		{"Blood Furnace", "Mannoroth", "Nazjatar"},
		{"Bloodscalp", "Boulderfist", "Dunemaul", "Maiev", "Stonemaul"},
		{"Bronzebeard", "Shandris"},
		{"Burning Blade", "Lightning's Blade", "Onyxia"},
		{"Cairne", "Perenolde"},
		{"Coilfang", "Dalvengyr", "Dark Iron", "Demon Soul"},
		{"Dentarg", "Whisperwind"},
		{"Draenor", "Echo Isles"},
		{"Dragonblight", "Fenris"},
		{"Drak'Tharon", "Firetree", "Malorne", "Rivendare", "Spirestone", "Stormscale"},
		{"Draka", "Suramar"},
		{"Eonar", "Velen"},
		{"Executus", "Kalecgos"},
		{"Frostmane", "Tortheldrin"},
		{"Hellscream", "Zangarmarsh"},
		{"Icecrown", "Malygos"},
		{"Kargath", "Norgannon"},
		{"Kilrogg", "Winterhoof"},
		{"Muradin", "Nordrassil"},
		{"Nazgrel", "Nesingwary", "Vek'nilash"},
		{"Quel'dorei", "Sen'jin"},
		{"Ravencrest", "Uldaman"},
	},
	EU = {
		{"Agamaggan", "Crushridge", "Emeriss", "Hakkar"},
		{"Aggra (Português)", "Grim Batol"},
		{"Alexstrasza", "Nethersturm"},
		{"Anetheron", "Gul'dan", "Rajaxx"},
		{"Arathi", "Naxxramas", "Temple noir"},
		{"Area 52", "Un'Goro"},
		{"Arthas", "Vek'lor"},
		{"Arak-arahm", "Rashgarroth", "Throk'Feroth"},
		{"Boulderfist", "Chromaggus", "Daggerspine", "Shattered Halls", "Talnivarr", "Trollbane"},
		{"Burning Steppes", "Executus", "Kor'gall"},
		{"Colinas Pardas", "Tyrande"},
		{"Dalvengyr", "Nazjatar"},
		{"Das Syndikat", "Die Arguswacht"},
		{"Deepholm", "Razuvious"},
		{"Dethecus", "Mug'thol", "Terrordar", "Theradras"},
		{"Echsenkessel", "Taerar"},
		{"Eldre'Thalas", "Sinstralis"},
		{"Exodar", "Minahonda"},
		{"Garona", "Ner'zhul"},
		{"Karazhan", "Lightning's Blade"},
		{"Kilrogg", "Runetotem"},
		{"Sanguino", "Shen'dralar", "Uldum", "Zul'jin"},
		{"Scarshield Legion", "Sporeggar", "The Venture Co"},
		{"Thunderhorn", "Wildhammer"},
	},
}

function TSMAPI:GetConnectedRealms()
	local region = strupper(strsub(GetCVar("realmList"), 1, 2))
	if not CONNECTED_REALMS[region] then return end
	local currentRealm = GetRealmName()
	
	for _, realms in ipairs(CONNECTED_REALMS[region]) do
		for i, realm in ipairs(realms) do
			if realm == currentRealm then
				local result = CopyTable(realms)
				tremove(result, i)
				return result
			end
		end
	end
end