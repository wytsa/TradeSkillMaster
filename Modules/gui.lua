-- ------------------------------------------------------------------------------------- --
-- 					Scroll Master - AddOn by Sapu (sapu94@gmail.com)			 		 --
--             http://wow.curse.com/downloads/wow-addons/details/slippy.aspx             --
-- ------------------------------------------------------------------------------------- --

-- The following functions are contained attached to this file:
-- GUI:OnEnable() - setup the main GUI frame / structure as well as the popups dialogs that the GUI uses
-- GUI:OpenFrame() - simple function for openning the GUI
-- GUI:SelectTree() - controls what is drawn on the right side of the GUI window
-- GUI:DrawMainEnchant() - Front Enchants page
-- GUI:DrawSubEnchant() - Enchant sub-pages
-- GUI:DrawMaterials() - Materials Page
-- GUI:DrawTotals() - Totals / Queue Page
-- GUI:DrawOptions() - Options Page
-- GUI:DrawExternal() - External Addon Options Page
-- GUI:DrawProfiles() - profiles page
-- GUI:DrawAddEnchant() - page for adding enchants
-- GUI:DrawRemoveEnchant() - page for removing added enchants
-- GUI:DrawHelp() - Help Page
-- GUI:DrawAbout() - About Page
-- GUI:DrawAPM - page for all APM3 features
-- GUI:UpdateQueue() - updates the craft queue
-- GUI:GetID() - extracts an ItemID from an ItemLink or EnchantLink
-- GUI:BuildPage() - goes through a page-table and draws out all the containers and widgets for that page
-- GUI:AddGUIElement() -creates a widget or container as detailed in the passed table (iTable) and adds it as a child of the passed parent

-- The following "global" (within the addon) variables are initialized in this file:
-- GUI.Frame1 - main frame which contains the entire GUI
-- GUI.TreeGroup - next highest layer after Frame1 which contains the tree structure
-- GUI.queueList - table which contains the craft queue
-- GUI.queueTotal - integer representing the total number of items (including multiple of the same enchant) in the craft queue
-- GUI.queueInTotal - integer representing the number of different items in the craft queue

-- ===================================================================================== --


-- load the parent file (ScrollMaster) into a local variable and register this file as a module
local TSM = select(2, ...)
local GUI = TSM:NewModule("GUI", "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries

local aceL = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local debug = function(...) TSM:Debug(...) end -- for debugging

local function L(phrase)
	--TSM.lTable[phrase] = true
	return aceL[phrase]
end

-- some static variables for easy changing of frame dimmensions
-- these values are what the frame starts out using but the user can resize it from there
local TREE_WIDTH = 150 -- the width of the tree part of the frame
local FRAME_WIDTH = 780 -- width of the entire frame
local FRAME_HEIGHT = 700 -- height of the entire frame
local VELLUM_ID = 38682

-- color codes
local CYAN = "|cff99ffff"
local BLUE = "|cff5555ff"
local GREEN = "|cff00ff00"
local RED = "|cffff0000"
local WHITE = "|cffffffff"
local GOLD = "|cffffbb00"
local YELLOW = "|cffffd000"

-- setup the main GUI frame / structure as well as the popups dialogs that the GUI uses
function GUI:OnEnable()
	GUI.queueList = {}
	GUI.offsets = {}
	GUI.currentPage = {}
	TSM.mode = "Enchanting"
	
	-- Popup Confirmation Window used in this module
	StaticPopupDialogs["TSM.DeleteConfirm"] = {
		text = L("Are you sure you want to delete the selected profile?"),
		button1 = L("Accept"),
		button2 = L("Cancel"),
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		OnCancel = false,
		-- OnAccept defined later
	}
	
	-- the tree structure for the main window
	local treeStructure = {
		{value = 1, text = L("Status")},
		{value = 2, text = L("Enchants"), children = {
				{value = 1, text = L("2H Weapon")},
				{value = 2, text = L("Boots")},
				{value = 3, text = L("Bracers")},
				{value = 4, text = L("Chest")},
				{value = 5, text = L("Cloak")},
				{value = 6, text = L("Gloves")},
				{value = 7, text = L("Shield")},
				{value = 8, text = L("Staff")},
				{value = 9, text = L("Weapon")},
			}
		},
		{value = 3, text = L("Materials")},
		{value = 4, text = L("Totals / Queue")},
	}

	-- Create Frame1 which is the main frame of Scroll Master
	GUI.Frame1 = AceGUI:Create("Frame")
	GUI.Frame1:SetTitle("TradeSkill Master v" .. TSM.version)
	GUI.Frame1:SetLayout("Fill")
	GUI.Frame1:SetWidth(FRAME_WIDTH)
	GUI.Frame1:SetHeight(FRAME_HEIGHT)
	GUI.Frame1:SetCallback("OnClose", function() GUI:UnregisterEvent("BAG_UPDATE") end)
	
	local function makeIcons()
		local names = {"Enchanting", "Blacksmithing", "Alchemy", "Inscription", "Engineering",
		"Jewelcrafting", "Leatherworking", "Tailoring", "Options"}
		local textures = {"Interface\\Icons\\trade_engraving", "Interface\\Icons\\trade_BlackSmithing",
		"Interface\\Icons\\trade_alchemy", "Interface\\Icons\\INV_Inscription_Tradeskill01",
		"Interface\\Icons\\trade_engineering", "Interface\\Icons\\INV_Misc_Gem_02",
		"Interface\\Icons\\INV_Misc_ArmorKit_17", "Interface\\Icons\\trade_tailoring",
		"Interface\\Icons\\INV_Misc_QuestionMark"}
		for i=1, 9 do
			local frame = CreateFrame("Button", nil, TSM.GUI.Frame1.frame)
			frame:SetPoint("BOTTOMLEFT", TSM.GUI.Frame1.frame, "TOPLEFT", -85, (7-78*i))
			frame:SetScript("OnClick", function() GUI:Icon(i) end)

			local image = frame:CreateTexture(nil, "BACKGROUND")
			image:SetWidth(56)
			image:SetHeight(56)
			image:SetPoint("TOP", 0, -5)
			frame.image = image
			
			local label = frame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmallOutline")
			label:SetPoint("BOTTOMLEFT")
			label:SetPoint("BOTTOMRIGHT")
			label:SetJustifyH("CENTER")
			label:SetJustifyV("TOP")
			label:SetHeight(10)
			label:SetText(names[i])
			frame.label = label

			local highlight = frame:CreateTexture(nil, "HIGHLIGHT")
			highlight:SetAllPoints(image)
			highlight:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight")
			highlight:SetTexCoord(0, 1, 0.23, 0.77)
			highlight:SetBlendMode("ADD")
			frame.highlight = highlight
			
			frame:SetHeight(71)
			frame:SetWidth(90)
			frame.image:SetTexture(textures[i])
			frame.image:SetVertexColor(1, 1, 1)
			
			if i>1 and i < 9 then
				frame:Disable()
				frame.label:SetTextColor(0.5, 0.5, 0.5)
				frame.image:SetVertexColor(0.5, 0.5, 0.5, 0.5)
			end
		end
	end
	makeIcons()
	GUI.Frame1:Hide()
	
	local treeGroupStatus = {treewidth = TREE_WIDTH, groups = TSM.db.global.treeStatus}
	
	-- Create the main tree-group that will control and contain the entire GUI
	GUI.TreeGroup = AceGUI:Create("TreeGroup")
	GUI.TreeGroup:SetLayout("Fill")
	GUI.TreeGroup:SetTree(treeStructure)
	GUI.TreeGroup:SetCallback("OnGroupSelected", function(...) GUI:SelectTree(...) end)
	GUI.TreeGroup:SetStatusTable(treeGroupStatus)
	GUI.Frame1:AddChild(GUI.TreeGroup)
end

-- simple function for openning the GUI
function GUI:OpenFrame(...)
	GUI.Frame1:Show()
	GUI.TreeGroup:SelectByPath(...)
end

function GUI:Icon(num)
	if num == 1 then
		TSM.mode = "Enchanting"
		local treeStructure = {
			{value = 1, text = L("Status")},
			{value = 2, text = L("Enchants"), children = {
					{value = 1, text = L("2H Weapon")},
					{value = 2, text = L("Boots")},
					{value = 3, text = L("Bracers")},
					{value = 4, text = L("Chest")},
					{value = 5, text = L("Cloak")},
					{value = 6, text = L("Gloves")},
					{value = 7, text = L("Shield")},
					{value = 8, text = L("Staff")},
					{value = 9, text = L("Weapon")},
				}
			},
			{value = 3, text = L("Materials")},
			{value = 4, text = L("Totals / Queue")},
		}
		local treeGroupStatus = {treewidth = TREE_WIDTH, groups = TSM.db.global.treeStatus}
		GUI.TreeGroup:SetTree(treeStructure)
		GUI.TreeGroup:SetStatusTable(treeGroupStatus)
		GUI.TreeGroup:SelectByPath(1)
	elseif num == 2 then
		TSM.mode = "Blacksmithing"
		local treeStructure = {
			{value = 1, text = L("Status")},
			{value = 2, text = "Crafts", children = {
					{value = 1, text = L("2H Weapon")},
					{value = 2, text = L("Boots")},
					{value = 3, text = L("Bracers")},
					{value = 4, text = L("Chest")},
					{value = 5, text = L("Cloak")},
					{value = 6, text = L("Gloves")},
					{value = 7, text = L("Shield")},
					{value = 8, text = L("Staff")},
					{value = 9, text = L("Weapon")},
				}
			},
			{value = 3, text = L("Materials")},
			{value = 4, text = L("Totals / Queue")},
		}
		local treeGroupStatus = {treewidth = TREE_WIDTH, groups = TSM.db.global.treeStatus}
		GUI.TreeGroup:SetTree(treeStructure)
		GUI.TreeGroup:SetStatusTable(treeGroupStatus)
		GUI.TreeGroup:SelectByPath(1)
	elseif num == 9 then
		--TSM.mode = "options"
		treeStructure = {
			{value = 6, text = L("Options")},
			{value = 7, text = L("3rd Party Addons")},
			{value = 8, text = L("Help")},
			{value = 9, text = L("About")},
		}
		local treeGroupStatus = {treewidth = TREE_WIDTH, groups = TSM.db.global.treeStatus}
		GUI.TreeGroup:SetTree(treeStructure)
		GUI.TreeGroup:SetStatusTable(treeGroupStatus)
		GUI.TreeGroup:SelectByPath(6)
	end
end

-- controls what is drawn on the right side of the GUI window
-- this is based on what is selected in the "tree" on the left (ex 'Options'->'Remove Enchants')
function GUI:SelectTree(treeFrame, _, selection)
	-- decodes and seperates the selection string from AceGUIWidget-TreeGroup
	local selectedParent, selectedChild = ("\001"):split(selection)
	selectedParent = tonumber(selectedParent) -- the main group that's selected (Enchants, Materials, Options, etc)
	selectedChild = tonumber(selectedChild) -- the child group that's if there is one (2H Weapon, Boots, Chest, etc)
	
	if GUI.currentPage.parent == 6 or GUI.currentPage.parent == 7 then
		--do nothing
	elseif treeFrame.children and treeFrame.children[1] and treeFrame.children[1].children and treeFrame.children[1].children[1] and treeFrame.children[1].children[1].localstatus then
		GUI.offsets[GUI.currentPage.parent][GUI.currentPage.child] = treeFrame.children[1].children[1].localstatus.offset
	end
	
	-- prepare the TreeFrame for a new container which will hold everything that is drawn on the right part of the GUI
	treeFrame:ReleaseChildren()
	GUI:UnregisterEvent("BAG_UPDATE")
	if TSM.mode == "Enchanting" or TSM.mode == "Blacksmithing" then
		GUI:UpdateQueue()
		TSM.Scan:Calc("mats")
	end
	GUI.currentPage = {parent=selectedParent, child=(selectedChild or 0)}
	
	-- a simple group to provide a fresh layout to whatever is put inside of it
	-- just acts as an invisible layer between the TreeGroup and whatever is drawn inside of it
	local container = AceGUI:Create("SimpleGroup")
	container:SetLayout("Fill")
	treeFrame:AddChild(container)
	container.Add = GUI.AddGUIElement
	
	-- figures out which tree element is selected
	-- then calls the correct function to build that part of the GUI
	if selectedParent == 1 then
		GUI:DrawStatus(container) -- the status page that shows when you first open the GUI
	elseif selectedParent == 2 then
		if not selectedChild then -- the main "Enchants" page that is shown on /tsm
			GUI:DrawMainEnchant(container)
		else -- one of the "Enchants" sub-groups
			GUI:DrawSubEnchant(container, selectedChild)
		end
	elseif selectedParent == 3 then -- Materials summary page
		GUI:DrawMaterials(container)
	elseif selectedParent == 4 then -- Totals / Queue page
		GUI:DrawTotals(container)
	elseif selectedParent == 5 then -- main options page
		GUI:DrawAPM(container)
	elseif selectedParent == 6 then
		treeFrame:ReleaseChildren()
		treeFrame:SetLayout("Fill")
		GUI:DrawOptions(treeFrame)
	elseif selectedParent == 7 then
		GUI:DrawExternal(container)
	elseif selectedParent == 8 then -- help page
		GUI:DrawHelp(container)
	elseif selectedParent == 9 then -- about page
		GUI:DrawAbout(container)
	end
	
	if (GUI.currentPage.parent ~= 5) and (GUI.currentPage.parent ~= 6 or GUI.currentPage.child ~= 0) then
		GUI.offsets[GUI.currentPage.parent] = GUI.offsets[GUI.currentPage.parent] or {}
		GUI.offsets[GUI.currentPage.parent][GUI.currentPage.child] = GUI.offsets[GUI.currentPage.parent][GUI.currentPage.child] or 0
		container.children[1].localstatus.offset = GUI.offsets[GUI.currentPage.parent][GUI.currentPage.child]
	end
end

 -- Front Enchants page
function GUI:DrawStatus(container)
	local function GetVars(num)
		local results = {}
		-- enables / disables the 2 Craft Queue buttons depending on the status of the craft queue
		if GUI.queueTotal > 0 then
			-- checks to see if the player is an enchanter (51313 is Grand Master enchanting)
			if TSM.Enchanting:IsEnchanter() then
				results[3] = false
				results[1] = ""
			else
				results[3] = true
				results[1] = GOLD .. L("Grand Master Enchanting not found! Craft Queue Disabled!") .. "|r"
			end
		else
			results[1] = GOLD .. L("Your craft queue is empty!") .. "|r"
			results[2] = true
			results[3] = true
		end
		
		local text = L("Clicking on the button below will add enchants to the craft queue that will " ..
		"make you the most possible profit for a total mat cost of %s gold or under. No enchant with " ..
		"a profit under %s gold will be included.")
		local maxGold = YELLOW .. TSM.db.profile.maxProfitGold .. "|r"
		local thresholdProfit = YELLOW .. TSM.db.profile.maxProfitThreshold .. "|r"
		results[4] = string.format(text, maxGold, thresholdProfit)
		if TSM.db.profile.queueProfitMethod == "gold" then
			local dText = L("Clicking on the button below will add all enchants with a profit of at least %s gold to the " ..
				"craft queue. Enough will be added to the queue in order to restock you to a total of %s of each scroll. " ..
				"These values can be changed in the options.")
			local minProfit = YELLOW .. TSM.db.profile.queueMinProfitGold .. "|r"
			local restock = YELLOW .. TSM.db.profile.restockMax .. "|r"
			results[5] = string.format(dText, minProfit, restock)
		elseif TSM.db.profile.queueProfitMethod == "percent" then
			local dText = L("Clicking on the button below will add all enchants with a profit of at least %s percent of the cost to the " ..
				"craft queue. Enough will be added to the queue in order to restock you to a total of %s of each scroll. " ..
				"These values can be changed in the options.")
			local minProfit = YELLOW .. TSM.db.profile.queueMinProfitPercent*100 .. "|r"
			local restock = YELLOW .. TSM.db.profile.restockMax .. "|r"
			results[5] = string.format(dText, minProfit, restock)
		elseif TSM.db.profile.queueProfitMethod == "both" then
			local dText = L("Clicking on the button below will add all enchants with a profit of at least %s gold and atleast %s percent of the cost to the " ..
				"craft queue. Enough will be added to the queue in order to restock you to a total of %s of each scroll. " ..
				"These values can be changed in the options.")
			local minProfitGold = YELLOW .. TSM.db.profile.queueMinProfitGold .. "|r"
			local minProfitPercent = YELLOW .. TSM.db.profile.queueMinProfitPercent*100 .. "|r"
			local restock = YELLOW .. TSM.db.profile.restockMax .. "|r"
			results[5] = string.format(dText, minProfitGold, minProfitPercent, restock)
		else
			local dText = L("Clicking on the button below will add enough of every enchant to the craft queue in order to " .. 
				"restock you to a total of %s of each scroll. These values can be changed in the options.")
			local restock = YELLOW .. TSM.db.profile.restockMax .. "|r"
			results[5] = string.format(dText, restock)
		end
		
		-- format some colored strings to go on this page
		local scrollT = "|r" .. BLUE .. TSM.db.factionrealm.ScanStatus.scrolls .. "|r" .. CYAN
		local matT = "|r" .. BLUE .. TSM.db.factionrealm.ScanStatus.mats .. "|r" .. CYAN
		local chantText = {
			string.format(L("%sScroll scan last run at %s local time.%s"), CYAN, scrollT, "|r"),
			CYAN .. L("Scroll scan has not been run yet this session. " ..
				"As a result, the lowest buyouts and profits will not be shown within the 'Enchants' pages.") .. "|r",
			string.format(L("%sMaterial scan last run at %s local time.%s"), CYAN, matT, "|r"),
			CYAN .. L("Material scan has not been run yet this session.") .. "|r",
			CYAN .. L("Material scanning has been disabled in the options.") .. "|r"
		}
		if TSM.db.factionrealm.ScanStatus.scrolls then
			results[7] = chantText[1] .. "\n"
		else
			results[7] = chantText[2] .. "\n"
		end
		
		if TSM.db.factionrealm.ScanStatus.mats then
			results[6] = chantText[3] .. "\n"
		else
			if TSM.db.profile.matScan then
				results[6] = chantText[4] .. "\n"
			else
				results[6] = chantText[5] .. "\n"
			end
		end
		
		return results[num]
	end
	
	
	local page = {
		{
			type = "ScrollFrame",
			layout = "List",
			children = {
				{
					type = "Label",
					text = "TradeSkill Master v" .. TSM.version .. " " .. L("Status") .. ":\n",
					fontObject = GameFontNormalHuge,
					fullWidth = true,
					colorRed = 255,
					colorGreen = 0,
					colorBlue = 0,
				},
				{
					type = "Label",
					text = GetVars(7),
					fontObject = GameFontNormalLarge,
					fullWidth = true,
				},
				{
					type = "Label",
					text = GetVars(6),
					fontObject = GameFontNormalLarge,
					fullWidth = true,
				},
				{
					type = "Label",
					text = CYAN .. L("Use the links on the left to select which page to show.") .. "|r",
					fontObject = GameFontNormalLarge,
					fullWidth = true,
				},
				{
					type = "Spacer",
					quantity = 3,
				},
				{ 	-- inlinegroup to contain the auto-build craft queue feature
					type = "InlineGroup",
					layout = "flow",
					title = L("Queue Enchants Automatically"),
					fullWidth = true,
					children = {
						{
							type = "Label",
							text = GetVars(5),
							fontObject = GameFontNormal,
							fullWidth = true,
						},
						{
							type = "Spacer",
							quantity = 1,
						},
						{	-- button to build the craft queue based on the options
							type = "Button",
							text = L("Build Craft Queue"),
							relativeWidth = 1,
							callback = function(self)
									TSM.Data:UpdateInventoryInfo("scrolls")
									for itemID, data in pairs(TSM.Data[TSM.mode].crafts) do
										local inventoryNum = TSM.Data.inventory[itemID] or 0
										local auctionNum = data.posted or 0
										local dataStoreNum = 0
										if TSM.db.profile.useDSQueue and DataStore then
											auctionNum = 0
											dataStoreNum = TSM:DSGetNum(itemID)
											for _, character in pairs(DataStore:GetCharacters()) do
												local lastVisit = (DataStore:GetAuctionHouseLastVisit(character) or 1/0) - time()
												if lastVisit < 48*60*60 then
													dataStoreNum = dataStoreNum + DataStore:GetAuctionHouseItemCount(character, itemID)
												end
											end
										end
										if not TSM.db.profile.restockAH then auctionNum = 0 end
										local numHave = inventoryNum + auctionNum + dataStoreNum
										
										if TSM.db.profile.queueProfitMethod == "none" then
											data.queued = TSM.db.profile.restockMax - numHave
										elseif TSM.db.profile.queueProfitMethod == "percent" then
											local profit = select(3, TSM.Data:CalcPrices(data))
											local minProfit = TSM.db.profile.queueMinProfitPercent
											minProfit = TSM.Data:CalcPrices(data)*minProfit
											if profit and profit >= minProfit then
												data.queued = TSM.db.profile.restockMax - numHave
											else
												data.queued = 0
											end
										elseif TSM.db.profile.queueProfitMethod == "gold" then
											local profit = select(3, TSM.Data:CalcPrices(data))
											local minProfit = TSM.db.profile.queueMinProfitGold
											if profit and profit >= minProfit then
												data.queued = TSM.db.profile.restockMax - numHave
											else
												data.queued = 0
											end
										elseif TSM.db.profile.queueProfitMethod == "both" then
											local profit = select(3, TSM.Data:CalcPrices(data))
											local minProfit = TSM.db.profile.queueMinProfitGold
											local percent = TSM.db.profile.queueMinProfitPercent
											minProfit = minProfit + TSM.Data:CalcPrices(data)*percent
											if profit and profit >= minProfit then
												data.queued = TSM.db.profile.restockMax - numHave
											else
												data.queued = 0
											end
										end
										if data.queued < 0 then data.queued = 0 end
									end
									GUI:UpdateQueue()
									if TSM.db.profile.autoOpenTotals then
										GUI.TreeGroup:SelectByPath(4)
									end
								end,
						},
					},
				},
				{
					type = "Spacer",
					quantity = 1,
				},
				{ 	-- inlinegroup to contain the max profit with X gold feature
					type = "InlineGroup",
					layout = "flow",
					title = L("Queue Maximum Profit for Set Gold Amount"),
					fullWidth = true,
					children = {
						{
							type = "Label",
							text = GetVars(4),
							fontObject = GameFontNormal,
							fullWidth = true,
						},
						{
							type = "Spacer",
							quantity = 1,
						},
						{	-- button to build the craft queue based on the options
							type = "Button",
							text = L("Queue Maximum Profit"),
							relativeWidth = 1,
							callback = function(self)
									sort(TSM.Data[TSM.mode].crafts, function(a, b)
											local defaultValue
											if TSM.db.profile.showUnknownProfit then defaultValue = 1/0 else defaultValue = 0 end
											local acost = TSM.Data:CalcPrices(a)
											local bcost = TSM.Data:CalcPrices(a)
											local aprofit = select(3, TSM.Data:CalcPrices(a)) or defaultValue
											local bprofit = select(3, TSM.Data:CalcPrices(b)) or defaultValue
											return ((aprofit/acost)>(bprofit/bcost))
										end)
									local totalCost = 0
									for itemID, data in pairs(TSM.Data[TSM.mode].crafts) do
										local cost, _, profit = TSM.Data:CalcPrices(data)
										if profit and (profit < TSM.db.profile.maxProfitThreshold) then break end
										if profit and cost < (TSM.db.profile.maxProfitGold - totalCost) then
											data.queued = 1
											totalCost = totalCost + cost
										else
											data.queued = 0
										end
									end
									GUI:UpdateQueue()
									if TSM.db.profile.autoOpenTotals2 then
										GUI.TreeGroup:SelectByPath(4)
									end
								end,
						},
					},
				},
				{
					type = "Spacer",
					quantity = 1,
				},
				{ 	-- inlinegroup to contain the craft queue buttons / text
					type = "InlineGroup",
					layout = "flow",
					title = L("Craft Queue"),
					fullWidth = true,
					children = {
						{	 -- creates the "Show Queue" button
							type = "Button",
							text = L("Show Queue"),
							width = 200,
							disabled = GetVars(3),
							callback = function(self)
									local siblings = self.parent.children --aw how cute...siblings ;)
									for i, v in pairs(siblings) do
										if v == self then
											siblings[i+1]:SetDisabled(false)
										end
									end
									TSM.Enchanting:OpenFrame()
								end,
						},
						{ 	-- creates the "Reset Craft Queue" button
							type = "Button",
							text = L("Reset Craft Queue"),
							width = 200,
							disabled = GetVars(2),
							callback = function() TSM.Data:ResetData() end,
						},
						{
							type = "Spacer",
							quantity = 1,
						},
						{	-- warning text if the craft queue is empty or the player isn't an enchanter
							type = "Label",
							text = GetVars(1),
							fontObject = GameFontNormal,
							fullWidth = true,
						}
					},
				},
			},
		},
	}
	
	GUI:BuildPage(container, page)
end

function GUI:DrawMainEnchant(container)
	-- sort the table by profit if that option is selected
	sort(TSM.Data[TSM.mode].crafts, function(a, b)
			local defaultValue
			if TSM.db.profile.showUnknownProfit then defaultValue = 1/0 else defaultValue = 0 end
			local aprofit = select(3, TSM.Data:CalcPrices(a)) or defaultValue
			local bprofit = select(3, TSM.Data:CalcPrices(b)) or defaultValue
			return (aprofit>bprofit)
		end)
			
	local tabText = {
		CYAN .. L("Links (clickable)") .. ":|r    ",
		L("How many of this scroll would you like to craft?") .. "   ",
		L("Craft:") .. "   "
	}

	TSM.Data:UpdateInventoryInfo("scrolls")
	
	local page = {
		{
			type = "ScrollFrame",
			layout = "List",
			children = {},
		},
	}
	
	local playerName = UnitName("Player")

	-- Creates the widgets for the tab
	-- loops once for every enchant contained in the tab
	for itemID, data in pairs(TSM.Data[TSM.mode].crafts) do
		local eProfit = select(3, TSM.Data:CalcPrices(data))
		if TSM.db.profile.showUnknownProfit and not eProfit then eProfit = 1/0 end
		local profitThreshold = TSM.db.profile.mainMinProfit
		if TSM.db.profile.mainProfitMethod == "percent" then
			profitThreshold = profitThreshold*TSM.Data:CalcPrices(data)
		end
		if eProfit and eProfit > profitThreshold then
			-- a container for each enchant (the box / title)
			local numCrafted = YELLOW .. (TSM.db.profile.craftHistory[data.spellID] or "0") .. "|r" .. WHITE
			local titleText = WHITE .. "(" .. L("%s crafted to date") .. ")|r"
			tinsert(page[1].children, {
					type = "InlineGroup",
					layout = "flow",
					title = GetSpellInfo(data.spellID),
					fullWidth = true,
				})
			
			-- local variable to store the parent table (the InlineGroup we just created) to add children widgets to
			page[1].children[#(page[1].children)].children = {}
			local inline = page[1].children[#(page[1].children)].children
			
			if TSM.db.profile.ShowLinks then
				-- row of links for the InlineGroups
				local inlineChildren = {
					{
						type = "Label",
						text = tabText[1],
						fontObject = GameFontNormal,
						width = 120,
					},
					{
						type = "InteractiveLabel",
						text = BLUE .. "[" .. L("Enchant") .. ")|r",
						fontObject = GameFontNormal,
						width = 80,
						callback = function() SetItemRef("spell:".. data.spellID) end,
					},
					{
						type = "InteractiveLabel",
						text = BLUE .. "[" .. L("Scroll") .. ")|r",
						fontObject = GameFontNormal,
						width = 110,
						callback = function() SetItemRef("item:".. itemID, itemID) end,
					},
					{
						type = "Label",
						text = string.format(titleText, numCrafted),
						fontObject = GameFontNormal,
						width = 140,
					},
				}
				foreach(inlineChildren, function(_, data) tinsert(inline, data) end)
			end

			
			--The text below the links of each InlineGroup
			local aNum = data.posted or "???"
			local bNum = TSM.Data.inventory[itemID] or 0
			local cNum = 0
			
			if TSM.db.profile.useDSEnchants and DataStore then
				-- uses DataStore to get the number of scrolls the user's alts have
				cNum = TSM:DSGetNum(itemID)
			else
				-- calculates the total number of scrolls in the bags of the registered alts
				for altNum=1, #(TSM.db.factionrealm.alts) do
					altName = TSM.db.factionrealm.alts[altNum]
					if altName ~= playerName and TSM.db.factionrealm.inventory[altName] then
						local numInAltBags = TSM.db.factionrealm.inventory[altName][itemID] or 0
						cNum = cNum + numInAltBags
					end
				end
			end
			
			-- sets up the colors of the text
			local c1 = GREEN
			local c2 = GREEN
			local c3 = GREEN
			if aNum == "???" then c1 = WHITE
			elseif aNum > 0 then c1 = RED end
			if bNum > 0 then c2 = RED end
			if cNum > 0 then c3 = RED end
			
			local quantityString = string.format(
				"AH/Bags/Alts: %s%s|r/%s%s|r/%s%s|r",
				c1, aNum, c2, bNum, c3, cNum)
			
			-- calculations / widget for printing out the cost, lowest buyout, and profit of the scroll
			local cost, buyout, profit = TSM.Data:CalcPrices(chant)
			if TSM.db.factionrealm.ScanStatus.scrolls then -- make sure we have scan data for scrolls
				if buyout and profit then
					buyout = CYAN .. buyout .. "|r" .. GOLD .. "g|r"
					if profit > 0 then
						profit = GREEN .. profit .. "|r" .. GOLD .. "g|r"
					else
						profit = RED .. profit .. "|r" .. GOLD .. "g|r"
					end
				else
					buyout = CYAN .. L("None on AH") .. "|r"
					profit = CYAN .. "???|r"
				end
			else -- if we don't have scan data for scrolls we can't calculate the profit (or buyout obviously)
				buyout = CYAN .. "???|r"
				profit = CYAN .. "???|r"
			end
			cost = CYAN .. cost .. "|r" .. GOLD .. "g|r"
			local ts = "          " -- tabspace
			
			-- the line that lists the cost, buyout, and profit
			if TSM.db.profile.Layout == 1 then
				local quantityString = string.format(
					L("You have %s%s|r of this scroll on the AH, %s%s|r in your bags, and %s%s|r in your alts' bags."),
					c1, aNum, c2, bNum, c3, cNum)
				local rString = L("Cost to Craft: ") .. cost .. ts .. L("Lowest Buyout on AH: ") ..
					buyout .. ts .. L("Profit: ") .. profit
					
				local inlineChildren = {
					{
						type = "Label",
						text = quantityString,
						fontObject = GameFontWhite,
						fullWidth=true,
					},
					{
						type = "Label",
						text = rString,
						fontObject = GameFontWhite,
						fullWidth=true,
					},
					{
						type = "Label",
						text = L("How many of this scroll would you like to craft?") .. "   ",
						fontObject = GameFontWhite,
						width = 315,
					},
				}
				foreach(inlineChildren, function(_, data) tinsert(inline, data) end)
			elseif TSM.db.profile.Layout == 2 then
				local quantityString = string.format(
					"AH/Bags/Alts: %s%s|r/%s%s|r/%s%s|r",
					c1, aNum, c2, bNum, c3, cNum)
				local rString = "Profit(Cost): " .. profit .. "(" .. cost .. ")"
				local text = quantityString .. "  " .. rString .. "  " .. tabText[3]
				
				tinsert(inline, {
						type = "Label",
						text = text,
						fontObject = GameFontWhite,
						width=315,
					})
			end
			
			local inlineChildren = {
				{	-- editbox for the player to input how many they'd like to make
					type = "EditBox",
					value = data.queued or 0,
					width = 60,
					callback = function(self,_,value)
							value = tonumber(value)
							if value and (floor(value) == value) and (value < 100) then
								data.queued = floor(tonumber(value)+0.5)
							else
								self:SetText(0)
							end
							GUI:UpdateQueue()
						end,
				},
				{	-- plus sign for incrementing the number of an enchant in the craft queue
					type = "Button",
					text = "+",
					width = 40,
					callback = function(self)
							if data.queued ~= 99 then
								data.queued = data.queued + 1
								local siblings = self.parent.children --aw how cute...siblings ;)
								for i, v in pairs(siblings) do
									if v == self then
										siblings[i-1]:SetText(data.queued)
									end
								end
								GUI:UpdateQueue()
							end
						end
				},
				{	-- minus sign for decrementing the number of an enchant in the craft queue
					type = "Button",
					text = "-",
					width = 40,
					callback = function(self)
							if data.queued ~= 0 then
								data.queued = data.queued - 1
								local siblings = self.parent.children --aw how cute...siblings ;)
								for i, v in pairs(siblings) do
									if v == self then
										siblings[i-2]:SetText(data.queued)
									end
								end
								GUI:UpdateQueue()
							end
						end
				},
			}
			foreach(inlineChildren, function(_, data) tinsert(inline, data) end)
		end
	end
	
	GUI:BuildPage(container, page)
end

-- Enchant sub-pages
function GUI:DrawSubEnchant(container, slot)
	-- sort the table by profit if that option is selected
	if TSM.db.profile.SortEnchants then
		sort(TSM.Data[TSM.mode].crafts, function(a, b)
			local aprofit = select(3, TSM.Data:CalcPrices(a)) or 1/0
			local bprofit = select(3, TSM.Data:CalcPrices(b)) or 1/0
			return (aprofit>bprofit)
		end)
	else -- otherwise, sort by spellID
		sort(TSM.Data[TSM.mode].crafts, function(a, b) return a.spellID>b.spellID end)
	end
			
	local tabText = {
		CYAN .. L("Links (clickable)") .. ":|r    ",
		L("How many of this scroll would you like to craft?") .. "   ",
		L("Craft:") .. "   "
	}

	TSM.Data:UpdateInventoryInfo("scrolls")
	
	local page = {
		{
			type = "ScrollFrame",
			layout = "List",
			children = {},
		},
	}

	-- Creates the widgets for the tab
	-- loops once for every enchant contained in the tab
	for itemID, data in pairs(TSM.Data[TSM.mode].crafts) do
		if data.group == slot then
			-- a container for each enchant (the box / title)
			local numCrafted = YELLOW .. (TSM.db.profile.craftHistory[data.spellID] or 0) .. "|r" .. WHITE
			local titleText = WHITE .. " (" .. L("%s crafted to date") .. ")|r"
			tinsert(page[1].children, {
					type = "InlineGroup",
					layout = "flow",
					title = GetSpellInfo(data.spellID),
					fullWidth = true,
				})
			
			-- local variable to store the parent table (the InlineGroup we just created) to add children widgets to
			page[1].children[#(page[1].children)].children = {}
			local inline = page[1].children[#(page[1].children)].children
			
			if TSM.db.profile.ShowLinks then
				-- row of links for the InlineGroups
				local inlineChildren = {
					{
						type = "Label",
						text = tabText[1],
						fontObject = GameFontNormal,
						width = 120,
					},
					{
						type = "InteractiveLabel",
						text = BLUE .. "[" .. L("Enchant") .. ")|r",
						fontObject = GameFontNormal,
						width = 80,
						callback = function() SetItemRef("spell:".. data.spellID) end,
					},
					{
						type = "InteractiveLabel",
						text = BLUE .. "[" .. L("Scroll") .. ")|r",
						fontObject = GameFontNormal,
						width = 110,
						callback = function() SetItemRef("item:".. itemID, itemID) end,
					},
					{
						type = "Label",
						text = string.format(titleText, numCrafted),
						fontObject = GameFontNormal,
						width = 140,
					},
				}
				foreach(inlineChildren, function(_, data) tinsert(inline, data) end)
			end
			
			--The text below the links of each InlineGroup
			local aNum = 0
			local bNum = TSM.Data.inventory[itemID] or 0
			local cNum = 0
			
			if select(4, GetAddOnInfo("DataStore_Auctions")) then
				for _, character in pairs(DataStore:GetCharacters()) do
					local lastVisit = (DataStore:GetAuctionHouseLastVisit(character) or 1/0) - time()
					if lastVisit < 48*60*60 then
						aNum = aNum + (DataStore:GetAuctionHouseItemCount(character, itemID) or 0)
					end
				end
			else
				aNum = data.posted or "???"
			end
			
			if TSM.db.profile.useDSEnchants and DataStore then
				-- uses DataStore to get the number of scrolls the user's alts have
				cNum = TSM:DSGetNum(itemID)
			else
				-- calculates the total number of scrolls in the bags of the registered alts
				for altNum=1, #(TSM.db.factionrealm.alts) do
					altName = TSM.db.factionrealm.alts[altNum]
					if altName ~= playerName and TSM.db.factionrealm.inventory[altName] then
						local numInAltBags = TSM.db.factionrealm.inventory[altName][itemID] or 0
						cNum = cNum + numInAltBags
					end
				end
			end
			
			-- sets up the colors of the text
			local c1 = GREEN
			local c2 = GREEN
			local c3 = GREEN
			if aNum == "???" then c1 = WHITE
			elseif aNum > 0 then c1 = RED end
			if bNum > 0 then c2 = RED end
			if cNum > 0 then c3 = RED end
			
			local quantityString = string.format(
				"AH/Bags/Alts: %s%s|r/%s%s|r/%s%s|r",
				c1, aNum, c2, bNum, c3, cNum)
			
			-- calculations / widget for printing out the cost, lowest buyout, and profit of the scroll
			local cost, buyout, profit = TSM.Data:CalcPrices(chant)
			if TSM.db.factionrealm.ScanStatus.scrolls then -- make sure we have scan data for scrolls
				if buyout and profit then
					buyout = CYAN .. buyout .. "|r" .. GOLD .. "g|r"
					if profit > 0 then
						profit = GREEN .. profit .. "|r" .. GOLD .. "g|r"
					else
						profit = RED .. profit .. "|r" .. GOLD .. "g|r"
					end
				else
					buyout = CYAN .. L("None on AH") .. "|r"
					profit = CYAN .. "???|r"
				end
			else -- if we don't have scan data for scrolls we can't calculate the profit (or buyout obviously)
				buyout = CYAN .. "???|r"
				profit = CYAN .. "???|r"
			end
			cost = CYAN .. cost .. "|r" .. GOLD .. "g|r"
			local ts = "          " -- tabspace
			
			-- the line that lists the cost, buyout, and profit
			if TSM.db.profile.Layout == 1 then
				local quantityString = string.format(
					L("You have %s%s|r of this scroll on the AH, %s%s|r in your bags, and %s%s|r in your alts' bags."),
					c1, aNum, c2, bNum, c3, cNum)
				local rString = L("Cost to Craft: ") .. cost .. ts .. L("Lowest Buyout on AH: ") ..
					buyout .. ts .. L("Profit: ") .. profit
					
				local inlineChildren = {
					{
						type = "Label",
						text = quantityString,
						fontObject = GameFontWhite,
						fullWidth=true,
					},
					{
						type = "Label",
						text = rString,
						fontObject = GameFontWhite,
						fullWidth=true,
					},
					{
						type = "Label",
						text = L("How many of this scroll would you like to craft?") .. "   ",
						fontObject = GameFontWhite,
						width = 315,
					},
				}
				foreach(inlineChildren, function(_, data) tinsert(inline, data) end)
			elseif TSM.db.profile.Layout == 2 then
				local quantityString = string.format(
					"AH/Bags/Alts: %s%s|r/%s%s|r/%s%s|r",
					c1, aNum, c2, bNum, c3, cNum)
				local rString = "Profit(Cost): " .. profit .. "(" .. cost .. ")"
				local text = quantityString .. "  " .. rString .. "  " .. tabText[3]
				
				tinsert(inline, {
						type = "Label",
						text = text,
						fontObject = GameFontWhite,
						width=315,
					})
			end
			
			local inlineChildren = {
				{	-- editbox for the player to input how many they'd like to make
					type = "EditBox",
					value = data.queued or 0,
					width = 60,
					callback = function(self,_,value)
							value = tonumber(value)
							if value and (floor(value) == value) and (value < 100) then
								data.queued = floor(tonumber(value)+0.5)
							else
								self:SetText(0)
							end
							GUI:UpdateQueue()
						end,
				},
				{	-- plus sign for incrementing the number of an enchant in the craft queue
					type = "Button",
					text = "+",
					width = 40,
					callback = function(self)
							if data.queued ~= 99 then
								data.queued = data.queued + 1
								local siblings = self.parent.children --aw how cute...siblings ;)
								for i, v in pairs(siblings) do
									if v == self then
										siblings[i-1]:SetText(data.queued)
									end
								end
								GUI:UpdateQueue()
							end
						end
				},
				{	-- minus sign for decrementing the number of an enchant in the craft queue
					type = "Button",
					text = "-",
					width = 40,
					callback = function(self)
							if data.queued ~= 0 then
								data.queued = data.queued - 1
								local siblings = self.parent.children --aw how cute...siblings ;)
								for i, v in pairs(siblings) do
									if v == self then
										siblings[i-2]:SetText(data.queued)
									end
								end
								GUI:UpdateQueue()
							end
						end
				},
			}
			foreach(inlineChildren, function(_, data) tinsert(inline, data) end)
		end
	end
	
	-- if all enchants have been hidden for this slot, show a message to alert the user
	if not page[1].children then
		local text = L("You have not added any enchants for this slot. Use the 'Add Enchants' page to " ..
			"add enchants to Scroll Master.")
		tinsert(inline, {
				type = "Label",
				text = text,
				fontObject = GameFontNormal,
				fullWidth=true,
			})
	end
	
	GUI:BuildPage(container, page)
end

-- Materials Page
function GUI:DrawMaterials(container)
	TSM.Scan:Calc("mats")
	local matText = L("Here, you can view and change the material prices. If scanning for materials is enabled "	..
		"in the options, Scroll Master will update these values with the results of the scan. If you lock " .. 
		"the cost of a material it will not be changed by Scroll Master.")
	
	-- scroll frame to contain everything
	local page = {
		{
			type = "ScrollFrame",
			layout = "List",
			children = {
				{
					type = "InlineGroup",
					layout = "flow",
					title = L("Help"),
					fullWidth = true,
					children = {
						{
							type = "Label",
							text = matText,
							fontObject = GameFontWhite,
							fullWidth = true,
						},
					},
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L("Materials"),
					fullWidth = true,
					children = {},
				},
			},
		},
	}

	-- create all the text lables / editboxes for the materials page
	-- this series of for loops and if statements builds the widgets in 2 collums
	-- numbers 1-7 are in the first collum and 8-13 in the second collum
	local matList = TSM.Data:GetMats()
	local inline = page[1].children[2].children
	for num=1, #(matList) do
		tinsert(inline, {
				type = "CheckBox",
				label = L("Lock Cost"),
				width = 100,
				value = TSM.db.profile.matLock[matList[num]],
				callback = function(self, _, value)
						TSM.db.profile.matLock[matList[num]] = value
					end,
			})
	
		-- the editboxes for viewing / changing the cost of the mats.
		tinsert(inline, {
				type = "EditBox",
				value = tostring(TSM.db.factionrealm[matList[num]]),
				relativeWidth = 0.15,
				callback = function(self,_,value)
						value = tonumber(value)
						if value and (value < 1000) then
							TSM.db.factionrealm[matList[num]] = value
						else
							self:SetText(0)
						end
					end,
			})
			
		tinsert(inline, {
				type = "InteractiveLabel",
				text = select(2, GetItemInfo(matList[num])) or TSM:GetName(matList[num]),
				fontObject = GameFontNormal,
				relativeWidth = 0.35,
				callback = function() SetItemRef("item:".. matList[num], matList[num]) end,
			})
		
		tinsert(inline, {
				type = "Spacer",
				quantity = 1,
			})
	end
	
	GUI:BuildPage(container, page)
end

-- Totals / Queue Page
function GUI:DrawTotals(container)
	local matTotals = {}
	local matList = TSM.Data:GetMats()

	-- resets the matTotals to 0
	for i=1, #(matList) do
		matTotals[matList[i]] = 0
	end
	
	-- Goes through every material and every enchant and adds up the matTotals.
	for itemID, data in pairs(TSM.Data[TSM.mode].crafts) do
		if data.queued then -- if the enchant is queued...
			for matItemID, matQuantity in pairs(data.mats) do
				-- for each material, find the corresponding index between 1 and #(matList) of the material in the matList
				-- then add the correct number of that material to the totals table
				for i=1, #(matList) do
					if tonumber(matList[i]) == tonumber(matItemID) then
						matTotals[matList[i]] = matTotals[matList[i]] + matQuantity*data.queued
					end
				end
			end
		end
	end
	
	GUI:RegisterEvent("BAG_UPDATE", function() GUI.TreeGroup:SelectByPath(4) end)
	TSM.Data:UpdateInventoryInfo("mats")
	
	local velNeed = {}
	local extra = {["weapon"]=0, ["armor"]=0}
	for i, id in pairs({43146, 39350, 39349, 43145, 37602, 38682}) do
		local dsInventory = 0
		if TSM.db.profile.useDSTotals and DataStore then dsInventory = TSM:DSGetNum(matList[i]) end
		local numHave = dsInventory + (TSM.Data.inventory[id] or 0)
		local numNeed = 0
		for itemID in pairs(matTotals) do
			if itemID == id then
				numNeed = matTotals[itemID]
			end
		end
		if i > 3 then
			if numHave >= numNeed then
				extra.weapon = extra.weapon + numHave - numNeed
				velNeed[id] = 0
			else
				numExtraNeeded = numNeed - numHave
				if numExtraNeeded <= extra.weapon then
					extra.weapon = extra.weapon - numExtraNeeded
					velNeed[id] = 0
				else
					velNeed[id] = numExtraNeeded - extra.weapon
					extra.weapon = 0
				end
			end
		else
			if numHave >= numNeed then
				debug(id, numHave)
				extra.armor = extra.armor + numHave - numNeed
				velNeed[id] = 0
			else
				numExtraNeeded = numNeed - numHave
				if numExtraNeeded <= extra.armor then
					extra.armor = extra.armor - numExtraNeeded
					velNeed[id] = 0
				else
					velNeed[id] = numExtraNeeded - extra.armor
					extra.armor = 0
				end
			end
		end
	end
	
	extra = {}
	for _, itemID in pairs(matList) do
		local dsInventory = 0
		if TSM.db.profile.useDSTotals and DataStore then dsInventory = TSM:DSGetNum(itemID) end
		local numHave = dsInventory + (TSM.Data.inventory[id] or 0)
		local numNeed = 0
		for ID in pairs(matTotals) do
			if itemID == ID then
				numNeed = matTotals[ID]
			end
		end
		if TSM.LibEnchant.greaterEssence[itemID] then -- we are on lesser _ essence
			if numHave > numNeed then
				extra[TSM.LibEnchant.greaterEssence[itemID]] = math.floor((numHave - numNeed) / 3)
			end
		elseif TSM.LibEnchant.lesserEssence[itemID] then -- we are on greater _ essence
			if numHave > numNeed then
				extra[TSM.LibEnchant.lesserEssence[itemID]] = (numHave - numNeed) * 3
			end
		end
	end
	for itemID, quantity in pairs(extra) do
		if matTotals[itemID] then
			matTotals[itemID] = matTotals[itemID] + quantity
		end
	end
	
	local wText, rDisabled, sDisabled
	-- enables / disables the 2 Craft Queue buttons depending on the status of the craft queue
	if GUI.queueTotal > 0 then
		-- checks to see if the player is an enchanter (51313 is Grand Master enchanting)
		if TSM.Enchanting:IsEnchanter() then
			sDisabled = false
			wText = ""
		else
			sDisabled = true
			wText = GOLD .. L("Grand Master Enchanting not found! Craft Queue Disabled!") .. "|r"
		end
	else
		wText = GOLD .. L("Your craft queue is empty!") .. "|r"
		rDisabled = true
		sDisabled = true
	end
	
	local page = {
		{	-- scroll frame to contain everything
			type = "ScrollFrame",
			layout = "List",
			children = {
				{ 	-- inline1 - inlinegroup to contain the craft queue buttons / text
					type = "InlineGroup",
					layout = "flow",
					title = L("Craft Queue"),
					fullWidth = true,
					children = {
						{	 -- creates the "Show Queue" button
							type = "Button",
							text = L("Show Queue"),
							width = 200,
							disabled = sDisabled,
							callback = function(self)
									local siblings = self.parent.children --aw how cute...siblings ;)
									for i, v in pairs(siblings) do
										if v == self then
											siblings[i+1]:SetDisabled(false)
										end
									end
									TSM.Enchanting:OpenFrame()
								end,
						},
						{ 	-- creates the "Reset Craft Queue" button
							type = "Button",
							text = L("Reset Craft Queue"),
							width = 200,
							disabled = rDisabled,
							callback = function()
									TSM.Data:ResetData() 
									TSM.GUI.TreeGroup:SelectByPath(4) -- refreshes the page
								end,
						},
						{
							type = "Spacer",
							quantity = 1,
						},
						{	-- warning text if the craft queue is empty or the player isn't an enchanter
							type = "Label",
							text = wText,
							fontObject = GameFontNormal,
							fullWidth = true,
						}
					},
				},
				{
					type = "Spacer",
					quantity = 1,
				},
				{ 	-- inline2 - inlinegroup to contain the totals
					type = "InlineGroup",
					layout = "flow",
					title = L("Totals"),
					fullWidth = true,
					children = {},
				},
			},
		},
	}
	
	local inline2 = page[1].children[3]
	
	if TSM.db.profile.useDSTotals and DataStore then
		if TSM.db.profile.advDSTotals then
			tinsert(inline2.children, {
					type = "Label",
					text = L("Extra data from DataStore is being shown according to the following format:"),
					fontObject = GameFontNormal,
					fullWidth = true,
				})
			tinsert(inline2.children, {
					type = "Spacer",
					quantity = 1,
				})
		
			local cText = YELLOW .. "C|r"
			local aText = YELLOW .. "A|r"
			local gbText = YELLOW .. "GB|r"
			local nText = YELLOW .. "##|r"
			local nText2 = YELLOW .. "##|r\n"
			tinsert(inline2.children, {
					type = "Label",
					text = string.format(L("Material Name (clickable link)           Have:[%s][%s][%s]  " ..
						"Need:%s  Total:%s (%s = This character's bags and bank; %s = Alts bags and " ..
						"banks; %s = Guild Banks)"), cText, aText, gbText, nText, nText2, cText, aText, gbText),
					fontObject = GameFontNormal,
					fullWidth = true,
				})
			tinsert(inline2.children, {
					type = "HeadingLine",
				})
		else
			tinsert(inline2.children, {
					type = "Label",
					text = L("The number you need accounts for how many you have on alts through DataStore. " ..
						"You can turn this off in the 'External Settings' page."),
					fontObject = GameFontNormal,
					fullWidth = true,
				})
			tinsert(inline2.children, {
					type = "HeadingLine",
				})
		end
	end
	
	local totalGold = 0
	-- create all the text labels to display the matTotals
	for i=1, #(matList) do
		if matTotals[matList[i]] > 0 then
			local c1 = RED
			local c3 = GOLD
			local dsInventory = 0
			if TSM.db.profile.useDSTotals and DataStore then dsInventory = TSM:DSGetNum(matList[i]) end
			local nameText = select(2, GetItemInfo(matList[i])) or TSM:GetName(matList[i])
			local need = matTotals[matList[i]] - (TSM.Data.inventory[matList[i]] or 0) - dsInventory
			if need <= 0 then
				need = 0
				c1 = GREEN
			end
			local txt1 = "|r" .. c3 .. need .. "|r" .. c1
			local txt2 = "|r" .. c3 .. matTotals[matList[i]] .. "|r" .. c1
			local needText = string.format(L("%sYou need %s out of %s."), c1, txt1, txt2)
			totalGold = totalGold + need*TSM.db.factionrealm[matList[i]]
			
			tinsert(inline2.children, {
						type = "InteractiveLabel",
						text = nameText,
						fontObject = GameFontNormal,
						width = 220,
						callback = function() SetItemRef("item:".. matList[i], matList[i]) end,
					})
			
			if DataStore and TSM.db.profile.useDSTotals and TSM.db.profile.advDSTotals then
				local itemID = matList[i]
				local cCount, aCount, gbCount = 0, 0, 0
				for characterName, character in pairs(DataStore:GetCharacters()) do
					local bagCount, bankCount = DataStore:GetContainerItemCount(character, itemID)
					if TSM.db.profile.useDSBags and DataStore and TSM.db.profile.DSCharacters[characterName] then
						if characterName ~= UnitName("Player") then
							aCount = aCount + bagCount
						end
					end
					if TSM.db.profile.useDSBanks and DataStore and TSM.db.profile.DSCharacters[characterName] then
						if characterName == UnitName("Player") then
							cCount = cCount + bankCount
						else
							aCount = aCount + bankCount
						end
					end
				end
				for guildName, guild in pairs(DataStore:GetGuilds()) do
					if TSM.db.profile.useDSGuildBanks and DataStore and TSM.db.profile.DSGuilds[guildName] then
						local itemCount = DataStore:GetGuildBankItemCount(guild, itemID)
						gbCount = gbCount + itemCount
					end
				end
				
				
				local cText = YELLOW .. (TSM.Data.inventory[matList[i]] or 0) + cCount .. "|r"
				local aText = YELLOW .. aCount .. "|r"
				local gbText = YELLOW .. gbCount .. "|r"
				local infoText = L("%sHave:%s[%s][%s][%s]   %sNeed:%s   Total:%s")
				infoText = string.format(infoText, c1, "|r", cText, aText, gbText, c1, txt1, txt2)
				tinsert(inline2.children, {
						type = "Label",
						text = infoText,
						fontObject = GameFontNormal,
						width = 270,
					})
			else
				tinsert(inline2.children, {
						type = "Label",
						text = needText,
						fontObject = GameFontNormal,
						width = 200,
					})
			end
			
			if i < #(matList) then 
				tinsert(inline2.children, {
						type = "Spacer",
						quantity = 1,
					})
			end
		end
	end
	
	local gText = L("Estimate cost of all materials you do not have: ") ..
		CYAN .. totalGold .. "|r" .. GOLD .. "g|r"
	
	tinsert(inline2.children, 1, {
			type = "Label",
			text = gText,
			fontObject = GameFontNormal,
			fullWidth = true,
		})
	tinsert(inline2.children, 2, {
			type = "HeadingLine",
		})
	
	GUI:BuildPage(container, page)
end

-- Options Page
function GUI:DrawOptions(container)
	-- code to deal with a particular change with v4.2
	-- will be removed in future releases
	if TSM.db.profile.queueMinProfit then
		if TSM.db.profile.queueProfitMethod == "gold" then
			TSM.db.profile.queueMinProfitGold = TSM.db.profile.queueMinProfit 
		elseif TSM.db.profile.queueProfitMethod == "percent" then
			TSM.db.profile.queueMinProfitPercent = TSM.db.profile.queueMinProfit
		end
		TSM.db.profile.queueMinProfit = nil
	end

	local tg = AceGUI:Create("TabGroup")
	tg:SetLayout("Fill")
	tg:SetFullHeight(true)
	tg:SetFullWidth(true)
	tg:SetTabs({{value = 1, text = L("General")}, {value = 2, text = L("Data")}, 
		{value = 3, text = L("Status Page")}, {value = 4, text = L("Profiles")},
		{value = 5, text = L("Add Enchants")}, {value = 6, text = L("Remove Enchants")}})
	container:AddChild(tg)
	tg.Add = GUI.AddGUIElement

	local optionsText = L("If you add the names of your alts below, Scroll Master will include any auctions" ..
		" by them as your own auctions and include their inventory in the 'Enchants' summaries. " ..
		"Note: You must enter the names before you scan.")
	local ddList1 = {["smart"]=L("Smart Average (recommended)"), ["lowest"]=L("Lowest Buyout"),
		["user"]=L("Manual Entry")}
	if select(4, GetAddOnInfo("Auc-Advanced")) then ddList1["auc"] = "Auctioneer" end
	local DDValue = 0 --value of the dropdown list
	local ddList2
	if #(TSM.db.factionrealm.alts) == 0 then
		ddList2 = {L("<No Alts Stored>")}
	else
		ddList2 = TSM.db.factionrealm.alts
	end
	
	local function GetProfitSliderValues(sliderNum)
		local profitText = {}
		
		if sliderNum == 1 then
			profitText = {
				L("Lowest Profit for Main 'Enchants' Page (% of profit)"),
				L("The main enchants page will display any enchant with a profit over this percent of the cost. " ..
					"For example, if the slider is set to 50, and an enchant cost 100g to make, it would only be shown " ..
					"if the profit were 50g or higher."),
				L("Lowest Profit for Main 'Enchants' Page (in gold)"),
				L("The main enchants page will display any enchants with a profit over " ..
					"this amount of gold. For example, if the slider is set to 30, any enchant with " ..
					"a profit above 30g will be shown in the main 'Enchants' page."),
			}
			if TSM.db.profile.mainProfitMethod == "percent" then
				return profitText[1], profitText[2], 0, 2, 0.01
			else
				return profitText[3], profitText[4], 0, 100, 1
			end
		else
			profitText = {
				L("Minimum Profit (in %)"),
				L("If enabled, any enchant with a profit over this percent of the cost will be added to " ..
					"the craft queue when you use the 'Build Craft Queue' button."),
				L("Minimum Profit (in gold)"),
				L("If enabled, any enchant with a profit over this value will be added to the craft queue " ..
					"when you use the 'Build Craft Queue' button."),
			}
			if TSM.db.profile.queueProfitMethod == "percent" then
				return profitText[1], profitText[2], 0, 2, 0.01
			else
				return profitText[3], profitText[4], 0, 100, 1
			end
		end
	end
	
	local function GetTab(num)
		local page = {}
		page[1] = {
			{	-- scroll frame to contain everything
				type = "ScrollFrame",
				layout = "List",
				children = {
					{ 	-- holds the first group of options (checkboxes + calc mat cost dropdown)
						type = "InlineGroup",
						layout = "flow",
						title = L("General Settings"),
						fullWidth = true,
						children = {
							{	-- option to show / hide minimap icon
								type = "CheckBox",
								value = not TSM.db.profile.minimapIcon.hide,
								label = L("Show Minimap Icon"),
								fullWidth = true,
								callback = function(_,_,value)
										TSM.db.profile.minimapIcon.hide = not value
										if value then TSM.LDBIcon:Show("TradeSkillMaster")
										else TSM.LDBIcon:Hide("TradeSkillMaster") end
									end,
							},
							{	-- option to automatically open TSM's main window when scans complete
								type = "CheckBox",
								value = TSM.db.profile.autoOpenSM,
								label = L("Automatically open Scroll Master when the scan is complete."),
								fullWidth = true,
								callback = function(_,_,value) TSM.db.profile.autoOpenSM = value end,
							},
						},
					},
					{
						type = "Spacer",
						quantity = 1,
					},
					{ 	-- holds the third group of options (layout selection + show links checkbox)
						type = "InlineGroup",
						layout = "flow",
						title = L("Appearance Settings"),
						fullWidth = true,
						children = {
							{	-- option to sort enchants by profit in the enchant sub-pages
								type = "CheckBox",
								value = TSM.db.profile.SortEnchants,
								label = L("Sort Enchants by Profit"),
								fullWidth = true,
								callback = function(_,_,value) TSM.db.profile.SortEnchants = value end,
								tooltip = L("If unchecked, enchants will be sorted by spellID."),
							},
							{	-- option to show / hide enchants with ??? profit in the main enchants page
								type = "CheckBox",
								value = TSM.db.profile.showUnknownProfit,
								label = L("Show enchants with '???' profit in main 'Enchants' page."),
								fullWidth = true,
								callback = function(_,_,value) TSM.db.profile.showUnknownProfit = value end,
							},
							{	-- dropdown to select the method for setting the Minimum profit for the main enchants page
								type = "Dropdown",
								label = L("Minimum Profit Method"),
								list = {["gold"]=L("Gold Amount"), ["percent"]=L("Percent of Cost")},
								value = TSM.db.profile.mainProfitMethod,
								relativeWidth = 0.4,
								callback = function(self,_,value)
										if value == "percent" then
											TSM.db.profile.mainMinProfit = 0.5
										else
											TSM.db.profile.mainMinProfit = 30
										end
										TSM.db.profile.mainProfitMethod = value
										tg:SelectTab(1)
									end,
								tooltip = L("You can select to set the minimum profit for the main 'Enchants' " ..
									"page as either a gold amount or as a percent of the cost of the enchant."),
							},
							{	-- slider to set the lowest profit to be shown in the main "Enchants" page
								type = "Slider",
								value = TSM.db.profile.mainMinProfit,
								label = GetProfitSliderValues(1),
								tooltip = select(2, GetProfitSliderValues(1)),
								min = select(3, GetProfitSliderValues(1)),
								max = select(4, GetProfitSliderValues(1)),
								step = select(5, GetProfitSliderValues(1)),
								isPercent = TSM.db.profile.mainProfitMethod == "percent",
								width = 350,
								callback = function(_,_,value) TSM.db.profile.mainMinProfit = value end,
							},
							{	-- dropdown to select the layout for the enchant sub-pages
								type = "Dropdown",
								label = L("Layout of 'Enchants' Section"),
								list = {"Full", "Simplified"},
								value = TSM.db.profile.Layout,
								relativeWidth = 0.4,
								callback = function(_,_,value) TSM.db.profile.Layout = value end,
							},
							{	-- option to show / hide the links in the enchant sub-pages
								type = "CheckBox",
								value = TSM.db.profile.ShowLinks,
								label = L("Show Links / Number Crafted in Enchants Section of Scroll Master"),
								fullWidth = true,
								callback = function(_,_,value) TSM.db.profile.ShowLinks = value end,
							},
						}
					},
				},
			},
		}
	
		page[2] = {
			{	-- scroll frame to contain everything
				type = "ScrollFrame",
				layout = "List",
				children = {
					{ 	-- holds the second group of options (profit deduction label + slider)
						type = "InlineGroup",
						layout = "flow",
						title = L("Enchant / Scroll Data Settings"),
						fullWidth = true,
						children = {
							{	-- option to include vellums when calculating enchant costs
								type = "CheckBox",
								value = TSM.db.profile.vellums,
								label = L("Include Vellums in Costs"),
								fullWidth = true,
								callback = function(_,_,value) TSM.db.profile.vellums = value end,
								tooltip = L("Checking this will include the cost of vellums when calculating scroll costs."),
							},
							{	-- dropdown to select how to calculate material costs
								type = "Dropdown",
								label = L("Get Mat Prices From:"),
								list = ddList1,
								value = TSM.db.profile.matCostMethod,
								relativeWidth = 0.45,
								callback = function(_,_,value)
										TSM.db.profile.matCostMethod = value
										TSM.Scan:Calc("mats")
									end,
								tooltip = L("This is how Scroll Master will get material prices. Smart Average will " ..
									"use Scroll Master's scan data and average functions to determine the prices " ..
									"(recommneded). Lowest buyout will use Scroll Master's scan data and set mat " ..
									"prices to the lowest buyout for each mat on the AH. You can also manually " ..
									"set mat prices or use Auctioneer (if Auc-Advanced is enabled) for mat " ..
									"prices. Chooseing either Manual or Auctioneer will cause Scroll Master to " ..
									"not scan the AH for mats."),
							},
							{	-- just a spacer to seperate the dropdown from the slider
								type = "Label",
								text = "",
								relativeWidth = 0.09,
							},
							{	-- slider to set the % to deduct from profits
								type = "Slider",
								value = TSM.db.profile.profitPercent,
								label = L("Profit Deduction"),
								isPercent = true,
								min = 0,
								max = 0.25,
								step = 0.01,
								relativeWidth = 0.45,
								callback = function(_,_,value) TSM.db.profile.profitPercent = value end,
								tooltip = L("Percent to subtract from buyout when calculating profits (5% will " ..
									"compensate for AH cut)."),
							},
						}
					},
					{
						type = "Spacer",
						quantity = 1,
					},
					{ 	-- holds the sixth group of options (alt related options)
						type = "InlineGroup",
						layout = "flow",
						title = L("Alternate Character Settings"),
						fullWidth = true,
						children = {
							{	-- label to explain what the slider is for
								type = "Label",
								text = optionsText,
								fontObject = GameFontNormal,
								fullWidth = true,
							},
							{
								type = "HeadingLine"
							},
							{	-- editbox to enter new alts
								type = "EditBox",
								value = "",
								label = L("Add Alt Name"),
								relativeWidth = 0.3,
								callback = function (_,_,value)
										tinsert(TSM.db.factionrealm.alts, value)
										tg:SelectTab(2)
									end,
							},
							{	-- dropdown to select an alt's name to delete
								type = "Dropdown",
								label = L("List of Alt Names Stored"),
								list = ddList2,
								value = DDValue,
								relativeWidth = 0.4,
								callback = function(_,_,value) DDValue = value end,
							},
							{	 -- button to delete the selected alt
								type = "Button",
								text = L("Delete Character"),
								relativeWidth = 0.3,
								callback = function() 
										if DDValue ~= 0 then
											tremove(TSM.db.factionrealm.alts, DDValue)
											tg:SelectTab(2)
										end
									end,
							},
						},
					},
				},
			},
		}
	
		page[3] = {
			{	-- scroll frame to contain everything
				type = "ScrollFrame",
				layout = "List",
				children = {
					{	-- holds the fourth group of options (options related to the Build Craft Queue button)
						type = "InlineGroup",
						layout = "flow",
						title = L("Build Craft Queue Settings"),
						fullWidth = true,
						children = {
							{
								type = "Label",
								text = L("These options control the 'Build Craft Queue' button on the Status page."),
								fontObject = GameFontNormal,
								fullWidth = true,
							},
							{
								type = "HeadingLine",
							},
							{
								type = "CheckBox",
								value = TSM.db.profile.autoOpenTotals,
								label = L("Automatically go to 'Totals / Queue' page after building the craft queue."),
								relativeWidth = 1,
								callback = function(_,_,value) TSM.db.profile.autoOpenTotals = value end,
							},
							{
								type = "CheckBox",
								value = TSM.db.profile.restockAH,
								label = L("Include Scrolls on AH When Restocking"),
								relativeWidth = 1,
								callback = function(_,_,value) TSM.db.profile.restockAH = value end,
								tooltip = L("When you use the Build Craft Queue button, it will queue enough of " ..
									"each enchant so that you will have the desired maximum quantity on hand. If " ..
									"you check this checkbox, anything that you have on the AH as of the last scan " ..
									"will be included in the number you currently have on hand."),
							},
							{	-- dropdown to select the method for setting the Minimum profit for the main enchants page
								type = "Dropdown",
								label = L("Minimum Profit Method"),
								list = {["gold"]=L("Gold Amount"), ["percent"]=L("Percent of Cost"),
									["none"]=L("No Minimum"), ["both"]=L("Percent and Gold Amount")},
								value = TSM.db.profile.queueProfitMethod,
								relativeWidth = 0.49,
								callback = function(self,_,value)
										TSM.db.profile.queueProfitMethod = value
										tg:SelectTab(3)
									end,
								tooltip = L("You can choose to specify a minimum profit amount (in gold or by " ..
									"percent of cost) for what enchants should be added to the craft queue."),
							},
							{	-- slider to set the stock number
								type = "Slider",
								value = TSM.db.profile.restockMax,
								label = L("Maximum Number to Queue"),
								isPercent = false,
								min = 1,
								max = 20,
								step = 1,
								callback = function(_,_,value) TSM.db.profile.restockMax = value end,
								tooltip = L("When you click on the 'Build Craft Queue' button enough of each " ..
									"enchant will be queued so that you have this maximum number on hand. For " ..
									"example, if you have 2 of scroll X on hand and you set this to 4, 2 more " ..
									"will be added to the craft queue."),
							},
							{
								type = "Slider",
								value = TSM.db.profile.queueMinProfitPercent,
								label = L("Minimum Profit (in %)"),
								tooltip = L("If enabled, any enchant with a profit over this percent of the cost will be added to " ..
									"the craft queue when you use the 'Build Craft Queue' button."),
								min = 0,
								max = 2,
								step = 0.01,
								relativeWidth = 0.49,
								isPercent = true,
								disabled = TSM.db.profile.queueProfitMethod == "none" or TSM.db.profile.queueProfitMethod == "gold",
								callback = function(_,_,value)
										TSM.db.profile.queueMinProfitPercent = math.floor(value*100)/100
									end,
							},
							{
								type = "Slider",
								value = TSM.db.profile.queueMinProfitGold,
								label = L("Minimum Profit (in gold)"),
								tooltip = L("If enabled, any enchant with a profit over this value will be added to the craft queue " ..
									"when you use the 'Build Craft Queue' button."),
								min = 0,
								max = 100,
								step = 1,
								relativeWidth = 0.49,
								disabled = TSM.db.profile.queueProfitMethod == "none" or TSM.db.profile.queueProfitMethod == "percent",
								callback = function(_,_,value)
										TSM.db.profile.queueMinProfitGold = math.floor(value)
									end,
							},
						},
					},
					{
						type = "Spacer",
						quantity = 1,
					},
					{	-- holds the fifth group of options (options related to the Queue Maximum Profit button)
						type = "InlineGroup",
						layout = "flow",
						title = L("Queue Maximum Profit Settings"),
						fullWidth = true,
						children = {
							{
								type = "Label",
								text = L("These options control the 'Queue Maximum Profit' button on the Status page."),
								fontObject = GameFontNormal,
								fullWidth = true,
							},
							{
								type = "HeadingLine",
							},
							{
								type = "CheckBox",
								value = TSM.db.profile.autoOpenTotals2,
								label = L("Automatically go to 'Totals / Queue' page after building the craft queue."),
								relativeWidth = 1,
								callback = function(_,_,value) TSM.db.profile.autoOpenTotals2 = value end,
							},
							{	-- slider to set the maximum gold to spend on mats
								type = "Slider",
								value = TSM.db.profile.maxProfitGold,
								label = L("Maximum Total Cost (in gold)"),
								isPercent = false,
								min = 1,
								max = 5000,
								step = 1,
								callback = function(_,_,value) TSM.db.profile.maxProfitGold = value end,
								tooltip = L("When you click on the 'Queue Maximum Profit' button, the " ..
									"most profitable enchants will be added to the craft queue up to " ..
									"this amount of gold in total mat costs."),
							},
							{	-- slider to set the stock number
								type = "Slider",
								value = TSM.db.profile.maxProfitThreshold,
								label = L("Minimum Profit to Include"),
								isPercent = false,
								min = 1,
								max = 100,
								step = 1,
								callback = function(self,_,value) 
										if value < TSM.db.profile.maxProfitGold then
											TSM.db.profile.maxProfitThreshold = value
										else
											self:SetValue(math.floor(TSM.db.profile.maxProfitGold*0.5))
											TSM:Print(L("The Minimum Profit must be lower than the Maxium Total Cost!"))
										end
									end,
								tooltip = L("No enchant below this minimum profit will be added to " ..
									"the craft queue when you hit the 'Queue Maximum Profit' button. " ..
									"This value must be lower than the Maximum Total Cost."),
							},
						},
					},
				},
			},
		}
		return page[num]
	end
	
	local offsets = {}
	local previousTab = 1
	
	tg:SetCallback("OnGroupSelected", function(self,_,value)
			if tg.children and tg.children[1] and tg.children[1].localstatus then
				offsets[previousTab] = tg.children[1].localstatus.offset
			end
			tg:ReleaseChildren()
			if value <= 3 then
				GUI:BuildPage(tg, GetTab(value))
			elseif value == 4 then
				GUI:DrawProfiles(tg)
			elseif value == 5 then
				GUI:DrawAddEnchant(tg)
			elseif value == 6 then
				GUI:DrawRemoveEnchant(tg)
			end
			if tg.children and tg.children[1] and tg.children[1].localstatus then
				tg.children[1].localstatus.offset = (offsets[value] or 0)
			end
			previousTab = value
		end)
	tg:SelectTab(1)
end

-- External Addon Options Page
function GUI:DrawExternal(container)
	local addonList = {auc=L("Not Loaded"), dataStore=L("Not Loaded"), APM3=L("Not Loaded")}
	if select(4, GetAddOnInfo("Auc-Advanced")) then addonList.auc=L("Loaded") end
	if select(4, GetAddOnInfo("AuctionProfitMaster")) then addonList.APM3=L("Loaded") end
	if select(4, GetAddOnInfo("DataStore")) then addonList.dataStore=L("Loaded") end

	
	
	local function GetTab(num)
		local page = {
			{	-- scroll frame to contain everything
				type = "ScrollFrame",
				layout = "List",
				children = {
					{ 	-- inline1 - holds the help text at the top
						type = "InlineGroup",
						layout = "list",
						title = L("General"),
						fullWidth = true,
						children = {
							{	-- label to explain what the slider is for
								type = "Label",
								text = L("On this page you can change the settings Scroll Master uses with " ..
									"interacting with addons that is integrates with."),
								fontObject = GameFontNormal,
								fullWidth = true,
							},
							{
								type = "HeadingLine"
							},
							{	-- label to display whether or not Auc-Advanced is loaded (Auctioneer)
								type = "InteractiveLabel",
								text = YELLOW .. "Auctioneer: |r" .. CYAN .. addonList.auc .. "|r\n",
								fontObject = GameFontNormal,
								fullWidth = true,
								tooltip = L("Scroll Master use Auctioneer's data for material prices. " ..
									"You can select to use Market Price, Appraiser, or Lowest Buyout " ..
									"from Auctioneer."),
							},
							{	-- label to display whether or not APM3 is loaded
								type = "InteractiveLabel",
								text = YELLOW .. "Auction Profit Master 3: |r" .. CYAN .. addonList.APM3 .. "|r\n",
								fontObject = GameFontNormal,
								fullWidth = true,
								tooltip = L("Scroll Master can export its data to APM3's threshold and " ..
									"fallback prices as well as create groups inside of APM3 with the " ..
									"push of a button."),
							},
							{	-- label to display whether or not DataStore is loaded
								type = "InteractiveLabel",
								text = YELLOW .. "DataStore: |r" .. CYAN .. addonList.dataStore .. "|r\n",
								fontObject = GameFontNormal,
								fullWidth = true,
								tooltip = L("Scroll Master can get data from DataStore about what items " ..
									"you have in your alts bags / banks as well as your guild banks."),
							},
						},
					},
					{
						type = "Spacer",
						quantity = 1,
					},
				},
			},
		}
	
		local aucOptions = {
			{	-- scroll frame to contain everything
				type = "ScrollFrame",
				layout = "List",
				children = {
					{
						type = "InlineGroup",
						layout = "flow",
						title = "Auctioneer (Auc-Advanced)",
						fullWidth = true,
						children = {
							{
								type = "Label",
								text = L("You can choose to have Scroll Master use data from Auctioneer for material " ..
									"costs (not scrolls) in the main 'Options' page. Use the dropdown below to select which " ..
									"Auctioneer price to use if Auctioneer is selected in the main 'Options' page."),
								fontObject = GameFontNormal,
								fullWidth = true,
							},
							{
								type = "HeadingLine",
							},
							{
								type = "Dropdown",
								label = L("Auctioneer Price Method"),
								list = {["market"]=L("Market Value"), ["appraiser"]=L("Appraiser Price"), ["minBuyout"]=L("Minimum Buyout")},
								value = TSM.db.profile.aucMethod,
								callback = function(_,_,value) TSM.db.profile.aucMethod = value end,
								tooltip = L("If Auctioneer is selected in the main 'Options' page, this Auctioneer method " ..
									"will be used. The default method is Market Value.")
							},
						},
					},
				},
			},
		}
		
		local APM3Options = {
			{	-- scroll frame to contain everything
				type = "ScrollFrame",
				layout = "List",
				children = {
					{
						type = "InlineGroup",
						layout = "flow",
						title = "Auction Profit Master 3",
						fullWidth = true,
						children = {
							{
								type = "Label",
								text = L("Here, you can set options for exporting to APM3. Hover over each setting for more " ..
									"information."),
								fontObject = GameFontNormal,
								fullWidth = true,
							},
							{
								type = "HeadingLine",
							},
							{	-- slider to set the % to add to enchant costs when exporting
								type = "Slider",
								value = TSM.db.profile.APMIncrease,
								label = L("Percent Increase"),
								isPercent = true,
								min = 0,
								max = 0.25,
								step = 0.01,
								relativeWidth = 0.49,
								callback = function(_,_,value) TSM.db.profile.APMIncrease = value end,
								tooltip = L("The 'Percent Increase' slider is for setting a minimum profit you want to make " ..
									"as a percent. A 5% increase will compensate for AH cut. For example, if it cost 95g to " ..
									"make an item and you sell it for 100g, you will break even after AH cut. Setting an " ..
									"increase of 5% would set the threshold of an item that costs 95g to make to 100g."),
							},
							{	-- slider to set the % to deduct from profits
								type = "Slider",
								value = TSM.db.profile.minThreshold,
								label = L("Minimum Threshold (in gold)"),
								min = 1,
								max = 100,
								step = 1,
								relativeWidth = 0.49,
								callback = function(_,_,value) TSM.db.profile.minThreshold = value end,
								tooltip = L("All thresholds will be set to at least the value of this slider. For example, " ..
									"if the slider is set to 50, anything that costs less than 50g to make will have its " ..
									"threshold set to 50g. Use 1 if you don't want this option applied."),
							},
							{
								type = "HeadingLine",
							},
							{
								type = "CheckBox",
								value = TSM.db.profile.APMFallback>0,
								label = L("Enable Exporting of Fallback Prices"),
								fullWidth = true,
								callback = function(self,_,value)
										local siblings = self.parent.children --aw how cute...siblings ;)
										local slider
										for i, v in pairs(siblings) do
											if v == self then
												slider = siblings[i+1]
											end
										end
										if not value then
											TSM.db.profile.APMFallback = 0
											slider:SetDisabled(true)
										else
											slider:SetDisabled(false)
										end									
									end,
								tooltip = L("Scroll Master can set fallback prices as well as threshold prices when " ..
									"exporting to APM3 if this option is enabled."),
							},
							{	-- slider to set the % to deduct from profits
								type = "Slider",
								value = TSM.db.profile.APMFallback,
								label = L("Set Fallback Prices to a % of Threshold Prices"),
								isPercent = true,
								min = 1.25,
								max = 4,
								step = 0.05,
								width = 350,
								callback = function(_,_,value) TSM.db.profile.APMFallback = value end,
								disabled = (TSM.db.profile.APMFallback == 0),
								tooltip = L("This is the percent of threshold prices that fallbacks will be set to. " ..
									"For example, if the threshold is 50g for an item and this slider is set to 200%, the " ..
									"fallback will be set to 100g."),
							},
						},
					},
				},
			},
		}
		
		local dsCharacters, dsGuilds, dsCharactersValue, dsGuildsValue = {}, {}, {}, {}
		if addonList.dataStore == L("Loaded") then
			if not TSM.db.profile.DSCharacters then
				for name in pairs(DataStore:GetCharacters()) do
					TSM.db.profile.DSCharacters[name] = true
				end
			end
			for name in pairs(DataStore:GetCharacters()) do
				tinsert(dsCharacters, name)
				tinsert(dsCharactersValue, TSM.db.profile.DSCharacters[name])
			end
			
			if not TSM.db.profile.DSGuilds then
				for name in pairs(DataStore:GetGuilds()) do
					TSM.db.profile.DSGuilds[name] = true
				end
			end
			for name in pairs(DataStore:GetGuilds()) do
				tinsert(dsGuilds, name)
				tinsert(dsGuildsValue, TSM.db.profile.DSGuilds[name])
			end
		end
		
		local dsOptions = {
			{	-- scroll frame to contain everything
				type = "ScrollFrame",
				layout = "List",
				children = {
					{
						type = "InlineGroup",
						layout = "flow",
						title = "DataStore",
						fullWidth = true,
						children = {
							{
								type = "Label",
								text = L("Scroll Master can use DataStore_Containers to provide data for a number of different " ..
									"places inside Scroll Master. Use the settings below to set up how you want DataStore used."),
								fontObject = GameFontNormal,
								fullWidth = true,
							},
							{
								type = "HeadingLine",
							},
							{
								type = "CheckBox",
								label = L("Include Bags"),
								value = TSM.db.profile.useDSBags,
								callback = function(self,_,value)
										TSM.db.profile.useDSBags = value
										local siblings = self.parent.children --aw how cute...siblings ;)
										for i, v in pairs(siblings) do
											if v == self then
												siblings[i+4]:SetDisabled(not (TSM.db.profile.useDSBanks or TSM.db.profile.useDSBags))
											end
										end
									end,
								tooltip = L("Includes the bags of all your alts."),
							},
							{
								type = "CheckBox",
								label = L("Include Banks"),
								value = TSM.db.profile.useDSBanks,
								callback = function(self,_,value)
										TSM.db.profile.useDSBanks = value
										local siblings = self.parent.children --aw how cute...siblings ;)
										for i, v in pairs(siblings) do
											if v == self then
												siblings[i+3]:SetDisabled(not (TSM.db.profile.useDSBanks or TSM.db.profile.useDSBags))
											end
										end
									end,
								tooltip = L("Includes the banks of all your alts."),
							},
							{
								type = "CheckBox",
								label = L("Include Guild Banks"),
								value = TSM.db.profile.useDSGuildBanks,
								callback = function(self,_,value)
										TSM.db.profile.useDSGuildBanks = value
										local siblings = self.parent.children --aw how cute...siblings ;)
										for i, v in pairs(siblings) do
											if v == self then
												siblings[i+3]:SetDisabled(not TSM.db.profile.useDSGuildBanks)
											end
										end
									end,
								tooltip = L("Includes the guild banks of all your alts."),
							},
							{
								type = "Spacer",
								quantity = 1,
							},
							{
								type = "Dropdown",
								label = L("Characters to include:"),
								value = dsCharactersValue,
								list = dsCharacters,
								relativeWidth = 0.49,
								multiselect = true,
								disabled = not (TSM.db.profile.useDSBanks or TSM.db.profile.useDSBags),
								callback = function(_,_,key,value)
										TSM.db.profile.DSCharacters[dsCharacters[key]] = value
									end,
							},
							{
								type = "Dropdown",
								label = L("Guilds to include:"),
								value = dsGuildsValue,
								list = dsGuilds,
								relativeWidth = 0.49,
								multiselect = true,
								disabled = not TSM.db.profile.useDSGuildBanks,
								callback = function(_,_,key, value)
										TSM.db.profile.DSGuilds[dsGuilds[key]] = value
									end,
							},
							{
								type = "HeadingLine",
							},
							{
								type = "CheckBox",
								label = L("Use DataStore for the 'Build Craft Queue' button."),
								value = TSM.db.profile.useDSQueue,
								fullWidth = true,
								callback = function(_,_,value) TSM.db.profile.useDSQueue = value end,
								tooltip = L("If checked, Scroll Master will include scrolls on your alts (through datastore) " ..
									"when determining how many of each scroll to queue."),
							},
							{
								type = "CheckBox",
								label = L("Use DataStore when calculating totals."),
								value = TSM.db.profile.useDSTotals,
								fullWidth = true,
								callback = function(self,_,value)
										TSM.db.profile.useDSTotals = value
										local siblings = self.parent.children --aw how cute...siblings ;)
										for i, v in pairs(siblings) do
											if v == self then
												if value then
													siblings[i+2]:SetDisabled(false)
												else
													siblings[i+2]:SetDisabled(true)
												end
											end
										end
									end,
								tooltip = L("If checked, any materials you have on your alts will be subtracted from the " ..
									"number needed."),
							},
							{
								type = "Label",
								text = " ",
								width = 30,
							},
							{
								type = "CheckBox",
								label = L("Use Advanced Totals Page."),
								value = TSM.db.profile.advDSTotals,
								disabled = not TSM.db.profile.useDSTotals,
								relativeWidth = 0.9,
								callback = function(_,_,value) TSM.db.profile.advDSTotals = value end,
								tooltip = L("If checked, the totals page will show additional information obtained from " ..
									"DataStore."),
							},
							{
								type = "CheckBox",
								label = L("Use DataStore on the enchant pages."),
								value = TSM.db.profile.useDSEnchants,
								fullWidth = true,
								callback = function(_,_,value) TSM.db.profile.useDSEnchants = value end,
								tooltip = L("If checked, DataStore will be used to determine how many scrolls you have on " ..
									"your alts to be be shown in the enchant pages."),
							},
						},
					},
				},
			},
		}
		
		local tabs = {page, aucOptions, dsOptions, APM3Options}
		return tabs[num]
	end
		
	local offsets = {}
	local previousTab = 1
	
	local tg = AceGUI:Create("TabGroup")
	tg:SetLayout("Fill")
	tg:SetFullHeight(true)
	tg:SetFullWidth(true)
	tg:SetTabs({{value = 1, text = L("General")},
		{value = 2, text = "Auctioneer (Auc-Advanced)", disabled = (addonList.auc ~= L("Loaded"))}, 
		{value = 3, text = "DataStore", disabled = (addonList.dataStore ~= L("Loaded"))},
		{value = 4, text = "Auction Profit Master 3", disabled = (addonList.APM3 ~= L("Loaded"))}})
	container:AddChild(tg)
	tg.Add = GUI.AddGUIElement
	tg:SetCallback("OnGroupSelected", function(_,_,value)
			if tg.children and tg.children[1] and tg.children[1].localstatus then
				offsets[previousTab] = tg.children[1].localstatus.offset
			end
			tg:ReleaseChildren()
			GUI:BuildPage(tg, GetTab(value))
			tg.children[1].localstatus.offset = offsets[value]
			previousTab = value
		end)
	tg:SelectTab(1)
end

-- profiles page
function GUI:DrawProfiles(container)
	local text = {
		default = L("Default"),
		intro = L("You can change the active database profile, so you can have different settings for every character."),
		reset_desc = L("Reset the current profile back to its default values, in case your configuration is broken, or you simply want to start over."),
		reset = L("Reset Profile"),
		choose_desc = L("You can either create a new profile by entering a name in the editbox, or choose one of the already exisiting profiles."),
		new = L("New"),
		new_sub = L("Create a new empty profile."),
		choose = L("Existing Profiles"),
		copy_desc = L("Copy the settings from one existing profile into the currently active profile."),
		copy = L("Copy From"),
		delete_desc = L("Delete existing and unused profiles from the database to save space, and cleanup the SavedVariables file."),
		delete = L("Delete a Profile"),
		profiles = L("Profiles"),
		current = L("Current Profile: ") .. CYAN .. TSM.db:GetCurrentProfile() .. "|r",
	}
	
	-- Returns a list of all the current profiles with common and nocurrent modifiers.
	-- This code taken from AceDBOptions-3.0.lua
	local function GetProfileList(db, common, nocurrent)
		local profiles = {}
		local tmpprofiles = {}
		local defaultProfiles = {["Default"] = "Default"}
		
		-- copy existing profiles into the table
		local currentProfile = db:GetCurrentProfile()
		for i,v in pairs(db:GetProfiles(tmpprofiles)) do 
			if not (nocurrent and v == currentProfile) then 
				profiles[v] = v 
			end 
		end
		
		-- add our default profiles to choose from ( or rename existing profiles)
		for k,v in pairs(defaultProfiles) do
			if (common or profiles[k]) and not (nocurrent and k == currentProfile) then
				profiles[k] = v
			end
		end
		
		return profiles
	end
	
	local page = {
		{	-- scroll frame to contain everything
			type = "ScrollFrame",
			layout = "List",
			children = {
				{
					type = "Label",
					text = "TradeSkill Master" .. "\n",
					fontObject = GameFontNormalLarge,
					fullWidth = true,
					colorRed = 255,
					colorGreen = 0,
					colorBlue = 0,
				},
				{
					type = "Label",
					text = text["intro"] .. "\n" .. "\n",
					fontObject = GameFontNormal,
					fullWidth = true,
				},
				{
					type = "Label",
					text = text["reset_desc"],
					fontObject = GameFontNormal,
					fullWidth = true,
				},
				{	--simplegroup1 for the reset button / current profile text
					type = "SimpleGroup",
					layout = "flow",
					fullWidth = true,
					children = {
						{
							type = "Button",
							text = text["reset"],
							callback = function() TSM.db:ResetProfile() end,
						},
						{
							type = "Label",
							text = text["current"],
							fontObject = GameFontNormal,
						},
					},
				},
				{
					type = "Spacer",
					quantity = 2,
				},
				{
					type = "Label",
					text = text["choose_desc"],
					fontObject = GameFontNormal,
					fullWidth = true,
				},
				{	--simplegroup2 for the new editbox / existing profiles dropdown
					type = "SimpleGroup",
					layout = "flow",
					fullWidth = true,
					children = {
						{
							type = "EditBox",
							label = text["new"],
							value = "",
							callback = function(_,_,value) 
									TSM.db:SetProfile(value)
									tg:SelectTab(4)
								end,
						},
						{
							type = "Dropdown",
							label = text["choose"],
							list = GetProfileList(TSM.db, true, nil),
							value = TSM.db:GetCurrentProfile(),
							callback = function(_,_,value)
									if value ~= TSM.db:GetCurrentProfile() then
										TSM.db:SetProfile(value)
										tg:SelectTab(4)
									end
								end,
						},
					},
				},
				{
					type = "Spacer",
					quantity = 1,
				},
				{
					type = "Label",
					text = text["copy_desc"],
					fontObject = GameFontNormal,
					fullWidth = true,
				},
				{
					type = "Dropdown",
					label = text["copy"],
					list = GetProfileList(TSM.db, true, nil),
					value = "",
					disabled = not GetProfileList(TSM.db, true, nil) and true,
					callback = function(_,_,value)
							if value ~= TSM.db:GetCurrentProfile() then
								TSM.db:CopyProfile(value)
								tg:SelectTab(4)
							end
						end,
				},
				{
					type = "Spacer",
					quantity = 2,
				},
				{
					type = "Label",
					text = text["delete_desc"],
					fontObject = GameFontNormal,
					fullWidth = true,
				},
				{
					type = "Dropdown",
					label = text["delete"],
					list = GetProfileList(TSM.db, true, nil),
					value = "",
					disabled = not GetProfileList(TSM.db, true, nil) and true,
					callback = function(_,_,value)
							StaticPopupDialogs["TSM.DeleteConfirm"].OnAccept = function()
									TSM.db:DeleteProfile(value)
									tg:SelectTab(4)
								end
							StaticPopup_Show("TSM.DeleteConfirm")
						end,
				},
			},
		},
	}
	
	GUI:BuildPage(container, page)
end

-- page for adding enchants	
function GUI:DrawAddEnchant(container)	
	if select(4, GetAddOnInfo("Skillet")) then -- TSM's 'Add Enchant' page doesn't work with Skillet :(
		local page = {
			{
				type = "ScrollFrame",
				layout = "flow",
				children = {
					{	-- label to warn that TSM doesn't work with skillet
						type = "Label",
						text = L("This part of Scroll Master is not compatible with Skillet. You must disable Skillet while adding new enchants to Scroll Master."),
						fontObject = GameFontNormal,
						fullWidth = true,
						colorRed = 0,
						colorGreen = 206,
						colorBlue = 209,
					},
				},
			},
		}
		return GUI:BuildPage(container, page)
	elseif not TSM.Enchanting:IsEnchanter() then -- they aren't an enchanter so don't load this page
		local page = {
			{
				type = "ScrollFrame",
				layout = "flow",
				children = {
					{	-- label to warn that enchanting was not found
						type = "Label",
						text = L("Enchanting was not found so this page has not been loaded."),
						fontObject = GameFontNormal,
						fullWidth = true,
						colorRed = 0,
						colorGreen = 206,
						colorBlue = 209,
					},
				},
			},
		}
		return GUI:BuildPage(container, page)
	end

	local enchantsTemp = {{},{},{},{},{},{},{},{},{}}
	local matsTemp = {}
	
	local function nextFunc()
		local numSkills = GetNumTradeSkills()
		local alreadyHave = {}
		if TSM.Data[TSM.mode] then
			for _, data in pairs(TSM.Data[TSM.mode].crafts) do
				alreadyHave[data.spellID] = true
			end
		end
		for index=2, numSkills do
			local dataTemp = {mats={}, itemID=nil, spellID=nil, queued=0, posted=nil, sell=nil, group=nil}
			dataTemp.spellID = GUI:GetID(GetTradeSkillItemLink(index)) or 0
			if not alreadyHave[dataTemp.spellID] then
				local itemID = TSM.LibEnchant.itemID[tonumber(dataTemp.spellID)]
				local slot = TSM.LibEnchant.slot[itemID]
				if slot and itemID then
					dataTemp.group = slot
					if TSM.mode == "Enchanting" then
						dataTemp.mats[VELLUM_ID] = 1
					end
					
					local valid = true
					
					-- loop over every material for the selected enchant and gather itemIDs and quantities for the mats
					for i=1, GetTradeSkillNumReagents(index) do
						local link = GetTradeSkillReagentItemLink(index, i)
						local matID = GUI:GetID(link)
						if not matID then
							valid = false
							break
						end
						local name, _, quantity = GetTradeSkillReagentInfo(index, i)
						dataTemp.mats[matID] = quantity
						matsTemp[matID] = {name = name, cost = 5}
					end
					dataTemp.itemID = itemID
					if valid then tinsert(enchantsTemp[slot], dataTemp) end
				end
			end
		end
		CloseTradeSkill()
			
		local page = {
			{	-- scroll frame to contain everything
				type = "ScrollFrame",
				layout = "flow",
				children = {
					{
						type = "InlineGroup",
						layout = "flow",
						title = L("Help"),
						fullWidth = true,
						children = {
							{	-- label at the top of the page
								type = "Label",
								text = L("Use the 'Add' buttons below to add enchants to Scroll Master."),
								fontObject = GameFontNormal,
								fullWidth = true,
							},
						},
					},
				},
			},
		}
		
		local slotList = {L("2H Weapon"), L("Boots"), L("Bracers"), L("Chest"), L("Cloak"), L("Gloves"),
							L("Shield"), L("Staff"), L("Weapon")}
		
		for slot=1, #(enchantsTemp) do
			tinsert(page[1].children, {
					type = "InlineGroup",
					layout = "flow",
					title = slotList[slot], 
					fullWidth = true,
					children = {},
				})
				
			local inline = page[1].children[#(page[1].children)].children
			
			for chant=1, #(enchantsTemp[slot]) do
				local text = YELLOW .. "[".. select(1, GetSpellInfo(enchantsTemp[slot][chant].spellID)) ..")|r"
				
				tinsert(inline, {
						type = "Button",
						text = L("Add Enchant"),
						relativeWidth = 0.32,
						callback = function(self)
								local itemID = enchantsTemp[slot][chant].itemID
								if not itemID then foreach(enchantsTemp[slot][chant], print) end
								TSM.Data[TSM.mode].crafts[itemID] = enchantsTemp[slot][chant]
								TSM.Data[TSM.mode].crafts[itemID].itemID = nil
								foreach(enchantsTemp[slot][chant].mats, function(ID, quantity)
										ID = tonumber(ID)
										local AddMat = true
										-- only add the mat if it isn't already in the matList table
										local matList = SM.Data:GetMats()
										for id in pairs(matList) do
											if id == ID then
												AddMat = false
											end
										end
										if AddMat then
											TSM.Data[TSM.mode].mats[ID] = matsTemp[ID]
										end
									end)
								container:SelectTab(5)
							end,
					})
					
				tinsert(inline, {
						type = "InteractiveLabel",
						text = YELLOW .. "[".. select(1, GetSpellInfo(enchantsTemp[slot][chant].spellID)) ..")|r",
						fontObject = GameFontNormal,
						relativeWidth = 0.67,
						callback = function() SetItemRef("spell:".. enchantsTemp[slot][chant].spellID) end,
					})
			end
		end
		
		GUI:BuildPage(container, page)
	end
	
	TSM.Enchanting:OpenEnchanting(nextFunc)
end

-- page for removing added enchants
function GUI:DrawRemoveEnchant(container)
	local text = L("Click on the 'Delete' button next to any enchant you would like to remove from Scroll " ..
		"Master. You can always re-add any enchant you have deleted.")
		
	local page = {
		{	-- scroll frame to contain everything
			type = "ScrollFrame",
			layout = "list",
			children = {
				{	-- inline group to contain the help text at the top
					type = "InlineGroup",
					layout = "flow",
					title = L("Help"),
					fullWidth = true,
					children = {
						{	-- text at the top of the scroll frame
							type = "Label",
							text = text,
							fontObject = GameFontNormal,
							fullWidth = true,
						},
					},
				},
				{	-- inline group to contain the list of enchants
					type = "InlineGroup",
					layout = "flow",
					title = L("Enchants"),
					fullWidth = true,
					children = {},
				},
			},
		},
	}
	
	local enchantList = TSM.Data:GetDataByGroups()
	
	for group=1, #(enchantList) do
		if group ~= 1 then
			tinsert(page[1].children[2].children, {
					type = "HeadingLine",
				})
		end
		for itemID, data in pairs(enchantList[group]) do
			tinsert(page[1].children[2].children, {
					type = "SimpleGroup",
					layout = "flow",
					fullWidth = true,
					children = {
						{
							type = "Button",
							text = L("Delete"),
							width = 80,
							callback = function()
									TSM.Data[TSM.mode].crafts[itemID] = nil
									container:SelectTab(6)
								end,
						},
						{
							type = "InteractiveLabel",
							text = YELLOW .. "[".. select(1, GetSpellInfo(data.spellID)) ..")|r",
							fontObject = GameFontNormal,
							width = 350,
							callback = function() SetItemRef("spell:".. data.spellID) end,
						}
					},
				})
		end
	end
	
	GUI:BuildPage(container, page)
end

-- page for all APM3 features
function GUI:DrawAPM(container)
	local exportList = TSM.db.profile.exportList
	local text = {
		L("APM3 was not found so this page did not load to prevent errors."),
		L("The following enchants do not have groups setup for them inside APM3. Using the 'Add' buttons " ..
			"below will have Scroll Master create a group automatically for that enchant. The name of the " ..
			"group will be the name of the enchant and no settings will be be set for the enchant."),
		L("Select which enchant costs you would like to export and then when you click on the button " ..
			"Scroll Master will automatically set APM3's thresholds (and fallbacks if enabled) for the chosen " ..
			"enchants to Scroll Master's cost values according to the options set in the 'Auction Profit Master 3' " ..
			"part of the 'External Options' page."),}	
	
	-- attempt to load APM3's saved variables
	local APM3 = LibStub("AceAddon-3.0"):GetAddon("AuctionProfitMaster", true)
	if APM3 then
		TSM.APM3db = APM3.db
	else
		local page = {
			{	-- scroll frame to contain everything
				type = "ScrollFrame",
				layout = "list",
				children = {
					{
						type = "Label",
						text = text[1],
						fontObject = GameFontNormal,
						fullWidth = true,
					},
				},
			},
		}
		return GUI:BuildPage(container, page)
	end

	local page = {
		{	-- scroll frame to contain everything
			type = "ScrollFrame",
			layout = "list",
			children = {
				{	-- inlinegroup to hold the list of groups that can be added to APM3
					type = "InlineGroup",
					layout = "flow",
					title = L("Adding New Groups to APM3"),
					fullWidth = true,
					children = {
						{
							type = "Label",
							text = text[2],
							fontObject = GameFontNormal,
							fullWidth = true,
						},
						{
							type = "HeadingLine"
						},
					},
				},
				{
					type = "Spacer",
					quantity = 1,
				},
				{	-- inlinegroup to hold the list of enchants to export to APM3
					type = "InlineGroup",
					layout = "flow",
					title = L("Export Enchant Costs to APM3"),
					fullWidth = true,
					children = {
						{
							type = "Label",
							text = text[3],
							fontObject = GameFontNormal,
							fullWidth = true,
						},
						{	-- simplegroup to hold the check/uncheck all buttons
							type = "SimpleGroup",
							layout = "flow",
							fullWidth = true,
							children = {
								{	-- check all button
									type = "Button",
									text = L("Check All"),
									relativeWidth = 0.49,
									callback = function()
											for itemID in pairs(TSM.Data[TSM.mode].crafts) do
												exportList[itemID] = true
											end
											GUI.TreeGroup:SelectByPath(6, 1)
										end,
								},
								{	-- uncheck all button
									type = "Button",
									text = L("Uncheck All"),
									relativeWidth = 0.49,
									callback = function()
											for itemID in pairs(TSM.Data[TSM.mode].crafts) do
												exportList[itemID] = nil
											end
											GUI.TreeGroup:SelectByPath(6, 1)
										end,
								},
							},
						},
						{
							type = "Button",
							text = L("Export Enchant Costs to APM3"),
							relativeWidth = 0.98,
							callback = function() TSM.Data:ExportDataToAPM() end,
						},
					},
				},
			},
		},
	}
	
	local enchantList = TSM.Data:GetDataByGroups()
	
	for group=1, #(enchantList) do
		tinsert(page[1].children[3].children, {
				type = "HeadingLine",
			})
		for itemID, data in pairs(enchantList[group]) do
			if not TSM.Data:GetAPMGroupName(itemID) then
				tinsert(page[1].children[1].children, {
						type = "Button",
						text = L("Add Group"),
						relativeWidth = 0.32,
						callback = function()
								local groupName = GetSpellInfo(data.spellID)
								local itemString = "item:" .. itemID
								TSM.APM3db.global.groups[groupName] = {[itemString] = true}
								GUI.TreeGroup:SelectByPath(6)
							end,
					})
					
				tinsert(page[1].children[1].children, {
						type = "InteractiveLabel",
						text = YELLOW .. "[".. select(1, GetSpellInfo(data.spellID)) ..")|r",
						fontObject = GameFontNormal,
						relativeWidth = 0.67,
						callback = function() SetItemRef("spell:".. data.spellID) end,
					})
			else
				tinsert(page[1].children[3].children, {
						type = "CheckBox",
						value = exportList[itemID],
						relativeWidth = 0.08,
						callback = function(_,_,value) exportList[itemID]=value end,
					})
					
				tinsert(page[1].children[3].children, {
						type = "InteractiveLabel",
						text = YELLOW .. "[".. select(1, GetSpellInfo(data.spellID)) ..")|r",
						fontObject = GameFontNormal,
						relativeWidth = 0.91,
						callback = function() SetItemRef("spell:".. data.spellID) end,
					})
			end
		end
	end
	
	GUI:BuildPage(container, page)
end

-- Help Page
function GUI:DrawHelp(container)
	local c1 = CYAN
	local cend = "|r"
	local HelpText = {
		L("How to use Scroll Master:"),
		"1. " .. string.format(L("Go to the %sauction house%s and type %s then wait for the " .. 
			"scan to finish. Once the scan is done, you can view / change the resulting material costs in the " .. 
			"%s section of the main window."), c1, cend, GOLD .. "/tsm scan|r", CYAN .. L("Materials") .. "|r"),
		"2. " .. string.format(L("Type %s to open up the main window."), GOLD .. "/tsm|r"),
		"3. " .. L("Click on the various enchant groups and scroll through to find which ones are profitable."),
		"4. " .. L("Check the boxes of the enchants you want to add to the queue."),
		"5. " .. string.format(L("Visit the %s section of the main window to make sure the prices have" .. 
			" been set reasonably and completely."), GOLD .. L("Materials") .. "|r"),
		"6. " .. string.format(L("Click on the %s section to view the total number of materials needed."), GOLD ..
			L("Totals / Queue") .. "|r"),
		"7. " .. L("Once you have all of a certain material in your bag, that line should turn from red to green."),
		"8. " .. string.format(L("Click the %s button to show the craft queue."), GOLD .. L("Show Queue") .. "|r"),
		"9. " .. L("Simply click on the name of each enchant inside the queue to make each scroll."),
		"10. " .. L("Craft away!")}
		
	local page = {
		{	-- scroll frame to contain everything
			type = "ScrollFrame",
			layout = "list",
			children = {
				{	-- first line of text
					type = "Label",
					text = HelpText[1] .. "\n",
					fontObject = GameFontNormalLarge,
					fullWidth = true,
					colorRed = 255,
					colorGreen = 0,
					colorBlue = 0,
				},
			},
		},
	}
	
	for i=2, #(HelpText) do
		tinsert(page[1].children, {
				type = "Label",
				text = HelpText[i] .. "\n",
				fontObject = GameFontNormal,
				fullWidth = true,
				colorRed = 0,
				colorGreen = 206,
				colorBlue = 209,
			})
	end
	
	GUI:BuildPage(container, page)
end

-- About Page
function GUI:DrawAbout(container)
	local AboutText = {
		"TradeSkill Master v" .. TSM.version,
		string.format(L("Scroll Master is an %s addon."), GOLD .. "Ace3|r"),
		L("Author") .. ": " .. GOLD .. "Sapu94|r - " .. "sapu94@gmail.com",
		L("Hosted @ http://wow.curse.com/downloads/wow-addons/details/slippy.aspx (or search curse for scroll master)."),
		L("If you have a question / suggestion / error to report please do so as either a curse comment at the above " ..
			"url or a message to me @ http://www.mmo-champion.com (username is Sapu94).") .. "\n",
		GOLD .. L("Slash Commands") .. ":|r",
		GOLD .. "/tsm|r - " .. L("opens the main Scroll Master window to the 'Enchants' main page."),
		GOLD .. "/tsm " .. L("scan") .. "|r - " .. L("scans the AH for scrolls and materials to calculate profits."),
		GOLD .. "/tsm " .. L("config") .. "|r - " .. L("opens the main Scroll Master window to the 'Options' page."),
		GOLD .. "/tsm " .. L("help") .. "|r - " .. L("opens the main Scroll Master window to the 'Help' page.")}
	
	local page = {
		{	-- scroll frame to contain everything
			type = "ScrollFrame",
			layout = "list",
			children = {
				{	-- first line of text
					type = "Label",
					text = AboutText[1] .. "\n",
					fontObject = GameFontNormalLarge,
					fullWidth = true,
					colorRed = 255,
					colorGreen = 0,
					colorBlue = 0,
				},
			},
		},
	}
	
	for i=2, #(AboutText) do
		tinsert(page[1].children, {
				type = "Label",
				text = AboutText[i] .. "\n",
				fontObject = GameFontNormal,
				fullWidth = true,
				colorRed = 0,
				colorGreen = 206,
				colorBlue = 209,
			})
	end
	
	GUI:BuildPage(container, page)
end

-- updates the craft queue
function GUI:UpdateQueue()
	wipe(GUI.queueList) -- clear the craft queue so we start fresh
	GUI.queueTotal = 0 --integer representing the total number of items (including multiple of the same enchant) in the craft queue
	GUI.queueInTotal = 0 -- integer representing the number of different items in the craft queue
	local queueProfit = 0 -- will store the total estimated profit
	
	for itemID, data in pairs(TSM.Data[TSM.mode].crafts) do
		if data.queued > 0 then -- find enchants that are queued
			-- get some information and add the enchant to the craft queue (GUI.queueList)
			local iName = GetSpellInfo(data.spellID)
			local iQuantity = data.queued
			local iSpellID = data.spellID
			tinsert(GUI.queueList, {name=iName, quantity=iQuantity, spellID=iSpellID})
			
			-- update our totals
			GUI.queueTotal = GUI.queueTotal + iQuantity
			GUI.queueInTotal = GUI.queueInTotal + 1
			
			-- if the profit can be calculated for this scroll, add it to the total estimated profit
			if select(3, TSM.Data:CalcPrices(data)) then
				queueProfit = queueProfit + select(3, TSM.Data:CalcPrices(data))*iQuantity
			end
		end
	end
	
	-- make sure the queueProfit is going to be valid
	if TSM.db.factionrealm.ScanStatus.scrolls then
		queueProfit = queueProfit .. GOLD .. "g" .. "|r"
	else
		queueProfit = "???"
	end
	
	-- now update the GUI's StatusText with information about the number of items in the queue and the total estimated profit
	GUI.Frame1:SetStatusText(L("Items in Craft Queue: ") .. BLUE .. GUI.queueTotal .. "|r     " .. 
		L("Estimated Total Profit from Queued Items: ") .. BLUE .. queueProfit)
		
	TSM.Data:UpdateInventoryInfo("mats")
	
	sort(GUI.queueList, function(a, b)
			local orderA = TSM.Enchanting:GetEnchantOrderIndex(a)
			local orderB = TSM.Enchanting:GetEnchantOrderIndex(b)
			return orderA > orderB
		end)
end

-- extracts an ItemID from an ItemLink or EnchantLink
function GUI:GetID(link)
	if not link then return end
	local s, e = string.find(link, "|H(.-):([-0-9]+)")
	link = string.sub(link, s+2, e)
	local c = string.find(link, ":")
	link = string.sub(link, c+1)
	return link
end

-- goes through a page-table and draws out all the containers and widgets for that page
function GUI:BuildPage(container, pageTable)
	for _, data in pairs(pageTable) do
		local parentElement = container:Add(data)
		if data.children then
			-- yay recursive function calls!
			GUI:BuildPage(parentElement, data.children)
		end
	end	
end

-- creates a widget or container as detailed in the passed table (iTable) and adds it as a child of the passed parent
function GUI.AddGUIElement(parent, iTable)
	local function AddTooltip(widget, text)
		if not text then return end
		widget:SetCallback("OnEnter", function(self)
				GameTooltip:SetOwner(self.frame, "ANCHOR_NONE")
				GameTooltip:SetPoint("LEFT", self.frame, "RIGHT")
				GameTooltip:AddLine(text, 1, 1, 1, 1)
				GameTooltip:Show()
			end)
		widget:SetCallback("OnLeave", function()
				GameTooltip:ClearLines()
				GameTooltip:Hide()
			end)
	end

	local Add = {
		InlineGroup = function(parent, args)
				local inlineGroup = AceGUI:Create("InlineGroup")
				inlineGroup:SetLayout(args.layout)
				inlineGroup:SetTitle(args.title)
				inlineGroup:SetFullWidth(args.fullWidth)
				parent:AddChild(inlineGroup)
				inlineGroup.Add = GUI.AddGUIElement
				return inlineGroup
			end,
			
		SimpleGroup = function(parent, args)
				local simpleGroup = AceGUI:Create("SimpleGroup")
				simpleGroup:SetLayout(args.layout)
				if args.fullWidth then
					simpleGroup:SetFullWidth(args.fullWidth)
				elseif args.width then
					simpleGroup:SetWidth(args.width)
				end
				parent:AddChild(simpleGroup)
				simpleGroup.Add = GUI.AddGUIElement
				return simpleGroup
			end,
		ScrollFrame = function(parent, args)
				local scrollFrame = AceGUI:Create("ScrollFrame")
				scrollFrame:SetLayout(args.layout)
				parent:AddChild(scrollFrame)
				scrollFrame.Add = GUI.AddGUIElement
				return scrollFrame
			end,
		Label = function(parent, args)
				local labelWidget = AceGUI:Create("Label")
				labelWidget:SetText(args.text)
				labelWidget:SetFontObject(args.fontObject)
				if args.fullWidth then
					labelWidget:SetFullWidth(args.fullWidth)
				elseif args.width then
					labelWidget:SetWidth(args.width)
				elseif args.relativeWidth then
					labelWidget:SetRelativeWidth(args.relativeWidth)
				end
				labelWidget:SetColor(args.colorRed, args.colorGreen, args.colorGreen)
				AddTooltip(labelWidget, args.tooltip)
				parent:AddChild(labelWidget)
				return labelWidget
			end,
		InteractiveLabel = function(parent, args)
				local iLabelWidget = AceGUI:Create("InteractiveLabel")
				iLabelWidget:SetText(args.text)
				iLabelWidget:SetFontObject(args.fontObject)
				if args.width then
					iLabelWidget:SetWidth(args.width)
				elseif args.relativeWidth then
					iLabelWidget:SetRelativeWidth(args.relativeWidth)
				end
				iLabelWidget:SetCallback("OnClick", args.callback)
				AddTooltip(iLabelWidget, args.tooltip)
				parent:AddChild(iLabelWidget)
				return iLabelWidget
			end,
		Button = function(parent, args)	
				local buttonWidget = AceGUI:Create("Button")
				buttonWidget:SetText(args.text)
				buttonWidget:SetDisabled(args.disabled)
				if args.width then
					buttonWidget:SetWidth(args.width)
				elseif args.relativeWidth then
					buttonWidget:SetRelativeWidth(args.relativeWidth)
				end
				if args.height then buttonWidget:SetHeight(args.height) end
				buttonWidget:SetCallback("OnClick", args.callback)
				AddTooltip(buttonWidget, args.tooltip)
				parent:AddChild(buttonWidget)
				return buttonWidget
			end,
			
		EditBox = function(parent, args)	
				local editBoxWidget = AceGUI:Create("EditBox")
				editBoxWidget:SetText(args.value)
				editBoxWidget:SetLabel(args.label)
				if args.width then
					editBoxWidget:SetWidth(args.width)
				elseif args.relativeWidth then
					editBoxWidget:SetRelativeWidth(args.relativeWidth)
				end
				editBoxWidget:SetCallback("OnEnterPressed", args.callback)
				AddTooltip(editBoxWidget, args.tooltip)
				parent:AddChild(editBoxWidget)
				return editBoxWidget
			end,
			
		CheckBox = function(parent, args)	
				local checkBoxWidget = AceGUI:Create("CheckBox")
				checkBoxWidget:SetType("checkbox")
				checkBoxWidget:SetValue(args.value)
				checkBoxWidget:SetLabel(args.label)
				if args.fullWidth then
					checkBoxWidget:SetFullWidth(args.fullWidth)
				elseif args.width then
					checkBoxWidget:SetWidth(args.width)
				elseif args.relativeWidth then
					checkBoxWidget:SetRelativeWidth(args.relativeWidth)
				end
				checkBoxWidget:SetCallback("OnValueChanged", args.callback)
				AddTooltip(checkBoxWidget, args.tooltip)
				parent:AddChild(checkBoxWidget)
				return checkBoxWidget
			end,
		Slider = function(parent, args)	
				local sliderWidget = AceGUI:Create("Slider")
				sliderWidget:SetValue(args.value)
				sliderWidget:SetSliderValues(args.min, args.max, args.step)
				sliderWidget:SetIsPercent(args.isPercent)
				sliderWidget:SetLabel(args.label)
				if args.width then sliderWidget:SetWidth(args.width) end
				if args.relativeWidth then sliderWidget:SetRelativeWidth(args.relativeWidth) end
				sliderWidget:SetCallback("OnValueChanged", args.callback)
				sliderWidget:SetDisabled(args.disabled)
				AddTooltip(sliderWidget, args.tooltip)
				parent:AddChild(sliderWidget)
				return sliderWidget
			end,
		Icon = function(parent, args)	
				local iconWidget = AceGUI:Create("Icon")
				iconWidget:SetImage(args.image)
				iconWidget:SetImageSize(args.width, args.height)
				iconWidget:SetWidth(args.width)
				AddTooltip(iconWidget, args.tooltip)
				parent:AddChild(iconWidget)
				return iconWidget
			end,
			
		Dropdown = function(parent, args)				
				local dropdownWidget = AceGUI:Create("Dropdown")
				dropdownWidget:SetText(args.text)
				dropdownWidget:SetLabel(args.label)
				dropdownWidget:SetList(args.list)
				if args.width then
					dropdownWidget:SetWidth(args.width)
				elseif args.relativeWidth then
					dropdownWidget:SetRelativeWidth(args.relativeWidth)
				end
				dropdownWidget:SetMultiselect(args.multiselect)
				dropdownWidget:SetDisabled(args.disabled)
				if type(args.value) == "table" then
					for name, value in pairs(args.value) do
						dropdownWidget:SetItemValue(name, value)
					end
				else
					dropdownWidget:SetValue(args.value)
				end
				dropdownWidget:SetCallback("OnValueChanged", args.callback)
				AddTooltip(dropdownWidget, args.tooltip)
				parent:AddChild(dropdownWidget)
				return dropdownWidget
			end,
			
		Spacer = function(parent, args)				
				for i=1, args.quantity do
					local spacer = parent:Add({type="Label", text=" ", fullWidth=true})
				end
			end,
		HeadingLine = function(parent, args)
				local heading = AceGUI:Create("Heading")
				heading:SetText("")
				heading:SetFullWidth(true)
				parent:AddChild(heading)
			end,
	}
	
	if not Add[iTable.type] then
		print("Invalid Widget or Container Type: ", iTable.type)
	end
	
	return Add[iTable.type](parent, iTable)
end