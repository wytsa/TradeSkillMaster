-- This file contains support code for the custom TSM widgets
local TSM = select(2, ...)
local lib = TSMAPI

TSMAPI.Design = {}
local Design = TSMAPI.Design
local coloredFrames = {}
local coloredTexts = {}


--[[-----------------------------------------------------------------------------
Support functions
-------------------------------------------------------------------------------]]

local function expandColor(tbl)
	tbl = CopyTable(tbl)
	for i=1, 3 do
		tbl[i] = tbl[i] / 255
	end
	return unpack(tbl)
end

local function SetFrameColor(obj, colorKey)
	local color = Design.frameColors[colorKey]
	if not obj then return expandColor(color.backdrop) end
	coloredFrames[obj] = {obj, colorKey}
	if obj:IsObjectType("Frame") then
		obj:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=Design.edgeSize})
		obj:SetBackdropColor(expandColor(color.backdrop))
		obj:SetBackdropBorderColor(expandColor(color.border))
	else
		obj:SetTexture(expandColor(color.backdrop))
	end
end

local function SetTextColor(obj, colorKey, isDisabled)
	local color = Design.textColors[colorKey]
	if not obj then return expandColor(color.enabled) end
	coloredTexts[obj] = {obj, colorKey, isDisabled}
	if obj:IsObjectType("Texture") then
		obj:SetTexture(expandColor(color.enabled))
	else
		if isDisabled then
			obj:SetTextColor(expandColor(color.disabled))
		else
			obj:SetTextColor(expandColor(color.enabled))
		end
	end
end

--[[-----------------------------------------------------------------------------
Design API functions
-------------------------------------------------------------------------------]]

function Design:SetFrameBackdropColor(obj)
	return SetFrameColor(obj, "frameBG")
end

function Design:SetFrameColor(obj)
	return SetFrameColor(obj, "frame")
end

function Design:SetContentColor(obj)
	return SetFrameColor(obj, "content")
end

function Design:SetIconRegionColor(obj)
	return SetTextColor(obj, "iconRegion")
end

function Design:SetWidgetTextColor(obj, isDisabled)
	return SetTextColor(obj, "text", isDisabled)
end

function Design:SetWidgetLabelColor(obj, isDisabled)
	return SetTextColor(obj, "label", isDisabled)
end

function Design:SetTitleTextColor(obj)
	return SetTextColor(obj, "title")
end

function Design:GetContentFont(size)
	size = size or "normal"
	if Design.fontSizes[size] then
		size = Design.fontSizes[size]
	else
		error(format("Invalid font size '%s", tostring(size)))
	end
	return Design.fonts.content, size
end

function Design:GetBoldFont()
	return Design.fonts.bold
end


function lib:UpdateDesign()
	local oldTbl = coloredFrames
	coloredFrames = {}
	for _, args in pairs(oldTbl) do
		SetFrameColor(unpack(args))
	end
	
	oldTbl = coloredTexts
	coloredTexts = {}
	for _, args in pairs(oldTbl) do
		SetTextColor(unpack(args))
	end
end