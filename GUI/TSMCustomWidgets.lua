-- This file contains custom TSM widgets that are based on AceGUI
-- widgets (minus MacroButton) but modified to fit the TSM theme.
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)


-- MacroButton
do
	local Type, Version = "TSMMacroButton", 1
	if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end
	
	local methods = {
		["OnAcquire"] = function(self)
			-- restore default values
			self:SetHeight(24)
			self:SetWidth(200)
			self:SetDisabled(false)
			self:SetText()
		end,

		-- ["OnRelease"] = nil,

		["SetText"] = function(self, text)
			self.frame:SetText(text)
		end,

		["SetDisabled"] = function(self, disabled)
			self.disabled = disabled
			if disabled then
				self.frame:Disable()
			else
				self.frame:Enable()
			end
		end
	}
	
	local function Constructor()
		local name = "AceGUITSMMacroButton" .. AceGUI:GetNextWidgetNum(Type)
		local frame = CreateFrame("Button", name, UIParent, "UIPanelButtonTemplate2, SecureActionButtonTemplate")
		frame:Hide()

		frame:EnableMouse(true)
		frame:SetScript("OnEnter", function(self) frame.obj:Fire("OnEnter") end)
		frame:SetScript("OnLeave", function(self) frame.obj:Fire("OnLeave") end)
		
		frame:SetBackdrop({
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			edgeSize = 18,
			insets = {left = 0, right = 0, top = 0, bottom = 0},
		})

		local normalTex = frame:CreateTexture()
		normalTex:SetTexture("Interface\\TokenFrame\\UI-TokenFrame-CategoryButton")
		normalTex:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
		normalTex:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 6, 6)
		normalTex:SetTexCoord(0.049, 0.958, 0.066, 0.244)
		frame:SetNormalTexture(normalTex)

		local disabledTex = frame:CreateTexture()
		disabledTex:SetTexture("Interface\\TokenFrame\\UI-TokenFrame-CategoryButton")
		disabledTex:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
		disabledTex:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 6, 6)
		disabledTex:SetVertexColor(0.1, 0.1, 0.1, 1)
		disabledTex:SetTexCoord(0.049, 0.958, 0.066, 0.244)
		frame:SetDisabledTexture(disabledTex)

		local highlightTex = frame:CreateTexture()
		highlightTex:SetTexture("Interface\\TokenFrame\\UI-TokenFrame-CategoryButton")
		highlightTex:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
		highlightTex:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 6, 6)
		highlightTex:SetTexCoord(0.005, 0.994, 0.613, 0.785)
		highlightTex:SetVertexColor(0.3, 0.3, 0.3, 0.7)
		frame:SetHighlightTexture(highlightTex)

		local pressedTex = frame:CreateTexture()
		pressedTex:SetTexture("Interface\\TokenFrame\\UI-TokenFrame-CategoryButton")
		pressedTex:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
		pressedTex:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 6, 6)
		pressedTex:SetVertexColor(1, 1, 1, 0.5)
		pressedTex:SetTexCoord(0.0256, 0.743, 0.017, 0.158)
		frame:SetPushedTexture(pressedTex)
		frame:SetPushedTextOffset(0, -2)

		local widget = {
			frame = frame,
			type  = Type
		}
		for method, func in pairs(methods) do
			widget[method] = func
		end

		return AceGUI:RegisterAsWidget(widget)
	end

	AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

-- FastDestroyButton
do
	local Type, Version = "TSMFastDestroyButton", 1
	if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end
	
	local function Delay(self)
		if self.wait == "cd" then
			self.endTime = self.endTime or GetTime() + 1
			if GetSpellCooldown(self.button.spell) == 0 and GetTime() > self.endTime then
				self.endTime = nil
				self:Hide()
				self.button:SetDisabled(false)
			end
		elseif self.wait == "lootopen" then
			if (self.button.mode == "fast" and not UnitCastingInfo("player")) or (self.button.mode == "normal" and LootFrame:IsVisible()) then
				self:Hide()
				self.button:SetDisabled(false)
			end
		elseif self.wait == "lootclosed" then
			if not LootFrame:IsVisible() then
				self:Hide()
				self.button:SetDisabled(false)
			end
		end
	end
	
	local function CreateDelay(button)
		button.delay = CreateFrame("Frame")
		button.delay.button = button
		
		button.delay:Hide()
		button.delay:SetScript("OnUpdate", Delay)
	end
	
	local function PreClick(self)
		if not SpellIsTargeting() then
			if LootFrame:IsVisible() then
				self.obj:SetDisabled(true)
				self.obj.delay.wait = "lootclosed"
				self.obj.delay:Show()
			else
				self.isCasting = true
				self:SetAttribute("type1", "macro")
				self:SetAttribute("macrotext1", format("/cast %s", self.obj.spell))
				self.attribute = "cast"
				if UnitCastingInfo("player") then
					self.obj:SetDisabled(true)
					self.obj.delay.wait = "lootopen"
					self.obj.delay:Show()
				end
			end
		else
			self.isCasting = false
			local target = self.obj.GetLocations(self.currentTarget or {bag=-1, slot=-1})
			self.currentTarget = target
			
			if target and target.bag ~= -1 and target.slot ~= -1 then
				self.nextTarget = CopyTable(target)
				self:SetAttribute("type1", "macro")
				self:SetAttribute("macrotext1", format("/use %s %s", target.bag, target.slot))
				self.attribute = "use"
				self.obj:SetDisabled(true)
				self.obj.delay.wait = "cd"
				self.obj.delay:Show()
			else
				self.obj:Fire("Finished")
			end
		end
	end
	
	local methods = {
		["OnAcquire"] = function(self)
			CreateDelay(self)
			self.frame:SetScript("PreClick", PreClick)
			self:SetHeight(24)
			self:SetWidth(200)
			self:SetDisabled(false)
			self:SetText()
			self.GetLocations = function() return {} end
			self.mode = "normal"
		end,

		["OnRelease"] = function(self)
			self.delay:Hide()
		end,

		["SetText"] = function(self, text)
			self.frame:SetText(text)
		end,
		
		["SetSpell"] = function(self, spell)
			spell = strlower(spell or "")
			assert(spell == "milling" or spell == "prospecting" or spell == "disenchanting", "Invalid spell name: "..spell..". Expected \"Milling\" or \"Prospecting\" or \"Disenchanting\"")
			self.spell = spell
		end,
		
		["SetMode"] = function(self, mode)
			mode = strlower(mode or "")
			assert(mode == "fast" or mode == "normal", "Invalid mode: "..mode..". Expected \"fast\" or \"normal\"")
			self.mode = mode
		end,

		["SetDisabled"] = function(self, disabled)
			self.disabled = disabled
			if disabled then
				self.frame:Disable()
			else
				self.frame:Enable()
			end
		end,
		
		["SetLocationsFunc"] = function(self, func)
			assert(type(func) == "function", "Expected function, got "..type(func)..".")
			self.GetLocations = func
		end,
	}
	
	local function Constructor()
		local name = "TSMDestroyingButton" .. AceGUI:GetNextWidgetNum(Type)
		local frame = CreateFrame("Button", name, UIParent, "SecureActionButtonTemplate")
		frame:Hide()

		frame:EnableMouse(true)
		frame:SetScript("OnEnter", function(self) frame.obj:Fire("OnEnter") end)
		frame:SetScript("OnLeave", function(self) frame.obj:Fire("OnLeave") end)
		
		frame:SetBackdrop({
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			edgeSize = 18,
			insets = {left = 0, right = 0, top = 0, bottom = 0},
		})

		local normalTex = frame:CreateTexture()
		normalTex:SetTexture("Interface\\TokenFrame\\UI-TokenFrame-CategoryButton")
		normalTex:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
		normalTex:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 6, 6)
		normalTex:SetTexCoord(0.049, 0.958, 0.066, 0.244)
		frame:SetNormalTexture(normalTex)

		local disabledTex = frame:CreateTexture()
		disabledTex:SetTexture("Interface\\TokenFrame\\UI-TokenFrame-CategoryButton")
		disabledTex:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
		disabledTex:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 6, 6)
		disabledTex:SetVertexColor(0.1, 0.1, 0.1, 1)
		disabledTex:SetTexCoord(0.049, 0.958, 0.066, 0.244)
		frame:SetDisabledTexture(disabledTex)

		local highlightTex = frame:CreateTexture()
		highlightTex:SetTexture("Interface\\TokenFrame\\UI-TokenFrame-CategoryButton")
		highlightTex:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
		highlightTex:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 6, 6)
		highlightTex:SetTexCoord(0.005, 0.994, 0.613, 0.785)
		highlightTex:SetVertexColor(0.3, 0.3, 0.3, 0.7)
		frame:SetHighlightTexture(highlightTex)

		local pressedTex = frame:CreateTexture()
		pressedTex:SetTexture("Interface\\TokenFrame\\UI-TokenFrame-CategoryButton")
		pressedTex:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
		pressedTex:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 6, 6)
		pressedTex:SetVertexColor(1, 1, 1, 0.5)
		pressedTex:SetTexCoord(0.0256, 0.743, 0.017, 0.158)
		frame:SetPushedTexture(pressedTex)
		frame:SetPushedTextOffset(0, -2)
		
		local tFile, tSize = GameFontHighlight:GetFont()
		local fontString = frame:CreateFontString()
		fontString:SetFont(tFile, tSize, "OUTLINE")
		frame:SetFontString(fontString)
		frame:GetFontString():SetPoint("CENTER")
		frame:GetFontString():SetTextColor(1, 0.73, 0, 1)

		local widget = {
			frame = frame,
			type  = Type
		}
		for method, func in pairs(methods) do
			widget[method] = func
		end

		return AceGUI:RegisterAsWidget(widget)
	end

	AceGUI:RegisterWidgetType(Type, Constructor, Version)
	--	Example Use:
	-- local function SapuGetLocations(previous)
		-- for bag=0, 4 do
			-- for slot=1, GetContainerNumSlots(bag) do
				-- local _, quantity = GetContainerItemInfo(bag, slot)
				-- local itemID = GetContainerItemID(bag, slot)
				-- if itemID and select(7, GetItemInfo(itemID)) == "Metal & Stone" and quantity >= 5 and (bag ~= previous.bag or slot ~= previous.slot) then
					-- return {bag=bag, slot=slot}
				-- end
			-- end
		-- end
	-- end

	-- local testButton = AceGUI:Create("TSMFastDestroyButton")
	-- testButton:SetText("CLICK ME")
	-- testButton:SetRelativeWidth(1)
	-- testButton:SetMode("fast")
	-- testButton:SetSpell("Prospecting")
	-- testButton:SetLocationsFunc(SapuGetLocations)
	-- testButton:SetCallback("Finished", function(self) self:SetDisabled(true) print("Done!") end)
	-- parent:AddChild(testButton)
end

-- Dropdown
do
	local Type, Version = "TSMDropdown", 1
	if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

	local function Constructor()
		local dropdown = AceGUI:Create("Dropdown")
		dropdown.type = Type
		return AceGUI:RegisterAsWidget(dropdown)
	end

	AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

-- EditBox
do
	local Type, Version = "TSMEditBox", 1
	if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end
	
	local function Constructor()
		local editBox = AceGUI:Create("EditBox")
		editBox.type = Type
		return AceGUI:RegisterAsWidget(editBox)
	end

	AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

-- CheckBox
do
	local Type, Version = "TSMCheckBox", 1
	if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end
	
	local function Constructor()
		local checkBox = AceGUI:Create("CheckBox")
		checkBox.type = Type
		return AceGUI:RegisterAsWidget(checkBox)
	end

	AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

-- Slider
do
	local Type, Version = "TSMSlider", 1
	if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end
	
	local function Constructor()
		local slider = AceGUI:Create("Slider")
		slider.type = Type
		return AceGUI:RegisterAsWidget(slider)
	end

	AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

-- Button
do
	local Type, Version = "TSMButton", 1
	if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end
	
	local function Constructor()
		local button = AceGUI:Create("Button")
		button.type = Type
		
		local btn = button.frame
		
		btn:SetBackdrop({
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			edgeSize = 18,
			insets = {left = 0, right = 0, top = 0, bottom = 0},
		})

		local normalTex = btn:CreateTexture()
		normalTex:SetTexture("Interface\\TokenFrame\\UI-TokenFrame-CategoryButton")
		normalTex:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -6, -6)
		normalTex:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 6, 6)
		normalTex:SetTexCoord(0.049, 0.958, 0.066, 0.244)
		btn:SetNormalTexture(normalTex)

		local disabledTex = btn:CreateTexture()
		disabledTex:SetTexture("Interface\\TokenFrame\\UI-TokenFrame-CategoryButton")
		disabledTex:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -6, -6)
		disabledTex:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 6, 6)
		disabledTex:SetVertexColor(0.1, 0.1, 0.1, 1)
		disabledTex:SetTexCoord(0.049, 0.958, 0.066, 0.244)
		btn:SetDisabledTexture(disabledTex)

		local highlightTex = btn:CreateTexture()
		highlightTex:SetTexture("Interface\\TokenFrame\\UI-TokenFrame-CategoryButton")
		highlightTex:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -6, -6)
		highlightTex:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 6, 6)
		highlightTex:SetTexCoord(0.005, 0.994, 0.613, 0.785)
		highlightTex:SetVertexColor(0.3, 0.3, 0.3, 0.7)
		btn:SetHighlightTexture(highlightTex)

		local pressedTex = btn:CreateTexture()
		pressedTex:SetTexture("Interface\\TokenFrame\\UI-TokenFrame-CategoryButton")
		pressedTex:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -6, -6)
		pressedTex:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 6, 6)
		pressedTex:SetVertexColor(1, 1, 1, 0.5)
		pressedTex:SetTexCoord(0.0256, 0.743, 0.017, 0.158)
		btn:SetPushedTexture(pressedTex)
		btn:SetPushedTextOffset(0, -2)

		return AceGUI:RegisterAsWidget(button)
	end

	AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

do
	local Type, Version = "TSMMultiLabel", 1
	
	local methods = {
		["OnAcquire"] = function(self)
			-- height is set dynamically by the text size
			self:SetWidth(200)
			for i=1, #self.labels do
				self.labels[i]:SetText()
			end
			self:SetColor()
			self:SetFontObject()
		end,
		
		["OnWidthSet"] = function(self, width)
			self:SetLabels(self.info)
		end,

		["SetLabels"] = function(self, info)
			self.info = info
			local totalWidth = self.frame:GetWidth() or 0
			local usedWidth = 0
			local maxHeight = 0
			for i=1, #info do
				if not self.labels[i] then
					self.labels[i] = self.frame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
					self.labels[i]:SetJustifyH("LEFT")
					self.labels[i]:SetJustifyV("TOP")
				end
				self.labels[i]:SetText(info[i].text)
				self.labels[i]:SetPoint("TOPLEFT", self.frame, "TOPLEFT", usedWidth, 0)
				
				local labelWidth = totalWidth*(info[i].relativeWidth or 0)
				labelWidth = min(labelWidth, totalWidth-usedWidth)
				self.labels[i]:SetWidth(labelWidth)
				usedWidth = usedWidth + labelWidth
				
				if self.labels[i]:GetHeight() > maxHeight then
					maxHeight = self.labels[i]:GetHeight()
				end
			end
			self.frame:SetHeight(maxHeight)
		end,

		["SetColor"] = function(self, r, g, b)
			if not (r and g and b) then
				r, g, b = 1, 1, 1
			end
			for _, label in ipairs(self.labels) do
				label:SetVertexColor(r, g, b)
			end
		end,

		["SetFont"] = function(self, font, height, flags)
			for _, label in ipairs(self.labels) do
				label:SetFont(font, height, flags)
			end
		end,

		["SetFontObject"] = function(self, font)
			for _, label in ipairs(self.labels) do
				label:SetFont((font or GameFontHighlightSmall):GetFont())
			end
		end,
	}
	
	local function Constructor()
		local frame = CreateFrame("Frame", nil, UIParent)
		frame:Hide()

		local labels = {}
		labels[1] = frame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
		labels[1]:SetJustifyH("LEFT")
		labels[1]:SetJustifyV("TOP")

		local widget = {
			labels = labels,
			info = {},
			frame = frame,
			type  = Type,
		}
		for method, func in pairs(methods) do
			widget[method] = func
		end

		return AceGUI:RegisterAsWidget(widget)
	end

	AceGUI:RegisterWidgetType(Type, Constructor, Version)
end