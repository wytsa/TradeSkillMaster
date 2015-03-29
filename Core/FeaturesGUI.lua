-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file contains all the code for the new tooltip options

local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local FeaturesGUI = TSM:NewModule("FeaturesGUI")
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries
local private = {inventoryFilters={characters={}, guilds={}, name="", group=nil}}


function FeaturesGUI:LoadGUI(parent)
	local tabGroup = AceGUI:Create("TSMTabGroup")
	tabGroup:SetLayout("Fill")
	tabGroup:SetTabs({{text="Misc. Features", value=1}, {text="Inventory Viewer", value=2}})
	tabGroup:SetCallback("OnGroupSelected", function(_, _, value)
		tabGroup:ReleaseChildren()
		if value == 1 then
			private:LoadMiscFeatures(tabGroup)
		elseif value == 2 then
			private:LoadInventoryViewer(tabGroup)
		end
	end)
	parent:AddChild(tabGroup)
	tabGroup:SelectTab(1)
end

function private:LoadMiscFeatures(container)
	local page = {
		{
			type = "ScrollFrame",
			layout = "list",
			children = {
				{
					type = "InlineGroup",
					layout = "Flow",
					title = "Auction Buys",
					children = {
						{
							type = "Label",
							text = "The auction buys feature will change the 'You have won an auction of XXX' text into something more useful which contains the link, stack size, and price of the item you bought.",
							relativeWidth = 1,
						},
						{
							type = "HeadingLine"
						},
						{
							type = "CheckBox",
							label = "Enable Auction Buys Feature",
							relativeWidth = 1,
							settingInfo = {TSM.db.global, "auctionBuyEnabled"},
							callback = TSM.Features.ReloadStatus,
						},
					},
				},
				{
					type = "Spacer"
				},
				{
					type = "InlineGroup",
					layout = "Flow",
					title = "Auction Sales",
					children = {
						{
							type = "Label",
							text = "The auction sales feature will change the 'A buyer has been found for your auction of XXX' text into something more useful which contains a link to the item and, if possible, the amount the auction sold for.",
							relativeWidth = 1,
						},
						{
							type = "HeadingLine"
						},
						{
							type = "CheckBox",
							label = "Enable Auction Sales Feature",
							relativeWidth = 1,
							settingInfo = {TSM.db.global, "auctionSaleEnabled"},
							callback = TSM.Features.ReloadStatus,
						},
						{
							type = "Dropdown",
							label = "Enable Sound",
							relativeWidth = 0.5,
							list = TSMAPI:GetSounds(),
							settingInfo = {TSM.db.global, "auctionSaleSound"},
							tooltip = "Play the selected sound when one of your auctions sells.",
						},
						{
							type = "Button",
							text = "Test Selected Sound",
							relativeWidth = 0.49,
							callback = function() TSMAPI:DoPlaySound(TSM.db.global.auctionSaleSound) end,
						},
					},
				},
				{
					type = "Spacer"
				},
				{
					type = "InlineGroup",
					layout = "Flow",
					title = "Vendor Buying",
					children = {
						{
							type = "Label",
							text = "The vendor buying feature will replace the default frame that is shown when you shift-right-click on a vendor item for purchasing with a small frame that allows you to buy more than one stacks worth at a time.",
							relativeWidth = 1,
						},
						{
							type = "HeadingLine"
						},
						{
							type = "CheckBox",
							label = "Enable Vendor Buying Feature",
							relativeWidth = 1,
							settingInfo = {TSM.db.global, "vendorBuyEnabled"},
							callback = TSM.Features.ReloadStatus,
						},
					},
				},
				{
					type = "InlineGroup",
					layout = "Flow",
					title = "Twitter Integration",
					children = {
						{
							type = "Label",
							text = "If you have WoW's Twitter integration setup, TSM will add a share link to its enhanced auction sales / purchaes messages (enabled above) as well as replace the URL in item tweets with a TSM link.",
							relativeWidth = 1,
						},
						{
							type = "HeadingLine"
						},
						{
							type = "CheckBox",
							label = "Enable Tweet Enhancement (Only Works if WoW Twitter Integration is Setup)",
							relativeWidth = 1,
							disabled = not C_Social.IsSocialEnabled(),
							settingInfo = {TSM.db.global, "tsmItemTweetEnabled"},
							callback = TSM.Features.ReloadStatus,
						},
					},
				},
			},
		},
	}
	TSMAPI:BuildPage(container, page)
end

function private:LoadInventoryViewer(container)
	local playerList, guildList = {}, {}
	for name in pairs(TSMAPI:GetCharacters()) do
		playerList[name] = name
		private.inventoryFilters.characters[name] = true
	end
	for name in pairs(TSMAPI:GetGuilds()) do
		guildList[name] = name
		private.inventoryFilters.guilds[name] = true
	end
	private.inventoryFilters.group = nil
	
	local stCols = {
		{
			name = "Item Name",
			width = 0.35,
		},
		{
			name = "Bags",
			width = 0.08,
		},
		{
			name = "Bank",
			width = 0.08,
		},
		{
			name = "Mail",
			width = 0.08,
		},
		{
			name = "GVault",
			width = 0.08,
		},
		{
			name = "AH",
			width = 0.08,
		},
		{
			name = "Total",
			width = 0.08,
		},
		{
			name = "Total Value",
			width = 0.17,
		}
	}
	local stHandlers = {
		OnEnter = function(_, data, self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			TSMAPI:SafeTooltipLink(data.itemString)
			GameTooltip:Show()
		end,
		OnLeave = function()
			GameTooltip:ClearLines()
			GameTooltip:Hide()
		end
	}

	local page = {
		{
			type = "SimpleGroup",
			layout = "TSMFillList",
			children = {
				{
					type = "SimpleGroup",
					layout = "Flow",
					children = {
						{
							type = "EditBox",
							label = "Item Search",
							relativeWidth = 0.19,
							onTextChanged = true,
							callback = function(_, _, value)
								private.inventoryFilters.name = value:trim()
								private:UpdateInventoryViewerST()
							end,
						},
						{
							type = "GroupBox",
							label = "Group",
							relativeWidth = 0.25,
							callback = function(_, _, value)
								private.inventoryFilters.group = value
								private:UpdateInventoryViewerST()
							end,
						},
						{
							type = "Dropdown",
							label = "Characters",
							relativeWidth = 0.2,
							list = playerList,
							value = private.inventoryFilters.characters,
							multiselect = true,
							callback = function(_, _, key, value)
								private.inventoryFilters.characters[key] = value
								private:UpdateInventoryViewerST()
							end,
						},
						{
							type = "Dropdown",
							label = "Guilds",
							relativeWidth = 0.2,
							list = guildList,
							value = private.inventoryFilters.guilds,
							multiselect = true,
							callback = function(_, _, key, value)
								private.inventoryFilters.guilds[key] = value
								private:UpdateInventoryViewerST()
							end,
						},
						{
							type = "EditBox",
							label = "Value Price Source",
							relativeWidth = 0.15,
							acceptCustom = true,
							settingInfo = {TSM.db.profile, "inventoryViewerPriceSource"},
						},
					},
				},
				{
					type = "HeadingLine",
				},
				{
					type = "ScrollingTable",
					tag = "TSM_INVENTORY_VIEWER",
					colInfo = stCols,
					handlers = stHandlers,
					defaultSort = 1,
				},
			},
		},
	}

	TSMAPI:BuildPage(container, page)
	private:UpdateInventoryViewerST()
end

function private:AddInventoryItem(items, itemString, key, quantity)
	itemString = TSMAPI:GetItemString(itemString)
	items[itemString] = items[itemString] or {total=0, bags=0, bank=0, guild=0, auctions=0, mail=0}
	items[itemString].total = items[itemString].total + quantity
	items[itemString][key] = items[itemString][key] + quantity
end

function private:UpdateInventoryViewerST()
	local items, rowData = {}, {}

	local playerData, guildData = TSM:GetAllInventoryData()
	for playerName, selected in pairs(private.inventoryFilters.characters) do
		if selected and playerData[playerName] then
			for itemString, quantity in pairs(playerData[playerName].bag) do
				private:AddInventoryItem(items, itemString, "bags", quantity)
			end
			for itemString, quantity in pairs(playerData[playerName].bank) do
				private:AddInventoryItem(items, itemString, "bank", quantity)
			end
			for itemString, quantity in pairs(playerData[playerName].reagentBank) do
				private:AddInventoryItem(items, itemString, "bank", quantity)
			end
			for itemString, quantity in pairs(playerData[playerName].auction) do
				private:AddInventoryItem(items, itemString, "auctions", quantity)
			end
			for itemString, quantity in pairs(playerData[playerName].mail) do
				private:AddInventoryItem(items, itemString, "mail", quantity)
			end
		end
	end
	for guildName, selected in pairs(private.inventoryFilters.guilds) do
		if selected and guildData[guildName] then
			for itemString, quantity in pairs(guildData[guildName]) do
				private:AddInventoryItem(items, itemString, "guild", quantity)
			end
		end
	end

	for itemString, data in pairs(items) do
		local name, itemLink = TSMAPI:GetSafeItemInfo(itemString)
		local marketValue = TSMAPI:GetCustomPriceValue(TSM.db.profile.inventoryViewerPriceSource, itemString) or 0
		local groupPath = TSMAPI:GetGroupPath(itemString)
		if (not name or private.inventoryFilters.name == "" or strfind(strlower(name), private.inventoryFilters.name)) and (not private.inventoryFilters.group or groupPath and strfind(groupPath, "^" .. TSMAPI:StrEscape(private.inventoryFilters.group))) then
			tinsert(rowData, {
				cols = {
					{
						value = itemLink or name or itemString,
						sortArg = name or "",
					},
					{
						value = data.bags,
						sortArg = data.bags,
					},
					{
						value = data.bank,
						sortArg = data.bank,
					},
					{
						value = data.mail,
						sortArg = data.mail,
					},
					{
						value = data.guild,
						sortArg = data.guild,
					},
					{
						value = data.auctions,
						sortArg = data.auctions,
					},
					{
						value = data.total,
						sortArg = data.total,
					},
					{
						value = TSMAPI:FormatTextMoney(data.total * marketValue) or "---",
						sortArg = data.total * marketValue,
					},
				},
				itemString = itemString,
				itemLink = itemLink,
			})
		end
	end

	sort(rowData, function(a, b) return a.cols[#a.cols].value > b.cols[#a.cols].value end)
	TSMAPI.TSMScrollingTable:UpdateData("TSM_INVENTORY_VIEWER", rowData)
end