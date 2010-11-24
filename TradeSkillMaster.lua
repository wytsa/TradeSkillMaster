-- This is the main TSM file that holds the majority of the APIs that modules will use.

-- register this file with Ace Libraries
local TSM = select(2, ...)
TSM = LibStub("AceAddon-3.0"):NewAddon(TSM, "TradeSkillMaster", "AceEvent-3.0", "AceConsole-3.0")
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries

local aceL = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
TSM.version = GetAddOnMetadata("TradeSkillMaster", "Version") -- current version of the addon

local function L(phrase)
	--TSM.lTable[phrase] = true
	return aceL[phrase]
end

-- stuff for debugging TSM
local TSMDebug = false
function TSM:Debug(...)
	if TSMdebug then
		print(...)
	end
end
local debug = function(...) TSM:Debug(...) end

local FRAME_WIDTH = 780 -- width of the entire frame
local FRAME_HEIGHT = 700 -- height of the entire frame
local TREE_WIDTH = 150 -- the width of the tree part of the options frame

TSMAPI = {}
local lib = TSMAPI
local private = {modules={}, iconInfo={}, icons={}, slashCommands={}, modData={}, options={}}

local savedDBDefaults = {
	profile = {
		minimapIcon = { -- minimap icon position and visibility
			hide = false,
			minimapPos = 220,
			radius = 80,
		},
	},
}

-- Called once the player has loaded WOW.
function TSM:OnInitialize()
	TSM:Print(string.format(L("Loaded %s successfully!"), "TradeSkill Master " .. TSM.version))
	
	-- load the savedDB into TSM.db
	TSM.db = LibStub:GetLibrary("AceDB-3.0"):New("TradeSkillMasterDB", savedDBDefaults, true)

	-- register the chat commands (slash commands)
	-- whenver '/tsm' or '/tradeskillmaster' is typed by the user, TSM:ChatCommand() will be called
   TSM:RegisterChatCommand("tsm", "ChatCommand")
	TSM:RegisterChatCommand("tradeskillmaster", "ChatCommand")
	
	-- create / register the minimap button
	TSM.LDBIcon = LibStub("LibDataBroker-1.1", true) and LibStub("LibDBIcon-1.0", true)
	local TradeSkillMasterLauncher = LibStub("LibDataBroker-1.1", true):NewDataObject("TradeSkillMaster", {
		type = "launcher",
		icon = "Interface\\Icons\\inv_scroll_05",
		OnClick = function(_, button) -- fires when a user clicks on the minimap icon
				if button == "RightButton" then
					-- does the same thing as typing '/tsm config'
					TSM:ChatCommand("config")
				elseif button == "LeftButton" then
					-- does the same thing as typing '/tsm'
					TSM:ChatCommand("")
				end
			end,
		OnTooltipShow = function(tt) -- tooltip that shows when you hover over the minimap icon
				local cs = "|cffffffcc"
				local ce = "|r"
				tt:AddLine("TradeSkill Master " .. TSM.version)
				tt:AddLine(string.format(L("%sLeft-Click%s to open the main window"), cs, ce))
				tt:AddLine(string.format(L("%sRight-click%s to open the options menu"), cs, ce))
				tt:AddLine(string.format(L("%sDrag%s to move this button"), cs, ce))
				tt:AddLine(string.format("%s/tsm%s for a list of slash commands", cs, ce))
			end,
		})
	TSM.LDBIcon:Register("TradeSkillMaster", TradeSkillMasterLauncher, TSM.db.profile.minimapIcon)
	
	-- Create Frame which is the main frame of Scroll Master
	TSM.Frame = AceGUI:Create("Frame")
	TSM.Frame:SetLayout("Fill")
	TSM.Frame:SetWidth(FRAME_WIDTH)
	TSM.Frame:SetHeight(FRAME_HEIGHT)
	TSM.Frame:SetCallback("OnClose", function() TSM:UnregisterEvent("BAG_UPDATE") end)
	TSM:DefaultContent()
	TSM.Frame:Hide()
	for _,v in pairs({TSM.Frame.frame:GetRegions()}) do
		local w = v:GetWidth()
		if w > 90 and w < 110 then
			v:SetWidth(200)
			break
		end
	end
	
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
	
	TSMFRAME = TSM.Frame
	TSM:OptionsPage()
end

-- deals with slash commands
function TSM:ChatCommand(oInput)
	local input, extraValue
	local sStart, sEnd = string.find(oInput, "  ")
	if sStart and sEnd then
		input = string.sub(oInput, 1, sStart-1)
		extraValue = string.sub(oInput, sEnd+1)
	else
		local inputs = {strsplit(" ", oInput)}
		input = inputs[1]
		extraValue = inputs[2]
		for i=3, #(inputs) do
			extraValue = extraValue .. " " .. inputs[i]
		end
	end
	if input == "" then	-- '/tsm' opens up the main window to the main 'enchants' page
		TSM.Frame:Show()
		if #(TSM.Frame.children) == 0 then
			for i=1, #(private.icons) do
				if private.icons[i].name=="Status" then
					private.icons[i].loadGUI(TSM.Frame)
					local name
					for _, module in pairs(private.modules) do
						if module.name == private.icons[i].moduleName then
							name = module.name
							version = module.version
						end
					end
					TSM.Frame:SetTitle((name or private.icons[i].moduleName) .. " v" .. version)
				end
			end
		end
		TSM:BuildIcons()
	elseif input == "test" and TSMdebug then -- for development purposes
	
	elseif input == "debug" then -- enter debugging mode - for development purposes
		if TSMdebug then
			TSM:Print("Debugging turned off.")
			TSMdebug = false
		else
			TSM:Print("Debugging mode turned on. Type '/tsm debug' again to cancel.")
			TSMdebug = true
		end
		
	else -- go through our Module-specific commands
		local found=false
		for _,v in ipairs(private.slashCommands) do
			if input == v.cmd then
				found = true
				if v.isLoadFunc then
					if #(TSM.Frame.children) > 0 then
						TSM.Frame:ReleaseChildren()
						TSMAPI:SetStatusText("")
					end
					v.loadFunc(self, TSM.Frame, extraValue)
					TSMFRAME:Show()
				else
					v.loadFunc(self, extraValue)
				end
			end
		end
		if not found then
			TSM:Print(L("Slash Commands") .. ":")
			print("|cffffaa00/tsm|r - " .. L("opens the main Scroll Master window to the 'Enchants' main page."))
			print("|cffffaa00/tsm " .. L("help") .. "|r - " .. L("Shows this help listing"))
			print("|cffffaa00/tsm " .. L("<command name>") .. " " .. L("help")  .. "|r - " .. L("Help for commands specific to this module") )
			
			for _,v in ipairs(private.slashCommands) do
				if input==L("help") and v.tier==0 then
					print("|cffffaa00/tsm " .. v.cmd .. "|r - " .. v.desc)
				end
				if input==strsub(v.cmd,0,strfind(v.cmd," ")).." " .. L("help") and v.tier>0 then -- possibly sort the slashCommands list for this output
					print("|cffffaa00/tsm " .. v.cmd .. "|r - " .. v.desc)
				end
			end
				
		end
    end
end

-- registers a module with TSM
function lib:RegisterModule(moduleName, version, authors, desc)
	if not (moduleName and version and authors and desc) then
		return nil, "invalid args", moduleName, version, authors, desc
	end
	
	tinsert(private.modules, {name=moduleName, version=version, authors=authors, desc=desc})
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
	
	tinsert(private.icons, {name=displayName, moduleName=moduleName, icon=icon, loadGUI=loadGUI, side=(string.lower(side or "module"))})
end

function lib:RegisterOptions(displayName, moduleName, loadOptions)
	if not (displayName and loadOptions and moduleName) then
		return nil, "invalid args", displayName, loadOptions, moduleName
	end
	
	if not TSM:CheckModuleName(moduleName) then
		return nil, "No module registered under name: " .. moduleName
	end
	
	for _, data in pairs(private.options) do
		if data.moduleName == moduleName then
			return nil, "Options already registered for that module"
		end
	end
	
	tinsert(private.options, {name=displayName, moduleName=moduleName, loadOptions=loadOptions})
end

function lib:SetSubOptions(moduleName, pages)
	if not (moduleName and pages) then return nil, "invalid args", moduleName, pages end
	
	if not TSM:CheckModuleName(moduleName) then
		return nil, "No module registered under name: " .. moduleName
	end
	
	if pages.value then
		return nil, "invalid pages table"
	end
	
	for i, data in pairs(private.options) do
		if data.moduleName == moduleName then
			data.subGroups = pages
			break
		end
	end
	
	TSM:ReloadOptionsTree()
end

-- registers a slash command with TSM
--  cmd : the slash command (after /tsm)
--  loadFunc : the function called when the slash command is executed
--  desc : a brief description of the command for help
--  notLoadFunc : set to true if loadFunc does not use the TSM GUI
function lib:RegisterSlashCommand(cmd, loadFunc, desc, notLoadFunc)
	if not desc then
		desc = L("No help provided.")
	end
	if not loadFunc then
		return nil, "no function provided"
	end
	if not cmd then
		return nil, "no command provided"
	end
	if cmd=="test" or cmd=="debug" or cmd=="help" or cmd=="" then
		return nil, "reserved command provided"
	end
	local tier = 0
	for w in string.gmatch(cmd, " ") do
		tier=tier+1 -- support for help
	end
	tinsert(private.slashCommands, {cmd=cmd, loadFunc=loadFunc, desc=desc, isLoadFunc=not notLoadFunc, tier=tier})
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
	TSM.Frame:SetStatusText(statusText)
end

function lib:CloseFrame()
	TSM.Frame:Hide()
end

function lib:RegisterData(label, dataFunc)
	label = string.lower(label)
	private.modData[label] = dataFunc
end

function lib:GetData(label, ...)
	label = string.lower(label)
	if private.modData[label] then
		return private.modData[label](self, ...)
	end
	
	return nil, "no data for that label"
end

function lib:GetItemID(itemLink, ignoreGemID)
	if not itemLink or type(itemLink) ~= "string" then return nil, "invalid args" end
	
	local test = select(2, strsplit(":", itemLink))
	if not test then return nil, "invalid link" end
	
	local s, e = string.find(test, "[0-9]+")
	if not (s and e) then return nil, "not an itemLink" end
	
	local itemID = tonumber(string.sub(test, s, e))
	if not itemID then return nil, "invalid number" end
	
	return (not ignoreGemID and TSMAPI:GetNewGem(itemID)) or itemID
end

function lib:SelectOptionsTree(moduleName, subGroup)
	if not private.optionsTree then return end
	if not moduleName then return nil, "no moduleName passed" end
	
	for _, data in pairs(private.icons) do
		if data.name == "Options" and data.moduleName == "TradeSkillMaster" then
			data.frame:Click()
		end
	end
	
	local page, child
	for i, data in ipairs(private.options) do
		if data.moduleName == moduleName then
			page = i
			if subGroup then
				for subPage in ipairs(data.subPages) do
					if subPage == subGroup then
						child = tonumber(subGroup)
					end
				end
			end
			break
		end
	end
	
	if page and (subGroup and child or not subGroup) then
		private.optionsTree:SelectByPath(page, child)
	else
		return nil, "Could not find page"
	end
end

function TSM:ReloadOptionsTree()
	if not private.optionsTree then return end
	
	local tree = {}
	for i, data in ipairs(private.options) do
		local treeGroup = {value=i, text=data.name}
		if data.subGroups then
			treeGroup.children = {}
			for _, gData in ipairs(data.subGroups) do
				tinsert(treeGroup.children, gData)
			end
		end
		tinsert(tree, treeGroup)
	end
	
	private.optionsTree:SetTree(tree)
	if #(private.options) > 0 then
		private.optionsTree:SelectByPath(1)
	end
	private.optionsTree:SelectByPath(("\001"):split(private.optionsTree.selection))
end

function TSM:CheckModuleName(moduleName)
	for _, module in pairs(private.modules) do
		if module.name == moduleName then
			return true
		end
	end
end

function TSM:BuildIcons()
	local numItems = {left=0, right=0, bottom=0}
	local rows = {left=1, right=1, bottom=1}
	local count = {left=0, right=0, bottom=0}
	local itemsPerRow = {}
	local width = TSM.Frame.localstatus.width or TSM.Frame.frame.width
	local height = TSM.Frame.localstatus.height or TSM.Frame.frame.height
	
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
	itemsPerRow.left = math.floor((height + 5)/78)
	itemsPerRow.right = math.floor((height + 5)/78)
	itemsPerRow.bottom = math.floor((width + 5)/90)
	rows.left = math.ceil(numItems.left/itemsPerRow.left)
	rows.right = math.ceil(numItems.right/itemsPerRow.right)
	rows.bottom = math.ceil(numItems.bottom/itemsPerRow.bottom)

	for i=1, #(private.icons) do
		local frame = nil
		if private.icons[i].frame then
			frame = private.icons[i].frame
			frame:Show()
		else
			frame = CreateFrame("Button", nil, TSM.Frame.frame)
			frame:SetFrameStrata("HIGH")
			frame:SetScript("OnClick", function()
					if #(TSM.Frame.children) > 0 then
						TSM.Frame:ReleaseChildren()
						TSMAPI:SetStatusText("")
					end
					local name
					for _, module in pairs(private.modules) do
						if module.name == private.icons[i].moduleName then
							name = module.name
							version = module.version
						end
					end
					TSM.Frame:SetTitle((name or private.icons[i].moduleName) .. " v" .. version)
					private.icons[i].loadGUI(TSM.Frame)
				end)

			local image = frame:CreateTexture(nil, "BACKGROUND")
			image:SetWidth(56)
			image:SetHeight(56)
			image:SetPoint("TOP", 0, -5)
			frame.image = image
			
			local label = frame:CreateFontString(nil, "BACKGROUND", "GameFontNormalSmall")
			label:SetPoint("BOTTOMLEFT")
			label:SetPoint("BOTTOMRIGHT")
			label:SetJustifyH("CENTER")
			label:SetJustifyV("TOP")
			label:SetHeight(10)
			label:SetText(private.icons[i].name)
			frame.label = label

			local highlight = frame:CreateTexture(nil, "HIGHLIGHT")
			highlight:SetAllPoints(image)
			highlight:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight")
			highlight:SetTexCoord(0, 1, 0.23, 0.77)
			highlight:SetBlendMode("ADD")
			frame.highlight = highlight
			
			frame:SetHeight(72)
			frame:SetWidth(90)
			frame.image:SetTexture(private.icons[i].icon)
			frame.image:SetVertexColor(1, 1, 1)
			
			private.icons[i].frame = frame
		end
		
		if private.icons[i].side == "crafting" then
			count.left = count.left + 1
			frame:SetPoint("BOTTOMLEFT", TSM.Frame.frame, "TOPLEFT", -85-(90*math.floor((count.left-1)/itemsPerRow.left)), 7-78*((count.left-1)%itemsPerRow.left+1))
		elseif private.icons[i].side == "options" then
			count.right = count.right + 1
			frame:SetPoint("BOTTOMRIGHT", TSM.Frame.frame, "TOPRIGHT", 85+(90*math.floor((count.right-1)/itemsPerRow.right)), 7-78*((count.right-1)%itemsPerRow.right+1))
		else
			count.bottom = count.bottom + 1
			frame:SetPoint("BOTTOMLEFT", TSM.Frame.frame, "BOTTOMLEFT", -90+90*((count.bottom-1)%itemsPerRow.bottom+1), 7-78*math.ceil(count.bottom/itemsPerRow.bottom))
		end
	end
end

function TSM:DefaultContent()
	local function LoadGUI(parent)
		TSMAPI:SetFrameSize(FRAME_WIDTH, FRAME_HEIGHT)
		local content = AceGUI:Create("SimpleGroup")
		content:SetLayout("flow")
		parent:AddChild(content)
		
		local text = AceGUI:Create("Label")
		text:SetText("Status")
		text:SetFullWidth(true)
		text:SetFontObject(GameFontNormalHuge)
		
		content:AddChild(text)
		
		for i, module in pairs(private.modules) do
			local thisFrame = AceGUI:Create("SimpleGroup")
			thisFrame:SetRelativeWidth(0.49)
			thisFrame:SetLayout("list")
			
			local name = AceGUI:Create("Label")
			name:SetText("|cffffbb00Module: \124r"..module.name)
			name:SetFullWidth(true)
			name:SetFontObject(GameFontNormalLarge)
			
			local version = AceGUI:Create("Label")
			version:SetText("|cffffbb00Version: \124r"..module.version)
			version:SetFullWidth(true)
			version:SetFontObject(GameFontNormal)
			
			local authors = AceGUI:Create("Label")
			authors:SetText("|cffffbb00Author(s): \124r"..module.authors)
			authors:SetFullWidth(true)
			authors:SetFontObject(GameFontNormal)
			
			local desc = AceGUI:Create("Label")
			desc:SetText("|cffffbb00Description: \124r"..module.desc)
			desc:SetFullWidth(true)
			desc:SetFontObject(GameFontNormal)
			
			local spacer = AceGUI:Create("Heading")
			spacer:SetText("")
			spacer:SetFullWidth(true)
			
			thisFrame:AddChild(spacer)
			thisFrame:AddChild(name)
			thisFrame:AddChild(version)
			thisFrame:AddChild(authors)
			thisFrame:AddChild(desc)
			content:AddChild(thisFrame)
		end
		
		if #(private.modules) == 0 then
			local warningText = AceGUI:Create("Label")
			warningText:SetText("\n\124cffff0000"..L("No modules are currently loaded.  Enable or download some for full functionality!").."\124r")
			warningText:SetFullWidth(true)
			warningText:SetFontObject(GameFontNormalLarge)
			content:AddChild(warningText)
		end
	end
	
	lib:RegisterModule("TradeSkillMaster", TSM.version, GetAddOnMetadata("TradeSkillMaster", "Author"), "Provides the main central frame as well as APIs for all TSM modules.")
	lib:RegisterIcon("Status", "Interface\\Icons\\Achievement_Quests_Completed_04", LoadGUI, "TradeSkillMaster", "options")
end

function TSM:OptionsPage()
	local function SetupOptions(parent)
		local function SelectTree(treeFrame, _, selection)
			local selectedPages = {}
			-- decodes and seperates the selection string from AceGUIWidget-TreeGroup
			for _, num in pairs({("\001"):split(selection)}) do
				tinsert(selectedPages, tonumber(num) or num)
			end
			local selectedParent = tremove(selectedPages, 1)
			
			-- prepare the TreeFrame for a new container which will hold everything that is drawn on the right part of the GUI
			treeFrame:ReleaseChildren()
			
			-- a simple group to provide a fresh layout to whatever is put inside of it
			-- just acts as an invisible layer between the TreeGroup and whatever is drawn inside of it
			local container = AceGUI:Create("SimpleGroup")
			container:SetLayout("Fill")
			treeFrame:AddChild(container)
		
			private.optionsTree.selection = selection
			private.options[selectedParent].loadOptions(container, unpack(selectedPages)) 
		end
	
		local treeGroupStatus = {treewidth = TREE_WIDTH, groups={}}
		for i=1, #(private.modules) do
			treeGroupStatus.groups[i] = true
		end
		
		-- Create the main tree-group that will control and contain the entire GUI
		private.optionsTree = AceGUI:Create("TreeGroup")
		private.optionsTree:SetLayout("Fill")
		private.optionsTree:SetCallback("OnGroupSelected", SelectTree)
		private.optionsTree:SetStatusTable(treeGroupStatus)
		parent:AddChild(private.optionsTree)
		
		local tree = {}
		for i, data in ipairs(private.options) do
			local treeGroup = {value=i, text=data.name}
			if data.subGroups then
				treeGroup.children = {}
				for _, gData in ipairs(data.subGroups) do
					tinsert(treeGroup.children, gData)
				end
			end
			tinsert(tree, treeGroup)
		end
		
		private.optionsTree:SetTree(tree)
		if #(private.options) > 0 then
			private.optionsTree:SelectByPath(1)
		end
	end
	
	lib:RegisterIcon("Options", "Interface\\Icons\\INV_Misc_Gear_05", SetupOptions, "TradeSkillMaster", "options")
end