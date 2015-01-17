-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table


--[[-----------------------------------------------------------------------------
TSMAPI:BuildFrame() Support Functions
-------------------------------------------------------------------------------]]


local function GetBuildFrameInfoDebugString(info)
	return format(" (key='%s', type='%s')", tostring(info.key), tostring(info.type))
end

function TSMAPI:BuildFrame(info)
	-- create the widget
	local widget
	if info.type == "PreFrame" then
		-- pre-created frame
		info.type = "Frame"
		widget = info.widget
		widget.tsmInfo = info
		for _, childInfo in ipairs(info.children or {}) do
			childInfo.parent = widget
			TSMAPI:BuildFrame(childInfo)
		end
		return
	elseif info.type == "Frame" then
		widget = CreateFrame("Frame", info.name, info.parent)
		if info.strata then
			widget:SetFrameStrata(info.strata)
		end
		if info.mouse then
			widget:EnableMouse(true)
		end
	elseif info.type == "Dropdown" then
		widget = TSMAPI.GUI:CreateDropdown(info.parent, info.list, info.tooltip)
		widget:SetLabel(info.label)
		widget:SetMultiselect(info.multiselect)
	elseif info.type == "Button" then
		TSMAPI:Assert(info.textHeight, "Buttons require a textHeight:"..GetBuildFrameInfoDebugString(info))
		widget = TSMAPI.GUI:CreateButton(info.parent, info.textHeight, info.name, info.isSecure)
		if info.clicks then
			widget:RegisterForClicks(info.clicks)
		end
		widget.tooltip = info.tooltip
	elseif info.type == "InputBox" then
		widget = TSMAPI.GUI:CreateInputBox(info.parent, info.name)
		widget:SetNumeric(info.numeric)
	elseif info.type == "HLine" then
		widget = TSMAPI.GUI:CreateHorizontalLine(info.parent, info.offset, info.relativeFrame, info.invertedColor)
	elseif info.type == "VLine" then
		widget = TSMAPI.GUI:CreateVerticalLine(info.parent, info.offset, info.relativeFrame, info.invertedColor)
	elseif info.type == "ScrollingTable" then
		widget = TSMAPI:CreateScrollingTable(info.parent, info.stCols, nil, info.headFontSize)
		widget:DisableSelection(info.stDisableSelection)
		if info.sortInfo then
			widget:EnableSorting(unpack(info.sortInfo))
		end
		widget:SetData({})
	elseif info.type == "ScrollingTableFrame" then
		widget = CreateFrame("Frame", nil, info.parent)
		TSMAPI.Design:SetFrameColor(widget)
		info._stTemp = {}
		for _, key in ipairs({"scripts", "handlers", "key", "stCols", "headFontSize", "stDisableSelection", "sortInfo"}) do
			info._stTemp[key] = info[key]
			info[key] = nil
		end
		if info._stTemp.key then
			info.key = info._stTemp.key.."Container"
		end
	elseif info.type == "GroupTreeFrame" then
		widget = CreateFrame("Frame", nil, info.parent)
		TSMAPI.Design:SetFrameColor(widget)
		if info.parent and info.key then
			info._gtKey = info.key
			info.key = info.key.."Container"
		end
	elseif info.type == "AuctionResultsTableFrame" then
		widget = CreateFrame("Frame", nil, info.parent)
		if info.parent and info.key then
			info._rtKey = info.key
			info.key = info.key.."Container"
		end
	elseif info.type == "StatusBarFrame" then
		TSMAPI:Assert(type(info.name) == "string", "Widget requires a name: "..info.type..GetBuildFrameInfoDebugString(info))
		widget = CreateFrame("Frame", nil, info.parent)
		if info.parent and info.key then
			info._sbKey = info.key
			info.key = info.key.."Container"
		end
	elseif info.type == "IconButton" then
		widget = CreateFrame("Button", info.name, info.parent)
		widget.icon = widget:CreateTexture()
		widget.icon:SetAllPoints()
		widget.SetTexture = function(self, ...) self.icon:SetTexture(...) end
		if info.icon then
			widget:SetTexture(info.icon)
		end
	elseif info.type == "Text" then
		widget = TSMAPI.GUI:CreateLabel(info.parent, info.textSize)
		widget:SetTextColor(1, 1, 1, 1)
		if info.justify then
			widget:SetJustifyH(info.justify[1] or "CENTER")
			widget:SetJustifyV(info.justify[2] or "MIDDLE")
		end
	elseif info.type == "TextureButton" then
		widget = CreateFrame("Button", info.name, info.parent)
		widget:SetNormalTexture(info.normalTexture)
		widget:SetPushedTexture(info.pushedTexture)
		widget:SetDisabledTexture(info.disabledTexture)
		widget:SetHighlightTexture(info.highlightTexture)
	elseif info.type == "MoneyInputBox" then
		TSMAPI:Assert(type(info.name) == "string", "Widget requires a name: "..info.type..GetBuildFrameInfoDebugString(info))
		widget = CreateFrame("Frame", info.name, info.parent, "MoneyInputFrameTemplate")
		widget.SetCopper = MoneyInputFrame_SetCopper
		widget.GetCopper = MoneyInputFrame_GetCopper
	elseif info.type == "ItemLinkLabel" then
		TSMAPI:Assert(not info.scripts, "Scripts are not supported for ItemLinkLabels"..GetBuildFrameInfoDebugString(info))
		widget = CreateFrame("Button", nil, info.parent)
		widget:SetScript("OnEnter", function(self) if self.link then GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT") TSMAPI:SafeTooltipLink(self.link) GameTooltip:Show() end end)
		widget:SetScript("OnLeave", HideTooltip)
		widget:SetScript("OnClick", function(self) if self.link then HandleModifiedItemClick(self.link) end end)
		widget:SetHeight(info.textHeight)
		widget:Show()
		local text = widget:CreateFontString()
		text:SetAllPoints()
		if info.textFont then
			text:SetFont(unpack(info.textFont))
		else
			text:SetFont(TSMAPI.Design:GetContentFont(), info.textHeight)
		end
		if info.justify then
			text:SetJustifyH(info.justify[1] or "CENTER")
			text:SetJustifyV(info.justify[2] or "MIDDLE")
		end
		widget:SetFontString(text)
	elseif info.type == "WidgetVList" then
		widget = {}
		TSMAPI:Assert(info.repeatCount > 1, "repeatCount must be > 1"..GetBuildFrameInfoDebugString(info))
	end
	TSMAPI:Assert(widget, "Invalid widget type: "..tostring(info.type)..GetBuildFrameInfoDebugString(info))
	
	if not info.handlers then
		info.handlers = (info.parent and info.parent.tsmInfo and info.parent.tsmInfo.handlers and info.parent.tsmInfo.handlers[info.key])
	end
	widget.tsmInfo = info
	
	-- add to parent table at specified key
	if info.parent and info.key then
		info.parent[info.key] = widget
	end
	
	-- set size
	if info.size then
		widget:SetWidth(info.size[1] or 0)
		widget:SetHeight(info.size[2] or 0)
	end
	
	-- set points
	if info.points == "ALL" then
		widget:ClearAllPoints()
		widget:SetAllPoints()
	elseif info.points then
		widget:ClearAllPoints()
		for i, pointInfo in ipairs(info.points) do
			if type(pointInfo[2]) == "string" then
				if pointInfo[2] == "" then
					pointInfo[2] = widget:GetParent()
				else
					-- look up the relative frame
					if widget.AceGUIWidgetVersion then
						-- it's an AceGUI widget
						pointInfo[2] = widget.frame:GetParent()[pointInfo[2]]
					else
						pointInfo[2] = widget:GetParent()[pointInfo[2]]
					end
					TSMAPI:Assert(pointInfo[2], "Could not lookup relative frame: "..tostring(pointInfo[2])..GetBuildFrameInfoDebugString(info))
				end
			end
			if type(pointInfo[2]) == "table" and pointInfo[2].AceGUIWidgetVersion then
				pointInfo[2] = pointInfo[2].frame
			end
			widget:SetPoint(unpack(pointInfo))
		end
	end
	
	-- set hidden if applicable
	if info.hidden then
		widget:Hide()
	end
	
	-- set scripts
	TSMAPI:Assert(not info.scripts or info.handlers, "No handlers found"..GetBuildFrameInfoDebugString(info))
	for _, script in ipairs(info.scripts or {}) do
		TSMAPI:Assert(info.handlers[script], "No handlers found for script: "..tostring(script)..GetBuildFrameInfoDebugString(info))
		if widget.AceGUIWidgetVersion then
			-- it's an AceGUI widget
			widget:SetCallback(script, function(self, script, ...) self.tsmInfo.handlers[script](self, ...) end)
		elseif widget.isTSMScrollingTable then
			-- it's a TSM ScrollingTable
			widget:SetHandler(script, info.handlers[script])
		else
			-- it's a plain WoW widget
			if type(info.handlers[script]) == "string" then
				widget:SetScript(script, widget[info.handlers[script]])
			else
				widget:SetScript(script, info.handlers[script])
			end
		end
	end
	
	-- set text attributes
	if info.text then
		widget:SetText(info.text)
	end
	if info.textColor then
		widget:SetTextColor(unpack(info.textColor))
	end
	if info.textFont then
		widget:SetFont(unpack(info.textFont))
	end
	
	-- set type-specific attributes for some types
	if info.type == "Frame" then
		-- create children
		for _, childInfo in ipairs(info.children or {}) do
			childInfo.parent = widget
			TSMAPI:BuildFrame(childInfo)
		end
	elseif info.type == "WidgetVList" then
		for i=1, info.repeatCount do
			local childInfo = info.widget
			childInfo.parent = info.parent
			if i == 1 then
				childInfo.points = info.startPoints
			else
				childInfo.points = {{"TOPLEFT", widget[i-1], "BOTTOMLEFT", 0, info.repeatOffset}, {"TOPRIGHT", widget[i-1], "BOTTOMRIGHT", 0, info.repeatOffset}}
			end
			tinsert(widget, TSMAPI:BuildFrame(childInfo))
		end
	elseif info.type == "ScrollingTableFrame" then
		-- create ST
		local stInfo = {type="ScrollingTable", parent=widget}
		for i, v in pairs(info._stTemp) do
			stInfo[i] = v
		end
		info.handlers = info.parent.tsmInfo.handlers
		info._stTemp = nil
		local st = TSMAPI:BuildFrame(stInfo)
		if info.parent and info.parent.tsmInfo and stInfo.key then
			info.parent[stInfo.key] = st
		end
	elseif info.type == "GroupTreeFrame" then
		local groupTree = TSMAPI:CreateGroupTree(widget, unpack(info.groupTreeInfo))
		if info._gtKey then
			info.parent[info._gtKey] = groupTree
		end
	elseif info.type == "AuctionResultsTableFrame" then
		local rt = TSMAPI:CreateAuctionResultsTable(widget, info.handlers)
		rt:SetData({})
		rt:SetSort(unpack(info.sortInfo))
		rt:Hide()
		if info._rtKey then
			info.parent[info._rtKey] = rt
		end
	elseif info.type == "StatusBarFrame" then
		local statusBar = TSMAPI.GUI:CreateStatusBar(widget, info.name)
		if info._sbKey then
			info.parent[info._sbKey] = statusBar
		end
	end
	
	return widget
end