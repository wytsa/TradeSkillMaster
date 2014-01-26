-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local private = {}
TSMAPI:RegisterForTracing(private, "TradeSkillMaster.Assistant_private")

local MAX_ASSISTANT_BUTTONS = 5
local ASSISTANT_INFO = {
	title = "What do you want to do?",
	buttons = {
		{
			text = "Buy items from the AH.",
			children = {
				title = "How would you like to shop?",
				buttons = {
					{
						text = "I have an importable list of items I want to shop for.",
						guides = {"newGroup", "groupImportItems", "shoppingOperation", "shoppingGroupSearch"},
					},
					{
						text = "I have at least one of the items I want to buy in my bags.",
						guides = {"newGroup", "groupAddFromBags", "shoppingOperation", "shoppingGroupSearch"},
					},
				},
			},
		},
		{
			text = "Test",
			guides = {"shoppingGroupSearch"},
		},
	},
}
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
local ASSISTANT_STEPS = {
	["newGroup"] = {
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
			description = "Create a new group by typing a name for the group into the 'Group Name' box and pressing the <Enter> key. Once you have done this, select your new group in the list of groups along the left of the window (if it's not selected automatically) and click on the button below.\n\nCurrently Selected Group: %s",
			getDescArgs = function()
				local selection = private:GetGroupTreeSelection()
				if selection and #selection > 1 then
					return TSMAPI:FormatGroupPath(selection[#selection], true)
				else
					return TSMAPI.Design:GetInlineColor("link").."<No Group Selected>".."|r"
				end
			end,
			isDone = private.GetGroupTab,
			doneButton = "My new group is selected.",
			onDoneButtonClicked = function()
				local selection = private:GetGroupTreeSelection()
				if selection and #selection > 1 then
					private.stepData.selectedGroup = selection[#selection]
				else
					TSM:Print("Please select the new group you've created.")
				end
			end,
		},
	},
	["groupImportItems"] = {
		{
			title = "Go to the 'Import/Export' Tab",
			description = "We will import items into this group using the import list you have.",
			isDone = function() 
				local path = TSM:GetTSMFrameSelectionPath()
				return (path and path[3].value == 3) or (private.stepData.lastEvent and private.stepData.lastEvent.key == "GROUP_IMPORT") or private.stepData.importedItems
			end,
		},
		{
			title = "Enter Import String",
			description = "Paste your import string into the 'Import String' box and hit the <Enter> key to import the list of items.",
			isDone = function()
				if private.stepData.importedItems then return true end
				if not private.stepData.lastEvent then return end
				local key = private.stepData.lastEvent.key
				local num = unpack(private.stepData.lastEvent.args)
				private.stepData.lastEvent = nil
				if key == "GROUP_IMPORT" then
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
			isDone = function() return private:GetGroupTab() == 2 end,
		},
		{
			title = "Add Items to this Group",
			description = "Select the items you want to add in the left column and then click on the 'Add >>>' button at the top to add them to this group.",
			isDone = function() return false end,
		},
	},
	["shoppingOperation"] = {
		{
			title = "Go to the 'Operations' Tab",
			description = "We will add a TSM_Shopping operation to this group through its 'Operations' tab. Click on that tab now.",
			isDone = function() return private:GetGroupTab() == 1 end,
			isCheckPoint = true,
		},
		{
			title = "Create a Shopping Operation 1/5",
			description = "A TSM_Shopping operation will allow us to set a maximum price we want to pay for the items you just imported. To create one for this group, Click on the 'Create Shopping Operation' button on this tab.",
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
				local key = private.stepData.lastEvent.key
				private.stepData.lastEvent = nil
				if key == "SHOPPING_GROUPS_START_SCAN" then
					private.stepData.startedScan = true
					return true
				end
			end,
		},
	}
}


function TSM:OpenAssistant()
	if not private.frame then
		private.frame = private:CreateAssistantFrame()
	end
	private.frame:Show()
end

function private:CreateAssistantFrame()
	local frameDefaults = {
		x = 50,
		y = 300,
		width = 300,
		height = 250,
		scale = 1,
	}
	local frame = TSMAPI:CreateMovableFrame("TSMAssistantFrame", frameDefaults)
	TSMAPI.Design:SetFrameBackdropColor(frame)
	frame:Hide()
	frame:SetScript("OnShow", function(self)
			self.guideFrame:Hide()
			self.questionFrame:Show()
		end)
	frame:SetScript("OnHide", function(self)
			private.currentStep = nil
		end)

	local title = frame:CreateFontString()
	title:SetFont(TSMAPI.Design:GetContentFont(), 18)
	TSMAPI.Design:SetWidgetLabelColor(title)
	title:SetPoint("TOP", frame, 0, -3)
	title:SetText("TSM Assistant")
	
	TSMAPI.GUI:CreateHorizontalLine(frame, -25)

	local closeBtn = TSMAPI.GUI:CreateButton(frame, 18)
	closeBtn:SetPoint("TOPRIGHT", -3, -3)
	closeBtn:SetWidth(19)
	closeBtn:SetHeight(19)
	closeBtn:SetText("X")
	closeBtn:SetScript("OnClick", function() frame:Hide() end)
	
	frame.questionFrame = private:CreateQuestionFrame(frame)
	frame.guideFrame = private:CreateGuideFrame(frame)
	return frame
end

function private:CreateQuestionFrame(parent)
	local frame = CreateFrame("Frame", nil, parent)
	frame:SetAllPoints()
	frame:Hide()
	frame:SetScript("OnShow", function(self)
			private.pageInfo = ASSISTANT_INFO
			self:Update()
		end)
	
	function frame.Update(self)
		-- update the title question
		self.questionText:SetText(private.pageInfo.title)
		
		-- hide all the buttons
		for _, button in ipairs(self.buttons) do
			button:Hide()
		end
		
		-- update buttons
		for i, buttonInfo in ipairs(private.pageInfo.buttons) do
			self.buttons[i]:Show()
			self.buttons[i]:SetText(buttonInfo.text)
			self.buttons[i].info = buttonInfo
		end
	end
	
	local questionText = TSMAPI.GUI:CreateTitleLabel(frame, 16)
	questionText:SetPoint("TOPLEFT", 5, -30)
	questionText:SetPoint("TOPRIGHT", -5, -30)
	questionText:SetHeight(20)
	questionText:SetJustifyH("LEFT")
	questionText:SetJustifyV("CENTER")
	frame.questionText = questionText
	
	local function OnAnswerButtonClicked(self)
		if self.info.children then
			private.pageInfo = self.info.children
			private.frame.questionFrame:Update()
		elseif self.info.guides then
			private.steps = {}
			for _, guideKey in ipairs(self.info.guides) do
				for _, step in ipairs(ASSISTANT_STEPS[guideKey]) do
					tinsert(private.steps, step)
				end
			end
			private.frame.questionFrame:Hide()
			private.frame.guideFrame:Show()
		end
	end
	
	frame.buttons = {}
	for i=1, MAX_ASSISTANT_BUTTONS do
		local button = TSMAPI.GUI:CreateButton(frame, 14)
		button:SetHeight(20)
		if i == 1 then
			button:SetPoint("TOPLEFT", frame.questionText, "BOTTOMLEFT", 0, -5)
			button:SetPoint("TOPRIGHT", frame.questionText, "BOTTOMRIGHT", 0, -5)
		else
			button:SetPoint("TOPLEFT", frame.buttons[i-1], "BOTTOMLEFT", 0, -5)
			button:SetPoint("TOPRIGHT", frame.buttons[i-1], "BOTTOMRIGHT", 0, -5)
		end
		button:SetScript("OnClick", OnAnswerButtonClicked)
		tinsert(frame.buttons, button)
	end
	
	return frame
end

function private:CreateGuideFrame(parent)
	local frame = CreateFrame("Frame", nil, parent)
	frame:SetAllPoints()
	frame:Hide()
	frame:SetScript("OnShow", function(self)
			private.currentStep = 1
			private.checkPoint = 1
			private.stepData = {}
			self:Update()
			private:StartStepWaitThread()
		end)
		
	function frame.Update(self)
		if private.currentStep == -1 then
			self.stepTitle:SetText("Done!")
			self.stepDesc:SetText("You have successfully completed this guide. If you require further assistance, visit out our website: http://tradeskillmaster.com")
			self.button:Hide()
		else
			local stepInfo = private.steps[private.currentStep]
			self.stepTitle:SetText(stepInfo.title)
			if stepInfo.getDescArgs then
				self.stepDesc:SetText(format(stepInfo.description, stepInfo.getDescArgs()))
			else
				self.stepDesc:SetText(stepInfo.description)
			end
			self.stepDesc:SetWidth(min(self.stepDesc:GetStringWidth(), self:GetWidth()-10))
			if stepInfo.doneButton then
				self.button:Show()
				self.button:SetText(stepInfo.doneButton)
				self.button:SetScript("OnClick", stepInfo.onDoneButtonClicked)
			else
				self.button:Hide()
			end
		end
	end

	local stepTitle = TSMAPI.GUI:CreateTitleLabel(frame, 16)
	stepTitle:SetPoint("TOPLEFT", 5, -30)
	stepTitle:SetPoint("TOPRIGHT", -5, -30)
	stepTitle:SetHeight(20)
	stepTitle:SetJustifyH("LEFT")
	stepTitle:SetJustifyV("CENTER")
	stepTitle:SetText("DEFAULT")
	frame.stepTitle = stepTitle

	local stepDesc = TSMAPI.GUI:CreateLabel(frame, "normal")
	stepDesc:SetPoint("TOPLEFT", 5, -55)
	stepDesc:SetJustifyH("LEFT")
	stepDesc:SetJustifyV("TOP")
	frame.stepDesc = stepDesc
	
	local button = TSMAPI.GUI:CreateButton(frame, 14)
	button:SetHeight(20)
	button:SetPoint("TOPLEFT", frame.stepDesc, "BOTTOMLEFT", 0, -5)
	button:SetPoint("TOPRIGHT", frame.stepDesc, "BOTTOMRIGHT", 0, -5)
	button:SetScript("OnClick", function() end)
	frame.button = button
	
	return frame
end


function private:StartStepWaitThread()
	TSMAPI.Threading:Start(private.GuideThread, 0.1, private.StepComplete)
end

function private:IsStepDone(step)
	if step.isDone and step.isDone() then
		return true
	end
end

function private:GetCurrentStep()
	for i=private.checkPoint, #private.steps do
		if not private:IsStepDone(private.steps[i]) then
			return i
		elseif private.steps[i].isCheckPoint then
			private.checkPoint = i+1
		end
	end
end

function private.GuideThread(self)
	-- loop until the player finishes the step or we abort
	while private.currentStep do
		local stepNum = private:GetCurrentStep()
		if not stepNum then return end
		if stepNum ~= private.currentStep then
			private.currentStep = stepNum
		end
		private.frame.guideFrame:Update()
		self:Sleep(0.1)
	end
end

function private.StepComplete()
	if private.currentStep then
		private.currentStep = -1
		private.frame.guideFrame:Update()
	end
end

function TSMAPI:AssistantEvent(key, ...)
	if not private.stepData then return end
	private.stepData.lastEvent = {key=key, args={...}}
end