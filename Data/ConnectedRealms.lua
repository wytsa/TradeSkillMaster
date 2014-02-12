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
		{"Aegwynn", "Bonechewer", "Daggerspine", "Gurubashi", "Hakkar"},
		{"Agamaggan", "Jaedenar", "The Underbog"},
		{"Aggramar", "Fizzcrank"},
		{"Altar of Storms", "Anetheron", "Magtheridon", "Ysondre"},
		{"Akama", "Dragonmaw"},
		{"Anub'arak", "Chromaggus", "Crushridge", "Garithos", "Nathrezim", "Smolderthorn"},
		{"Antonidas", "Uldum"},
		{"Andorhal", "Scilla", "Ursin"},
		{"Arygos", "Llane"},
		{"Auchindoun", "Laughing Skull"},
		{"Azgalor", "Azshara", "Destromath"},
		{"Balnazzar", "Gorgonnash", "The Forgotten Coast", "Warsong"},
		{"Black Dragonflight", "Gul'dan", "Skullcrusher"},
		{"Blackhand", "Galakrond"},
		{"Blackwing Lair", "Dethecus", "Detheroc", "Haomarush", "Lethon"},
		{"Blade's Edge", "Thunderhorn"},
		{"Bladefist", "Kul Tiras"},
		{"Blood Furnace", "Mannoroth", "Nazjatar"},
		{"Bloodscalp", "Boulderfist", "Dunemaul", "Maiev", "Stonemaul"},
		{"Bronzebeard", "Shandris"},
		{"Burning Blade", "Lightning's Blade", "Onyxia"},
		{"Cairne", "Perenolde"},
		{"Coilfang", "Dalvengyr", "Dark Iron", "Demon Soul"},
		{"Darrowmere", "Windrunner"},
		{"Dentarg", "Whisperwind"},
		{"Draenor", "Echo Isles"},
		{"Dragonblight", "Fenris"},
		{"Drak'Tharon", "Firetree", "Malorne", "Rivendare", "Spirestone", "Stormscale"},
		{"Draka", "Suramar"},
		{"Eonar", "Velen"},
		{"Executus", "Kalecgos"},
		{"Frostmane", "Ner'zhul", "Tortheldrin"},
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
		{"Ahn'Qiraj", "Balnazzar", "Boulderfist", "Chromaggus", "Daggerspine", "Shattered Halls", "Talnivarr", "Trollbane"},
		{"Alexstrasza", "Nethersturm"},
		{"Anetheron", "Festung der Stürme", "Gul'dan", "Rajaxx"},
		{"Arak-arahm", "Rashgarroth", "Throk'Feroth"},
		{"Arathi", "Naxxramas", "Temple noir"},
		{"Area 52", "Un'Goro"},
		{"Arthas", "Blutkessel", "Vek'lor"},
		{"Auchindoun", "Jaedenar"},
		{"Bladefist", "Zenedar"},
		{"Burning Steppes", "Executus", "Kor'gall"},
		{"Cho'gall", "Eldre'Thalas", "Sinstralis"},
		{"Colinas Pardas", "Tyrande"},
		{"Dalvengyr", "Nazjatar"},
		{"Das Syndikat", "Die Arguswacht"},
		{"Deathwing", "Karazhan", "Lightning's Blade"},
		{"Deepholm", "Razuvious"},
		{"Dethecus", "Mug'thol", "Terrordar", "Theradras"},
		{"Dragonmaw", "Haomarush"},
		{"Echsenkessel", "Taerar"},
		{"Exodar", "Minahonda"},
		{"Garona", "Ner'zhul"},
		{"Garrosh", "Nozdormu", "Shattrath"},
		{"Kilrogg", "Runetotem"},
		{"Ravenholdt", "Scarshield Legion", "Sporeggar", "The Venture Co"},
		{"Sanguino", "Shen'dralar", "Uldum", "Zul'jin"},
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