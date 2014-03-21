-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)
local Assistant = TSM.modules.Assistant
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local private = {stepData = {}}
TSMAPI:RegisterForTracing(private, "TradeSkillMaster.Steps_private")
local eventObj = TSMAPI:GetEventObject()

function Assistant:ClearStepData()
	private.stepData = {}
end

function private.OnEvent(event, arg)
	if not private.stepData then return end
	private.stepData.lastEvent = {event=event, arg=arg}
end
eventObj:SetCallbackAnyEvent(private.OnEvent)

function private:IsTSMFrameIconSelected(iconText)
	local path = TSM:GetTSMFrameSelectionPath()
	return path and path[1].value == iconText
end
function private:GetPathLevelValue(iconText, level)
	local path = TSM:GetTSMFrameSelectionPath()
	return path and path[1] and path[1].value == iconText and path[level] and path[level].value
end
function private:GetGroupTreeSelection()
	return private:GetPathLevelValue(L["Groups"], 2)
end
function private:GetGroupTab()
	local temp = private:GetPathLevelValue(L["Groups"], 2)
	return temp and temp[#temp] == private.stepData.selectedGroup and private:GetPathLevelValue(L["Groups"], 3)
end
function private:GetOperationModuleSelection()
	return private:GetPathLevelValue(L["Module Operations / Options"], 2)
end
function private:GetOperationTreeSelection(module)
	if private:GetOperationModuleSelection() ~= module then return end
	return private:GetPathLevelValue(L["Module Operations / Options"], 3)
end
function private:GetOperationTab(module)
	if not private:GetOperationTreeSelection(module) then return end
	local temp = private:GetPathLevelValue(L["Module Operations / Options"], 3)
	return temp and temp and temp[#temp] == private.stepData.selectedOperation and private:GetPathLevelValue(L["Module Operations / Options"], 4)
end

function private:GetIsDoneStep(title, description, isDoneFunc)
	local step = {
			title = title,
			description = description,
			doneButton = "I'm done.",
			isDone = function(self) return private.stepData[self] and (not isDoneFunc or isDoneFunc()) end,
			onDoneButtonClicked = function(self) private.stepData[self] = true end,
			isCheckPoint = true
	}
	return step
end

function private:PrependCreateOperationSteps(tbl, moduleLong, moduleShort, description)
	local steps = {
		{
			title = "Go to the 'Operations' Tab",
			description = format("We will add a %s operation to this group through its 'Operations' tab. Click on that tab now.", moduleLong),
			isDone = function() return private:GetGroupTab() == 1 end,
			isCheckPoint = true,
		},
		{
			title = "Go to the 'Operations' Tab",
			description = format("We will add a %s operation to this group through its 'Operations' tab. Click on that tab now.", moduleLong),
			isDone = function() return private:GetGroupTab() == 1 end,
			isCheckPoint = true,
		},
		{
			title = format("Create a %s Operation %d/5", moduleShort, 1),
			description = description,
			isDone = function() return private:GetOperationTreeSelection(moduleShort) end,
		},
		{
			title = format("Create a %s Operation %d/5", moduleShort, 2),
			description = "Select the 'Operations' page from the list on the left of the TSM window.",
			isDone = function()
				local selection = private:GetOperationTreeSelection(moduleShort)
				if selection and #selection == 1 and selection[1] == "2" then
					private.stepData.operationsPageClicked = true
				end
				return private.stepData.operationsPageClicked
			end,
		},
		{
			title = format("Create a %s Operation %d/5", moduleShort, 3),
			description = format("Create a new %s operation by typing a name for the operation into the 'Operation Name' box and pressing the <Enter> key.", moduleLong),
			isDone = function()
				local selection = private:GetOperationTreeSelection(moduleShort)
				return selection and #selection > 1 and selection[1] == "2"
			end,
		},
		{
			title = format("Create a %s Operation %d/5", moduleShort, 4),
			description = "Assign this operation to the group you previously created by clicking on the 'Yes' button in the popup that's now being shown.",
			isDone = function()
				for i=1, 100 do
					local popup = _G["StaticPopup"..i]
					if not popup then break end
					if popup:IsVisible() and popup.which == "TSM_NEW_OPERATION_ADD" then
						return
					end
				end
				return true
			end,
		},
		{
			title = format("Create a %s Operation %d/5", moduleShort, 5),
			description = "Select your new operation in the list of operation along the left of the TSM window (if it's not selected automatically) and click on the button below.\n\nCurrently Selected Operation: %s",
			getDescArgs = function()
				local selection = private:GetOperationTreeSelection(moduleShort)
				if selection and #selection > 1 then
					return TSMAPI.Design:GetInlineColor("link")..selection[#selection].."|r"
				else
					return TSMAPI.Design:GetInlineColor("link").."<No Operation Selected>".."|r"
				end
			end,
			isDone = function() return private:GetOperationTab(moduleShort) end,
			doneButton = "My new operation is selected.",
			onDoneButtonClicked = function()
				local selection = private:GetOperationTreeSelection(moduleShort)
				if selection and #selection > 1 then
					private.stepData.selectedOperation = selection[#selection]
				else
					TSM:Print("Please select the new operation you've created.")
				end
			end,
			isCheckPoint = true,
		},
	}
	
	-- prepend all the steps to the passed table
	for i, step in ipairs(steps) do
		tinsert(tbl, i, step)
	end
end

local tsmSteps = {
	["notYetImplemented"] = {
		private:GetIsDoneStep(
				"Not Yet Implemented",
				"This step is not yet implemented."
			),
	},
	["openGroups"] = {
		{
			title = "Open the TSM Window",
			description = "Type '/tsm' or click on the minimap icon to open the main TSM window.",
			isDone = function() return TSM:TSMFrameIsVisible() end,
		},
		{
			title = "Click on the Groups Icon",
			description = "Along top of the window, on the left side, click on the 'Groups' icon to open up the TSM group settings.",
			isDone = function() return private:IsTSMFrameIconSelected(L["Groups"]) end,
		},
	},
	["newGroup"] = {
		{
			title = "Go to the 'Groups' Page",
			description = "In the list on the left, select the top-level 'Groups' page.",
			isDone = function()
				local selection = private:GetGroupTreeSelection()
				if selection and #selection == 1 and selection[1] == "1" then
					private.stepData.groupsPageClicked = true
				end
				return private.stepData.groupsPageClicked
			end,
		},
		{
			title = "Create a New Group",
			description = "Create a new group by typing a name for the group into the 'Group Name' box and pressing the <Enter> key.",
			isDone = function()
				if private.stepData.createdGroup then return true end
				if not private.stepData.lastEvent then return end
				local key = private.stepData.lastEvent.event
				private.stepData.lastEvent = nil
				if key == "TSM:GROUPS:NEWGROUP" then
					private.stepData.createdGroup = true
					return true
				end
			end,
		},
	},
	["selectGroup"] = {
		{
			title = "Select Existing Group",
			description = "Select the group you'd like to use. Once you have done this, click on the button below.\n\nCurrently Selected Group: %s",
			getDescArgs = function()
				local selection = private:GetGroupTreeSelection()
				if selection and #selection > 1 then
					return TSMAPI:FormatGroupPath(selection[#selection], true)
				else
					return TSMAPI.Design:GetInlineColor("link").."<No Group Selected>".."|r"
				end
			end,
			isDone = function() return private:GetGroupTab() end,
			doneButton = "My group is selected.",
			onDoneButtonClicked = function()
				local selection = private:GetGroupTreeSelection()
				if selection and #selection > 1 then
					private.stepData.selectedGroup = selection[#selection]
				else
					TSM:Print("Please select the group you'd like to use.")
				end
			end,
		},
	},
	["groupImportItems"] = {
		{
			title = "Go to the 'Import/Export' Tab",
			description = "We will import items into this group using the import list you have.",
			isDone = function() return private:GetGroupTab() == 3 or (private.stepData.lastEvent and private.stepData.lastEvent.key == "GROUP_IMPORT") or private.stepData.importedItems end,
		},
		{
			title = "Enter Import String",
			description = "Paste your import string into the 'Import String' box and hit the <Enter> key to import the list of items.",
			isDone = function()
				if private.stepData.importedItems then return true end
				if not private.stepData.lastEvent then return end
				local key = private.stepData.lastEvent.event
				local arg = private.stepData.lastEvent.arg
				private.stepData.lastEvent = nil
				if key == "TSM:GROUPS:ADDITEMS" and arg.isImport then
					if arg.num == 0 then
						TSM:Print("Looks like no items were imported. This might be because they are already in another group in which case you might consider checking the 'Move Already Grouped Items' box to force them to move to this group.")
					else
						private.stepData.importedItems = true
						return true
					end
				end
			end,
		},
	},
	["groupAddFromBags"] = {
		{
			title = "Go to the 'Items' Tab",
			description = "We will add items to this group through its 'Items' tab. Click on that tab now.",
			isDone = function() return private:GetGroupTab() == 2 or private.stepData.addedItems end,
		},
		{
			title = "Add Items to this Group",
			description = "Select the items you want to add in the left column and then click on the 'Add >>>' button at the top to add them to this group.",
			isDone = function()
				if private.stepData.addedItems then return true end
				if not private.stepData.lastEvent then return end
				local key = private.stepData.lastEvent.event
				local arg = private.stepData.lastEvent.arg
				private.stepData.lastEvent = nil
				if key == "TSM:GROUPS:ADDITEMS" and not arg.isImport then
					private.stepData.addedItems = true
					return true
				end
			end,
		},
	},
}

local craftingSteps = {
	["openCrafting"] = {
		{
			title = "Open the TSM Window",
			description = "Type '/tsm' or click on the minimap icon to open the main TSM window.",
			isDone = function() return TSM:TSMFrameIsVisible() end,
		},
		{
			title = "Click on the Groups Icon",
			description = "Along top of the window, on the right side, click on the 'Crafting' icon to open up the TSM_Crafting page.",
			isDone = function() return private:GetPathLevelValue("Crafting", 2) == 1 end,
		},
	},
	["craftingCraftsTab"] = {
		{
			title = "Select the 'Crafts' Tab",
			description = "At the top, switch to the 'Crafts' tab in order to view a list of crafts you can make.",
			isDone = function() return TSM:TSMFrameIsVisible() end,
		},
		private:GetIsDoneStep(
				"Queue Profitable Crafts",
				"You can use the filters at the top of the page to narrow down your search and click on a column to sort by that column. Then, left-click on a row to add one of that item to the queue, and right-click to remove one.\n\nOnce you're done adding items to the queue, click the button below."
			),
	},
	["openProfession"] = {
		{
			title = "Open up Your Profession",
			description = "Open one of the professions which you would like to use to craft items.",
			isDone = function() return TSMAPI:ModuleAPI("Crafting", "getCraftingFrameStatus") end,
		},
	},
	["useProfessionQueue"] = {
		{
			title = "Show the Queue",
			description = "Click on the 'Show Queue' button at the top of the TSM_Crafting window to show the queue if it's not already visible.",
			isDone = function() local status = TSMAPI:ModuleAPI("Crafting", "getCraftingFrameStatus") return status and status.queue end,
		},
		private:GetIsDoneStep(
				"Craft Items from Queue",
				"You can craft items either by clicking on rows in the queue which are green (meaning you can craft all) or blue (meaning you can craft some) or by clicking on the 'Craft Next' button at the bottom.\n\nClick on the button below when you're done reading this. There is another guide which tells you how to buy mats required for your queue."
			),
	},
	["craftingOperation"] = {
		private:GetIsDoneStep(
				"Set Max Restock Quantity",
				"The 'Max Restock Quantity' defines how many of each item you want to restock up to when using the restock queue, taking your inventory into account.\n\nOnce you're done adjusting this setting, click the button below."
			),
		private:GetIsDoneStep(
				"Set Minimum Profit",
				"If you'd like, you can adjust the value in the 'Minimum Profit' box in order to specify the minimum profit before Crafting will queue these items.\n\nOnce you're done adjusting this setting, click the button below."
			),
		private:GetIsDoneStep(
				"Set Other Options",
				"You can look through the tooltips of the other options to see what they do and decide if you want to change their values for this operation.\n\nOnce you're done, click on the button below."
			),
	},
	["professionRestock"] = {
		{
			title = "Switch to the 'TSM Groups' Tab",
			description = "Along the top of the TSM_Crafting window, click on the 'TSM Groups' button.",
			isDone = function() local status = TSMAPI:ModuleAPI("Crafting", "getCraftingFrameStatus") return status and status.page == "groups" end,
		},
		{
			title = "Select Group and Start Scan",
			description = "First, ensure your new group is selected in the group-tree and then click on the 'Restock Selected Groups' button at the bottom.",
			isDone = function(self)
				if private.stepData[self] then return true end
				if not private.stepData.lastEvent then return end
				local event = private.stepData.lastEvent.event
				local arg = private.stepData.lastEvent.arg
				private.stepData.lastEvent = nil
				if event == "CRAFTING:QUEUE:RESTOCKED" then
					if arg == 0 then
						TSM:Print("Looks like no items were added to the queue. This may be because you are already at or above your restock levels, or there is nothing profitable to queue.")
					else
						private.stepData[self] = true
						return true
					end
				end
			end,
		},
	},
	["craftFromProfession"] = {
		{
			title = "Switch to the 'Professions' Tab",
			description = "Along the top of the TSM_Crafting window, click on the 'Professions' button.",
			isDone = function() local status = TSMAPI:ModuleAPI("Crafting", "getCraftingFrameStatus") return status and status.page == "profession" end,
		},
		private:GetIsDoneStep(
				"Select the Craft",
				"Just like the default profession UI, you can select what you want to craft from the list of crafts for this profession. Click on the one you want to craft.\n\nOnce you're done, click the button below."
			),
		private:GetIsDoneStep(
				"Create the Craft",
				"You can now use the buttons near the bottom of the TSM_Crafting window to create this craft.\n\nOnce you're done, click the button below."
			),
	},
}
private:PrependCreateOperationSteps(craftingSteps["craftingOperation"], "TSM_Crafting", "Crafting", "A TSM_Crafting operation will allow us automatically queue profitable items from the group you just made. To create one for this group, scroll down to the 'Crafting' section, and click on the 'Create Crafting Operation' button.")

local shoppingSteps = {
	["shoppingOperation"] = {
		private:GetIsDoneStep(
				"Set a Maximum Price",
				"The 'Maxium Auction Price (per item)' is the most you want to pay for the items you've added to your group. If you're not sure what to set this to and have TSM_AuctionDB installed (and it contains data from recent scans), you could try '90% dbmarket' for this option.\n\nOnce you're done adjusting this setting, click the button below."
			),
		private:GetIsDoneStep(
				"Set Other Options",
				"You can look through the tooltips of the other options to see what they do and decide if you want to change their values for this operation.\n\nOnce you're done, click on the button below."
			),
	},
	["openShoppingAHTab"] = {
		{
			title = "Open the Auction House",
			description = "Go to the Auction House and open it.",
			isDone = function() return AuctionFrame and AuctionFrame:IsVisible() end,
		},
		{
			title = "Click on the Shopping Tab",
			description = "Along the bottom of the AH are various tabs. Click on the 'Shopping' AH tab.",
			isDone = function() return TSMAPI:AHTabIsVisible("Shopping") end,
		},
	},
	["shoppingGroupSearch"] = {
		{
			title = "Show the 'TSM Groups' Sidebar Tab",
			description = "Underneath the serach bar at the top of the 'Shopping' AH tab are a handful of buttons which change what's displayed in the sidebar window. Click on the 'TSM Groups' one.",
			isDone = function() return TSMAPI:ModuleAPI("Shopping", "getSidebarPage") == "groups" end,
		},
		{
			title = "Select Group and Start Scan",
			description = "First, ensure your new group is selected in the group-tree and then click on the 'Start Search' button at the bottom of the sidebar window.",
			isDone = function(self)
				if private.stepData[self] then return true end
				if not private.stepData.lastEvent then return end
				local event = private.stepData.lastEvent.event
				private.stepData.lastEvent = nil
				if event == "SHOPPING:GROUPS:STARTSCAN" then
					private.stepData[self] = true
					return true
				end
			end,
		},
	},
	["shoppingFilterSearch"] = {
		{
			title = "Show the 'Custom Filter' Sidebar Tab",
			description = "Underneath the serach bar at the top of the 'Shopping' AH tab are a handful of buttons which change what's displayed in the sidebar window. Click on the 'Custom Filter' one.",
			isDone = function() return TSMAPI:ModuleAPI("Shopping", "getSidebarPage") == "custom" end,
		},
		{
			title = "Enter Filters and Start Scan",
			description = "You can use this sidebar window to help build AH searches. You can also type the filter directly in the search bar at the top of the AH window.\n\nEnter your filter and start the search.",
			isDone = function(self)
				if private.stepData[self] then return true end
				if not private.stepData.lastEvent then return end
				local event = private.stepData.lastEvent.event
				private.stepData.lastEvent = nil
				if event == "SHOPPING:SEARCH:STARTFILTERSCAN" then
					private.stepData[self] = true
					return true
				end
			end,
		},
	},
	["shoppingWaitForScan"] = {
		{
			title = "Waiting for Scan to Finish",
			description = "Waiting for the scan to finish...",
			isDone = function(self)
				if private.stepData[self] then return true end
				if not private.stepData.lastEvent then return end
				if not AuctionFrame:IsVisible() or not TSMAPI:AHTabIsVisible("Shopping") then return end
				local event = private.stepData.lastEvent.event
				local arg = private.stepData.lastEvent.arg
				private.stepData.lastEvent = nil
				if event == "SHOPPING:SEARCH:SCANDONE" then
					if arg == 0 then
						TSM:Print("Looks like no items were found. You can either try searching for something else, or simply close the Assistant window if you're done.")
					else
						private.stepData[self] = true
						return true
					end
				end
			end,
		},
	},
}
private:PrependCreateOperationSteps(shoppingSteps["shoppingOperation"], "TSM_Shopping", "Shopping", "A TSM_Shopping operation will allow us to set a maximum price we want to pay for the items in the group you just made. To create one for this group, scroll down to the 'Shopping' section, and click on the 'Create Shopping Operation' button.")

do
	Assistant.STEPS = {}
	for _, moduleSteps in ipairs({tsmSteps, craftingSteps, shoppingSteps}) do
		for key, steps in pairs(moduleSteps) do
			assert(not Assistant.STEPS[key], format("Multiples steps with key '%s' exist!", key))
			Assistant.STEPS[key] = steps
		end
	end
end