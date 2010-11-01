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

TSMAPI = {}
local lib = TSMAPI
local private = {modules={}, iconInfo={}, icons={}}

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
	TSM.Frame:SetTitle("TradeSkill Master " .. TSM.version)
	TSM.Frame:SetLayout("Fill")
	TSM.Frame:SetWidth(FRAME_WIDTH)
	TSM.Frame:SetHeight(FRAME_HEIGHT)
	TSM.Frame:SetCallback("OnClose", function() TSM:UnregisterEvent("BAG_UPDATE") end)
	TSM.Frame:Hide()
	for _,v in pairs({TSM.Frame.frame:GetRegions()}) do
		local w = v:GetWidth()
		if w > 90 and w < 110 then
			v:SetWidth(200)
			break
		end
	end
	
	TSMFRAME = TSM.Frame
	
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

-- registers a module with TSM
function lib:RegisterModule(moduleName, version, authors, desc)
	if not (moduleName and version and authors and desc) then
		return "invalid args", moduleName, version, authors, desc
	end
	
	tinsert(private.modules, {name=moduleName, version=version, authors=authors, desc=desc})
end

-- registers a new icon to be displayed around the border of the TSM frame
function lib:RegisterIcon(displayName, icon, loadGUI, side)
	if not (displayName and icon and loadGUI) then
		return "invalid args", displayName, icon, loadGUI
	end
	if side and not (side == "module" or side == "crafting" or side == "options") then
		return "invalid side", side
	end
	
	tinsert(private.icons, {name=displayName, icon=icon, loadGUI=loadGUI, side=(string.lower(side or "module"))})
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
	for _, data in pairs(private.icons) do
		if data.frame then 
			data.frame:Hide()
		end
	end
	
	local count = {left=0, right=0, bottom=0}

	for i=1, #(private.icons) do
		if private.icons[i].frame then
			private.icons[i].frame:Show()
		else
			local frame = CreateFrame("Button", nil, TSM.Frame.frame)
			if private.icons[i].side == "crafting" then
				count.left = count.left + 1
				frame:SetPoint("BOTTOMLEFT", TSM.Frame.frame, "TOPLEFT", -85, (7-78*count.left))
			elseif private.icons[i].side == "options" then
				count.right = count.right + 1
				frame:SetPoint("BOTTOMRIGHT", TSM.Frame.frame, "TOPRIGHT", 85, (7-78*count.right))
			else
				count.bottom = count.bottom + 1
				frame:SetPoint("BOTTOMLEFT", TSM.Frame.frame, "BOTTOMLEFT", (90*count.bottom-100), -60)
			end
			frame:SetScript("OnClick", function()
					if #(TSM.Frame.children) > 0 then
						TSM.Frame:ReleaseChildren()
						TSMAPI:SetStatusText("")
					end
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
	end
end

function TSM:DefaultContent()
	
	local function LoadGUI(parent)
		-- Create the main tree-group that will control and contain the entire TSM
		local content = AceGUI:Create("SimpleGroup")
		content:SetLayout("flow")
		parent:AddChild(content)
		
		local text = AceGUI:Create("Label")
		text:SetText("Status")
		text:SetFullWidth(true)
		text:SetFontObject(GameFontNormalHuge)
		
		content:AddChild(text)
		local TSMInfo = {name="TradeSkillMaster", version=TSM.version, authors="Sapu, Mischanix",
			desc="Provides the main central frame as well as APIs for all TSM modules."}
		
		for i, module in pairs({TSMInfo, unpack(private.modules)}) do
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
	end
	
	lib:RegisterIcon("Status", "Interface\\Icons\\Achievement_Quests_Completed_04", LoadGUI, "options")
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