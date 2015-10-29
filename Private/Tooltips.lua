-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file contains all the code for the new tooltip options

local TSM = select(2, ...)
local Tooltips = TSM:NewModule("Tooltips")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local LibExtraTip = LibStub("LibExtraTip-1")
local moduleObjects = TSM.moduleObjects
local private = {tooltipInfo={}, tooltipLines={lastUpdate=0, modifier=0}}



-- ============================================================================
-- Module Functions
-- ============================================================================

function Tooltips:OnInitialize()
	LibExtraTip:AddCallback({type = "battlepet", callback = private.LoadTooltip})
	LibExtraTip:AddCallback({type = "item", callback = private.LoadTooltip})
	LibExtraTip:RegisterTooltip(GameTooltip)
	LibExtraTip:RegisterTooltip(ItemRefTooltip)
	LibExtraTip:RegisterTooltip(BattlePetTooltip)
	LibExtraTip:RegisterTooltip(FloatingBattlePetTooltip)
	local orig = OpenMailAttachment_OnEnter
	OpenMailAttachment_OnEnter = function(self, index)
		private.lastMailTooltipUpdate = private.lastMailTooltipUpdate or 0
		if private.lastMailTooltipIndex ~= index or private.lastMailTooltipUpdate + 0.1 < GetTime() then
			private.lastMailTooltipUpdate = GetTime()
			private.lastMailTooltipIndex = index
			orig(self, index)
		end
	end
end

function Tooltips:RegisterInfo(module, info)
	info.module = module
	tinsert(private.tooltipInfo, info)
	TSM.db.profile.tooltipOptions[module] = TSM.db.profile.tooltipOptions[module] or info.defaults
end



-- ============================================================================
-- Helper Functions
-- ============================================================================

function private.LoadTooltip(tipFrame, link, quantity)
	local itemString = TSMAPI.Item:ToItemString(link)
	if not itemString then return end
	
	-- get all the tooltip lines
	quantity = max(quantity or 1, 1)
	if not IsShiftKeyDown() then
		quantity = 1 -- pretend this is a stack of 1 if the shift key isn't pressed
	end
	local modifier = (IsShiftKeyDown() and 4 or 0) + (IsAltKeyDown() and 2 or 0) + (IsControlKeyDown() and 1 or 0)
	if modifier ~= private.tooltipLines.modifier then
		private.tooltipLines.modifier = modifier
		private.tooltipLines.lastUpdate = 0
	end
	if (TSM.db.profile.tooltipShowModifier == "alt" and not IsAltKeyDown()) or (TSM.db.profile.tooltipShowModifier == "ctrl" and not IsControlKeyDown()) then
		wipe(private.tooltipLines)
		private.tooltipLines.modifier = modifier
		private.tooltipLines.lastUpdate = 0
		return private.tooltipLines
	end
	if private.tooltipLines.itemString ~= itemString or private.tooltipLines.quantity ~= quantity or (private.tooltipLines.lastUpdate + 5) < GetTime() then
		wipe(private.tooltipLines)
		local moneyCoins = TSM.db.profile.tooltipPriceFormat == "icon"
		-- TSM isn't considered a module by the tooltip code, so insert its lines explicitly
		TSM:LoadTooltip(itemString, quantity, moneyCoins, private.tooltipLines)
		-- insert module lines
		for _, info in ipairs(private.tooltipInfo) do
			-- make sure the module has been loaded
			if TSM.db.profile.tooltipOptions[info.module] then
				info.callbackLoad(itemString, quantity, TSM.db.profile.tooltipOptions[info.module], moneyCoins, private.tooltipLines)
			end
		end
		private.tooltipLines.itemString = itemString
		private.tooltipLines.quantity = quantity
		private.tooltipLines.lastUpdate = GetTime()
		private.tooltipLines.modifier = modifier
	end
	
	-- add the tooltip lines
	if #private.tooltipLines > 0 then
		LibExtraTip:AddLine(tipFrame, " ", 1, 1, 0, TSM.db.profile.embeddedTooltip)
		local r, g, b = unpack(TSM.db.profile.design.inlineColors.tooltip or { 130, 130, 250 })

		for i = 1, #private.tooltipLines do
			if type(private.tooltipLines[i]) == "table" then
				LibExtraTip:AddDoubleLine(tipFrame, private.tooltipLines[i].left, private.tooltipLines[i].right, r / 255, g / 255, b / 255, r / 255, g / 255, b / 255, TSM.db.profile.embeddedTooltip)
			else
				LibExtraTip:AddLine(tipFrame, private.tooltipLines[i], r / 255, g / 255, b / 255, TSM.db.profile.embeddedTooltip)
			end
		end
		LibExtraTip:AddLine(tipFrame, " ", 1, 1, 0, TSM.db.profile.embeddedTooltip)
	end
end



-- ============================================================================
-- Code for Tooltip Options
-- ============================================================================

function Tooltips:GetTreeInfo(value)
	local childInfo = {}
	for i, info in ipairs(private.tooltipInfo) do
		tinsert(childInfo, { value = i, text = info.module })
	end
	sort(childInfo, function(a, b) return a.text < b.text end)
	return {value = value, text = L["Tooltip Options"], children = childInfo}
end

function Tooltips:LoadOptions(parent, moduleIndex)
	moduleIndex = tonumber(moduleIndex)
	if not moduleIndex then
		private:DrawTooltipGeneral(parent)
	else
		local info = private.tooltipInfo[moduleIndex]
		TSMAPI:Assert(info)
		info.callbackOptions(parent, TSM.db.profile.tooltipOptions[info.module])
	end
end

function private:DrawTooltipGeneral(container)
	local priceSources = TSMAPI:GetPriceSources()
	priceSources["Crafting"] = nil
	priceSources["VendorBuy"] = nil
	priceSources["VendorSell"] = nil
	priceSources["Destroy"] = nil
	local operationModules = {}
	for moduleName, info in pairs(moduleObjects) do
		if info.operations and moduleName ~= "TradeSkillMaster" then
			operationModules[moduleName] = moduleName
		end
	end
	local page = {
		{
			-- scroll frame to contain everything
			type = "ScrollFrame",
			layout = "List",
			children = {
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["General Options"],
					children = {
						{
							type = "Dropdown",
							label = "Tooltip Price Format:",
							list = {icon=format("Coins (%s)", TSMAPI:MoneyToString(3451267, "OPT_ICON")), text=format("Text (%s)", TSMAPI:MoneyToString(3451267))},
							settingInfo = {TSM.db.profile, "tooltipPriceFormat"},
							relativeWidth = 0.35,
							tooltip = "Select how TSM will format prices in item tooltips.",
						},
						{
							type = "CheckBox",
							label = L["Embed TSM Tooltips"],
							settingInfo = {TSM.db.profile, "embeddedTooltip"},
							relativeWidth = 0.29,
							tooltip = L["If checked, TSM's tooltip lines will be embedded in the item tooltip. Otherwise, it will show as a separate box below the item's tooltip."],
						},
						{
							type = "Dropdown",
							label = "Show on Modifier:",
							list = {none="None (Always Show)", alt=ALT_KEY, ctrl=CTRL_KEY},
							settingInfo = {TSM.db.profile, "tooltipShowModifier"},
							relativeWidth = 0.35,
							tooltip = "Only show TSM's tooltip when the selected modifier is pressed.",
						},
						{
							type = "HeadingLine",
						},
						{
							type = "Dropdown",
							label = "Inventory Tooltip Format:",
							list = {none="None", simple="Simple", full="Full"},
							settingInfo = {TSM.db.profile, "inventoryTooltipFormat"},
							relativeWidth = 0.5,
							tooltip = "Select how much detail should be shown in item tooltips with respect to inventory information.",
						},
						{
							type = "HeadingLine",
						},
						{
							type = "CheckBox",
							label = "Display group name in tooltip",
							relativeWidth = 0.49,
							settingInfo = {TSM.db.profile, "groupOperationTooltip"},
						},
						{
							type = "Dropdown",
							label = "Display Operation Names in Tooltip for Modules:",
							list = operationModules,
							multiselect = true,
							settingInfo = {TSM.db.profile, "operationTooltips"},
							relativeWidth = 0.5,
							tooltip = "The operations for the selected module(s) will be displaed in item tooltips.",
						},
						{
							type = "HeadingLine",
						},
						{
							type = "CheckBox",
							label = L["Display vendor buy price in tooltip."],
							settingInfo = { TSM.db.profile, "vendorBuyTooltip" },
							relativeWidth = 0.5,
							tooltip = L["If checked, the price of buying the item from a vendor is displayed."],
						},
						{
							type = "CheckBox",
							label = L["Display vendor sell price in tooltip."],
							settingInfo = { TSM.db.profile, "vendorSellTooltip" },
							relativeWidth = 0.49,
							tooltip = L["If checked, the price of selling the item to a vendor displayed."],
						},
					},
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Destroy Values"],
					children = {
						{
							type = "Dropdown",
							label = L["Destroy Value Source:"],
							settingInfo = {TSM.db.profile, "destroyValueSource"},
							list = priceSources,
							relativeWidth = 0.5,
							tooltip = L["Select the price source for calculating destroy values."],
						},
						{
							type = "CheckBox",
							label = L["Display Detailed Destroy Tooltips"],
							settingInfo = { TSM.db.profile, "detailedDestroyTooltip" },
							relativeWidth = 0.49,
							tooltip = L["If checked, a detailed list of items which an item destroys into will be displayed below the destroy value in the tooltip."],
						},
						{
							type = "HeadingLine",
						},
						{
							type = "CheckBox",
							label = L["Display mill value in tooltip."],
							settingInfo = { TSM.db.profile, "millTooltip" },
							relativeWidth = 0.5,
							tooltip = L["If checked, the mill value of the item will be shown. This value is calculated using the average market value of materials the item will mill into."],
						},
						{
							type = "CheckBox",
							label = L["Display prospect value in tooltip."],
							settingInfo = { TSM.db.profile, "prospectTooltip" },
							relativeWidth = 0.5,
							tooltip = L["If checked, the prospect value of the item will be shown. This value is calculated using the average market value of materials the item will prospect into."],
						},
						{
							type = "CheckBox",
							label = L["Display disenchant value in tooltip."],
							settingInfo = { TSM.db.profile, "deTooltip" },
							relativeWidth = 0.5,
							tooltip = L["If checked, the disenchant value of the item will be shown. This value is calculated using the average market value of materials the item will disenchant into."],
						},
						{
							type = "CheckBox",
							label = L["Display transform value in tooltip."],
							settingInfo = { TSM.db.profile, "transformTooltip" },
							relativeWidth = 0.5,
							tooltip = L["If checked, the transform value of the item will be shown. This value is calculated using the average market value of materials the item will disenchant into."],
						},
					},
				},
			},
		},
	}
	
	if next(TSM.db.global.customPriceSources) then
		local inlineGroup = {
			type = "InlineGroup",
			layout = "flow",
			title = L["Custom Price Sources"],
			children = {
				{
					type = "Label",
					text = L["Custom price sources to display in item tooltips:"],
					relativeWidth = 1,
				},
			},
		}
		for name in pairs(TSM.db.global.customPriceSources) do
			local checkbox = {
				type = "CheckBox",
				label = name,
				relativeWidth = 0.5,
				settingInfo = { TSM.db.global.customPriceTooltips, name },
				tooltip = L["If checked, this custom price will be displayed in item tooltips."],
			}
			tinsert(inlineGroup.children, checkbox)
		end
		tinsert(page[1].children, inlineGroup)
	end

	TSMAPI.GUI:BuildOptions(container, page)
end