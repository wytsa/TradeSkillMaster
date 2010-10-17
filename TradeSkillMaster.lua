-- ------------------------------------------------------------------------------------- --
-- 					Scroll Master - AddOn by Sapu (sapu94@gmail.com)			 		 --
--             http://wow.curse.com/downloads/wow-addons/details/slippy.aspx             --
-- ------------------------------------------------------------------------------------- --

-- This is the main file for Scroll Master. This file mainly sets up the saved variables database, slash commands,
-- and the other files associated with Scroll Master. The following functions are contained attached to this file:
-- TSM:Debug() - for debugging purposes
-- TSM:OnEnable() - called when the addon is loaded / initizalizes the entire addon
-- TSM:OnDisable() - stores the tree status
-- TSM:ChatCommand() - registers slash commands (such as '/tsm', '/tsm scan', etc)
-- TSM:GetName() - takes an itemID and returns the name of that item - used throughout Scroll Master
-- TSM:BAG_UPDATE() - fires whenever a player's bags change - keeps track of materials / scrolls in bags
-- TSM:GetGroup() - converts the name (or table) of an enchant to a number
-- TSM:DSGetNum() - returns the number of the passed itemID in bags of the user's alts

-- The following "global" (within the addon) variables are initialized in this file:
-- TSM.version - stores the version of the addon
-- TSM.mode - stores the mode (profession) TSM is currently in
-- TSM.db - used to read from / save to the savedDB (saved variables database)
-- TSM.Data - contains the entire data.lua module
-- TSM.Scan - contains the entire scan.lua module
-- TSM.Enchanting - contains the entire enchanting.lua module
-- TSM.GUI - contains the entire gui.lua module
-- TSM.GameTime - a way to get millisecond precision timing - used for developing more effecient code

-- ===================================================================================== --


-- register this file with Ace Libraries
local TSM = select(2, ...)
TSM = LibStub("AceAddon-3.0"):NewAddon(TSM, "TradeSkillMaster", "AceEvent-3.0", "AceConsole-3.0")

local aceL = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
TSM.version = "0.1" -- current version of the addon

local function L(phrase)
	--TSM.lTable[phrase] = true
	return aceL[phrase]
end

-- stuff for debugging
local SMdebug = false
function TSM:Debug(...)
	if SMdebug then
		print(...)
	end
end
local debug = function(...) TSM:Debug(...) end

-- default values for the savedDB
local savedDBDefaults = {
	global = {
		treeStatus = {[2] = true, [5] = true},
		textOutput = {},
	},
	-- data that is stored per realm/faction combination
	factionrealm = {
		ScanStatus = {scrolls = "none", mats = "none"}, -- time of last scan
		AucData = {}, -- auction house scan data table
		alts = {}, -- stored alt names
		inventory = {}, -- stored inventory information
	},
	-- data that is stored per user profile
	profile = {
		minimapIcon = { -- minimap icon position and visibility
			hide = false,
			minimapPos = 220,
			radius = 80,
		},
		vellums = true, -- option to include vellums when computing scroll costs
		warnings = true, -- option to display warnings when TSM isn't compatible with another addon
		enchanting = {chants={}, mats={}}, -- table to store every enchant the user has in TSM
		matLock = {}, -- table of which material costs are locked ('lock mat costs' tab)
		SortEnchants = true, -- option to sort enchants by profit
		ShowLinks = true, -- option to show links in the enchant tabs
		Layout = 1, -- stores the selected layout
		autoOpenSM = true, -- whether or not to automatically open TSM when the scan is complete
		APMIncrease = 0.05, -- percentage to increase cost by when setting APM thresholds (5% = AH cut)
		APMFallback = 2,
		profitPercent = 0, -- percentage to subtract from buyout when calculating profit (5% = AH cut)
		matCostMethod = "smart", -- how to calculate the cost of materials: use the 'smart' average or lowest buyout as cost
		exportList = {}, -- list of enchants to export to APM3
		mainMinProfit = 30,
		showUnknownProfit = true,
		craftHistory = {}, -- stores a history of what enchants were crafted
		queueMinProfitGold = 50,
		queueMinProfitPercent = 0.5,
		restockMax = 3,
		restockAH = false,
		minThreshold = 1,
		aucMethod = "market",
		useDSBags = true,
		useDSBanks = true,
		useDSGuildBanks = true,
		useDSQueue = true,
		useDSTotals = true,
		useDSEnchants = true,
		DSGuilds = {},
		DSCharacters = {},
		autoOpenTotals = true,
		autoOpenTotals2 = true,
		mainProfitMethod = "gold",
		queueProfitMethod = "gold",
		maxProfitGold = 100,
		maxProfitThreshold = 20,
		advDSTotals = false,
	},
}

-- Called once the player has loaded WOW.
function TSM:OnEnable()
	TSM.lTable = {}
	for phrase in pairs(aceL) do
		TSM.lTable[phrase] = false
	end

	TSM:Print(string.format(L("Loaded %s successfully!"), "TradeSkill Master v" .. TSM.version))
	
	-- load Scroll Master's modules
	TSM.Data = TSM.modules.Data
	TSM.Scan = TSM.modules.Scan
	TSM.GUI = TSM.modules.GUI
	TSM.Enchanting = TSM.modules.Enchanting
	TSM.LibEnchant = TSM.modules.LibEnchant
	TSM.LibName = TSM.modules.LibName or {}
	
	-- load the savedDB into TSM.db
	TSM.db = LibStub:GetLibrary("AceDB-3.0"):New("TradeSkillMasterDB", savedDBDefaults, true)
	TSM.Data:Initialize() -- setup Scroll Master's internal data table using some savedDB data

	-- register the chat commands (slash commands)
	-- whenver '/tsm' or '/tradeskillmaster' is typed by the user, TSM:ChatCommand() will be called
   TSM:RegisterChatCommand("tsm", "ChatCommand")
	TSM:RegisterChatCommand("tradeskillmaster", "ChatCommand")
	TSM:RegisterEvent("BAG_UPDATE") -- call TSM:BAG_UPDATE whenever the user's bags change
	
	-- create / register the minimap button
	TSM.LDBIcon = LibStub("LibDataBroker-1.1", true) and LibStub("LibDBIcon-1.0", true)
	local TradeSkillMasterLauncher = LibStub("LibDataBroker-1.1", true):NewDataObject("TradeSkillMaster", {
		type = "launcher",
		icon = "Interface\\Icons\\inv_scroll_05",
		OnClick = function(_, button) -- fires when a user clicks on the minimap icon
				if button == "RightButton" then
					-- does the same thing as typing '/tsm config'
					TSM:ChatCommand("config")
				elseif button == "LeftButton" then
					-- does the same thing as typing '/tsm'
					TSM:ChatCommand("")
				end
			end,
		OnTooltipShow = function(tt) -- tooltip that shows when you hover over the minimap icon
				local cs = "|cffffffcc"
				local ce = "|r"
				tt:AddLine("TradeSkill Master v" .. TSM.version)
				tt:AddLine(string.format(L("%sLeft-Click%s to open the main window"), cs, ce))
				tt:AddLine(string.format(L("%sRight-click%s to open the options menu"), cs, ce))
				tt:AddLine(string.format(L("%sDrag%s to move this button"), cs, ce))
				tt:AddLine(string.format("%s/tsm%s for a list of slash commands", cs, ce))
			end,
		})
	TSM.LDBIcon:Register("TradeSkillMaster", TradeSkillMasterLauncher, TSM.db.profile.minimapIcon)
end

function TSM:OnDisable()
	TSM.db.global.treeStatus = TSM.GUI.TreeGroup.frame.obj.status.groups
end

-- deals with slash commands
function TSM:ChatCommand(input)
	if input == L("config") then	-- '/tsm config' opens up the main window to the 'options' page
		TSM.GUI:OpenFrame(5)
		
	elseif input == "" then	-- '/tsm' opens up the main window to the main 'enchants' page
		TSM.GUI:OpenFrame(1)
		
	elseif input == L("scan") then -- '/tsm scan' scans the AH for scrolls and materials
		if TSM.db.profile.matCostMethod == "smart" or TSM.db.profile.matCostMethod == "lowest" then
			-- run a full scan if TSM needs to scan for mats based on mat cost method setting
			TSM.Scan:RunScan("full")
		else
			-- just scans for scrolls if TSM doesn't need to scan for mats
			TSM.Scan:RunScan("scrolls")
		end
		
	elseif input == L("craft") then -- /tsm craft opens Scroll Master's craft queue
		TSM.Enchanting:OpenFrame()
		
	elseif input == "test" and SMdebug then -- for development purposes
	
	elseif input == "debug" then -- enter debugging mode - for development purposes
		if SMdebug then
			TSM:Print("Debugging turned off.")
			SMdebug = false
		else
			TSM:Print("Debugging mode turned on. Type '/tsm debug' again to cancel.")
			SMdebug = true
		end
		TSM.GameTime:Initialize()
	
	elseif input == L("help") then -- '/tsm help' opens the main window to the 'help' page
		TSM.GUI:OpenFrame(5)
		
	else -- if the command is unrecognized, print out the slash commands to help the user
        TSM:Print(L("Slash Commands") .. ":")
		print("|cffffaa00/tsm|r - " .. L("opens the main Scroll Master window to the 'Enchants' main page."))
		print("|cffffaa00/tsm " .. L("scan") .. "|r - " .. L("scans the AH for scrolls and materials to calculate profits."))
		print("|cffffaa00/tsm " .. L("craft") .. "|r - " .. L("opens Scroll Master's craft queue."))
		print("|cffffaa00/tsm " .. L("config") .. "|r - " .. L("opens the main Scroll Master window to the 'Options' page."))
		print("|cffffaa00/tsm " .. L("help") .. "|r - " .. L("opens the main Scroll Master window to the 'Help' page."))
    end
end

-- converts an itemID into the name of the item.
function TSM:GetName(sID)
	if not sID then return end
	
	if TSM.LibName and TSM.LibName.names and TSM.LibName.names[sID] then -- check to see if we have the name in LibName
		return TSM.LibName.names[sID]
	elseif TSM.LibName and TSM.LibName.matNames and TSM.LibName.matNames[sID] then
		return TSM.LibName.matNames[sID]
	elseif TSM.db.global[sID] then -- check to see if we have the name stored already in the saved DB
		return TSM.db.global[sID]
	end

	-- try to use the GetItemInfo function
	-- this will fail if the server hasn't seen the item since last restart
	local tName = select(1, GetItemInfo(sID))
	if tName then
		-- if GetItemInfo worked, store the name in the database for future use
		TSM.db.global[sID] = tName
		return tName
	end
	
	-- sad face :(
	TSM:Print("TradeSkill Master imploded on itemID " .. sID .. ". This means you have not seen this " ..
		"item since the last patch and Scroll Master doesn't have a record of it. Try to find this " ..
		"item in game and then Scroll Master again. If you continue to get this error message please " ..
		"report this to the author (include the itemID in your message).")
end

-- fires whenever a player's bags change - keeps track of materials / scrolls in bags
function TSM:BAG_UPDATE()
	TSM.db.factionrealm.alts = TSM.db.factionrealm.alts or {}
	if #(TSM.db.factionrealm.alts) == 0 then
		return TSM:UnregisterEvent("BAG_UPDATE")
	end
	
	local playerName = select(1, UnitName("Player"))
	
	-- clear the table
	TSM.db.factionrealm.inventory[playerName] = {}
	
	-- count up how many of each scroll is in the player's bags and store it in the saved variables database
	for bag=0, 4 do -- go through every bag...
		for slot=1, GetContainerNumSlots(bag) do -- and every slot
			local bagItemID = GetContainerItemID(bag, slot)
			if TSM.Data[TSM.mode].crafts[bagItemID] then
				-- we care about it so add it to the savedDB
				TSM.db.factionrealm.inventory[playerName][bagItemID] = TSM.db.factionrealm.inventory[playerName][bagItemID] or 0
				local count = select(2, GetContainerItemInfo(bag, slot))
				TSM.db.factionrealm.inventory[playerName][bagItemID] = TSM.db.factionrealm.inventory[playerName][bagItemID] + count
			end
		end
	end
end

-- converts the name (or table) of an enchant to a number
function TSM:GetGroup(spellID)
	spellID = tonumber(spellID)
	if spellID then
		local itemID = TSM.LibEnchant.itemID[spellID]
		local slot = TSM.LibEnchant.slot[itemID]
		return slot
	end
	
	return error("Invalid SpellID. Please report this error! (code " .. spellID .. ")")
end

-- returns the number of the passed itemID in bags of the user's alts
function TSM:DSGetNum(itemID)
	if not (select(4, GetAddOnInfo("DataStore_Containers")) and DataStore) then return 0 end

	local count = 0
	for characterName, character in pairs(DataStore:GetCharacters()) do
		local bagCount, bankCount = DataStore:GetContainerItemCount(character, itemID)
		if characterName ~= UnitName("Player") and TSM.db.profile.useDSBags and TSM.db.profile.DSCharacters[characterName] then
			count = count + bagCount
		end
		if TSM.db.profile.useDSBanks and TSM.db.profile.DSCharacters[characterName] then
			count = count + bankCount
		end
	end
	for guildName, guild in pairs(DataStore:GetGuilds()) do
		if TSM.db.profile.useDSGuildBanks and TSM.db.profile.DSGuilds[guildName] then
			local itemCount = DataStore:GetGuildBankItemCount(guild, itemID)
			count = count + itemCount
		end
	end
	return count
end

-- a way to get millisecond precision timing - stolen from wowwiki
-- this is only used for development and is not used by any feature of TSM
TSM.GameTime = {
	Get = function(self)
			if (self.LastMinuteTimer == nil) then
				local h,m = GetGameTime()
				return h,m,0
			end
			local s = GetTime() - self.LastMinuteTimer
			if(s>59.999) then
				s=59.999
			end
			return self.LastGameHour, self.LastGameMinute, s
		end,

	OnUpdate = function(self)
			local h,m = GetGameTime()
			if(self.LastGameMinute == nil) then
				self.LastGameHour = h
				self.LastGameMinute = m
				return;
			end
			if(self.LastGameMinute == m) then
				return;
			end
			self.LastGameHour = h
			self.LastGameMinute = m
			self.LastMinuteTimer = GetTime()
			if not self.notify then
				self.notify = true
				print("Timer Ready")
			end
		end,

	Initialize = function(self)
			self.Frame = CreateFrame("Frame");
			self.Frame:SetScript("OnUpdate", function() self:OnUpdate() end)
		end
}