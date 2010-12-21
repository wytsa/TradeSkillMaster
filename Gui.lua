-- This module holds some GUI helper functions for modules to use.
-- These functions support the table format for building AceGUI pages created by Sapu94.

local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries
local lib = TSMAPI
local private = {}

-- creates a widget or container as detailed in the passed table (iTable) and adds it as a child of the passed parent
local function AddGUIElement(parent, iTable)
	local function AddTooltip(widget, text, title)
		if not text then return end
		widget:SetCallback("OnEnter", function(self)
				GameTooltip:SetOwner(self.frame, "ANCHOR_NONE")
				GameTooltip:SetPoint("BOTTOM", self.frame, "TOP")
				if title then
					GameTooltip:SetText(title, 1, .82, 0, 1)
				end
				if type(text) == "number" then
					GameTooltip:SetHyperlink("item:" .. text)
				else
					GameTooltip:AddLine(text, 1, 1, 1, 1)
				end
				GameTooltip:Show()
			end)
		widget:SetCallback("OnLeave", function()
				GameTooltip:ClearLines()
				GameTooltip:Hide()
			end)
	end

	local Add = {
		InlineGroup = function(parent, args)
				local inlineGroup = AceGUI:Create("TSMInlineGroup")
				inlineGroup:SetLayout(args.layout)
				inlineGroup:SetTitle(args.title)
				inlineGroup:SetFullWidth(true)
				parent:AddChild(inlineGroup)
				return inlineGroup
			end,
			
		SimpleGroup = function(parent, args)
				local simpleGroup = AceGUI:Create("TSMSimpleGroup")
				simpleGroup:SetLayout(args.layout)
				simpleGroup:SetFullWidth(true)
				parent:AddChild(simpleGroup)
				return simpleGroup
			end,
		ScrollFrame = function(parent, args)
				local scrollFrame = AceGUI:Create("TSMScrollFrame")
				scrollFrame:SetLayout(args.layout)
				parent:AddChild(scrollFrame)
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
				elseif args.fullWidth then
					iLabelWidget:SetFullWidth(args.fullWidth)
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
				elseif args.fullWidth then
					buttonWidget:SetFullWidth(args.fullWidth)
				end
				if args.height then buttonWidget:SetHeight(args.height) end
				buttonWidget:SetCallback("OnClick", args.callback)
				AddTooltip(buttonWidget, args.tooltip, args.text)
				parent:AddChild(buttonWidget)
				return buttonWidget
			end,
			
		MacroButton = function(parent, args)
				local buttonWidget = AceGUI:Create("TSMMacroButton")
				buttonWidget:SetText(args.text)
				buttonWidget:SetDisabled(args.disabled)
				if args.width then
					buttonWidget:SetWidth(args.width)
				elseif args.relativeWidth then
					buttonWidget:SetRelativeWidth(args.relativeWidth)
				elseif args.fullWidth then
					buttonWidget:SetFullWidth(args.fullWidth)
				end
				if args.height then buttonWidget:SetHeight(args.height) end
				buttonWidget.SecureClick = args.callback
				buttonWidget.frame:SetAttribute("type", "macro")
				buttonWidget.frame:SetAttribute("macrotext", args.macroText)
				AddTooltip(buttonWidget, args.tooltip, args.text)
				parent:AddChild(buttonWidget)
				return buttonWidget
			end,
			
		EditBox = function(parent, args)
				local editBoxWidget = AceGUI:Create("EditBox")
				editBoxWidget:SetText(args.value)
				editBoxWidget:SetLabel(args.label)
				editBoxWidget:SetDisabled(args.disabled)
				if args.width then
					editBoxWidget:SetWidth(args.width)
				elseif args.relativeWidth then
					editBoxWidget:SetRelativeWidth(args.relativeWidth)
				elseif args.fullWidth then
					editBoxWidget:SetFullWidth(args.fullWidth)
				end
				editBoxWidget:SetCallback("OnEnterPressed", args.callback)
				AddTooltip(editBoxWidget, args.tooltip, args.label)
				parent:AddChild(editBoxWidget)
				return editBoxWidget
			end,
			
		CheckBox = function(parent, args)
				local checkBoxWidget = AceGUI:Create("CheckBox")
				checkBoxWidget:SetType("checkbox")
				checkBoxWidget:SetValue(args.value)
				checkBoxWidget:SetLabel(args.label)
				checkBoxWidget:SetDisabled(args.disabled)
				if args.fullWidth then
					checkBoxWidget:SetFullWidth(args.fullWidth)
				elseif args.width then
					checkBoxWidget:SetWidth(args.width)
				elseif args.relativeWidth then
					checkBoxWidget:SetRelativeWidth(args.relativeWidth)
				end
				checkBoxWidget:SetCallback("OnValueChanged", args.callback)
				AddTooltip(checkBoxWidget, args.tooltip, args.label)
				parent:AddChild(checkBoxWidget)
				return checkBoxWidget
			end,
		Slider = function(parent, args)
				local sliderWidget = AceGUI:Create("Slider")
				sliderWidget:SetValue(args.value)
				sliderWidget:SetSliderValues(args.min, args.max, args.step)
				sliderWidget:SetIsPercent(args.isPercent)
				sliderWidget:SetLabel(args.label)
				if args.width then
					sliderWidget:SetWidth(args.width)
				elseif args.relativeWidth then
					sliderWidget:SetRelativeWidth(args.relativeWidth)
				elseif args.fullWidth then
					sliderWidget:SetFullWidth(args.fullWidth)
				end
				sliderWidget:SetCallback("OnValueChanged", args.callback)
				sliderWidget:SetDisabled(args.disabled)
				AddTooltip(sliderWidget, args.tooltip, args.label)
				parent:AddChild(sliderWidget)
				return sliderWidget
			end,
		Icon = function(parent, args)
				local iconWidget = AceGUI:Create("Icon")
				iconWidget:SetImage(args.image)
				iconWidget:SetImageSize(args.imageWidth, args.imageHeight)
				if args.width then
					iconWidget:SetWidth(args.width)
				end
				iconWidget:SetDisabled(args.disabled)
				iconWidget:SetLabel(args.label)
				iconWidget:SetCallback("OnClick", args.callback)
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
				elseif args.fullWidth then
					dropdownWidget:SetFullWidth(args.fullWidth)
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
				AddTooltip(dropdownWidget, args.tooltip, args.label)
				parent:AddChild(dropdownWidget)
				return dropdownWidget
			end,
			
		Spacer = function(parent, args)
				args.quantity = args.quantity or 1
				for i=1, args.quantity do
					local spacer = parent:Add({type="Label", text=" ", fullWidth=true})
				end
			end,
		HeadingLine = function(parent, args)
				local heading = AceGUI:Create("Heading")
				heading:SetText("")
				if args.relativeWidth then
					heading:SetRelativeWidth(args.relativeWidth)
				else
					heading:SetFullWidth(true)
				end
				parent:AddChild(heading)
			end,
	}
	
	if not Add[iTable.type] then
		print("Invalid Widget or Container Type: ", iTable.type)
		return
	end
	
	return Add[iTable.type](parent, iTable)
end

-- register all the custom AceGUI containers / widgets
do
	do
		local Type, Version = "TSMWindow", 1
		if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end
		
		local function Constructor()
			local container = AceGUI:Create("Window")
			container.type = Type
			container.Add = AddGUIElement
			
			for _, frame in pairs({container.frame:GetRegions()}) do
				if frame.GetVertexColor and frame:GetVertexColor() == 0 then
					frame:SetTexture(0, 0, 0, 1)
					frame:SetVertexColor(0, 0, 0, 0.9)
				end
			end
			
			AceGUI:RegisterAsContainer(container)
			return container
		end

		AceGUI:RegisterWidgetType(Type, Constructor, Version)
	end
	
	do
		local Type, Version = "TSMFrame", 1
		if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end
		
		local function Constructor()
			local container = AceGUI:Create("Frame")
			container.type = Type
			container.frame:SetBackdrop({
				bgFile = "Interface\\Buttons\\WHITE8X8",
				tile = false,
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				edgeSize = 24,
				insets = {left = 4, right = 4, top = 4, bottom = 4},
			})
			container.frame:SetBackdropColor(0, 0, 0.05, 1)
			container.frame:SetBackdropBorderColor(0,0,0.7,1)
			container.frame:SetFrameLevel(2)
			
			local titleFrame = container.titletext:GetParent()
			titleFrame:SetBackdrop({
				bgFile = "Interface\\Buttons\\WHITE8X8",
				tile = false,
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				edgeSize = 24,
				insets = {left = 4, right = 4, top = 4, bottom = 4},
			})
			titleFrame:SetBackdropColor(0, 0, 0.05, 1)
			titleFrame:SetBackdropBorderColor(0,0,0.7,1)
			
			local statusFrame = container.statustext:GetParent()
			statusFrame:SetBackdrop({
				bgFile = "Interface\\Buttons\\WHITE8X8",
				tile = false,
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				edgeSize = 24,
				insets = {left = 4, right = 4, top = 4, bottom = 4},
			})
			statusFrame:SetBackdropColor(0, 0, 0.05, 1)
			statusFrame:SetBackdropBorderColor(0,0,0.7,1)
			
			container.titlebg:Hide()
			
			for _,v in pairs({container.frame:GetRegions()}) do
				if v:GetTexture() == "Interface\\DialogFrame\\UI-DialogBox-Header" then
					v:Hide()
				end
			end
			
			-- frame to contain the icons on the right
			local frame = CreateFrame("Frame", nil, container.frame)
			frame:SetWidth(60)
			frame:SetBackdrop({
				bgFile = "Interface\\Buttons\\WHITE8X8",
				tile = false,
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				edgeSize = 20,
				insets = {left = 1, right = 4, top = 4, bottom = 4},
			})
			frame:SetBackdropColor(0, 0, 0.05, 1)
			frame:SetBackdropBorderColor(0,0,0.7,1)
			frame:SetPoint("TOPLEFT", container.frame, "TOPRIGHT", -8, -10)
			frame:SetPoint("BOTTOMLEFT", container.frame, "BOTTOMRIGHT", -8, 10)
			frame:SetFrameLevel(1)
			container.optionsIconContainer = frame
			
			-- frame to contain the icons on the left
			local frame = CreateFrame("Frame", nil, container.frame)
			frame:SetWidth(60)
			frame:SetBackdrop({
				bgFile = "Interface\\Buttons\\WHITE8X8",
				tile = false,
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				edgeSize = 20,
				insets = {left = 4, right = 1, top = 4, bottom = 4},
			})
			frame:SetBackdropColor(0, 0, 0.05, 1)
			frame:SetBackdropBorderColor(0,0,0.7,1)
			frame:SetPoint("TOPRIGHT", container.frame, "TOPLEFT", 8, -10)
			frame:SetPoint("BOTTOMRIGHT", container.frame, "BOTTOMLEFT", 8, 10)
			frame:SetFrameLevel(1)
			container.craftingIconContainer = frame
			
			-- frame to contain the icons on the bottom
			local frame = CreateFrame("Frame", nil, container.frame)
			frame:SetHeight(60)
			frame:SetBackdrop({
				bgFile = "Interface\\Buttons\\WHITE8X8",
				tile = false,
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				edgeSize = 20,
				insets = {left = 4, right = 1, top = 4, bottom = 4},
			})
			frame:SetBackdropColor(0, 0, 0.05, 1)
			frame:SetBackdropBorderColor(0,0,0.7,1)
			frame:SetPoint("TOPLEFT", container.frame, "BOTTOMLEFT", 10, 8)
			frame:SetPoint("TOPRIGHT", container.frame, "BOTTOMRIGHT", -10, 8)
			frame:SetFrameLevel(1)
			container.moduleIconContainer = frame
			
			AceGUI:RegisterAsContainer(container)
			return container
		end

		AceGUI:RegisterWidgetType(Type, Constructor, Version)
	end
	
	do
		local Type, Version = "TSMTreeGroup", 1
		if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end
		
		local function Constructor()
			local container = AceGUI:Create("TreeGroup")
			container.type = Type
			container.Add = AddGUIElement
			
			container.border:SetBackdrop({
				bgFile = "Interface\\Buttons\\WHITE8X8",
				tile = false,
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				edgeSize = 20,
				insets = {left = 4, right = 1, top = 4, bottom = 4},
			})
			container.border:SetBackdropColor(0, 0, 0.05, 1)
			container.border:SetBackdropBorderColor(0,0,0.7,1)
			
			container.treeframe:SetBackdrop({
				bgFile = "Interface\\Buttons\\WHITE8X8",
				tile = false,
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				edgeSize = 20,
				insets = {left = 4, right = 1, top = 4, bottom = 4},
			})
			container.treeframe:SetBackdropColor(0, 0, 0.05, 1)
			container.treeframe:SetBackdropBorderColor(0,0,0.7,1)
			
			AceGUI:RegisterAsContainer(container)
			return container
		end
		
		AceGUI:RegisterWidgetType(Type, Constructor, Version)
	end

	do
		local Type, Version = "TSMScrollFrame", 1
		if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end
		
		local function Constructor()
			local container = AceGUI:Create("ScrollFrame")
			container.type = Type
			container.Add = AddGUIElement
			AceGUI:RegisterAsContainer(container)
			return container
		end

		AceGUI:RegisterWidgetType(Type, Constructor, Version)
	end

	do
		local Type, Version = "TSMSimpleGroup", 1
		if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end
		
		local function Constructor()
			local container = AceGUI:Create("SimpleGroup")
			container.type = Type
			container.Add = AddGUIElement
			AceGUI:RegisterAsContainer(container)
			return container
		end

		AceGUI:RegisterWidgetType(Type, Constructor, Version)
	end
	
	do
		local Type, Version = "TSMTabGroup", 1
		if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end
		
		local function Constructor()
			local container = AceGUI:Create("TabGroup")
			container.type = Type
			container.Add = AddGUIElement
			
			container.border:SetBackdrop({
				bgFile = "Interface\\Buttons\\WHITE8X8",
				tile = false,
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				edgeSize = 20,
				insets = {left = 4, right = 1, top = 4, bottom = 4},
			})
			container.border:SetBackdropColor(0, 0, 0.05, 1)
			container.border:SetBackdropBorderColor(0,0,0.7,1)
			
			AceGUI:RegisterAsContainer(container)
			return container
		end

		AceGUI:RegisterWidgetType(Type, Constructor, Version)
	end

	do
		local Type, Version = "TSMInlineGroup", 1
		if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end
		
		local function Constructor()
			local container = AceGUI:Create("InlineGroup")
			container.type = Type
			container.Add = AddGUIElement
			
			local frame = container.content:GetParent()
			frame:SetBackdrop({
				bgFile = "Interface\\Buttons\\WHITE8X8",
				tile = false,
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				edgeSize = 20,
				insets = {left = 4, right = 1, top = 4, bottom = 4},
			})
			frame:SetBackdropColor(0, 0, 0.05, 1)
			frame:SetBackdropBorderColor(0,0,0.7,1)
			
			AceGUI:RegisterAsContainer(container)
			return container
		end

		AceGUI:RegisterWidgetType(Type, Constructor, Version)
	end
	
	do
		local Type, Version = "TSMMacroButton", 1
		local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
		if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end
		
		local function Button_OnClick(frame, ...)
			AceGUI:ClearFocus()
			PlaySound("igMainMenuOption")
		end

		local function Control_OnEnter(frame)
			frame.obj:Fire("OnEnter")
		end

		local function Control_OnLeave(frame)
			frame.obj:Fire("OnLeave")
		end

		--[[-----------------------------------------------------------------------------
		Methods
		-------------------------------------------------------------------------------]]
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
				self.text:SetText(text)
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
			frame:SetAttribute("type", "macro")
			frame:SetAttribute("macrotext", "/cast Milling;\n"
					.."/use Icethorn;")
			frame:SetScript("OnEnter", Control_OnEnter)
			frame:SetScript("OnLeave", Control_OnLeave)

			local text = frame:GetFontString()
			text:ClearAllPoints()
			text:SetPoint("TOPLEFT", 15, -1)
			text:SetPoint("BOTTOMRIGHT", -15, 1)
			text:SetJustifyV("MIDDLE")

			local widget = {
				text  = text,
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
end

-- goes through a page-table and draws out all the containers and widgets for that page
function lib:BuildPage(oContainer, oPageTable, noPause)
	local function recursive(container, pageTable)
		for _, data in pairs(pageTable) do
			local parentElement = container:Add(data)
			if data.children then
				parentElement:PauseLayout()
				-- yay recursive function calls!
				recursive(parentElement, data.children)
				parentElement:ResumeLayout()
				parentElement:DoLayout()
			end
		end
	end
	if not oContainer.Add then
		local container = AceGUI:Create("TSMSimpleGroup")
		container:SetLayout("fill")
		container:SetFullWidth(true)
		container:SetFullHeight(true)
		oContainer:AddChild(container)
		oContainer = container
	end
	if not noPause then
		oContainer:PauseLayout()
		recursive(oContainer, oPageTable)
		oContainer:ResumeLayout()
		oContainer:DoLayout()
	else
		recursive(oContainer, oPageTable)
	end
end