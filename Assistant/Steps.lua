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
eventObj:SetCallback("TSM:GROUPS:IMPORT", private.OnEvent)
eventObj:SetCallback("TSM:GROUPS:ADDITEMS", private.OnEvent)
eventObj:SetCallback("TSM:GROUPS:NEWGROUP", private.OnEvent)
eventObj:SetCallback("SHOPPING:GROUPS:STARTSCAN", private.OnEvent)

function private:IsTSMFrameIconSelected(iconText)
	local path = TSM:GetTSMFrameSelectionPath()
	return path and path[1].value == iconText
end
function private:GetGroupTreeSelection()
	if not private:IsTSMFrameIconSelected(L["Groups"]) then return end
	local path = TSM:GetTSMFrameSelectionPath()
	return path and #path >= 2 and path[1].value == L["Groups"] and path[2].value
end
function private:GetGroupTab()
	if not private:IsTSMFrameIconSelected(L["Groups"]) then return end
	local path = TSM:GetTSMFrameSelectionPath()
	return path and #path == 3 and path[1].value == L["Groups"] and path[2].value[#path[2].value] == private.stepData.selectedGroup and path[3].value
end
function private:GetOperationModuleSelection()
	if not private:IsTSMFrameIconSelected(L["Module Operations / Options"]) then return end
	local path = TSM:GetTSMFrameSelectionPath()
	return path and path[2] and path[2].value
end
function private:GetOperationTreeSelection(module)
	if private:GetOperationModuleSelection() ~= module then return end
	local path = TSM:GetTSMFrameSelectionPath()
	return path and #path >= 3 and path[3].value
end
function private:GetOperationTab(module)
	if not private:IsTSMFrameIconSelected(L["Module Operations / Options"]) then return print("FAIL1") end
	if not private:GetOperationTreeSelection(module) then return print("FAIL1") end
	local path = TSM:GetTSMFrameSelectionPath()
	return path and #path == 4 and path[3].value[#path[3].value] == private.stepData.selectedOperation and path[4].value
end

local tsmSteps = {
	["notYetImplemented"] = {
		{
			title = "Not Yet Implemented",
			description = "This step is not yet implemented.",
			doneButton = "CLICK ME!",
			onDoneButtonClicked = function() private.stepData.notYetImplementedStepDone = true end,
			isDone = function() return private.stepData.notYetImplementedStepDone end,
		},
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
			isDone = private.GetGroupTab,
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
				local num = private.stepData.lastEvent.arg
				private.stepData.lastEvent = nil
				if key == "TSM:GROUPS:IMPORT" then
					if num == 0 then
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
				private.stepData.lastEvent = nil
				if key == "TSM:GROUPS:ADDITEMS" then
					private.stepData.addedItems = true
					return true
				end
			end,
		},
	},
}

local shoppingSteps = {
	["shoppingOperation"] = {
		{
			title = "Go to the 'Operations' Tab",
			description = "We will add a TSM_Shopping operation to this group through its 'Operations' tab. Click on that tab now.",
			isDone = function() return private:GetGroupTab() == 1 end,
			isCheckPoint = true,
		},
		{
			title = "Create a Shopping Operation 1/5",
			description = "A TSM_Shopping operation will allow us to set a maximum price we want to pay for the items you just imported. To create one for this group, scroll down to the 'Shopping' section, and click on the 'Create Shopping Operation' button.",
			isDone = function() return private:GetOperationTreeSelection("Shopping") end,
		},
		{
			title = "Create a Shopping Operation 2/5",
			description = "Select the 'Operations' page from the list on the left of the TSM window.",
			isDone = function()
				local selection = private:GetOperationTreeSelection("Shopping")
				if selection and #selection == 1 and selection[1] == "2" then
					private.stepData.operationsPageClicked = true
				end
				return private.stepData.operationsPageClicked
			end,
		},
		{
			title = "Create a Shopping Operation 3/5",
			description = "Create a new TSM_Shopping operation by typing a name for the operation into the 'Operation Name' box and pressing the <Enter> key.",
			isDone = function()
				local selection = private:GetOperationTreeSelection("Shopping")
				return selection and #selection > 1 and selection[1] == "2"
			end,
		},
		{
			title = "Create a Shopping Operation 4/5",
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
			title = "Create a Shopping Operation 5/5",
			description = "Select your new operation in the list of operation along the left of the TSM window (if it's not selected automatically) and click on the button below.\n\nCurrently Selected Operation: %s",
			getDescArgs = function()
				local selection = private:GetOperationTreeSelection("Shopping")
				if selection and #selection > 1 then
					return TSMAPI.Design:GetInlineColor("link")..selection[#selection].."|r"
				else
					return TSMAPI.Design:GetInlineColor("link").."<No Operation Selected>".."|r"
				end
			end,
			isDone = function() return private:GetOperationTab("Shopping") end,
			doneButton = "My new operation is selected.",
			onDoneButtonClicked = function()
				local selection = private:GetOperationTreeSelection("Shopping")
				if selection and #selection > 1 then
					private.stepData.selectedOperation = selection[#selection]
				else
					TSM:Print("Please select the new operation you've created.")
				end
			end,
			isCheckPoint = true,
		},
		{
			title = "Set a Maximum Price",
			description = "The 'Maxium Auction Price (per item)' is the most you want to pay for the items you've added to your group. If you're not sure what to set this to and have TSM_AuctionDB installed (and it contains data from recent scans), you could try '90% dbmarket' for this option.\n\nOnce you're done adjusting this setting, click the button below.",
			isDone = function() return private.stepData.maxPriceDone end,
			doneButton = "I'm done.",
			onDoneButtonClicked = function() private.stepData.maxPriceDone = true end,
		},
		{
			title = "Set Other Options",
			description = "You can look through the tooltips of the other options to see what they do and decide if you want to change their values for this operation.\n\nOnce you're done, click on the button below.",
			isDone = function() return private.stepData.otherOptionsDone end,
			doneButton = "I'm done.",
			onDoneButtonClicked = function() private.stepData.otherOptionsDone = true end,
			isCheckPoint = true,
		},
	},
	["shoppingGroupSearch"] = {
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
		{
			title = "Show the 'TSM Groups' Sidebar Tab",
			description = "Underneath the serach bar at the top of the 'Shopping' AH tab are a handful of buttons which changes what's displayed in the sidebar window. Click on the 'TSM Groups' one.",
			isDone = function() return LibStub("AceAddon-3.0"):GetAddon("TSM_Shopping").Sidebar:GetCurrentPage() == "groups" end,
		},
		{
			title = "Select Group and Start Scan",
			description = "First, ensure your new group is selected in the group-tree and then click on the 'Start Search' button at the bottom of the sidebar window.",
			isDone = function()
				if private.stepData.startedScan then return true end
				if not private.stepData.lastEvent then return end
				local event = private.stepData.lastEvent.event
				private.stepData.lastEvent = nil
				if event == "SHOPPING:GROUPS:STARTSCAN" then
					private.stepData.startedScan = true
					return true
				end
			end,
		},
	},
}

do
	local moduleSteps = {tsmSteps, shoppingSteps}
	Assistant.STEPS = {}
	for _, module in ipairs(moduleSteps) do
		for key, steps in pairs(module) do
			Assistant.STEPS[key] = steps
		end
	end
end