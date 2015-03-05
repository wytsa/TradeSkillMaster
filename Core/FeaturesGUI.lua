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
local FeaturesGUI = TSM:NewModule("FeaturesGUI", "AceHook-3.0")
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries
local private = {viewerST=nil, inventoryFilters={characters={}, guilds={}, name="", group=nil}}


function FeaturesGUI:LoadGUI(parent)
	local tabGroup = AceGUI:Create("TSMTabGroup")
	tabGroup:SetLayout("Fill")
	tabGroup:SetTabs({{text="Misc. Features", value=1}, {text="Inventory Viewer", value=2}, {text="Pending Group Imports (via TSM Desktop App)", value=3}})
	tabGroup:SetCallback("OnGroupSelected", function(_, _, value)
		tabGroup:ReleaseChildren()
		if private.viewerST then private.viewerST:Hide() end
		if value == 1 then
			private:LoadMiscFeatures(tabGroup)
		elseif value == 2 then
			private:LoadInventoryViewer(tabGroup)
		elseif value == 3 then
			private:LoadGroupImport(tabGroup)
		end
	end)
	parent:AddChild(tabGroup)
	tabGroup:SelectTab(1)

	FeaturesGUI:HookScript(tabGroup.frame, "OnHide", function()
		FeaturesGUI:UnhookAll()
		if private.viewerST then private.viewerST:Hide() end
	end)
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
							callback = TSM.UpdateFeatureStates,
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
							callback = TSM.UpdateFeatureStates,
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
							callback = TSM.UpdateFeatureStates,
						},
					},
				},
			},
		},
	}
	TSMAPI:BuildPage(container, page)
end

function private:LoadGroupImport(container)
	local checkedImports = {}
	local page = {
		{
			type = "ScrollFrame", -- simple group didn't work here for some reason
			fullHeight = true,
			layout = "Flow",
			children = {
				{
					type = "InlineGroup",
					title = "Help",
					layout = "Flow",
					children = {
						{
							type = "Label",
							text = "Below is a list of pending imports. They will be removed after 1 day if they aren't imported before then. Check the box next to the one(s) which you want to import and then select the group you want to import them into using the box below.",
							relativeWidth = 1,
						},
						{
							type = "HeadingLine",
						},
						{
							type = "GroupBox",
							label = "Import Selected Strings to Group",
							relativeWidth = 0.5,
							callback = function(self, _, groupPath)
								local didImport = false
								for key, import in pairs(checkedImports) do
									local num = TSM:ImportGroup(import, groupPath)
									if num then
										didImport = true
										TSM:Printf(L["Successfully imported %d items to %s."], num, TSMAPI:FormatGroupPath(groupPath, true))
									else
										TSM:Print(L["Invalid import string."].." \""..import.."\"")
									end
									TSM.db.global.groupImportHistory[key].imported = true
								end
								if didImport then
									container:ReloadTab()
								else
									TSM:Print("No group import strings were selected.")
								end
							end,
						},
						{
							type = "CheckBox",
							label = L["Move Already Grouped Items"],
							relativeWidth = 0.49,
							settingInfo = {TSM.db.profile, "moveImportedItems"},
							callback = function() container:ReloadTab() end,
							tooltip = L["If checked, any items you import that are already in a group will be moved out of their current group and into this group. Otherwise, they will simply be ignored."],
						},
					},
				},
				{
					type = "InlineGroup",
					title = "Pending Imports",
					layout = "Flow",
					children = {
					},
				},
			},
		},
	}
	
	local pendingImportContainer = page[1].children[2].children
	
	for key, data in pairs(TSM.db.global.groupImportHistory) do
		if not data.imported then
			local import = TSM.AppData.groupImports[data.index].import
			tinsert(pendingImportContainer, {type="CheckBox", relativeWidth=1, label=import, callback=function(_, _, value) checkedImports[key] = value and import or nil end})
		end
	end
	
	if #pendingImportContainer == 0 then
		tinsert(pendingImportContainer, {type="Label", relativeWidth=1, text="No pending group imports from the TSM desktop application."})
	end

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

	local page = {
		{
			type = "SimpleGroup",
			layout = "Flow",
			fullHeight = true,
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
				{
					type = "ScrollFrame", -- simple group didn't work here for some reason
					fullHeight = true,
					layout = "Flow",
					children = {},
				},
			},
		},
	}

	TSMAPI:BuildPage(container, page)

	-- scrolling table
	local stParent = container.children[1].children[#container.children[1].children].frame

	if not private.viewerST then
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
		local handlers = {
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
		private.viewerST = TSMAPI:CreateScrollingTable(stParent, stCols, handlers)
		private.viewerST:EnableSorting(true)
	end

	private.viewerST:Show()
	private.viewerST:SetParent(stParent)
	private.viewerST:SetAllPoints()
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
		local marketValue = TSM:GetCustomPrice(TSM.db.profile.inventoryViewerPriceSource, itemString) or 0
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
			})
		end
	end

	sort(rowData, function(a, b) return a.cols[#a.cols].value > b.cols[#a.cols].value end)
	private.viewerST:SetData(rowData)
end