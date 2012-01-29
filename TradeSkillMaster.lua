-- This is the main TSM file that holds the majority of the APIs that modules will use.

-- register this file with Ace Libraries
local TSM = select(2, ...)
TSM = LibStub("AceAddon-3.0"):NewAddon(TSM, "TradeSkillMaster", "AceEvent-3.0", "AceConsole-3.0")
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries

local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
TSM.version = GetAddOnMetadata("TradeSkillMaster","X-Curse-Packaged-Version") or GetAddOnMetadata("TradeSkillMaster", "Version") -- current version of the addon
TSM.versionKey = 2


local FRAME_WIDTH = 780 -- width of the entire frame
local FRAME_HEIGHT = 700 -- height of the entire frame
local TREE_WIDTH = 150 -- the width of the tree part of the options frame

TSMAPI = {}
local lib = TSMAPI
local private = {modules={}, iconInfo={}, icons={}, slashCommands={}, modData={}, delays={}, tooltips={}, currentIcon=0}
local tooltip = LibStub("nTipHelper:1")

local savedDBDefaults = {
	profile = {
		minimapIcon = { -- minimap icon position and visibility
			hide = false,
			minimapPos = 220,
			radius = 80,
		},
		infoMessage = 0,
		pricePerUnit = false,
		frameBackdropColor = {r=0, g=0, b=0.05, a=1},
		frameBorderColor = {r=0, g=0, b=1, a=1},
		auctionButtonColors = {
			feature = {
				{r=0.2, g=0.2, b=0.2, a=1}, -- button color
				{r=0.4, g=0.4, b=0.4, a=0.4}, -- highlight color
				{r=0.9, g=0.9, b=0.95, a=1}, -- text color
			},
			control = {
				{r=0.4, g=0.32, b=0.4, a=1}, -- button color
				{r=0.4, g=0.4, b=0.4, a=0.4}, -- highlight color
				{r=0.9, g=0.9, b=0.95, a=1}, -- text color
			},
			action = {
				{r=0.2, g=0.32, b=0.4, a=1}, -- button color
				{r=0.4, g=0.4, b=0.4, a=0.4}, -- highlight color
				{r=0.9, g=0.9, b=0.95, a=1}, -- text color
			},
			action2 = {
				{r=0.32, g=0.32, b=0.4, a=1}, -- button color
				{r=0.59, g=0.53, b=0.51, a=0.4}, -- highlight color
				{r=0.9, g=0.9, b=0.95, a=1}, -- text color
			},
		},
		isDefaultTab = true,
		auctionFrameMovable = true,
		auctionFrameScale = 1,
	},
}

-- Called once the player has loaded WOW.
function TSM:OnInitialize()
	-- load the savedDB into TSM.db
	TSM.db = LibStub:GetLibrary("AceDB-3.0"):New("TradeSkillMasterDB", savedDBDefaults, true)

	-- register the chat commands (slash commands)
	-- whenver '/tsm' or '/tradeskillmaster' is typed by the user, TSM:ChatCommand() will be called
   TSM:RegisterChatCommand("tsm", "ChatCommand")
	TSM:RegisterChatCommand("tradeskillmaster", "ChatCommand")
	
	-- embed LibAuctionScan into TSMAPI
	LibStub("LibAuctionScan-1.0"):Embed(lib)
	
	-- create / register the minimap button
	TSM.LDBIcon = LibStub("LibDataBroker-1.1", true) and LibStub("LibDBIcon-1.0", true)
	local TradeSkillMasterLauncher = LibStub("LibDataBroker-1.1", true):NewDataObject("TradeSkillMaster", {
		type = "launcher",
		icon = "Interface\\Addons\\TradeSkillMaster\\TSM_Icon",
		OnClick = function(_, button) -- fires when a user clicks on the minimap icon
				if button == "LeftButton" then
					-- does the same thing as typing '/tsm'
					TSM:ChatCommand("")
				end
			end,
		OnTooltipShow = function(tt) -- tooltip that shows when you hover over the minimap icon
				local cs = "|cffffffcc"
				local ce = "|r"
				tt:AddLine("TradeSkillMaster " .. TSM.version)
				tt:AddLine(format(L["%sLeft-Click%s to open the main window"], cs, ce))
				tt:AddLine(format(L["%sDrag%s to move this button"], cs, ce))
			end,
		})
	TSM.LDBIcon:Register("TradeSkillMaster", TradeSkillMasterLauncher, TSM.db.profile.minimapIcon)
	
	-- Create Frame which is the main frame of Scroll Master
	TSM.Frame = AceGUI:Create("TSMMainFrame")
	TSM.Frame:SetLayout("Fill")
	TSM.Frame:SetWidth(FRAME_WIDTH)
	TSM.Frame:SetHeight(FRAME_HEIGHT)
	lib:RegisterReleasedModule("TradeSkillMaster", TSM.version, GetAddOnMetadata("TradeSkillMaster", "Author"), L["Provides the main central frame as well as APIs for all TSM modules."], TSM.versionKey)
	lib:RegisterIcon(L["Status"], "Interface\\Icons\\Achievement_Quests_Completed_04", function(...) TSM:LoadOptions(...) end, "TradeSkillMaster", "options")
	
	local oldWidthSet = TSM.Frame.OnWidthSet
	TSM.Frame.OnWidthSet = function(self, width)
			TSM.Frame.localstatus.width = width
			oldWidthSet(self, width)
			TSM:BuildIcons()
		end
	local oldHeightSet = TSM.Frame.OnHeightSet
	TSM.Frame.OnHeightSet = function(self, height)
			TSM.Frame.localstatus.height = height
			oldHeightSet(self, height)
			TSM:BuildIcons()
		end
	
	tooltip:Activate()
	tooltip:AddCallback(function(...) TSM:LoadTooltip(...) end)
end

function TSM:OnEnable()
	lib:CreateTimeDelay("noModules", 3, function()
			if #private.modules == 1 then
				StaticPopupDialogs["TSMModuleWarningPopup"] = {
					text = L["|cffffff00Important Note:|rYou do not currently have any modules installed / enabled for TradeSkillMaster! |cff77ccffYou must download modules for TradeSkillMaster to have some useful functionality!|r\n\nPlease visit http://wow.curse.com/downloads/wow-addons/details/tradeskill-master.aspx and check the project description for links to download modules."],
					button1 = L["I'll Go There Now!"],
					timeout = 0,
					whileDead = true,
					OnAccept = function() TSM:Print(L["Just incase you didn't read this the first time:"]) TSM:Print(L["|cffffff00Important Note:|r You do not currently have any modules installed / enabled for TradeSkillMaster! |cff77ccffYou must download modules for TradeSkillMaster to have some useful functionality!|r\n\nPlease visit http://wow.curse.com/downloads/wow-addons/details/tradeskill-master.aspx and check the project description for links to download modules."]) end,
				}
				StaticPopup_Show("TSMModuleWarningPopup")
			elseif TSM.db.profile.infoMessage < 10 then
				TSM.db.profile.infoMessage = 10
				StaticPopupDialogs["TSMInfoPopup"] = {
					text = L["Welcome to the release version of TradeSkillMaster!\n\nIf you ever need help with TSM, check out the resources listed on the first page of the main TSM window (type /tsm or click the minimap icon)!"],
					button1 = L["Thanks!"],
					timeout = 0,
					whileDead = true,
				}
				StaticPopup_Show("TSMInfoPopup")
			end
		end)
	lib:CreateTimeDelay("tsm_test", 1, Check)
end

function lib:GetNumModules()
	return #private.modules
end

function TSM:LoadTooltip(tipFrame, link, quantity)
	local itemID = lib:GetItemID(link)
	if not itemID then return end
	
	local lines = {}
	for _, v in ipairs(private.tooltips) do
		local moduleLines = v.loadFunc(itemID, quantity)
		if type(moduleLines) ~= "table" then moduleLines = {} end
		for _, line in ipairs(moduleLines) do
			tinsert(lines, line)
		end
	end
	
	if #lines > 0 then
		tooltip:SetFrame(tipFrame)
		tooltip:AddLine(" ", nil, true)
		tooltip:SetColor(1,1,0)
		tooltip:AddLine(L["TradeSkillMaster Info:"], nil, true)
		tooltip:SetColor(0.4,0.4,0.9)
		
		for i=1, #lines do
			tooltip:AddLine(lines[i], nil, true)
		end
		
		tooltip:AddLine(" ", nil, true)
	end
end

-- deals with slash commands
function TSM:ChatCommand(oInput)
	local input, extraValue
	local sStart, sEnd = strfind(oInput, "  ")
	if sStart and sEnd then
		input = strsub(oInput, 1, sStart-1)
		extraValue = strsub(oInput, sEnd+1)
	else
		local inputs = {strsplit(" ", oInput)}
		input = inputs[1]
		extraValue = inputs[2]
		for i=3, #(inputs) do
			extraValue = extraValue .. " " .. inputs[i]
		end
	end
	
	if input == "" then	-- '/tsm' opens up the main window to the status page
		TSM.Frame:Show()
		if #TSM.Frame.children > 0 then
			TSM.Frame:ReleaseChildren()
		end
		if not private.icons[private.currentIcon] then
			for i=1, #(private.icons) do
				if private.icons[i].name==L["Status"] then
					private.icons[i].loadGUI(TSM.Frame)
					local name
					for _, module in pairs(private.modules) do
						if module.name == private.icons[i].moduleName then
							name = module.name
							version = module.version
						end
					end
					TSM.Frame:SetTitle((name or private.icons[i].moduleName) .. " " .. version)
					break
				end
			end
		else
			private.icons[private.currentIcon].loadGUI(TSM.Frame)
			local name
			for _, module in pairs(private.modules) do
				if module.name == private.icons[private.currentIcon].moduleName then
					name = module.name
					version = module.version
				end
			end
			TSM.Frame:SetTitle((name or private.icons[i].moduleName) .. " " .. version)
		end
		TSM:BuildIcons()
		lib:SetStatusText("")
	else -- go through our Module-specific commands
		local found=false
		for _,v in ipairs(private.slashCommands) do
			if input == v.cmd then
				found = true
				if v.isLoadFunc then
					if #(TSM.Frame.children) > 0 then
						TSM.Frame:ReleaseChildren()
						lib:SetStatusText("")
					end
					v.loadFunc(self, TSM.Frame, extraValue)
					TSM.Frame:Show()
				else
					v.loadFunc(self, extraValue)
				end
			end
		end
		if not found then
			TSM:Print(L["Slash Commands:"])
			print("|cffffaa00"..L["/tsm|r - opens the main TSM window."])
			print("|cffffaa00"..L["/tsm help|r - Shows this help listing"])
			
			for _,v in ipairs(private.slashCommands) do
				print("|cffffaa00/tsm " .. v.cmd .. "|r - " .. v.desc)
			end
		end
    end
end

function lib:RegisterModule(...)
	error(format(L["Module \"%s\" is out of date. Please update."], ...), 2)
end

-- registers a module with TSM
function lib:RegisterReleasedModule(moduleName, version, authors, desc, versionKey)
	if not (moduleName and version and authors and desc) then
		return nil, "invalid args", moduleName, version, authors, desc
	end
	
	tinsert(private.modules, {name=moduleName, version=version, authors=authors, desc=desc, versionKey=versionKey})
end

-- returns the versionKey for the passed module
-- used when one module requires a certain version or higher of another module
function lib:GetVersionKey(moduleName)
	if not moduleName then return nil, "no module name passed" end
	for i=1, #private.modules do
		if private.modules[i].name == moduleName then
			return private.modules[i].versionKey
		end
	end
end

-- registers a new icon to be displayed around the border of the TSM frame
function lib:RegisterIcon(displayName, icon, loadGUI, moduleName, side)
	if not (displayName and icon and loadGUI and moduleName) then
		return nil, "invalid args", displayName, icon, loadGUI, moduleName
	end
	
	if not TSM:CheckModuleName(moduleName) then
		return nil, "No module registered under name: " .. moduleName
	end
	
	if side and not (side == "module" or side == "crafting" or side == "options") then
		return nil, "invalid side", side
	end
	
	tinsert(private.icons, {name=displayName, moduleName=moduleName, icon=icon, loadGUI=loadGUI, side=(strlower(side or "module"))})
end

-- registers a slash command with TSM
--  cmd : the slash command (after /tsm)
--  loadFunc : the function called when the slash command is executed
--  desc : a brief description of the command for help
--  notLoadFunc : set to true if loadFunc does not use the TSM GUI
function lib:RegisterSlashCommand(cmd, loadFunc, desc, notLoadFunc)
	if not desc then
		desc = L["No help provided."]
	end
	
	if not loadFunc then
		return nil, "no function provided"
	elseif not cmd then
		return nil, "no command provided"
	elseif cmd=="test" or cmd=="debug" or cmd=="help" or cmd=="" then
		return nil, "reserved command provided"
	end
	
	tinsert(private.slashCommands, {cmd=cmd, loadFunc=loadFunc, desc=desc, isLoadFunc=not notLoadFunc})
end

-- API to register an addon to show info in a tooltip
function lib:RegisterTooltip(moduleName, loadFunc)
	if not (moduleName and loadFunc) then
		return nil, "Invalid arguments", moduleName, loadFunc
	elseif not TSM:CheckModuleName(moduleName) then
		return nil, "No module registered under name: " .. moduleName
	end
	tinsert(private.tooltips, {module=moduleName, loadFunc=loadFunc})
end

function lib:UnregisterTooltip(moduleName)
	if not TSM:CheckModuleName(moduleName) then
		return nil, "No module registered under name: " .. moduleName
	end
	
	for i, v in pairs(private.tooltips) do
		if v.module == moduleName then
			tremove(private.tooltips, i)
			return
		end
	end
end

-- API to interface with :SetPoint()
function lib:SetFramePoint(point, relativeFrame, relativePoint, ofsx, ofsy)
	TSM.Frame:ClearAllPoints()
	TSM.Frame:SetPoint(point, relativeFrame, relativePoint, ofsx, ofsy)
end

-- set the frame size to the specified width and height then re-layout the icons
-- as well as reset the frame to the default point in the center of the screen
function lib:SetFrameSize(width, height)
	TSM.Frame:SetWidth(width)
	TSM.Frame:SetHeight(height)
	TSM.Frame.localstatus.width = width
	TSM.Frame.localstatus.height = height
	TSM:BuildIcons()
	TSM.Frame:ClearAllPoints()
	TSM.Frame:SetPoint("CENTER", UIParent, "CENTER")
end

function lib:SetStatusText(statusText)
	if statusText and statusText:trim() ~= "" then
		TSM.Frame:SetStatusText(statusText)
	else
		TSM.Frame:SetStatusText("|cffffd200"..L["Tip:"].." |r"..TSM:GetTip())
	end
end

function lib:CloseFrame()
	TSM.Frame:Hide()
end

function lib:OpenFrame()
	TSM.Frame:Show()
	TSM:BuildIcons()
end

function lib:RegisterData(label, dataFunc)
	label = strlower(label)
	private.modData[label] = dataFunc
end

function lib:GetData(label, ...)
	label = strlower(label)
	if private.modData[label] then
		return private.modData[label](self, ...)
	end
	
	return nil, "no data for that label"
end

function lib:GetItemID(itemLink, ignoreGemID)
	if not itemLink or type(itemLink) ~= "string" then return nil, "invalid args" end
	
	local test = select(2, strsplit(":", itemLink))
	if not test then return nil, "invalid link" end
	
	local s, e = strfind(test, "[0-9]+")
	if not (s and e) then return nil, "not an itemLink" end
	
	local itemID = tonumber(strsub(test, s, e))
	if not itemID then return nil, "invalid number" end
	
	return (not ignoreGemID and lib:GetNewGem(itemID)) or itemID
end

function lib:GetItemString(itemLink)
	if type(itemLink) ~= "string" and type(itemLink) ~= "number" then
		return nil, "invalid arg type"
	end
	itemLink = select(2, GetItemInfo(itemLink)) or itemLink
	if tonumber(itemLink) then
		return "item:"..itemLink..":0:0:0:0:0:0"
	end
	
	local itemInfo = {strfind(itemLink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%-?%d*):?(%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")}
	if not itemInfo[11] then return nil, "invalid link" end
	
	return table.concat(itemInfo, ":", 4, 11)
end

local GOLD_TEXT = "|cffffd700g|r"
local SILVER_TEXT = "|cffc7c7cfs|r"
local COPPER_TEXT = "|cffeda55fc|r"

local function PadNumber(num, pad)
	if num < 10 and pad then
		return format("%3d", num)
	end
	
	return tostring(num)
end

function lib:FormatTextMoney(money, color, pad)
	local money = tonumber(money)
	if not money then return end
	local gold = floor(money / COPPER_PER_GOLD)
	local silver = floor((money - (gold * COPPER_PER_GOLD)) / COPPER_PER_SILVER)
	local copper = floor(money%COPPER_PER_SILVER)
	local text = ""
	
	-- Add gold
	if gold > 0 then
		if color then
			text = format("%s%s ", color..PadNumber(gold, pad).."|r", GOLD_TEXT)
		else
			text = format("%s%s ", PadNumber(gold, pad), GOLD_TEXT)
		end
	end
	
	-- Add silver
	if gold > 0 or silver > 0 then
		if color then
			text = format("%s%s%s ", text, color..PadNumber(silver, pad).."|r", SILVER_TEXT)
		else
			text = format("%s%s%s ", text, PadNumber(silver, pad), SILVER_TEXT)
		end
	end
	
	-- Add copper
	if color then
		text = format("%s%s%s ", text, color..PadNumber(copper, pad).."|r", COPPER_TEXT)
	else
		text = format("%s%s%s ", text, PadNumber(copper, pad), COPPER_TEXT)
	end
	
	return text:trim()
end

function lib:SafeDivide(a, b)
	if b == 0 then
		if a > 0 then
			return math.huge
		elseif a < 0 then
			return -math.huge
		else
			return log(-1)
		end
	end
	
	return a / b
end

function lib:ShowStaticPopupDialog(name)
	StaticPopup_Show(name)
	for i=1, 100 do
		if _G["StaticPopup" .. i] and _G["StaticPopup" .. i].which == name then
			_G["StaticPopup" .. i]:SetFrameStrata("TOOLTIP")
			break
		end
	end
end

function lib:SelectIcon(moduleName, iconName)
	if not moduleName then return nil, "no moduleName passed" end
	
	if not TSM:CheckModuleName(moduleName) then
		return nil, "No module registered under name: " .. moduleName
	end
	
	for _, data in pairs(private.icons) do
		if not data.frame then return nil, "not ready yet" end
		if data.moduleName == moduleName and data.name == iconName then
			data.frame:Click()
		end
	end
end

function lib:CreateTimeDelay(label, duration, callback, repeatDelay)
	if not (label and type(duration) == "number" and type(callback) == "function") then return nil, "invalid args", label, duration, callback, repeatDelay end

	local frameNum
	for i, frame in ipairs(private.delays) do
		if frame.label == label then return end
		if not frame.inUse then
			frameNum = i
		end
	end
	
	if not frameNum then
		local delay = CreateFrame("Frame")
		delay:Hide()
		tinsert(private.delays, delay)
		frameNum = #private.delays
	end
	
	local frame = private.delays[frameNum]
	frame.inUse = true
	frame.repeatDelay = repeatDelay
	frame.label = label
	frame.timeLeft = duration
	frame:SetScript("OnUpdate", function(self, elapsed)
		self.timeLeft = self.timeLeft - elapsed
		if self.timeLeft <= 0 then
			if self.repeatDelay then
				self.timeLeft = self.repeatDelay
			else
				lib:CancelFrame(self)
			end
			callback()
		end
	end)
	frame:Show()
end

function lib:CreateFunctionRepeat(label, callback)
	local callbackIsValid = type(callback) == "function"
	if not (label and callbackIsValid) then return nil, "invalid args", label, callback end

	local frameNum
	for i, frame in pairs(private.delays) do
		if frame.label == label then return end
		if not frame.inUse then
			frameNum = i
		end
	end
	
	if not frameNum then
		local delay = CreateFrame("Frame")
		delay:Hide()
		tinsert(private.delays, delay)
		frameNum = #private.delays
	end
	
	local frame = private.delays[frameNum]
	frame.inUse = true
	frame.repeatDelay = repeatDelay
	frame.label = label
	frame.validate = duration
	frame:SetScript("OnUpdate", function(self)
		callback()
	end)
	frame:Show()
end

function lib:CancelFrame(label)
	local delayFrame
	if type(label) == "table" then
		delayFrame = label
	else
		for i, frame in pairs(private.delays) do
			if frame.label == label then
				delayFrame = frame
			end
		end
	end
	
	if delayFrame then
		delayFrame:Hide()
		delayFrame.label = nil
		delayFrame.inUse = false
		delayFrame.validate = nil
		delayFrame.timeLeft = nil
		delayFrame:SetScript("OnUpdate", nil)
	end
end

function lib:SafeDivide(a, b)
	if b == 0 then
		if a > 0 then
			return math.huge
		elseif a < 0 then
			return -math.huge
		else
			return log(-1)
		end
	end
	
	return a / b
end

function TSM:CheckModuleName(moduleName)
	for _, module in ipairs(private.modules) do
		if module.name == moduleName then
			return true
		end
	end
end

function TSM:BuildIcons()
	local numItems = {left=0, right=0, bottom=0}
	local count = {left=0, right=0, bottom=0}
	local spacing = {}
	
	for _, data in pairs(private.icons) do
		if data.frame then 
			data.frame:Hide()
		end
		if data.side == "crafting" then
			numItems.left = numItems.left + 1
		elseif data.side == "options" then
			numItems.right = numItems.right + 1
		else
			numItems.bottom = numItems.bottom + 1
		end
	end
	
	spacing.left = min(lib:SafeDivide(TSM.Frame.craftingIconContainer:GetHeight() - 10, numItems.left), 200)
	spacing.right = min(lib:SafeDivide(TSM.Frame.optionsIconContainer:GetHeight() - 10, numItems.right), 200)
	spacing.bottom = min(lib:SafeDivide(TSM.Frame.moduleIconContainer:GetWidth() - 10, numItems.bottom), 200)

	for i=1, #(private.icons) do
		local frame = nil
		if private.icons[i].frame then
			frame = private.icons[i].frame
			frame:Show()
		else
			frame = CreateFrame("Button", nil, TSM.Frame.frame)
			frame:SetScript("OnClick", function()
					if #(TSM.Frame.children) > 0 then
						TSM.Frame:ReleaseChildren()
						lib:SetStatusText("")
					end
					local name, version
					for _, module in ipairs(private.modules) do
						if module.name == private.icons[i].moduleName then
							name = module.name
							version = module.version
						end
					end
					TSM.Frame:SetTitle((name or private.icons[i].moduleName) .. " " .. version)
					private.icons[i].loadGUI(TSM.Frame)
					private.currentIcon = i
				end)
			frame:SetScript("OnEnter", function(self)
					if private.icons[i].side == "options" then
						GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 5, -20)
					elseif private.icons[i].side == "crafting" then
						GameTooltip:SetOwner(self, "ANCHOR_LEFT", -5, -20)
					else
						GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
					end
					GameTooltip:SetText(private.icons[i].name)
					GameTooltip:Show()
				end)
			frame:SetScript("OnLeave", function(self) GameTooltip:Hide() end)

			local image = frame:CreateTexture(nil, "BACKGROUND")
			image:SetWidth(40)
			image:SetHeight(40)
			image:SetPoint("TOP")
			frame.image = image

			local highlight = frame:CreateTexture(nil, "HIGHLIGHT")
			highlight:SetAllPoints(image)
			highlight:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight")
			highlight:SetTexCoord(0, 1, 0.23, 0.77)
			highlight:SetBlendMode("ADD")
			frame.highlight = highlight
			
			frame:SetHeight(40)
			frame:SetWidth(40)
			frame.image:SetTexture(private.icons[i].icon)
			frame.image:SetVertexColor(1, 1, 1)
			
			private.icons[i].frame = frame
		end
		
		if private.icons[i].side == "crafting" then
			count.left = count.left + 1
			frame:SetPoint("BOTTOMLEFT", TSM.Frame.craftingIconContainer, "TOPLEFT", 10, -((count.left-1)*spacing.left)-50)
		elseif private.icons[i].side == "options" then
			count.right = count.right + 1
			frame:SetPoint("BOTTOMLEFT", TSM.Frame.optionsIconContainer, "TOPLEFT", 11, -((count.right-1)*spacing.right)-50)
		else
			count.bottom = count.bottom + 1
			frame:SetPoint("BOTTOMLEFT", TSM.Frame.moduleIconContainer, "BOTTOMLEFT", ((count.bottom-1)*spacing.bottom)+10, 7)
		end
	end
	local minHeight = max(max(numItems.left, numItems.right)*50, 200)
	local minWidth = max(numItems.bottom*50, 400)
	TSM.Frame.frame:SetMinResize(minWidth, minHeight)
end

function TSM:LoadOptions(parent)
	local CYAN = "|cff99ffff"

	local function LoadHelpPage(parent)
		local page = {
			{
				type = "ScrollFrame",
				layout = "flow",
				children = {
					{
						type = "InlineGroup",
						layout = "flow",
						title = L["TSM Help Resources"],
						children = {
							{
								type = "Label",
								text = CYAN .. L["Need help with TSM? Check out the following resources!"] .. "\n\n",
								fullWidth = true,
							},
							{
								type = "Label",
								text = L["Official TradeSkillMaster Forum:"] .. " |cffffd200http://stormspire.net/official-tradeskillmaster-development-forum/|r\n",
								fullWidth = true,
							},
							{
								type = "Label",
								text = L["TradeSkillMaster IRC Channel:"] .. " |cffffd200http://tradeskillmaster.wikispaces.com/IRC|r\n",
								fullWidth = true,
							},
							{
								type = "Label",
								text = L["TradeSkillMaster Website:"] .. " |cffffd200http://tradeskillmaster.com|r\n",
								fullWidth = true,
							},
						},
					},
					{
						type = "InlineGroup",
						layout = "flow",
						title = "TradeSkillMaster Module Info",
						children = {
							{
								type = "Label",
								text = L["TradeSkillMaster currently has 9 modules (not including the core addon) each of which can be used completely independantly of the others and have unique features."] .. "\n\n",
								fullWidth = true,
							},
							{
								type = "Label",
								text = CYAN .. "Accounting" .. "|r - " .. L["Keeps track of all your sales and purchases from the auction house allowing you to easily track your income and expendatures and make sure you're turning a profit."] .. "\n",
								fullWidth = true,
							},
							{
								type = "Label",
								text = CYAN .. "AuctionDB" .. "|r - " .. L["Performs scans of the auction house and calculates the market value of items as well as the minimum buyout. This information can be shown in items' tooltips as well as used by other modules."] .. "\n",
								fullWidth = true,
							},
							{
								type = "Label",
								text = CYAN .. "Auctioning" .. "|r - " .. L["Posts and cancels your auctions to / from the auction house accorder to pre-set rules. Also, this module can show you markets which are ripe for being reset for a profit."] .. "\n",
								fullWidth = true,
							},
							{
								type = "Label",
								text = CYAN .. "Crafting" .. "|r - " .. L["Allows you to build a queue of crafts that will produce a profitable, see what materials you need to obtain, and actually craft the items."] .. "\n",
								fullWidth = true,
							},
							{
								type = "Label",
								text = CYAN .. "Destroying" .. "|r - " .. L["Mills, prospects, and disenchants items at super speed!"] .. "\n",
								fullWidth = true,
							},
							{
								type = "Label",
								text = CYAN .. "ItemTracker" .. "|r - " .. L["Tracks and manages your inventory across multiple characters including your bags, bank, and guild bank."] .. "\n",
								fullWidth = true,
							},
							{
								type = "Label",
								text = CYAN .. "Mailing" .. "|r - " .. L["Allows you to quickly and easily empty your mailbox as well as automatically send items to other characters with the single click of a button."] .. "\n",
								fullWidth = true,
							},
							{
								type = "Label",
								text = CYAN .. "Shopping" .. "|r - " .. L["Provides interfaces for efficiently searching for items on the auction house. When an item is found, it can easily be bought, canceled (if it's yours), or even posted from your bags."] .. "\n",
								fullWidth = true,
							},
							{
								type = "Label",
								text = CYAN .. "Warehousing" .. "|r - " .. L["Manages your inventory by allowing you to easily move stuff between your bags, bank, and guild bank."] .. "\n",
								fullWidth = true,
							},
						},
					},
				},
			},
		}
	
		lib:BuildPage(parent, page)
	end

	local function LoadStatusPage(parent)
		local page = {
			{
				type = "ScrollFrame",
				layout = "flow",
				children = {
					{
						type = "InlineGroup",
						layout = "flow",
						title = L["Installed Modules"],
						children = {},
					},
					{
						type = "InlineGroup",
						layout = "flow",
						title = L["Credits"],
						children = {
							{
								type = "Label",
								text = L["TradeSkillMaster Team:"],
								relativeWidth = 1,
								fontObject = GameFontHighlightLarge,
							},
							{
								type = "Label",
								text = "|cffffbb00"..L["Lead Developer and Project Manager:"].."|r Sapu94",
								relativeWidth = 1,
							},
							{
								type = "Label",
								text = "|cffffbb00"..L["Active Developers:"].."|r Geemoney, Drethic, Fancyclaps",
								relativeWidth = 1,
							},
							{
								type = "Label",
								text = "|cffffbb00"..L["Testers (Special Thanks):"].."|r Acry, Vith, Quietstrm07, Cryan",
								relativeWidth = 1,
							},
							{
								type = "Label",
								text = "|cffffbb00"..L["Past Contributors:"].."|r Cente, Mischanix, Xubera, cduhn, cjo20",
								relativeWidth = 1,
							},
							-- {
								-- type = "Label",
								-- text = "|cffffbb00"..L["Translators:"].."|r ".."Pataya"..CYAN.."(frFR)".."|r"..", rachelka"..CYAN.."(ruRU)".."|r"..", Duco"..CYAN.."(deDE)".."|r"..", Wolf15"..CYAN.."(esMX)".."|r"..", MauleR"..CYAN.."(ruRU)".."|r"..", Kennyal"..CYAN.."(deDE)".."|r"..", Flyhard"..CYAN.."(deDE)".."|r"..", trevyn"..CYAN.."(deDE)".."|r"..", foxdodo"..CYAN.."(zhCN)".."|r"..", wyf115"..CYAN.."(zhTW)".."|r"..", and many others!",
								-- relativeWidth = 1,
							-- },
						},
					},
				},
			},
		}
		
		for i, module in ipairs(private.modules) do
			local moduleWidgets = {
				type = "SimpleGroup",
				relativeWidth = 0.49,
				layout = "list",
				children = {
					{
						type = "Label",
						text = "|cffffbb00"..L["Module:"].."|r"..module.name,
						fullWidth = true,
						fontObject = GameFontNormalLarge,
					},
					{
						type = "Label",
						text = "|cffffbb00"..L["Version:"].."|r"..module.version,
						fullWidth = true,
					},
					{
						type = "Label",
						text = "|cffffbb00"..L["Author(s):"].."|r"..module.authors,
						fullWidth = true,
					},
					{
						type = "Label",
						text = "|cffffbb00"..L["Description:"].."|r"..module.desc,
						fullWidth = true,
					},
				},
			}
			
			if i > 2 then
				tinsert(moduleWidgets.children, 1, {type = "Spacer"})
			end
			tinsert(page[1].children[1].children, moduleWidgets)
		end
		
		if #private.modules == 1 then
			local warningText = {
				type = "Label",
				text = "\n|cffff0000"..L["No modules are currently loaded.  Enable or download some for full functionality!"].."\n\n|r",
				fullWidth = true,
				fontObject = GameFontNormalLarge,
			}
			tinsert(page[1].children[1].children, warningText)
			
			local warningText2 = {
				type = "Label",
				text = "\n|cffff0000"..format(L["Visit %s for information about the different TradeSkillMaster modules as well as download links."], "http://www.curse.com/addons/wow/tradeskill-master").."|r",
				fullWidth = true,
				fontObject = GameFontNormalLarge,
			}
			tinsert(page[1].children[1].children, warningText2)
		end
		
		lib:BuildPage(parent, page)
	end
	
	local function LoadOptionsPage(parent)
		local page = {
			{
				type = "ScrollFrame",
				layout = "flow",
				children = {
					{
						type = "InlineGroup",
						layout = "flow",
						title = L["General Settings"],
						children = {
							{
								type = "CheckBox",
								label = L["Hide Minimap Icon"],
								quickCBInfo = {TSM.db.profile.minimapIcon, "hide"},
								relativeWidth = 0.5,
								callback = function(_,_,value)
										if value then
											TSM.LDBIcon:Hide("TradeSkillMaster")
										else
											TSM.LDBIcon:Show("TradeSkillMaster")
										end
									end,
							},
							{
								type = "Button",
								text = L["New Tip"],
								relativeWidth = 0.5,
								callback = lib.ForceNewTip,
								tooltip = L["Changes the tip showing at the bottom of the main TSM window."],
							},
						},
					},
					{
						type = "InlineGroup",
						layout = "flow",
						title = L["Auction House Tab Settings"],
						children = {
							{
								type = "CheckBox",
								label = L["Make TSM Default Auction House Tab"],
								quickCBInfo = {TSM.db.profile, "isDefaultTab"},
								relativeWidth = 0.5,
							},
							{
								type = "CheckBox",
								label = L["Make Auction Frame Movable"],
								quickCBInfo = {TSM.db.profile, "auctionFrameMovable"},
								relativeWidth = 0.5,
								callback = function(_,_,value) AuctionFrame:SetMovable(value) end,
							},
							{
								type = "Slider",
								label = L["Auction Frame Scale"],
								value = TSM.db.profile.auctionFrameScale,
								isPercent = true,
								relativeWidth = 0.5,
								min = 0.1,
								max = 2,
								step = 0.05,
								callback = function(_,_,value)
										TSM.db.profile.auctionFrameScale = value
										AuctionFrame:SetScale(value)
									end,
								tooltip = L["Changes the size of the auction frame. The size of the detached TSM auction frame will always be the same as the main auction frame."],
							},
						},
					},
					{
						type = "InlineGroup",
						layout = "flow",
						title = L["Auction House Tab Button Colors"],
						children = {
							{
								type = "Label",
								text = L["Use the options below to change the color of the various buttons used in the TSM auction house tab."],
								fullWidth = 1,
							},
							{
								type = "HeadingLine"
							},
							{
								type = "ColorPicker",
								label = L["Feature Button Color"],
								relativeWidth = 0.33,
								value = TSM.db.profile.auctionButtonColors.feature[1],
								callback = function(_,_,r,g,b)
										local alpha = TSM.db.profile.auctionButtonColors.feature[1].a
										TSM.db.profile.auctionButtonColors.feature[1] = {r=r, g=g, b=b, a=alpha}
										TSM:UpdateAuctionButtonColors()
									end,
							},
							{
								type = "ColorPicker",
								label = L["Feature Highlight Color"],
								relativeWidth = 0.33,
								value = TSM.db.profile.auctionButtonColors.feature[2],
								callback = function(_,_,r,g,b)
										local alpha = TSM.db.profile.auctionButtonColors.feature[2].a
										TSM.db.profile.auctionButtonColors.feature[2] = {r=r, g=g, b=b, a=alpha}
										TSM:UpdateAuctionButtonColors()
									end,
							},
							{
								type = "ColorPicker",
								label = L["Feature Text Color"],
								relativeWidth = 0.33,
								value = TSM.db.profile.auctionButtonColors.feature[3],
								callback = function(_,_,r,g,b)
										local alpha = TSM.db.profile.auctionButtonColors.feature[3].a
										TSM.db.profile.auctionButtonColors.feature[3] = {r=r, g=g, b=b, a=alpha}
										TSM:UpdateAuctionButtonColors()
									end,
							},
							{
								type = "HeadingLine"
							},
							{
								type = "ColorPicker",
								label = L["Control Button Color"],
								relativeWidth = 0.33,
								value = TSM.db.profile.auctionButtonColors.control[1],
								callback = function(_,_,r,g,b)
										local alpha = TSM.db.profile.auctionButtonColors.control[1].a
										TSM.db.profile.auctionButtonColors.control[1] = {r=r, g=g, b=b, a=alpha}
										TSM:UpdateAuctionButtonColors()
									end,
							},
							{
								type = "ColorPicker",
								label = L["Control Highlight Color"],
								relativeWidth = 0.33,
								value = TSM.db.profile.auctionButtonColors.control[2],
								callback = function(_,_,r,g,b)
										local alpha = TSM.db.profile.auctionButtonColors.control[2].a
										TSM.db.profile.auctionButtonColors.control[2] = {r=r, g=g, b=b, a=alpha}
										TSM:UpdateAuctionButtonColors()
									end,
							},
							{
								type = "ColorPicker",
								label = L["Control Text Color"],
								relativeWidth = 0.33,
								value = TSM.db.profile.auctionButtonColors.control[3],
								callback = function(_,_,r,g,b)
										local alpha = TSM.db.profile.auctionButtonColors.control[3].a
										TSM.db.profile.auctionButtonColors.control[3] = {r=r, g=g, b=b, a=alpha}
										TSM:UpdateAuctionButtonColors()
									end,
							},
							{
								type = "HeadingLine"
							},
							{
								type = "ColorPicker",
								label = L["Action Button Color"],
								relativeWidth = 0.33,
								value = TSM.db.profile.auctionButtonColors.action[1],
								callback = function(_,_,r,g,b)
										local alpha = TSM.db.profile.auctionButtonColors.action[1].a
										TSM.db.profile.auctionButtonColors.action[1] = {r=r, g=g, b=b, a=alpha}
										TSM:UpdateAuctionButtonColors()
									end,
							},
							{
								type = "ColorPicker",
								label = L["Action Highlight Color"],
								relativeWidth = 0.33,
								value = TSM.db.profile.auctionButtonColors.action[2],
								callback = function(_,_,r,g,b)
										local alpha = TSM.db.profile.auctionButtonColors.action[2].a
										TSM.db.profile.auctionButtonColors.action[2] = {r=r, g=g, b=b, a=alpha}
										TSM:UpdateAuctionButtonColors()
									end,
							},
							{
								type = "ColorPicker",
								label = L["Action Text Color"],
								relativeWidth = 0.33,
								value = TSM.db.profile.auctionButtonColors.action[3],
								callback = function(_,_,r,g,b)
										local alpha = TSM.db.profile.auctionButtonColors.action[3].a
										TSM.db.profile.auctionButtonColors.action[3] = {r=r, g=g, b=b, a=alpha}
										TSM:UpdateAuctionButtonColors()
									end,
							},
							{
								type = "HeadingLine"
							},
							{
								type = "ColorPicker",
								label = L["Action2 Button Color"],
								relativeWidth = 0.33,
								value = TSM.db.profile.auctionButtonColors.action2[1],
								callback = function(_,_,r,g,b)
										local alpha = TSM.db.profile.auctionButtonColors.action2[1].a
										TSM.db.profile.auctionButtonColors.action2[1] = {r=r, g=g, b=b, a=alpha}
										TSM:UpdateAuctionButtonColors()
									end,
							},
							{
								type = "ColorPicker",
								label = L["Action2 Highlight Color"],
								relativeWidth = 0.33,
								value = TSM.db.profile.auctionButtonColors.action2[2],
								callback = function(_,_,r,g,b)
										local alpha = TSM.db.profile.auctionButtonColors.action2[2].a
										TSM.db.profile.auctionButtonColors.action2[2] = {r=r, g=g, b=b, a=alpha}
										TSM:UpdateAuctionButtonColors()
									end,
							},
							{
								type = "ColorPicker",
								label = L["Action2 Text Color"],
								relativeWidth = 0.33,
								value = TSM.db.profile.auctionButtonColors.action2[3],
								callback = function(_,_,r,g,b)
										local alpha = TSM.db.profile.auctionButtonColors.action2[3].a
										TSM.db.profile.auctionButtonColors.action2[3] = {r=r, g=g, b=b, a=alpha}
										TSM:UpdateAuctionButtonColors()
									end,
							},
							{
								type = "HeadingLine"
							},
							{
								type = "Button",
								text = L["Restore Default Colors"],
								relativeWidth = 1,
								callback = function() TSM:RestoreDefaultColors() parent:SelectTab(3) end,
								tooltip = L["Restores all the color settings below to their default values."],
							},
						},
					},
					{
						type = "InlineGroup",
						layout = "flow",
						title = L["Main TSM Frame Colors"],
						children = {
							{
								type = "Label",
								text = L["Use the options below to change the color of the various TSM frames including this frame as well as the Craft Management Window."],
								fullWidth = 1,
							},
							{
								type = "HeadingLine"
							},
							{
								type = "ColorPicker",
								label = L["Backdrop Color"],
								relativeWidth = 0.5,
								hasAlpha = true,
								value = TSM.db.profile.frameBackdropColor,
								callback = function(_,_,r,g,b,a)
										TSM.db.profile.frameBackdropColor = {r=r, g=g, b=b, a=a}
										TSM:UpdateFrameColors()
									end,
							},
							{
								type = "ColorPicker",
								label = L["Border Color"],
								relativeWidth = 0.49,
								hasAlpha = true,
								value = TSM.db.profile.frameBorderColor,
								callback = function(_,_,r,g,b,a)
										TSM.db.profile.frameBorderColor = {r=r, g=g, b=b, a=a}
										TSM:UpdateFrameColors()
									end,
							},
						},
					},
				},
			},
		}
		
		lib:BuildPage(parent, page)
	end
	
	lib:SetFrameSize(FRAME_WIDTH, FRAME_HEIGHT)
	
	local tg = AceGUI:Create("TSMTabGroup")
	tg:SetLayout("Fill")
	tg:SetFullWidth(true)
	tg:SetFullHeight(true)
	tg:SetTabs({{value=1, text=L["TSM Info / Help"]}, {value=2, text=L["Status / Credits"]}, {value=3, text=L["Options"]}})
	tg:SetCallback("OnGroupSelected", function(self,_,value)
		tg:ReleaseChildren()
		
		if value == 1 then
			LoadHelpPage(self)
		elseif value == 2 then
			LoadStatusPage(self)
		elseif value == 3 then
			LoadOptionsPage(self)
		end
	end)
	parent:AddChild(tg)
	tg:SelectTab(1)
end

-- TSM:UpdateFrameColors() is defined in TSMCustomContainers.lua
function TSM:RestoreDefaultColors()
	local colorOptions = {"frameBackdropColor", "frameBorderColor", "auctionButtonColors"}
	for _, option in ipairs(colorOptions) do
		TSM.db.profile[option] = CopyTable(savedDBDefaults.profile[option])
	end
	TSM:UpdateFrameColors()
end

function lib:GetBackdropColor()
	local color = TSM.db.profile.frameBackdropColor
	return color.r, color.g, color.b, color.a
end

function lib:GetBorderColor()
	local color = TSM.db.profile.frameBorderColor
	return color.r, color.g, color.b, color.a
end

local coloredFrames = {}

function TSM:UpdateCustomFrameColors()
	for _, frame in ipairs(coloredFrames) do
		frame:SetBackdropColor(lib:GetBackdropColor())
		frame:SetBackdropBorderColor(lib:GetBorderColor())
	end
end

function lib:RegisterForColorChanges(frame)
	tinsert(coloredFrames, frame)
	frame:SetBackdropColor(lib:GetBackdropColor())
	frame:SetBackdropBorderColor(lib:GetBorderColor())
end


local itemsToCache = {}

local function UpdateCache()
	local maxIndex = min(#itemsToCache, 100)
	for i=maxIndex, 1, -1 do
		if GetItemInfo(itemsToCache[i]) then
			tremove(itemsToCache, i)
		end
	end
	
	if #itemsToCache == 0 then
		lib:CancelFrame("TSMItemInfoCache")
	end
end

function lib:GetItemInfoCache(items, isKey)
	if isKey then
		for item in pairs(items) do
			tinsert(itemsToCache, item)
		end
	else
		for _, item in ipairs(items) do
			tinsert(itemsToCache, item)
		end
	end

	if #itemsToCache > 0 then
		lib:CreateTimeDelay("TSMItemInfoCache", 1, UpdateCache, 0.2)
	end
end