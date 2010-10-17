-- ------------------------------------------------------------------------------------- --
-- 					Scroll Master - AddOn by Sapu (sapu94@gmail.com)			 		 --
--             http://wow.curse.com/downloads/wow-addons/details/slippy.aspx             --
-- ------------------------------------------------------------------------------------- --

-- The following functions are contained attached to this file:
-- Enchanting:OpenFrame() - opens the craft queue and initializes it if it hasn't previously been shown
-- Enchanting:Create() - initializes the craft queue frame when it is shown for the first time
-- Enchanting:Update() - gets called to update the craft queue frame whenever something changes
-- Enchanting:TRADE_SKILL_UPDATE()
-- Enchanting:TRADE_SKILL_CLOSE() - cleans up the tables used and unregisters events  when the trade skill window is closed
-- Enchanting:UNIT_SPELLCAST_SUCCEEDED() - detects when enchants are successfully cast and removes that item from the queue
-- Enchanting:GetIndex() - returns the trade skill index for a given enchant name
-- Enchanting:OpenEnchanting() - opens the enchanting window and removes any filters on the shown enchants so that everything is visible

-- The following "global" (within the addon) variables are initialized in this file:
-- Enchanting.frame - the entire craft queue frame (not used outside this module)
-- Enchanting.rows - contains all the rows of the craft queue (not used outside this module)

-- ===================================================================================== --


-- load the parent file (ScrollMaster) into a local variable and register this file as a module
local TSM = select(2, ...)
local Enchanting = TSM:NewModule("Enchanting", "AceEvent-3.0")

local aceL = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local debug = function(...) TSM:Debug(...) end -- for debugging

local function L(phrase)
	--TSM.lTable[phrase] = true
	return aceL[phrase]
end

-- intialize some internal-global variables
local ROW_HEIGHT = 16
local MAX_ROWS = 22
local FRAME_HEIGHT = 465
local FRAME_WIDTH = 340
local VELLUM_ID = 38682

-- opens the craft queue and initializes it if it hasn't previously been shown
function Enchanting:OpenFrame()
	TSM.GUI:UpdateQueue()
	if TSM.GUI.queueInTotal == 0 then
		return TSM:Print(L("Your craft queue is empty!"))
	end
	
	if not Enchanting.frame then Enchanting:Create() end
	Enchanting:OpenEnchanting()
	Enchanting:PrepareFrame()
end
	
function Enchanting:PrepareFrame()
	-- register events and collect some data
	Enchanting:RegisterEvent("TRADE_SKILL_CLOSE")
	Enchanting:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	Enchanting:RegisterEvent("BAG_UPDATE", "Update")
	
	-- check to see if ATSW is enabled
	if select(4, GetAddOnInfo("AdvancedTradeSkillWindow")) then
		-- if ATSW is enabled, the queue frame must be moved and user alerted (unless they turned warnings off)
		if TSM.db.profile.warnings then
			TSM:Print(L("Scroll Master is not completely compatible with ATSW so " ..
				"the craft queue may need to be moved manually. You can turn this warning off in the options."))
		end
		Enchanting.frame:SetPoint("TOPLEFT", TradeSkillFrame, "TOPRIGHT", 300, -50)
	else
		Enchanting.frame:SetPoint("TOPLEFT", TradeSkillFrame, "TOPRIGHT", -30, -10)
	end
	
	-- update the frame for the first time and then show it
	Enchanting.frame:SetWidth(FRAME_WIDTH)
	Enchanting.frame:SetHeight(FRAME_HEIGHT)
	Enchanting.frame:Show()
	Enchanting:Update()
end

-- initializes the craft queue frame when it is shown for the first time
function Enchanting:Create()
	-- Queue Frame GUI
	Enchanting.frame = CreateFrame("Frame", nil, UIParent)
	Enchanting.frame:SetWidth(FRAME_WIDTH)
	Enchanting.frame:SetHeight(FRAME_HEIGHT)
	Enchanting.frame:SetClampedToScreen(true)
	Enchanting.frame:SetFrameStrata("HIGH")
	Enchanting.frame:SetMovable(true)
	Enchanting.frame:SetResizable(true)
	Enchanting.frame:EnableMouse(true)
	Enchanting.frame:SetScript("OnMouseDown", Enchanting.frame.StartMoving)
	Enchanting.frame:SetScript("OnMouseUp", Enchanting.frame.StopMovingOrSizing)
	Enchanting.frame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		edgeSize = 26,
		insets = {left = 9, right = 9, top = 9, bottom = 9},
	})
	
	-- the resizer in the bottom left of the craft queue
	local function sizerOnMouseDown()
		Enchanting.frame:StartSizing("BOTTOMRIGHT")
	end
	local function sizerOnMouseUp()
		Enchanting.frame:StopMovingOrSizing()
	end
	
	local sizer = CreateFrame("Frame",nil,Enchanting.frame)
	sizer:SetPoint("BOTTOMRIGHT",Enchanting.frame,"BOTTOMRIGHT",0,0)
	sizer:SetWidth(25)
	sizer:SetHeight(25)
	sizer:EnableMouse()
	sizer:SetScript("OnMouseDown",sizerOnMouseDown)
	sizer:SetScript("OnMouseUp", sizerOnMouseUp)
	Enchanting.frame.sizer = sizer

	local line1 = sizer:CreateTexture(nil, "BACKGROUND")
	Enchanting.frame.line1 = line1
	line1:SetWidth(14)
	line1:SetHeight(14)
	line1:SetPoint("BOTTOMRIGHT", -8, 8)
	line1:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
	local x = 0.1 * 14/17
	line1:SetTexCoord(0.05 - x, 0.5, 0.05, 0.5 + x, 0.05, 0.5 - x, 0.5 + x, 0.5)

	local line2 = sizer:CreateTexture(nil, "BACKGROUND")
	Enchanting.frame.line2 = line2
	line2:SetWidth(8)
	line2:SetHeight(8)
	line2:SetPoint("BOTTOMRIGHT", -8, 8)
	line2:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
	local x = 0.1 * 8/17
	line2:SetTexCoord(0.05 - x, 0.5, 0.05, 0.5 + x, 0.05, 0.5 - x, 0.5 + x, 0.5)
	
	-- X button in the top right to close the window
	Enchanting.frame.button = CreateFrame("Button", nil, Enchanting.frame, "UIPanelCloseButton")
	Enchanting.frame.button:SetPoint("TOPRIGHT", Enchanting.frame, "TOPRIGHT")
	Enchanting.frame.button:SetScript("OnClick", function() CloseTradeSkill() end)
	
	-- Tittle frame which contains the tittle text
	local tFile, tSize = GameFontRedLarge:GetFont()
	Enchanting.frame.text = Enchanting.frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	Enchanting.frame.text:SetFont(tFile, tSize, "OUTLINE")
	Enchanting.frame.text:SetPoint("TOPLEFT", Enchanting.frame, "TOPLEFT", 0, -8)
	Enchanting.frame.text:SetText("TradeSkill Master v" .. TSM.version .. " - " .. L("Craft Queue"))
	Enchanting.frame.text:SetWidth(FRAME_WIDTH)
	Enchanting.frame.text:SetHeight(20)
	
	-- Scroll frame to contain all the queued enchants
	Enchanting.frame.scroll = CreateFrame("ScrollFrame", "SMScroll", Enchanting.frame, "FauxScrollFrameTemplate")
	Enchanting.frame.scroll:SetPoint("TOPLEFT", Enchanting.frame, "TOPLEFT", 0, -30)
	Enchanting.frame.scroll:SetPoint("BOTTOMRIGHT", Enchanting.frame, "BOTTOMRIGHT", -30, 25)
	Enchanting.frame.scroll:SetScript("OnVerticalScroll", function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT, Enchanting.Update) end)
		
	local btn = CreateFrame("Button", "SMButton", Enchanting.frame, "SecureActionButtonTemplate, UIPanelButtonTemplate2")
	btn:SetWidth(FRAME_WIDTH - 33)
	btn:SetHeight(24)
	btn:SetNormalFontObject(GameFontHighlight)
	btn:SetText("Craft Next Enchant")
	btn:GetFontString():SetPoint("CENTER", btn, "CENTER", -12, 0)
	local tFile, tSize = GameFontRedLarge:GetFont()
	btn:GetFontString():SetFont(tFile, tSize-2, "OUTLINE")
	btn:SetPushedTextOffset(0, 0)
	btn:SetPoint("BOTTOMLEFT", Enchanting.frame, "BOTTOMLEFT", 8, 8)
	btn:SetScript("PreClick", function() Enchanting:Update() end)
	Enchanting.button = btn
		
	-- rows of the scrollframe containing the enchants in the queue
	-- each row is the clickable name of an enchant (we set up the script to craft the enchant later)
	Enchanting.rows = {}
	for count=1, MAX_ROWS do
		-- exits out of the loop if we've reached the end of the craft queue
		if count > TSM.GUI.queueInTotal then
			break
		end
	
		local row = CreateFrame("Button", nil, Enchanting.frame, "SecureActionButtonTemplate")
		row:SetWidth(Enchanting.frame:GetWidth())
		row:SetHeight(ROW_HEIGHT)
		row:SetNormalFontObject(GameFontHighlight)
		row:SetText("*")
		row:GetFontString():SetPoint("LEFT", row, "LEFT", 0, 0)
		row:SetPushedTextOffset(0, 0)
		row:SetScript("PreClick", function() Enchanting:Update() end)
		
		if( count > 1 ) then
			row:SetPoint("TOPLEFT", Enchanting.rows[count - 1], "BOTTOMLEFT", 0, -2)
		else
			row:SetPoint("TOPLEFT", Enchanting.frame, "TOPLEFT", 12, -30)
		end
		
		Enchanting.rows[count] = row
	end
end

-- gets called to update the craft queue frame whenever something changes
function Enchanting:Update(testBool)
	for _, row in pairs(Enchanting.rows) do row:Hide() end
	
	TSM.GUI:UpdateQueue()
		
	-- Update the scroll bar
	FauxScrollFrame_Update(Enchanting.frame.scroll, TSM.GUI.queueInTotal, MAX_ROWS-1, ROW_HEIGHT)
	
	-- Now display the correct rows
	local offset = FauxScrollFrame_GetOffset(Enchanting.frame.scroll)
	local displayIndex = 0
	local counter = 0
	TSM.Data:UpdateInventoryInfo("mats")
	TSM.Data:UpdateInventoryInfo("scrolls")
	
	for index, data in pairs(TSM.GUI.queueList) do
		-- if the enchant should be displayed based on the scope of the scrollframe
		if( index >= offset and displayIndex < MAX_ROWS ) then
			local mats = {}
			local haveMats, needEssence, essenceID = Enchanting:GetEnchantOrderIndex(data)
			local color
			for itemID, eData in pairs(TSM.Data[TSM.mode].crafts) do
				if eData.spellID == data.spellID then
					mats = eData.mats
				end
			end
			if haveMats == 3 then
				color = "|cff00ff00"
			elseif haveMats == 2 then
				color = "|cffffff00"
			else
				color = "|cffff0000"
			end
			displayIndex = displayIndex + 1
			Enchanting.rows[displayIndex]:SetText(color .. data.name .. " (x" .. data.quantity .. ")|r")
			
			-- catches any enchant which the player can't craft
			local cIndex = Enchanting:GetIndex(data.name)
			if not cIndex then
				if GetNumTradeSkills() < 50 then
					CloseTradeSkill()
					TSM:Print(L("Please clear all filters from your enchanting tradeskill window and try showing the craft queue again."))
					return
				else
					local text = "|cfffcd59c" .. data.name .. "|r"
					TSM:Print(string.format(L("You have not trained %s. It has been removed from Scroll Master."), text))
					-- remove the item from the queue list
					tremove(TSM.GUI.queueList, index)
					-- remove the enchant from Scroll Master
					for itemID, eData in pairs(TSM.Data[TSM.mode].crafts) do
						if eData.spellID == data.spellID then
							TSM.Data[TSM.mode].crafts[itemID] = nil
							break
						end
					end
					return Enchanting:Update()
				end
			end
			
			-- sets up the macro commands which get called when the player clicks on the enchant name
			Enchanting.rows[displayIndex]:SetAttribute("type", "macro")
			
			local velName = ""
			if TSM.mode == "Enchanting" then
				velName = TSM.LibEnchant.velName[VELLUM_ID]
			end
			
			local essence -- FOR SPLITTING / COMBINING ESSENCES
			for k=1, math.floor(needEssence) do
				essence = (essence or "") .. "/use " .. TSM:GetName(essenceID) .. "\n"
			end
			
			Enchanting.rows[displayIndex]:SetAttribute("macrotext", string.format("/script DoTradeSkill(%d,%d)\n/use %s;", cIndex, 1, velName))
			
			if displayIndex == 1 then
				-- setup the "Craft Next Enchant" button
				Enchanting.button:SetAttribute("type", "macro")
				if essence then
					Enchanting.button:SetText(L("Combine / Split Essences"))
					Enchanting.button:SetAttribute("macrotext", essence)
					Enchanting.button:SetScript("PostClick", function()
							Enchanting.button:Disable()
							Enchanting.button:RegisterEvent("BAG_UPDATE", function() print("HI") Enchanting.button:UnregisterEvent("BAG_UPDATE") Enchanting.button:Enable() end)
							Enchanting.button:SetScript("PostClick", nil)
						end)
				else
					Enchanting.button:SetText(L("Craft Next Enchant"))
					Enchanting.button:SetAttribute("macrotext", string.format("/script DoTradeSkill(%d,%d)\n/use %s;", cIndex, 1, velName))
				end
				
				if haveMats == 3 then
					Enchanting.button:Enable()
				else
					Enchanting.button:Disable()
				end
			end
			
			Enchanting.rows[displayIndex]:Show()
			Enchanting.rows[displayIndex]:SetScript("OnEnter", function(frame)			
					GameTooltip:SetOwner(frame, "ANCHOR_NONE")
					GameTooltip:SetPoint("LEFT", frame, "RIGHT")
					GameTooltip:AddLine(data.name)
					for itemID, nQuantity in pairs(mats) do
						local name = select(2, GetItemInfo(itemID)) or TSM:GetName(itemID)
						local inventory = TSM.Data.inventory[itemID] or 0
						local need = nQuantity * data.quantity
						local color
						if inventory >= need then color = "|cff00ff00" else color = "|cffff0000" end
						name = color .. inventory .. "/" .. need .. "|r " .. name
						GameTooltip:AddLine(name)
					end
					GameTooltip:Show()
				end)
			Enchanting.rows[displayIndex]:SetScript("OnLeave", function()
					GameTooltip:ClearLines()
					GameTooltip:Hide()
				end)
		end
	end
end

-- cleans up the tables used and unregisters events when the trade skill window is closed
function Enchanting:TRADE_SKILL_CLOSE()
	if Enchanting.frame then
		Enchanting.frame:Hide()
	end
	
	Enchanting:UnregisterEvent("TRADE_SKILL_CLOSE")
	Enchanting:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	Enchanting:UnregisterEvent("BAG_UPDATE")
end

-- detects when enchants are successfully cast and removes that item from the queue
function Enchanting:UNIT_SPELLCAST_SUCCEEDED(event, unit, name)
	-- verifies that we are interested in this spellcast
	if not (unit == "player" and string.find(name, "%s[^%a]%s")) then
		return
	end
	
	-- finds which enchant was cast and decrease the number queued by 1
	local valid = false
	for itemID, data in pairs(TSM.Data[TSM.mode].crafts) do
		local spellID = data.spellID
		local iName = select(1, GetSpellInfo(spellID))
		if iName == name then
			valid = true
			-- decrements the number of this enchant that are queued to be crafted
			data.queued = data.queued - 1
			if TSM.db.profile.craftHistory[spellID] then
				TSM.db.profile.craftHistory[spellID] = TSM.db.profile.craftHistory[spellID] + 1
			else
				TSM.db.profile.craftHistory[spellID] = 1
			end
		end
	end
	
	if not valid then
		TSM:Print(L("ERROR: Could not update queue after craft! Please report this error!"))
	end
	
	-- updates the craft queue
	TSM.GUI:UpdateQueue()
	Enchanting:Update()
end

-- returns the trade skill index for a given enchant name
function Enchanting:GetIndex(sName)
	
	local numSkills = GetNumTradeSkills()
	
	-- iterate over every enchant in the trade skill window until we find the one with the name we are looking for
	for i=1, numSkills do
		local eName = GetTradeSkillInfo(i)
		if eName == sName then
			-- store and then return the index of the enchant we were looking for in the trade skill window
			return i
		end
	end
	
	-- I love blizzard and their inconsistancies with "Bracer" / "Bracers"
	if string.find(sName, L("Bracers")) then
		return Enchanting:GetIndex(string.gsub(sName, L("Bracers"), L("Bracer")))
	end
end

local doNext
-- opens the enchanting window and removes any filters on the shown enchants so that everything is visible
function Enchanting:OpenEnchanting(nextFunc)
	doNext = nextFunc
	CloseTradeSkill()
	local enchantingName = GetSpellInfo(51313)
	Enchanting:RegisterEvent("TRADE_SKILL_SHOW", "TSSHOW")
	CastSpellByName(enchantingName) -- opens enchanting
end

function Enchanting:TSSHOW()
	Enchanting:UnregisterEvent("TRADE_SKILL_SHOW")
	if doNext then
		doNext()
	end
end

function Enchanting:GetEnchantOrderIndex(data)
	local mats = {}
	local needEssence = 0
	local essenceID = 0
	local haveMats = nil
	for itemID, eData in pairs(TSM.Data[TSM.mode].crafts) do
		if eData.spellID == data.spellID then
			mats = eData.mats
		end
	end
	for itemID, nQuantity in pairs(mats) do
		local numHave = TSM.Data.inventory[itemID] or 0
		local need = nQuantity * data.quantity
		
		if TSM.LibEnchant.lesserEssence[itemID] and need > numHave then -- need more greaters
			local diff = need - numHave
			if ((TSM.Data.inventory[TSM.LibEnchant.lesserEssence[itemID]] or 0) / 3) >= diff then
				numHave = need
				needEssence = diff
				essenceID = TSM.LibEnchant.lesserEssence[itemID]
			end
		elseif TSM.LibEnchant.greaterEssence[itemID] and need > numHave then -- need more lessers
			local diff = need - numHave
			if (TSM.Data.inventory[TSM.LibEnchant.greaterEssence[itemID]] or 0) >= (diff / 3) then
				numHave = need
				needEssence = math.ceil(diff / 3)
				essenceID = TSM.LibEnchant.greaterEssence[itemID]
			end
		end
		
		if numHave < need then
			if not haveMats then
				haveMats = 1
			end
			if haveMats == 3 then
				haveMats = 2
			end
		else
			if not haveMats then
				haveMats = 3
			end
			if haveMats == 1 then
				haveMats = 2
			end
		end
	end
	return haveMats, needEssence, essenceID
end

-- determines if the player is an enchanter (either /450 or /525)
function Enchanting:IsEnchanter()
	return IsSpellKnown(51313) or IsSpellKnown(74258)
end