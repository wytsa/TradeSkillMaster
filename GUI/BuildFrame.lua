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
	elseif info.type == "Dropdown" then
		widget = TSMAPI.GUI:CreateDropdown(info.parent, info.list, info.tooltip)
	elseif info.type == "Button" then
		widget = TSMAPI.GUI:CreateButton(info.parent, info.textHeight, info.name, info.isSecure)
		if info.clicks then
			widget:RegisterForClicks(info.clicks)
		end
		widget.tooltip = info.tooltip
	elseif info.type == "InputBox" then
		widget = TSMAPI.GUI:CreateInputBox(info.parent, info.name)
	elseif info.type == "HLine" then
		widget = TSMAPI.GUI:CreateHorizontalLine(info.parent, info.offset, info.relativeFrame, info.invertedColor)
	elseif info.type == "VLine" then
		widget = TSMAPI.GUI:CreateVerticalLine(info.parent, info.offset, info.relativeFrame, info.invertedColor)
	elseif info.type == "ScrollingTable" then
		widget = TSMAPI:CreateScrollingTable(info.parent, info.stCols, nil, info.headFontSize)
	elseif info.type == "ScrollingTableFrame" then
		widget = CreateFrame("Frame", nil, info.parent)
		info._stTemp = {}
		for _, key in ipairs({"scripts", "handlers", "key", "stCols", "headFontSize"}) do
			info._stTemp[key] = info[key]
			info[key] = nil
		end
		if info._stTemp.key then
			info.key = info._stTemp.key.."Container"
		end
	elseif info.type == "GroupTreeFrame" then
		widget = CreateFrame("Frame", nil, info.parent)
		local groupTree = TSMAPI:CreateGroupTree(widget, unpack(info.groupTreeInfo))
		if info.parent and info.key then
			info._gtKey = info.key
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
					pointInfo[2] = widget:GetParent()[pointInfo[2]]
					TSMAPI:Assert(pointInfo[2], "Could not lookup relative frame: "..tostring(pointInfo[2])..GetBuildFrameInfoDebugString(info))
				end
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
			widget:SetScript(script, info.handlers[script])
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
	end
	
	return widget
end