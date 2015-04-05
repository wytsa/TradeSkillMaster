-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This is the main TSM file that holds the majority of the APIs that modules will use.

-- register this file with Ace libraries
local TSM = select(2, ...)
TSM = LibStub("AceAddon-3.0"):NewAddon(TSM, "TradeSkillMaster", "AceEvent-3.0", "AceConsole-3.0", "AceHook-3.0")
TSM.moduleObjects = {}
TSM.moduleNames = {}
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local private = {}
TSMAPI = {Auction={}, GUI={}, Design={}, Debug={}}

TSM.designDefaults = {
	frameColors = {
		frameBG = { backdrop = { 24, 24, 24, .93 }, border = { 30, 30, 30, 1 } },
		frame = { backdrop = { 24, 24, 24, 1 }, border = { 255, 255, 255, 0.03 } },
		content = { backdrop = { 42, 42, 42, 1 }, border = { 0, 0, 0, 0 } },
	},
	textColors = {
		iconRegion = { enabled = { 249, 255, 247, 1 } },
		text = { enabled = { 255, 254, 250, 1 }, disabled = { 147, 151, 139, 1 } },
		label = { enabled = { 216, 225, 211, 1 }, disabled = { 150, 148, 140, 1 } },
		title = { enabled = { 132, 219, 9, 1 } },
		link = { enabled = { 49, 56, 133, 1 } },
	},
	inlineColors = {
		link = { 153, 255, 255, 1 },
		link2 = { 153, 255, 255, 1 },
		category = { 36, 106, 36, 1 },
		category2 = { 85, 180, 8, 1 },
		tooltip = { 130, 130, 250, 1 },
		advanced = { 255, 30, 0, 1 },
	},
	edgeSize = 1.5,
	fonts = {
		content = "Fonts\\ARIALN.TTF",
		bold = "Interface\\Addons\\TradeSkillMaster\\Media\\DroidSans-Bold.ttf",
	},
	fontSizes = {
		normal = 15,
		medium = 13,
		small = 12,
	},
}

local savedDBDefaults = {
	global = {
		vendorItems = {},
		ignoreRandomEnchants = nil,
		globalOperations = false,
		operations = {},
		customPriceSources = {},
		bankUITab = "Warehousing",
		chatFrame = "",
		infoMessage = 1000,
		bankUIframeScale = 1,
		frameStatus = {},
		customPriceTooltips = {},
		debugLogBuffers = {},
		vendorBuyEnabled = true,
		auctionSaleEnabled = true,
		auctionSaleSound = "TSM_NO_SOUND",
		auctionBuyEnabled = true,
		tsmItemTweetEnabled = true,
	},
	profile = {
		minimapIcon = {
			-- minimap icon position and visibility
			hide = false,
			minimapPos = 220,
			radius = 80,
		},
		auctionFrameMovable = true,
		auctionFrameScale = 1,
		protectAH = false,
		openAllBags = true,
		auctionResultRows = 20,
		groups = {},
		items = {},
		operations = {},
		groupTreeStatus = {},
		customPriceSourceTreeStatus = {},
		pricePerUnit = true,
		postDuration = 3,
		isBankui = true,
		defaultAuctionTab = "Shopping",
		gotoNewGroup = true,
		gotoNewCustomPriceSource = true,
		defaultGroupTab = 2,
		moveImportedItems = false,
		importParentOnly = false,
		keepInParent = true,
		savedThemes = {},
		groupTreeCollapsedStatus = {},
		groupTreeSelectedGroupStatus = {},
		exportSubGroups = false,
		groupFilterPrice = "dbmarket",
		inventoryViewerPriceSource = "dbmarket",
		tooltipOptions = {},
		-- tooltip options
		tooltipPriceFormat = "text",
		embeddedTooltip = false,
		tooltipShowModifier = "none",
		inventoryTooltipFormat = "full",
		groupOperationTooltip = true,
		vendorBuyTooltip = true,
		vendorSellTooltip = true,
		destroyValueSource = "DBMarket",
		detailedDestroyTooltip = false,
		millTooltip = true,
		prospectTooltip = true,
		deTooltip = true,
		operationTooltips = {},
	},
	factionrealm = {
		accountKey = nil,
		characters = {},
		characterGuilds = {},
		ignoreGuilds = {},
		syncAccounts = {},
		syncMetadata = {},
		bankUIBankFramePosition = {100, 300},
		bankUIGBankFramePosition = {100, 300},
		inventory = {},
		pendingMail = {},
		guildVaults = {},
	},
	char = {
		auctionPrices = {},
		auctionMessages = {},
	},
}



-- ============================================================================
-- Module Functions
-- ============================================================================

function TSM:OnInitialize()
	TSM:StartDelayThread()
	
	TSM.moduleObjects = nil
	TSM.moduleNames = nil
	
	-- load the savedDB into TSM.db
	TSM.db = LibStub:GetLibrary("AceDB-3.0"):New("TradeSkillMasterDB", savedDBDefaults, true)
	TSM.db:RegisterCallback("OnProfileChanged", function() TSM:UpdateModuleProfiles() end)
	TSM.db:RegisterCallback("OnProfileCopied", function() TSM:UpdateModuleProfiles() end)
	TSM.db:RegisterCallback("OnProfileReset", function() TSM:UpdateModuleProfiles(true) end)
	TSM.db:RegisterCallback("OnDatabaseShutdown", TSM.ModuleOnDatabaseShutdown)
	if TSM.db.global.globalOperations then
		TSM.operations = TSM.db.global.operations
	else
		TSM.operations = TSM.db.profile.operations
	end
	
	-- TSM3 updates
	TSM.db.realm.numPagesCache = nil
	
	TSM:RegisterEvent("BLACK_MARKET_ITEM_UPDATE", private.ScanBMAH)
	
	-- Prepare the TradeSkillMasterAppDB database
	-- We're not using AceDB here on purpose due to bugs in AceDB, but are emulating the parts of it that we need.
	local json = TradeSkillMasterAppDB
	TradeSkillMasterAppDB = nil
	if type(json) == "table" then
		json = table.concat(json)
	end
	if type(json) == "string" then
		json = gsub(json, "%[", "{")
		json = gsub(json, "%]", "}")
		json = gsub(json, "\"([a-zA-Z]+)\":", "%1=")
		json = gsub(json, "\"([^\"]+)\":", "[\"%1\"]=")
		local func, err = loadstring("TSM_APP_DATA_TMP = " .. json .. "")
		if func then
			func()
			TradeSkillMasterAppDB = TSM_APP_DATA_TMP
			TSM_APP_DATA_TMP = nil
		end
	end
	TradeSkillMasterAppDB = TradeSkillMasterAppDB or {realm={}, profiles={}, global={}}
	TradeSkillMasterAppDB.version = max(TradeSkillMasterAppDB.version or 0, 7)
	TradeSkillMasterAppDB.region = GetCVar("portal") == "public-test" and "PTR" or GetCVar("portal")
	local realmKey = GetRealmName()
	local profileKey = TSM.db:GetCurrentProfile()
	TradeSkillMasterAppDB.factionrealm = nil
	TradeSkillMasterAppDB.global = TradeSkillMasterAppDB.global or {}
	TradeSkillMasterAppDB.realm = TradeSkillMasterAppDB.realm or {}
	TradeSkillMasterAppDB.realm[realmKey] = TradeSkillMasterAppDB.realm[realmKey] or {}
	TradeSkillMasterAppDB.profiles[profileKey] = TradeSkillMasterAppDB.profiles[profileKey] or {}
	TSM.appDB = {}
	TSM.appDB.realm = TradeSkillMasterAppDB.realm[realmKey]
	TSM.appDB.profile = TradeSkillMasterAppDB.profiles[profileKey]
	TSM.appDB.profile.groupTest = nil
	TSM.appDB.global = TradeSkillMasterAppDB.global
	TSM.appDB.keys = {profile=profileKey, realm=realmKey}

	for name, module in pairs(TSM.modules) do
		TSM[name] = module
	end

	-- TSM core must be registered just like the modules
	TSM:RegisterModule()

	-- create account key for multi-account syncing if necessary
	TSM.db.factionrealm.accountKey = TSM.db.factionrealm.accountKey or (GetRealmName() .. random(time()))
	
	-- add this character to the list of characters on this realm
	TSMAPI.Sync:Mirror(TSM.db.factionrealm.characters, "TSM_CHARACTERS")
	TSMAPI.Sync:SetKeyValue(TSM.db.factionrealm.characters, UnitName("player"), select(2, UnitClass("player")))

	if not TSM.db.profile.design then
		TSM:LoadDefaultDesign()
	end
	TSM:SetDesignDefaults(TSM.designDefaults, TSM.db.profile.design)

	-- create / register the minimap button
	TSM.LDBIcon = LibStub("LibDataBroker-1.1", true) and LibStub("LibDBIcon-1.0", true)
	local TradeSkillMasterLauncher = LibStub("LibDataBroker-1.1", true):NewDataObject("TradeSkillMasterMinimapIcon", {
		icon = "Interface\\Addons\\TradeSkillMaster\\Media\\TSM_Icon",
		OnClick = function(_, button) -- fires when a user clicks on the minimap icon
			if button == "LeftButton" then
				-- does the same thing as typing '/tsm'
				TSM.Modules:ChatCommand("")
			end
		end,
		OnTooltipShow = function(tt) -- tooltip that shows when you hover over the minimap icon
			local cs = "|cffffffcc"
			local ce = "|r"
			tt:AddLine("TradeSkillMaster " .. TSM._version)
			tt:AddLine(format(L["%sLeft-Click%s to open the main window"], cs, ce))
			tt:AddLine(format(L["%sDrag%s to move this button"], cs, ce))
		end,
	})
	TSM.LDBIcon:Register("TradeSkillMaster", TradeSkillMasterLauncher, TSM.db.profile.minimapIcon)
	local TradeSkillMasterLauncher2 = LibStub("LibDataBroker-1.1", true):NewDataObject("TradeSkillMaster", {
		type = "launcher",
		icon = "Interface\\Addons\\TradeSkillMaster\\Media\\TSM_Icon2",
		OnClick = function(_, button) -- fires when a user clicks on the minimap icon
			if button == "LeftButton" then
				-- does the same thing as typing '/tsm'
				TSM.Modules:ChatCommand("")
			end
		end,
		OnTooltipShow = function(tt) -- tooltip that shows when you hover over the minimap icon
			local cs = "|cffffffcc"
			local ce = "|r"
			tt:AddLine("TradeSkillMaster " .. TSM._version)
			tt:AddLine(format(L["%sLeft-Click%s to open the main window"], cs, ce))
			tt:AddLine(format(L["%sDrag%s to move this button"], cs, ce))
		end,
	})

	-- create the main TSM frame
	TSM:CreateMainFrame()

	-- fix any items with spaces in them
	for itemString, groupPath in pairs(TSM.db.profile.items) do
		if strfind(itemString, " ") then
			local newItemString = gsub(itemString, " ", "")
			TSM.db.profile.items[newItemString] = groupPath
			TSM.db.profile.items[itemString] = nil
		end
	end
	
	if TSM.db.profile.deValueSource then
		TSM.db.profile.destroyValueSource = TSM.db.profile.deValueSource
		TSM.db.profile.deValueSource = nil
	end
	
	-- Cache battle pet names
	for i=1, C_PetJournal.GetNumPets() do C_PetJournal.GetPetInfoByIndex(i) end
	-- force a garbage collection
	collectgarbage()
	
	TSMAPI.Sync:RegisterRPC("CreateGroupWithItems", TSM.CreateGroupWithItems)
end

function TSM:RegisterModule()
	TSM.icons = {
		{ side = "options", desc = L["TSM Status / Options"], callback = "LoadOptions", icon = "Interface\\Icons\\Achievement_Quests_Completed_04" },
		{ side = "options", desc = L["Groups"], callback = "LoadGroupOptions", slashCommand = "groups", icon = "Interface\\Icons\\INV_DataCrystal08" },
		{ side = "options", desc = L["Module Operations / Options"], slashCommand = "operations", callback = "LoadOperationOptions", icon = "Interface\\Icons\\INV_Misc_Enggizmos_33" },
		{ side = "options", desc = L["Tooltip Options"], slashCommand = "tooltips", callback = "LoadTooltipOptions", icon = "Interface\\Icons\\PET_Type_Mechanical" },
		{ side = "module", desc = "TSM Features", slashCommand = "features", callback = "FeaturesGUI:LoadGUI", icon = "Interface\\Icons\\Achievement_Faction_GoldenLotus" },
	}

	TSM.priceSources = {}
	-- Auctioneer
	if select(4, GetAddOnInfo("Auc-Advanced")) and AucAdvanced then
		if AucAdvanced.Modules.Util.Appraiser and AucAdvanced.Modules.Util.Appraiser.GetPrice then
			tinsert(TSM.priceSources, { key = "AucAppraiser", label = L["Auctioneer - Appraiser"], callback = AucAdvanced.Modules.Util.Appraiser.GetPrice })
		end
		if AucAdvanced.Modules.Util.SimpleAuction and AucAdvanced.Modules.Util.SimpleAuction.Private.GetItems then
			tinsert(TSM.priceSources, { key = "AucMinBuyout", label = L["Auctioneer - Minimum Buyout"], callback = function(itemLink) return select(6, AucAdvanced.Modules.Util.SimpleAuction.Private.GetItems(itemLink)) end })
		end
		if AucAdvanced.API.GetMarketValue then
			tinsert(TSM.priceSources, { key = "AucMarket", label = L["Auctioneer - Market Value"], callback = AucAdvanced.API.GetMarketValue })
		end
	end
	
	-- Auctionator
	if select(4, GetAddOnInfo("Auctionator")) and Atr_GetAuctionBuyout then
		tinsert(TSM.priceSources, { key = "AtrValue", label = L["Auctionator - Auction Value"], callback = Atr_GetAuctionBuyout })
	end
	
	-- TheUndermineJournal
	if select(4, GetAddOnInfo("TheUndermineJournal")) and TUJMarketInfo then
		tinsert(TSM.priceSources, { key = "TUJRecent", label = "TUJ 3-Day Price", callback = function(itemLink) return (TUJMarketInfo(TSMAPI:GetItemID(itemLink)) or {}).recent end })
		tinsert(TSM.priceSources, { key = "TUJMarket", label = "TUJ 14-Day Price", callback = function(itemLink) return (TUJMarketInfo(TSMAPI:GetItemID(itemLink)) or {}).market end })
		tinsert(TSM.priceSources, { key = "TUJGlobalMean", label = L["TUJ Global Mean"], callback = function(itemLink) return (TUJMarketInfo(TSMAPI:GetItemID(itemLink)) or {}).globalMean end })
		tinsert(TSM.priceSources, { key = "TUJGlobalMedian", label = L["TUJ Global Median"], callback = function(itemLink) return (TUJMarketInfo(TSMAPI:GetItemID(itemLink)) or {}).globalMedian end })
	end
	
	-- Vendor Buy Price
	tinsert(TSM.priceSources, { key = "VendorBuy", label = L["Buy from Vendor"], callback = function(itemString) return TSMAPI:GetVendorCost(itemString) end, takeItemString = true })

	-- Vendor Buy Price
	tinsert(TSM.priceSources, { key = "VendorSell", label = L["Sell to Vendor"], callback = function(itemString) local sell = select(11, TSMAPI:GetSafeItemInfo(itemString)) return (sell or 0) > 0 and sell or nil end, takeItemString = true })

	-- Disenchant Value
	tinsert(TSM.priceSources, { key = "Destroy", label = "Destroy Value", callback = function(itemString) return TSMAPI.Conversions:GetValue(itemString, TSM.db.profile.destroyValueSource) or TSMAPI.Disenchant:GetValue(itemString, TSM.db.profile.destroyValueSource) end, takeItemString = true })

	TSM.slashCommands = {
		{ key = "version", label = L["Prints out the version numbers of all installed modules"], callback = "PrintVersion" },
		{ key = "freset", label = L["Resets the position, scale, and size of all applicable TSM and module frames."], callback = "ResetFrames" },
		{ key = "bankui", label = L["Toggles the bankui"], callback = "toggleBankUI" },
		{ key = "sources", label = L["Prints out the available price sources for use in custom price boxes."], callback = "PrintPriceSources" },
		{ key = "price", label = L["Allows for testing of custom prices."], callback = "TestPriceSource" },
		{ key = "profile", label = "Changes to the specified profile (i.e. '/tsm profile Default' changes to the 'Default' profile)", callback = "ChangeProfile" },
		{ key = "debug", label = "Some debug commands for TSM.", callback = "Debug:SlashCommandHandler", hidden = true },
	}

	TSMAPI:NewModule(TSM)
end

function TSM:OnTSMDBShutdown()
	local function GetOperationPrice(module, settingKey, itemString)
		local operations = TSMAPI:GetItemOperation(itemString, module)
		local operation = operations and operations[1] ~= "" and operations[1] and TSM.operations[module][operations[1]]
		if operation and operation[settingKey] then
			if type(operation[settingKey]) == "number" and operation[settingKey] > 0 then
				return operation[settingKey]
			elseif type(operation[settingKey]) == "string" then
				local value = TSMAPI:GetCustomPriceValue(operation[settingKey], itemString)
				if not value or value <= 0 then return end
				return value
			else
				return
			end
		end
	end

	-- save group info into TSM.appDB
	for profile in TSMAPI:GetTSMProfileIterator() do
		local profileGroupData = {}
		for itemString, groupPath in pairs(TSM.db.profile.items) do
			if strfind(itemString, "item") then
				local shortItemString = gsub(gsub(itemString, "item:", ""), ":0:0:0:0:0:", ":")
				local itemPrices = {}
				itemPrices.sm = GetOperationPrice("Shopping", "maxPrice", itemString)
				itemPrices.am = GetOperationPrice("Auctioning", "minPrice", itemString)
				itemPrices.an = GetOperationPrice("Auctioning", "normalPrice", itemString)
				itemPrices.ax = GetOperationPrice("Auctioning", "maxPrice", itemString)
				if next(itemPrices) then
					itemPrices.gr = groupPath
					local itemID, rand = (":"):split(shortItemString)
					if rand == "0" then
						shortItemString = itemID
					end
					profileGroupData[shortItemString] = itemPrices
				end
			end
		end
		if next(profileGroupData) then
			TSM.appDB.profile.groupInfo = profileGroupData
			TSM.appDB.profile.lastUpdate = time()
		end
	end
end



-- ============================================================================
-- TSM Tooltip Handling
-- ============================================================================

function TSM:LoadTooltip(itemString, quantity, moneyCoins, lines)
	local numStartingLines = #lines
	
	-- add group / operation info
	if TSM.db.profile.groupOperationTooltip then
		local isBaseItem
		local path = TSM.db.profile.items[itemString]
		if not path then
			path = TSM.db.profile.items[TSMAPI:GetBaseItemString(itemString)]
			isBaseItem = true
		end
		if path and TSM.db.profile.groups[path] then
			local leftText = nil
			if isBaseItem then
				leftText = L["Group(Base Item):"]
			else
				leftText = L["Group:"]
			end
			tinsert(lines, {left="  "..leftText, right = "|cffffffff"..TSMAPI:FormatGroupPath(path).."|r"})
			local modules = {}
			for module, operations in pairs(TSM.db.profile.groups[path]) do
				if operations[1] and operations[1] ~= "" and TSM.db.profile.operationTooltips[module] then
					tinsert(modules, {module=module, operations=table.concat(operations, ", ")})
				end
			end
			sort(modules, function(a, b) return a.module < b.module end)
			for _, info in ipairs(modules) do
				tinsert(lines, {left="  "..format(L["%s operation(s):"], info.module), right="|cffffffff"..info.operations.."|r"})
			end
		end
	end

	-- add disenchant value info
	if TSM.db.profile.deTooltip then
		local value = TSMAPI.Disenchant:GetValue(itemString, TSM.db.profile.destroyValueSource)
		if value then
			local leftText = "  "..(quantity > 1 and format(L["Disenchant Value x%s:"], quantity) or L["Disenchant Value:"])
			tinsert(lines, {left=leftText, right=TSMAPI:FormatMoney(moneyCoins, value*quantity, "|cffffffff", true)})
			if TSM.db.profile.detailedDestroyTooltip then
				TSM:GetDetailedDisenchantTooltip(itemString, lines, moneyCoins)
			end
		end
	end
	
	-- add mill value info
	if TSM.db.profile.millTooltip then
		local value = TSMAPI.Conversions:GetValue(itemString, TSM.db.profile.destroyValueSource, "mill")
		if value then
			local leftText = "  "..(quantity > 1 and format(L["Mill Value x%s:"], quantity) or L["Mill Value:"])
			tinsert(lines, {left=leftText, right=TSMAPI:FormatMoney(moneyCoins, value*quantity, "|cffffffff", true)})
			
			if TSM.db.profile.detailedDestroyTooltip then
				for _, targetItem in ipairs(TSMAPI.Conversions:GetTargetItemsByMethod("mill")) do
					local herbs = TSMAPI.Conversions:GetData(targetItem)
					if herbs[itemString] then
						local value = (TSMAPI:GetCustomPriceValue(TSM.db.profile.destroyValueSource, targetItem) or 0) * herbs[itemString].rate
						local name, _, matQuality = TSMAPI:GetSafeItemInfo(targetItem)
						if matQuality then
							local colorName = format("|c%s%s%s%s|r",select(4,GetItemQualityColor(matQuality)),name, " x ", herbs[itemString].rate * quantity)
							if value > 0 then
								tinsert(lines, {left="    "..colorName, right=TSMAPI:FormatMoney(moneyCoins, value*quantity, "|cffffffff", true)})
							end
						end
					end
				end
			end
		end
	end
	
	-- add prospect value info
	if TSM.db.profile.prospectTooltip then
		local value = TSMAPI.Conversions:GetValue(itemString, TSM.db.profile.destroyValueSource, "prospect")
		if value then
			local leftText = "  "..(quantity > 1 and format(L["Prospect Value x%s:"], quantity) or L["Prospect Value:"])
			tinsert(lines, {left=leftText, right=TSMAPI:FormatMoney(moneyCoins, value*quantity, "|cffffffff", true)})
			
			if TSM.db.profile.detailedDestroyTooltip then
				for _, targetItem in ipairs(TSMAPI.Conversions:GetTargetItemsByMethod("prospect")) do
					local gems = TSMAPI.Conversions:GetData(targetItem)
					if gems[itemString] then
						local value = (TSMAPI:GetCustomPriceValue(TSM.db.profile.destroyValueSource, targetItem) or 0) * gems[itemString].rate
						local name, _, matQuality = TSMAPI:GetSafeItemInfo(targetItem)
						if matQuality then
							local colorName = format("|c%s%s%s%s|r",select(4,GetItemQualityColor(matQuality)),name, " x ", gems[itemString].rate * quantity)
							if value > 0 then
								tinsert(lines, {left="    "..colorName, right=TSMAPI:FormatMoney(moneyCoins, value*quantity, "|cffffffff", true)})
							end
						end
					end
				end
			end
		end
	end

	-- add vendor buy price
	if TSM.db.profile.vendorBuyTooltip then
		local value = TSMAPI:GetVendorCost(itemString) or 0
		if value > 0 then
			local leftText = "  "..(quantity > 1 and format(L["Vendor Buy Price x%s:"], quantity) or L["Vendor Buy Price:"])
			tinsert(lines, {left=leftText, right=TSMAPI:FormatMoney(moneyCoins, value*quantity, "|cffffffff", true)})
		end
	end

	-- add vendor sell price
	if TSM.db.profile.vendorSellTooltip then
		local value = select(11, TSMAPI:GetSafeItemInfo(itemString)) or 0
		if value > 0 then
			local leftText = "  "..(quantity > 1 and format(L["Vendor Sell Price x%s:"], quantity) or L["Vendor Sell Price:"])
			tinsert(lines, {left=leftText, right=TSMAPI:FormatMoney(moneyCoins, value*quantity, "|cffffffff", true)})
		end
	end
	
	-- add custom price sources
	for name, method in pairs(TSM.db.global.customPriceSources) do
		if TSM.db.global.customPriceTooltips[name] then
			local price = TSMAPI:GetCustomPriceValue(name, itemString) or 0
			if price > 0 then
				tinsert(lines, {left="  "..L["Custom Price Source"].." '"..name.."':", right=TSMAPI:FormatMoney(moneyCoins, price*quantity, "|cffffffff", true)})
			end
		end
	end
	
	-- add inventory information
	if TSM.db.profile.inventoryTooltipFormat == "full" then
		local numLines = #lines
		local totalNum = 0
		local playerData, guildData = TSM:GetItemInventoryData(itemString)
		for playerName, data in pairs(playerData) do
			local playerTotal = data.bag + data.bank + data.reagentBank + data.auction + data.mail
			if playerTotal > 0 then
				totalNum = totalNum + playerTotal
				local classColor = type(TSM.db.factionrealm.characters[playerName]) == "string" and RAID_CLASS_COLORS[TSM.db.factionrealm.characters[playerName]]
				local rightText = format("%s (%s bags, %s bank, %s AH, %s mail)", "|cffffffff"..playerTotal.."|r", "|cffffffff"..data.bag.."|r", "|cffffffff"..(data.bank+data.reagentBank).."|r", "|cffffffff"..data.auction.."|r", "|cffffffff"..data.mail.."|r")
				if classColor then
					tinsert(lines, {left="    |c"..classColor.colorStr..playerName.."|r:", right=rightText})
				else
					tinsert(lines, {left="    "..playerName..":", right=rightText})
				end
			end
		end
		for guildName, guildQuantity in pairs(guildData) do
			if guildQuantity > 0 then
				totalNum = totalNum + guildQuantity
				tinsert(lines, {left="    "..guildName..":", right=format("%s in guild vault", "|cffffffff"..guildQuantity.."|r")})
			end
		end
		if #lines > numLines then
			tinsert(lines, numLines+1, {left="  ".."Inventory:", right=format("%s total", "|cffffffff"..totalNum.."|r")})
		end
	elseif TSM.db.profile.inventoryTooltipFormat == "simple" then
		local numLines = #lines
		local totalPlayer, totalAlt, totalGuild, totalAuction = 0, 0, 0, 0
		local playerData, guildData = TSM:GetItemInventoryData(itemString)
		for playerName, data in pairs(playerData) do
			if playerName == UnitName("player") then
				totalPlayer = totalPlayer + data.bag + data.bank + data.reagentBank + data.mail
				totalAuction = totalAuction + data.auction
			else
				totalAlt = totalAlt + data.bag + data.bank + data.reagentBank + data.mail
				totalAuction = totalAuction + data.auction
			end
		end
		for guildName, guildQuantity in pairs(guildData) do
			totalGuild = totalGuild + guildQuantity
		end
		local totalNum = totalPlayer + totalAlt + totalGuild + totalAuction
		if totalNum > 0 then
			local rightText = format("%s (%s player, %s alts, %s guild, %s AH)", "|cffffffff"..totalNum.."|r", "|cffffffff"..totalPlayer.."|r", "|cffffffff"..totalAlt.."|r", "|cffffffff"..totalGuild.."|r", "|cffffffff"..totalAuction.."|r")
			tinsert(lines, numLines+1, {left="  ".."Inventory:", right=rightText})
		end
	end

	-- add heading
	if #lines > numStartingLines then
		tinsert(lines, numStartingLines+1, "|cffffff00" .. L["TradeSkillMaster Info:"].."|r")
	end
end



-- ============================================================================
-- General Slash-Command Handlers
-- ============================================================================

function TSM:PrintPriceSources()
	TSM:Printf("Below are your currently available price sources organized by module. The %skey|r is what you would type into a custom price box.", TSMAPI.Design:GetInlineColor("link"))
	local lines = {}
	local modulesList = {}
	local sources, modules = TSMAPI:GetPriceSources()
	for key, label in pairs(sources) do
		local module = modules[key]
		if not lines[module] then
			lines[module] = {}
			tinsert(modulesList, module)
		end
		tinsert(lines[module], {key=key, label=label})
	end
	for _, moduleLines in pairs(lines) do
		sort(moduleLines, function(a, b) return strlower(a.key) < strlower(b.key) end)
	end
	local chatFrame = TSMAPI:GetChatFrame()
	sort(modulesList, function(a, b) return strlower(a) < strlower(b) end)
	for _, module in ipairs(modulesList) do
		chatFrame:AddMessage("|cffffff00"..module..":|r")
		for _, info in ipairs(lines[module]) do
			chatFrame:AddMessage(format("  %s (%s)", TSMAPI.Design:GetInlineColor("link")..info.key.."|r", info.label))
		end
	end
end

function TSM:TestPriceSource(price)
	local link = select(3, strfind(price, "(\124c.+\124r)"))
	if not link then return TSM:Print(L["Usage: /tsm price <ItemLink> <Price String>"]) end
	price = gsub(price, TSMAPI:StrEscape(link), ""):trim()
	if price == "" then return TSM:Print(L["Usage: /tsm price <ItemLink> <Price String>"]) end
	local isValid, err = TSMAPI:ValidateCustomPrice(price)
	if not isValid then
		TSM:Printf(L["%s is not a valid custom price and gave the following error: %s"], TSMAPI.Design:GetInlineColor("link") .. price .. "|r", err)
	else
		local itemString = TSMAPI:GetItemString(link)
		if not itemString then return TSM:Printf(L["%s is a valid custom price but %s is an invalid item."], TSMAPI.Design:GetInlineColor("link") .. price .. "|r", link) end
		local value = TSMAPI:GetCustomPriceValue(price, itemString)
		if not value then return TSM:Printf(L["%s is a valid custom price but did not give a value for %s."], TSMAPI.Design:GetInlineColor("link") .. price .. "|r", link) end
		TSM:Printf(L["A custom price of %s for %s evaluates to %s."], TSMAPI.Design:GetInlineColor("link") .. price .. "|r", link, TSMAPI:FormatTextMoney(value))
	end
end

function TSM:PrintVersion()
	TSM:Print(L["TSM Version Info:"])
	local chatFrame = TSMAPI:GetChatFrame()
	local unofficialModules = {}
	for _, module in ipairs(TSM.Modules:GetInfo()) do
		if module.isOfficial then
			chatFrame:AddMessage(module.name.." |cff99ffff"..module.version.."|r")
		else
			tinsert(unofficialModules, module)
		end
	end
	for _, module in ipairs(unofficialModules) do
		chatFrame:AddMessage(module.name.." |cff99ffff"..module.version.."|r |cffff0000[Unofficial Module]|r")
	end
end

function TSM:ChangeProfile(targetProfile)
	targetProfile = targetProfile:trim()
	local profiles = TSM.db:GetProfiles()
	if targetProfile == "" then
		TSM:Printf("No profile specified. Possible profiles: \"%s\"", table.concat(profiles, "\", \""))
	else
		for _, profile in ipairs(profiles) do
			if profile == targetProfile then
				if profile ~= TSM.db:GetCurrentProfile() then
					TSM.db:SetProfile(profile)
				end
				TSM:Printf("Profile changed to \"%s\".", profile)
				return
			end
		end
		TSM:Printf("Could not find profile \"%s\". Possible profiles: \"%s\"", targetProfile, table.concat(profiles, "\", \""))
	end
end



-- ============================================================================
-- Private Helper Functions
-- ============================================================================

function private.ScanBMAH()
	TSM.appDB.realm.bmah = nil
	local items = {}
	for i=1, C_BlackMarket.GetNumItems() do
		local quantity, minBid, minIncr, currBid, numBids, timeLeft, itemLink, bmId = TSMAPI:Select({3, 9, 10, 11, 13, 14, 15, 16}, C_BlackMarket.GetItemInfoByIndex(i))
		local itemID = TSMAPI:GetItemID(TSMAPI:GetItemString(itemLink))
		if itemID then
			minBid = floor(minBid/COPPER_PER_GOLD)
			minIncr = floor(minIncr/COPPER_PER_GOLD)
			currBid = floor(currBid/COPPER_PER_GOLD)
			tinsert(items, {bmId, itemID, quantity, timeLeft, minBid, minIncr, currBid, numBids, time()})
		end
	end
	TSM.appDB.realm.blackMarket = items
end




-- ============================================================================
-- General TSMAPI Functions
-- ============================================================================

function TSMAPI:GetTSMProfileIterator()
	local originalProfile = TSM.db:GetCurrentProfile()
	local profiles = CopyTable(TSM.db:GetProfiles())

	return function()
		local profile = tremove(profiles)
		if profile then
			TSM.db:SetProfile(profile)
			return profile
		end
		TSM.db:SetProfile(originalProfile)
	end
end

function TSMAPI:GetChatFrame()
	local chatFrame = DEFAULT_CHAT_FRAME
	for i = 1, NUM_CHAT_WINDOWS do
		local name = strlower(GetChatWindowInfo(i) or "")
		if name ~= "" and name == strlower(TSM.db.global.chatFrame) then
			chatFrame = _G["ChatFrame" .. i]
			break
		end
	end
	return chatFrame
end