﻿-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--          http://www.curse.com/addons/wow/tradeskillmaster_warehousing          --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file contains various utility related to connected realms

local TSM = select(2, ...)
local cachedResult = nil

local CONNECTED_REALMS = {
	EU = {
		{"Aerie Peak","Bronzebeard"},
		{"Agamaggan","Emeriss","Twilight's Hammer","Bloodscalp","Crushridge","Hakkar"},
		{"Aggra (Português)","Grim Batol"},
		{"Aggramar","Hellscream"},
		{"Ahn'Qiraj","Sunstrider","Shattered Halls","Balnazzar","Talnivarr","Chromaggus","Daggerspine","Laughing Skull","Trollbane","Boulderfist"},
		{"Al'Akir","Skullcrusher","Xavius"},
		{"Alexstrasza","Nethersturm"},
		{"Alleria","Rexxar"},
		{"Alonsus","Kul Tiras","Anachronos"},
		{"Ambossar","Kargath"},
		{"Anetheron","Kil'jaeden","Rajaxx","Festung der Stürme","Gul'dan","Nathrezim"},
		{"Anub'arak","Nazjatar","Zuluhed","Dalvengyr","Frostmourne"},
		{"Arak-arahm","Rashgarroth","Kael'thas","Throk'Feroth"},
		{"Arathi","Naxxramas","Illidan","Temple noir"},
		{"Arathor","Hellfire"},
		{"Area 52","Un'Goro","Sen'jin"},
		{"Arthas","Blutkessel","Wrathbringer","Kel'Thuzad","Vek'lor"},
		{"Arygos","Khaz'goroth"},
		{"Aszune","Shadowsong"},
		{"Auchindoun","Dunemaul","Jaedenar"},
		{"Azjol-Nerub","Quel'Thalas"},
		{"Azshara","Krag'jin"},
		{"Azuremyst","Stormrage"},
		{"Baelgun","Lothar"},
		{"Blade's Edge","Vek'nilash"},
		{"Bladefist","Frostwhisper","Zenedar"},
		{"Bloodfeather","Shattered Hand","Kor'gall","Executus","Burning Steppes"},
		{"Bloodhoof","Khadgar"},
		{"Пиратская бухта","Ткач Смерти"},
		{"Bronze Dragonflight","Nordrassil"},
		{"Burning Blade","Drak'thul"},
		{"Chants éternels","Vol'jin"},
		{"Cho'gall","Sinstralis","Eldre'Thalas"},
		{"Colinas Pardas","Tyrande","Los Errantes"},
		{"Confrérie du Thorium","Les Sentinelles","Les Clairvoyants"},
		{"Conseil des Ombres","La Croisade écarlate","Culte de la Rive noire"},
		{"Dalaran","Marécage de Zangar"},
		{"Darkmoon Faire","Earthen Ring"},
		{"Darksorrow","Genjuros","Neptulon"},
		{"Darkspear","Terokkar","Saurfang"},
		{"Das Syndikat","Kult der Verdammten","Der Abyssische Rat","Die Todeskrallen","Die Arguswacht"},
		{"Deathwing","Karazhan","The Maelstrom","Lightning's Blade"},
		{"Подземье","Разувий"},
		{"Defias Brotherhood","Sporeggar","Scarshield Legion","The Venture Co","Ravenholdt"},
		{"Dentarg","Tarren Mill"},
		{"Der Mithrilorden","Der Rat von Dalaran"},
		{"Destromath","Nefarian","Mannoroth","Gorgonnash","Nera'thor"},
		{"Dethecus","Theradras","Onyxia","Terrordar","Mug'thol"},
		{"Die Nachtwache","Forscherliga"},
		{"Die Silberne Hand","Die ewige Wacht"},
		{"Doomhammer","Turalyon"},
		{"Dragonblight","Ghostlands"},
		{"Dragonmaw","Spinebreaker","Stormreaver","Vashj","Haomarush"},
		{"Drek'Thar","Uldaman"},
		{"Dun Morogh","Norgannon"},
		{"Durotan","Tirion"},
		{"Echsenkessel","Mal'Ganis","Taerar"},
		{"Eitrigg","Krasus"},
		{"Elune","Varimathras"},
		{"Emerald Dream","Terenas"},
		{"Exodar","Minahonda"},
		{"Garona","Sargeras","Ner'zhul"},
		{"Garrosh","Shattrath","Nozdormu"},
		{"Gilneas","Ulduar"},
		{"Седогрив","Король-лич"},
		{"Гром","Термоштепсель"},
		{"Kilrogg","Nagrand","Runetotem"},
		{"Lightbringer","Mazrigos"},
		{"Lordaeron","Tichondrius"},
		{"Madmortem","Proudmoore"},
		{"Malfurion","Malygos"},
		{"Malorne","Ysera"},
		{"Medivh","Suramar"},
		{"Moonglade","The Sha'tar"},
		{"Perenolde","Teldrassil"},
		{"Sanguino","Zul'jin","Uldum","Shen'dralar"},
		{"Thunderhorn","Wildhammer"},
		{"Todeswache","Zirkel des Cenarius"},
	},
	US = {
		{"Aegwynn","Bonechewer","Daggerspine","Gurubashi","Hakkar"},
		{"Agamaggan","Burning Legion","Archimonde","Jaedenar","The Underbog"},
		{"Aggramar","Fizzcrank"},
		{"Akama","Dragonmaw","Mug'thol"},
		{"Alexstrasza","Terokkar"},
		{"Alleria","Khadgar"},
		{"Altar of Storms","Magtheridon","Anetheron","Ysondre"},
		{"Alterac Mountains","Gorgonnash","Warsong","Balnazzar","The Forgotten Coast"},
		{"Andorhal","Zuluhed","Scilla","Ursin"},
		{"Antonidas","Uldum"},
		{"Anub'arak","Nathrezim","Crushridge","Smolderthorn","Chromaggus","Garithos"},
		{"Anvilmar","Undermine"},
		{"Arathor","Drenden"},
		{"Argent Dawn","The Scryers"},
		{"Arygos","Llane"},
		{"Auchindoun","Laughing Skull","Cho'gall"},
		{"Azgalor","Destromath","Thunderlord","Azshara"},
		{"Azjol-Nerub","Khaz Modan"},
		{"Azuremyst","Staghelm"},
		{"Baelgun","Doomhammer"},
		{"Black Dragonflight","Skullcrusher","Gul'dan"},
		{"Blackhand","Galakrond"},
		{"Blackwater Raiders","Shadow Council"},
		{"Blackwing Lair","Dethecus","Shadowmoon","Haomarush","Lethon","Detheroc"},
		{"Blade's Edge","Thunderhorn"},
		{"Bladefist","Kul Tiras"},
		{"Blood Furnace","Mannoroth","Nazjatar"},
		{"Bloodhoof","Duskwood"},
		{"Bloodscalp","Stonemaul","Dunemaul","Boulderfist","Maiev"},
		{"Borean Tundra","Shadowsong"},
		{"Bronzebeard","Shandris"},
		{"Burning Blade","Lightning's Blade","Onyxia"},
		{"Caelestrasz","Nagrand"},
		{"Cairne","Perenolde"},
		{"Cenarion Circle","Sisters of Elune"},
		{"Coilfang","Shattered Hand","Dalvengyr","Demon Soul","Dark Iron"},
		{"Darrowmere","Windrunner"},
		{"Dath'Remar","Khaz'goroth"},
		{"Dawnbringer","Madoran"},
		{"Deathwing","Executus","Kalecgos","Shattered Halls"},
		{"Dentarg","Whisperwind"},
		{"Draenor","Echo Isles"},
		{"Dragonblight","Fenris"},
		{"Drak'Tharon","Stormscale","Spirestone","Firetree","Malorne","Rivendare"},
		{"Drak'thul","Skywall"},
		{"Draka","Suramar"},
		{"Dreadmaul","Thaurissan"},
		{"Durotan","Ysera"},
		{"Eitrigg","Shu'halo"},
		{"Eldre'Thalas","Korialstrasz"},
		{"Elune","Gilneas"},
		{"Eonar","Velen"},
		{"Eredar","Spinebreaker","Gorefiend","Wildhammer"},
		{"Exodar","Medivh"},
		{"Farstriders","Thorium Brotherhood","Silver Hand"},
		{"Feathermoon","Scarlet Crusade"},
		{"Frostmane","Ner'zhul","Tortheldrin"},
		{"Frostwolf","Vashj"},
		{"Ghostlands","Kael'thas"},
		{"Gnomeregan","Moonrunner"},
		{"Greymane","Tanaris"},
		{"Grizzly Hills","Lothar"},
		{"Gundrak","Jubei'Thos"},
		{"Hellscream","Zangarmarsh"},
		{"Hydraxis","Terenas"},
		{"Icecrown","Malygos"},
		{"Kargath","Norgannon"},
		{"Kilrogg","Winterhoof"},
		{"Kirin Tor","Steamwheedle Cartel","Sentinels"},
		{"Lightninghoof","The Venture Co","Maelstrom"},
		{"Malfurion","Trollbane"},
		{"Misha","Rexxar"},
		{"Mok'Nathal","Silvermoon"},
		{"Muradin","Nordrassil"},
		{"Nazgrel","Vek'nilash","Nesingwary"},
		{"Quel'dorei","Sen'jin"},
		{"Ravencrest","Uldaman"},
		{"Ravenholdt","Twisting Nether"},
		{"Runetotem","Uther"},
	},
}

function TSMAPI:GetConnectedRealms()
	if cachedResult then return cachedResult end
	local region = GetCVar("portal") == "public-test" and "PTR" or GetCVar("portal")
	if not CONNECTED_REALMS[region] then
		cachedResult = {}
		return cachedResult
	end
	local currentRealm = GetRealmName()
	
	for _, realms in ipairs(CONNECTED_REALMS[region]) do
		for i, realm in ipairs(realms) do
			if realm == currentRealm then
				cachedResult = realms
				tremove(cachedResult, i)
				return cachedResult
			end
		end
	end
	cachedResult = {}
	return cachedResult
end