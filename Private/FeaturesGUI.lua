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
	tabGroup:SetTabs({{text=L["Scroll Wheel Macro"], value=1}, {text=L["Misc. Features"], value=2}, {text=L["Inventory Viewer"], value=3}})
	tabGroup:SetCallback("OnGroupSelected", function(_, _, value)
		tabGroup:ReleaseChildren()
		if value == 1 then
			private:LoadMacroCreation(tabGroup)
		elseif value == 2 then
			private:LoadMiscFeatures(tabGroup)
		elseif value == 3 then
			private:LoadInventoryViewer(tabGroup)
		end
	end)
	parent:AddChild(tabGroup)
	tabGroup:SelectTab(1)
end

function private:LoadMacroCreation(container)
	-- set default buttons (or use current ones)
	local macroButtonNames = {}
	local macroButtons = {}
	local body = GetMacroBody(GetMacroIndexByName("TSMMacro") or 0)
	if TSMAPI:HasModule("Auctioning") then
		macroButtonNames.auctioningPost = "TSMAuctioningPostButton"
		macroButtonNames.auctioningCancel = "TSMAuctioningCancelButton"
		macroButtons.auctioningPost = (not body or strfind(body, macroButtonNames.auctioningPost)) and true or false
		macroButtons.auctioningCancel = (not body or strfind(body, macroButtonNames.auctioningCancel)) and true or false
	end
	if TSMAPI:HasModule("Crafting") then
		macroButtonNames.craftingCraftNext = "TSMCraftNextButton"
		macroButtons.craftingCraftNext = (not body or strfind(body, macroButtonNames.craftingCraftNext)) and true or false
	end
	if TSMAPI:HasModule("Destroying") then
		macroButtonNames.destroyingDestroyNext = "TSMDestroyButton"
		macroButtons.destroyingDestroyNext = (not body or strfind(body, macroButtonNames.destroyingDestroyNext)) and true or false
	end
	if TSMAPI:HasModule("Shopping") then
		macroButtonNames.shoppingBuyout = "TSMShoppingBuyoutButton"
		macroButtonNames.shoppingBuyoutConfirmation = "TSMShoppingBuyoutConfirmationButton"
		macroButtons.shoppingBuyout = (not body or strfind(body, macroButtonNames.shoppingBuyout)) and true or false
		macroButtons.shoppingBuyoutConfirmation = (not body or strfind(body, macroButtonNames.shoppingBuyoutConfirmation)) and true or false
	end
	
	-- set default options (or use current ones)
	local macroOptions = nil
	local currentBindings = {GetBindingKey("MACRO TSMMacro")}
	if #currentBindings > 0 and #currentBindings <= 2 and strfind(currentBindings[1], "MOUSEWHEEL") then
		macroOptions = {}
		if #currentBindings == 2 then
			-- assume it's up/down
			macroOptions.up = true
			macroOptions.down = true
		else
			macroOptions.up = strfind(currentBindings[1], "MOUSEWHEELUP") and true or false
			macroOptions.down = strfind(currentBindings[1], "MOUSEWHEELDOWN") and true or false
		end
		-- use modifiers from the first binding
		macroOptions.ctrl = strfind(currentBindings[1], "CTRL") and true or false
		macroOptions.shift = strfind(currentBindings[1], "SHIFT") and true or false
		macroOptions.alt = strfind(currentBindings[1], "ALT") and true or false
	else
		macroOptions = {down=true, up=true, ctrl=true, shift=false, alt=false}
	end
	
	local page = {
		{
			type = "ScrollFrame",
			layout = "list",
			children = {
				{
					type = "InlineGroup",
					layout = "flow",
					children = {
						{
							type = "Label",
							text = L["Many commonly-used buttons in TSM can be macro'd and added bound to your scroll wheel. Below, select the buttons you would like to include in this macro and the modifier(s) you would like to use with the scroll wheel."],
							relativeWidth = 1,
						},
					},
				},
				{
					type = "InlineGroup",
					layout = "flow",
					children = {
						{
							type = "CheckBox",
							label = L["TSM_Auctioning 'Post' Button"],
							settingInfo = { macroButtons, "auctioningPost" },
							disabled = not TSMAPI:HasModule("Auctioning"),
							tooltip = L["Will include the TSM_Auctioning 'Post' button in the macro."],
						},
						{
							type = "CheckBox",
							label = L["TSM_Auctioning 'Cancel' Button"],
							settingInfo = { macroButtons, "auctioningCancel" },
							disabled = not TSMAPI:HasModule("Auctioning"),
							tooltip = L["Will include the TSM_Auctioning 'Cancel' button in the macro."],
						},
						{
							type = "HeadingLine",
						},
						{
							type = "CheckBox",
							label = L["TSM_Crafting 'Craft Next' Button"],
							settingInfo = { macroButtons, "craftingCraftNext" },
							disabled = not TSMAPI:HasModule("Crafting"),
							tooltip = L["Will include the TSM_Crafting 'Craft Next' button in the macro."],
						},
						{
							type = "HeadingLine",
						},
						{
							type = "CheckBox",
							label = L["TSM_Destroying 'Destroy Next' Button"],
							settingInfo = { macroButtons, "destroyingDestroyNext" },
							disabled = not TSMAPI:HasModule("Destroying"),
							tooltip = L["Will include the TSM_Destroying 'Destroy Next' button in the macro."],
						},
						{
							type = "HeadingLine",
						},
						{
							type = "CheckBox",
							label = L["TSM_Shopping 'Buyout' Button"],
							settingInfo = { macroButtons, "shoppingBuyout" },
							disabled = not TSMAPI:HasModule("Shopping"),
							tooltip = L["Will include the TSM_Shopping 'Buyout' button in the macro."],
						},
						{
							type = "CheckBox",
							label = L["TSM_Shopping 'Buyout' (Confirmation) Button"],
							settingInfo = { macroButtons, "shoppingBuyoutConfirmation" },
							disabled = not TSMAPI:HasModule("Shopping"),
							tooltip = L["Will include the TSM_Shopping buyout confirmation window 'Buyout' button in the macro."],
						},
					},
				},
				{
					type = "InlineGroup",
					layout = "flow",
					children = {
						{
							type = "Label",
							text = L["Scroll Wheel Direction:"],
							relativeWidth = 0.4,
						},
						{
							type = "CheckBox",
							label = L["Up"],
							relativeWidth = 0.3,
							settingInfo = { macroOptions, "up" },
							tooltip = L["Will cause the macro to be triggered when the scroll wheel goes up (with the selected modifiers pressed)."],
						},
						{
							type = "CheckBox",
							label = L["Down"],
							relativeWidth = 0.3,
							settingInfo = { macroOptions, "down" },
							tooltip = L["Will cause the macro to be triggered when the scroll wheel goes down (with the selected modifiers pressed)."],
						},
						{
							type = "Label",
							text = L["Modifiers:"],
							relativeWidth = 0.4,
						},
						{
							type = "CheckBox",
							label = "ALT",
							relativeWidth = 0.2,
							settingInfo = { macroOptions, "alt" },
						},
						{
							type = "CheckBox",
							label = "CTRL",
							relativeWidth = 0.2,
							settingInfo = { macroOptions, "ctrl" },
						},
						{
							type = "CheckBox",
							label = "SHIFT",
							relativeWidth = 0.2,
							settingInfo = { macroOptions, "shift" },
						},
						{
							type = "HeadingLine",
						},
						{
							type = "Button",
							relativeWidth = 1,
							text = L["Create Macro and Bind Scroll Wheel"],
							callback = function()
								-- delete old bindings
								for _, binding in ipairs({GetBindingKey("MACRO TSMAucBClick")}) do
									SetBinding(binding)
								end
								for _, binding in ipairs({GetBindingKey("MACRO TSMMacro")}) do
									SetBinding(binding)
								end
							
								-- delete old macros
								DeleteMacro("TSMAucBClick")
								DeleteMacro("TSMMacro")
								
								-- create the new macro
								local lines = {}
								for key, enabled in pairs(macroButtons) do
									if enabled then
										TSMAPI:Assert(macroButtonNames[key])
										tinsert(lines, "/click "..macroButtonNames[key])
									end
								end
								CreateMacro("TSMMacro", "Achievement_Faction_GoldenLotus", table.concat(lines, "\n"))

								-- create the scroll wheel binding
								local modifierStr = (macroOptions.ctrl and "CTRL-" or "")..(macroOptions.alt and "ALT-" or "")..(macroOptions.shift and "SHIFT-" or "")
								local bindingNum = (GetCurrentBindingSet() == 1) and 2 or 1
								if macroOptions.up then
									SetBinding(modifierStr.."MOUSEWHEELUP", nil, bindingNum)
									SetBinding(modifierStr.."MOUSEWHEELUP", "MACRO TSMMacro", bindingNum)
								end
								if macroOptions.down then
									SetBinding(modifierStr.."MOUSEWHEELDOWN", nil, bindingNum)
									SetBinding(modifierStr.."MOUSEWHEELDOWN", "MACRO TSMMacro", bindingNum)
								end
								SaveBindings(2)

								TSM:Print(L["Macro created and scroll wheel bound!"])
							end,
						},
					},
				},
			},
		},
	}
	TSMAPI.GUI:BuildOptions(container, page)
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
					title = L["Auction Buys"],
					children = {
						{
							type = "Label",
							text = L["The auction buys feature will change the 'You have won an auction of XXX' text into something more useful which contains the link, stack size, and price of the item you bought."],
							relativeWidth = 1,
						},
						{
							type = "HeadingLine"
						},
						{
							type = "CheckBox",
							label = L["Enable Auction Buys Feature"],
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
					title = L["Auction Sales"],
					children = {
						{
							type = "Label",
							text = L["The auction sales feature will change the 'A buyer has been found for your auction of XXX' text into something more useful which contains a link to the item and, if possible, the amount the auction sold for."],
							relativeWidth = 1,
						},
						{
							type = "HeadingLine"
						},
						{
							type = "CheckBox",
							label = L["Enable Auction Sales Feature"],
							relativeWidth = 1,
							settingInfo = {TSM.db.global, "auctionSaleEnabled"},
							callback = TSM.Features.ReloadStatus,
						},
						{
							type = "Dropdown",
							label = L["Enable Sound"],
							relativeWidth = 0.5,
							list = TSMAPI:GetSounds(),
							settingInfo = {TSM.db.global, "auctionSaleSound"},
							tooltip = L["Play the selected sound when one of your auctions sells."],
						},
						{
							type = "Button",
							text = L["Test Selected Sound"],
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
							text = L["The vendor buying feature will replace the default frame that is shown when you shift-right-click on a vendor item for purchasing with a small frame that allows you to buy more than one stacks worth at a time."],
							relativeWidth = 1,
						},
						{
							type = "HeadingLine"
						},
						{
							type = "CheckBox",
							label = L["Enable Vendor Buying Feature"],
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
							text = L["If you have WoW's Twitter integration setup, TSM will add a share link to its enhanced auction sales / purchaes messages (enabled above) as well as replace the URL in item tweets with a TSM link."],
							relativeWidth = 1,
						},
						{
							type = "HeadingLine"
						},
						{
							type = "CheckBox",
							label = L["Enable Tweet Enhancement (Only Works if WoW Twitter Integration is Setup)"],
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
	TSMAPI.GUI:BuildOptions(container, page)
end

function private:LoadInventoryViewer(container)
	local playerList, guildList = {}, {}
	for name in pairs(TSMAPI.Player:GetCharacters()) do
		playerList[name] = name
		private.inventoryFilters.characters[name] = true
	end
	for name in pairs(TSMAPI.Player:GetGuilds()) do
		guildList[name] = name
		private.inventoryFilters.guilds[name] = true
	end
	private.inventoryFilters.group = nil
	
	local stCols = {
		{
			name = L["Item Name"],
			width = 0.35,
		},
		{
			name = L["Bags"],
			width = 0.08,
			align = "CENTER",
		},
		{
			name = L["Bank"],
			width = 0.08,
			align = "CENTER",
		},
		{
			name = L["Mail"],
			width = 0.08,
			align = "CENTER",
		},
		{
			name = L["GVault"],
			width = 0.08,
			align = "CENTER",
		},
		{
			name = L["AH"],
			width = 0.08,
			align = "CENTER",
		},
		{
			name = L["Total"],
			width = 0.08,
			align = "CENTER",
		},
		{
			name = L["Total Value"],
			width = 0.17,
			align = "RIGHT",
		}
	}
	local stHandlers = {
		OnEnter = function(_, data, self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			TSMAPI.Util:SafeTooltipLink(data.itemString)
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
							label = L["Item Search"],
							relativeWidth = 0.19,
							onTextChanged = true,
							callback = function(_, _, value)
								private.inventoryFilters.name = value:trim()
								private:UpdateInventoryViewerST()
							end,
						},
						{
							type = "GroupBox",
							label = L["Group"],
							relativeWidth = 0.25,
							callback = function(_, _, value)
								private.inventoryFilters.group = value
								private:UpdateInventoryViewerST()
							end,
						},
						{
							type = "Dropdown",
							label = L["Characters"],
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
							label = L["Guilds"],
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
							label = L["Value Price Source"],
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

	TSMAPI.GUI:BuildOptions(container, page)
	private:UpdateInventoryViewerST()
end

function private:AddInventoryItem(items, itemString, key, quantity)
	itemString = TSMAPI.Item:ToItemString(itemString)
	items[itemString] = items[itemString] or {total=0, bags=0, bank=0, guild=0, auctions=0, mail=0}
	items[itemString].total = items[itemString].total + quantity
	items[itemString][key] = items[itemString][key] + quantity
end

function private:UpdateInventoryViewerST()
	local items, rowData = {}, {}

	local playerData, guildData = TSM.Inventory:GetAllData()
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
		local name, itemLink = TSMAPI.Item:GetInfo(itemString)
		local marketValue = TSMAPI:GetCustomPriceValue(TSM.db.profile.inventoryViewerPriceSource, itemString) or 0
		local groupPath = TSMAPI.Groups:GetPath(itemString)
		if (not name or private.inventoryFilters.name == "" or strfind(strlower(name), private.inventoryFilters.name)) and (not private.inventoryFilters.group or groupPath and strfind(groupPath, "^" .. TSMAPI.Util:StrEscape(private.inventoryFilters.group))) then
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
						value = TSMAPI:MoneyToString(data.total * marketValue) or "---",
						sortArg = data.total * marketValue,
					},
				},
				itemString = itemString,
				itemLink = itemLink,
			})
		end
	end

	sort(rowData, function(a, b) return a.cols[#a.cols].value > b.cols[#a.cols].value end)
	TSMAPI.GUI:UpdateTSMScrollingTableData("TSM_INVENTORY_VIEWER", rowData)
end