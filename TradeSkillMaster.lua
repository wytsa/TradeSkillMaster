-- ------------------------------------------------------------------------------------- --
-- 					Scroll Master - AddOn by Sapu (sapu94@gmail.com)			 		 --
--             http://wow.curse.com/downloads/wow-addons/details/slippy.aspx             --
-- ------------------------------------------------------------------------------------- --

-- This is the main file for Scroll Master. This file mainly sets up the saved variables database, slash commands,
-- and the other files associated with Scroll Master. The following functions are contained attached to this file:
-- TSM:Debug() - for debugging purposes
-- TSM:OnEnable() - called when the addon is loaded / initizalizes the entire addon
-- TSM:OnDisable() - stores the tree status
-- TSM:ChatCommand() - registers slash commands (such as '/tsm', '/tsm scan', etc)
-- TSM:GetName() - takes an itemID and returns the name of that item - used throughout Scroll Master
-- TSM:BAG_UPDATE() - fires whenever a player's bags change - keeps track of materials / scrolls in bags
-- TSM:GetGroup() - converts the name (or table) of an enchant to a number
-- TSM:DSGetNum() - returns the number of the passed itemID in bags of the user's alts

-- The following "global" (within the addon) variables are initialized in this file:
-- TSM.version - stores the version of the addon
-- TSM.mode - stores the mode (profession) TSM is currently in
-- TSM.db - used to read from / save to the savedDB (saved variables database)
-- TSM.GameTime - a way to get millisecond precision timing - used for developing more effecient code

-- ===================================================================================== --


-- register this file with Ace Libraries
local TSM = select(2, ...)
TSM = LibStub("AceAddon-3.0"):NewAddon(TSM, "TradeSkillMaster", "AceEvent-3.0", "AceConsole-3.0")
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries

local aceL = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
TSM.version = "0.1" -- current version of the addon

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

TSMAPI = {}
local lib = TSMAPI
local private = {modules={}, icons={}}

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
	TSM:Print(string.format(L("Loaded %s successfully!"), "TradeSkill Master v" .. TSM.version))
	
	-- load Scroll Master's modules
	
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
				tt:AddLine("TradeSkill Master v" .. TSM.version)
				tt:AddLine(string.format(L("%sLeft-Click%s to open the main window"), cs, ce))
				tt:AddLine(string.format(L("%sRight-click%s to open the options menu"), cs, ce))
				tt:AddLine(string.format(L("%sDrag%s to move this button"), cs, ce))
				tt:AddLine(string.format("%s/tsm%s for a list of slash commands", cs, ce))
			end,
		})
	TSM.LDBIcon:Register("TradeSkillMaster", TradeSkillMasterLauncher, TSM.db.profile.minimapIcon)
	
	-- Create Frame which is the main frame of Scroll Master
	TSM.Frame = AceGUI:Create("Frame")
	TSM.Frame:SetTitle("TradeSkill Master v" .. TSM.version)
	TSM.Frame:SetLayout("Fill")
	TSM.Frame:SetWidth(FRAME_WIDTH)
	TSM.Frame:SetHeight(FRAME_HEIGHT)
	TSM.Frame:SetCallback("OnClose", function() TSM:UnregisterEvent("BAG_UPDATE") end)
	TSM.Frame:Hide()
	
	TSM:DefaultContent()
end

-- deals with slash commands
function TSM:ChatCommand(input)
	if input == "" then	-- '/tsm' opens up the main window to the main 'enchants' page
		TSM.Frame:Show()
		TSM:BuildIcons()
	elseif input == "test" and TSMdebug then -- for development purposes
	
	elseif input == "debug" then -- enter debugging mode - for development purposes
		if SMdebug then
			TSM:Print("Debugging turned off.")
			TSMdebug = false
		else
			TSM:Print("Debugging mode turned on. Type '/tsm debug' again to cancel.")
			TSMdebug = true
		end
		TSM.GameTime:Initialize()
		
	else -- if the command is unrecognized, print out the slash commands to help the user
        TSM:Print(L("Slash Commands") .. ":")
		print("|cffffaa00/tsm|r - " .. L("opens the main Scroll Master window to the 'Enchants' main page."))
		print("|cffffaa00/tsm " .. L("help") .. "|r - " .. L("opens the main Scroll Master window to the 'Help' page."))
    end
end

function lib:RegisterModule(name, icon, loadGUI)
	if not (name and icon and loadGUI) then return end
	
	if private.modules[1] and private.modules[1].name == "Default" then
		tremove(private.modules, 1)
	end
	
	tinsert(private.modules, {name=name, icon=icon, loadGUI=loadGUI})
end

function lib:SetFrameSize(width, height)
	TSM.Frame:SetWidth(width)
	TSM.Frame:SetHeight(height)
end

function lib:SetStatusText(statusText)
	TSM.Frame:SetStatusText(statusText)
end

function lib:CloseFrame()
	TSM.Frame:Hide()
end

function TSM:BuildIcons()
	for _, frame in pairs(private.icons) do frame:Hide() end

	local k = 1
	for i=1, #(private.modules) do
		local name, icon, loadGUI = private.modules[i].name, private.modules[i].icon, private.modules[i].loadGUI
	
		if private.icons[i] then
			private.icons[i]:Show()
		else
			local frame = CreateFrame("Button", nil, TSM.Frame.frame)
			frame:SetPoint("BOTTOMLEFT", TSM.Frame.frame, "TOPLEFT", -85, (7-78*k))
			frame:SetScript("OnClick", function() if #(TSM.Frame.children) > 0 then TSM.Frame:ReleaseChildren() loadGUI(TSM.Frame) end end)

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
			label:SetText(name)
			frame.label = label

			local highlight = frame:CreateTexture(nil, "HIGHLIGHT")
			highlight:SetAllPoints(image)
			highlight:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight")
			highlight:SetTexCoord(0, 1, 0.23, 0.77)
			highlight:SetBlendMode("ADD")
			frame.highlight = highlight
			
			frame:SetHeight(71)
			frame:SetWidth(90)
			frame.image:SetTexture(icon)
			frame.image:SetVertexColor(1, 1, 1)
			
			private.icons[k] = frame
		end
		
		k = k + 1
	end
end

function TSM:DefaultContent()
	local name = "Default"
	local icon = "Interface\\TutorialFrame\\TutorialFrame-QuestionMark"
	
	local function LoadGUI(parent)
		-- Create the main tree-group that will control and contain the entire TSM
		local content = AceGUI:Create("SimpleGroup")
		content:SetLayout("list")
		parent:AddChild(content)
		
		local text = AceGUI:Create("Label")
		text:SetText("This is a test module!!!")
		text:SetFullWidth(true)
		text:SetFontObject(GameFontNormalHuge)
		content:AddChild(text)
	end
	
	lib:RegisterModule(name, icon, LoadGUI)
end

-- a way to get millisecond precision timing - stolen from wowwiki
-- this is only used for development and is not used by any feature of TSM
TSM.GameTime = {
	Get = function(self)
			if (self.LastMinuteTimer == nil) then
				local h,m = GetGameTime()
				return h,m,0
			end
			local s = GetTime() - self.LastMinuteTimer
			if(s>59.999) then
				s=59.999
			end
			return self.LastGameHour, self.LastGameMinute, s
		end,

	OnUpdate = function(self)
			local h,m = GetGameTime()
			if(self.LastGameMinute == nil) then
				self.LastGameHour = h
				self.LastGameMinute = m
				return;
			end
			if(self.LastGameMinute == m) then
				return;
			end
			self.LastGameHour = h
			self.LastGameMinute = m
			self.LastMinuteTimer = GetTime()
			if not self.notify then
				self.notify = true
				print("Timer Ready")
			end
		end,

	Initialize = function(self)
			self.Frame = CreateFrame("Frame");
			self.Frame:SetScript("OnUpdate", function() self:OnUpdate() end)
		end
}