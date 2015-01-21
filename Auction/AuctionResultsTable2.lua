-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table

local RT_COUNT = 100
local HEAD_HEIGHT = 27
local HEAD_SPACE = 2


local function OnSizeChanged(rt, width)
	for i, cell in ipairs(rt.headCells) do
		cell:SetWidth(cell.info.width*width)
	end
	
	for _, row in ipairs(rt.rows) do
		for i, cell in ipairs(row.cells) do
			cell:SetWidth(rt.headCells[i].info.width*width)
		end
	end
end

local rowTextFunctions = {
	GetPriceText = function(buyout, displayBid)
		return buyout and buyout > 0 and TSMAPI:FormatTextMoney(buyout, nil, true) or "---"
	end,

	GetTimeLeftText = function(timeLeft)
		return _G["AUCTION_TIME_LEFT"..(timeLeft or "")] or ""
	end,

	GetNameText = function(_, link)
		return gsub(link, "[%[%]]", "")
	end,

	GetAuctionsText = function(num, player, isExpandable, totalNum)
		num = isExpandable and (TSMAPI.Design:GetInlineColor("link2")..(totalNum or num).."|r") or num
		local playerText = player and (" |cffffff00("..player..")|r") or ""
		return num..playerText
	end,

	GetSellerText = function(seller)
		seller = seller or ""
		return TSMAPI:IsPlayer(seller) and ("|cffffff00"..seller.."|r") or seller
	end,

	GetPercentText = function(pct)
		return pct and (TSMAPI:GetAuctionPercentColor(pct)..floor(pct+0.5).."%|r") or "---"
	end
}

local function GetRowTable(rt, auction, isExpandable)
	if not auction then return end
	
	local bid, buyout
	if TSM.db.profile.pricePerUnit then
		bid = auction:GetItemDisplayedBid()
		buyout = auction:GetItemBuyout()
	else
		bid = auction:GetDisplayedBid()
		buyout = auction.buyout
	end
	
	local auctionsData, rowTable
	local itemString = TSMAPI:GetItemString(auction.itemLink) or auction.parent:GetItemString()
	if rt.expanded[itemString] then
		auctionsData = {#auction.parent.records, nil, nil, auction.numAuctions}
	else
		auctionsData = {#auction.parent.records, auction.parent.records[1].playerAuctions, isExpandable}
	end
	local name, iLvl = TSMAPI:Select({1, 4}, TSMAPI:GetSafeItemInfo(auction.itemLink))
	ilvl = ilvl or 1
	local pct = auction:GetPercent()
	if not pct or pct < 0 or pct == math.huge then
		pct = nil
	end
	
	rowTable = {
		{value=rowTextFunctions.GetNameText, 		args={name, auction.itemLink}, 	sortArg=name},
		{value=iLvl, 										args={iLvl}, 							sortArg=ilvl},
		{value=rowTextFunctions.GetAuctionsText, 	args=auctionsData, 					sortArg=#auction.parent.records},
		{value=auction.count, 							args={auction.count}, 				sortArg=auction.count},
		{value=rowTextFunctions.GetTimeLeftText, 	args={auction.timeLeft}, 			sortArg=auction.timeLeft},
		{value=rowTextFunctions.GetSellerText,		args={auction.seller}, 				sortArg=auction.seller},
		{value=rowTextFunctions.GetPriceText,		args={buyout, bid}, 					sortArg=auction.buyout},
		{value=rowTextFunctions.GetPercentText, 	args={pct}, 							sortArg=auction.pct},
	}
	
	rowTable.itemString = itemString
	rowTable.auctionRecord = auction
	rowTable.expandable = isExpandable
	rowTable.texture = auction.texture
	rowTable.link = auction.itemLink
	
	return rowTable
end

local function GetTableIndex(tbl, value)
	for i, v in pairs(tbl) do
		if value == v then
			return i
		end
	end
end

local function OnColumnClick(self, ...)
	local button = ...
	local rt = self.rt
	local column = GetTableIndex(rt.headCells, self)
	
	if button == "RightButton" and column == #rt.headCells-1 then
		TSM.db.profile.pricePerUnit = not TSM.db.profile.pricePerUnit
		self:SetText(TSM.db.profile.pricePerUnit and L["Price Per Item"] or L["Price Per Stack"])
		rt:RefreshRowData()
		return
	end
	
	local ascending = rt.sortInfo.ascending
	rt:SetSort(column, rt.sortInfo.column ~= column or not ascending)
	
	local handler = self.rt.handlers.OnColumnClick
	if handler then
		handler(self.rt, self.row.data, self, ...)
	end
end

local methods = {
	DrawRows = function(rt)
		if not rt.auctionData then return end
		for i=1, rt.NUM_ROWS do
			rt.rows[i]:Hide()
		end
	
		wipe(rt.displayRows)
		local itemsUsed = {}
		for i, data in ipairs(rt.data) do
			print(i, data.itemString)
			local itemString = data.itemString
			if not itemsUsed[itemString] or rt.expanded[itemString] then
				tinsert(rt.displayRows, data)
				itemsUsed[itemString] = true
			elseif i == rt.selected then
				rt.selected = nil
			end
		end
	
		FauxScrollFrame_Update(rt.scrollFrame, #rt.displayRows, rt.NUM_ROWS, rt.ROW_HEIGHT)
		local offset = FauxScrollFrame_GetOffset(rt.scrollFrame)

		for i=1, min(rt.NUM_ROWS, #rt.displayRows) do
			rt.rows[i]:Show()
			local data = rt.displayRows[i+offset]
			rt.rows[i].data = data
			
			if rt.selected == GetTableIndex(rt.data, data) then
				rt.rows[i].highlight:Show()
			else
				rt.rows[i].highlight:Hide()
			end
			
			for j, cell in ipairs(rt.rows[i].cells) do
				local colData = data[j]
				
				if j == 1 then
					cell.icon:SetTexture(data.texture)
					if data.indented then
						cell.spacer:SetWidth(10)
						cell.icon:SetAlpha(0.5)
						cell:GetFontString():SetAlpha(0.7)
					else
						cell.spacer:SetWidth(1)
						cell.icon:SetAlpha(1)
						cell:GetFontString():SetAlpha(1)
					end
				end
				
				if type(colData.value) == "function" then
					cell:SetText(colData.value(unpack(colData.args)))
				else
					cell:SetText(colData.value)
				end
			end
		end
	end,

	RefreshRowData = function(rt)
		if not rt.auctionData then return end
		wipe(rt.data)
		wipe(rt.displayRows)
		
		local function RowSort(a, b)
			for i, key in ipairs({rt.sortInfo.column, 1, 7}) do
				local aVal = a[key].sortArg
				local bVal = b[key].sortArg
				if type(aValue) == "string" or type(bVal) == "string" then
					aVal = aVal or ""
					bVal = bVal or ""
				else
					aVal = tonumber(aVal) or 0
					bVal = tonumber(bVal) or 0
				end
				if aVal ~= bVal then
					if rt.sortInfo.ascending or i > 1 then
						return aVal < bVal
					else
						return aVal > bVal
					end
				end
			end
			-- if all else fails, make this a stable sort by comparing table reference strings
			return tostring(a) < tostring(b)
		end
		
		local tmp = {}
		for _, auction in ipairs(rt.auctionData) do
			print(auction.itemLink, #auction.compactRecords)
			local itemRowData = {}
			for i, data in ipairs(auction.compactRecords) do
				local rowTbl = GetRowTable(rt, data, #auction.compactRecords > 1)
				rowTbl.indented = true
				tinsert(itemRowData, rowTbl)
			end
			
			sort(itemRowData, RowSort)
			if itemRowData[1] then
				itemRowData[1].indented = false
			end
			tinsert(tmp, itemRowData)
		end
		
		sort(tmp, function(a, b) return RowSort(a[1], b[1]) end)
		
		for _, itemRows in ipairs(tmp) do
			for _, row in ipairs(itemRows) do
				tinsert(rt.data, row)
			end
		end
		
		rt:DrawRows()
	end,

	SetData = function(rt, auctionData)
		rt.auctionData = auctionData
		rt:RefreshRowData()
	end,

	ClearSelection = function(rt)
		rt.selected = nil
		rt:DrawRows()
	end,

	SetSelectedAuction = function(rt, auction)
		rt.selected = nil
		for i, data in ipairs(rt.data) do
			if type(auction) == "table" then
				if data.auctionRecord == auction or data.auctionRecord:Equals(auction) then
					rt.selected = i
					break
				end
			elseif type(auction) == "string" then
				if data.itemString == auction then
					rt.selected = i
					break
				end
			end
		end
		rt:DrawRows()
	end,
	
	GetSelectedAuction = function(rt)
		if not rt.selected or not rt.data[rt.selected] then return end
		return rt.data[rt.selected].auctionRecord
	end,
	
	SetExpanded = function(rt, itemString, expanded)
		rt.expanded[itemString] = expanded
		rt:RefreshRowData()
	end,
	
	ToggleExpanded = function(rt, itemString)
		rt.expanded[itemString] = not rt.expanded[itemString]
		rt:RefreshRowData()
	end,
	
	SetSort = function(rt, column, ascending)
		if not rt.headCells[column or 0] then return end
		rt.sortInfo.column = column
		rt.sortInfo.ascending = ascending

		for _, cell in ipairs(rt.headCells) do
			local tex = cell:GetNormalTexture()
			tex:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScore-Highlight")
			tex:SetTexCoord(0.017, 1, 0.083, 0.909)
			tex:SetAlpha(0.5)
		end

		if ascending then
			rt.headCells[column]:GetNormalTexture():SetTexture(0.6, 0.8, 1, 0.8)
		else
			rt.headCells[column]:GetNormalTexture():SetTexture(0.8, 0.6, 1, 0.8)
		end
		rt:RefreshRowData()
	end,
	
	SetDisabled = function(rt, disabled)
		rt.disabled = disabled
	end,
	
	SetColHeadText = function(rt, column, text)
		rt.headCells[column]:SetText(text)
	end,
	
	SetHandler = function(rt, event, handler)
		rt.handlers[event] = handler
	end,
}

local defaultCellScripts = {
	OnEnter = function(self, ...)
		if self.rt.disabled then return end
		
		if self ~= self.row.cells[1] or not self.rt.isShowingItemTooltip then
			GameTooltip:SetOwner(self, "ANCHOR_NONE")
			GameTooltip:SetPoint("BOTTOMLEFT", self, "TOPLEFT")

			if self.rt.expanded[self.row.data.itemString] then
				GameTooltip:AddLine(L["Double-click to collapse this item and show only the cheapest auction."], 1, 1, 1, true)
			elseif self.row.data.expandable then
				GameTooltip:AddLine(L["Double-click to expand this item and show all the auctions."], 1, 1, 1, true)
			else
				GameTooltip:AddLine(L["There is only one price level and seller for this item."], 1, 1, 1, true)
			end
			GameTooltip:Show()
		end
		
		self.row.highlight:Show()
		
		local handler = self.rt.handlers.OnEnter
		if handler then
			handler(self.rt, self.row.data, self, ...)
		end
	end,
	
	OnLeave = function(self, ...)
		if self.rt.disabled then return end
		
		if self ~= self.row.cells[1] or not self.rt.isShowingItemTooltip then
			GameTooltip:Hide()
		end
		
		if not self.rt.selected or self.rt.selected ~= GetTableIndex(self.rt.data, self.row.data) then
			self.row.highlight:Hide()
		end
		
		local handler = self.rt.handlers.OnLeave
		if handler then
			handler(self.rt, self.row.data, self, ...)
		end
	end,
	
	OnClick = function(self, button, ...)
		if self.rt.disabled then return end
		self.rt:ClearSelection()
		self.rt.selected = GetTableIndex(self.rt.data, self.row.data)
		self.row.highlight:Show()
		
		local handler = self.rt.handlers.OnClick
		if handler then
			handler(self.rt, self.row.data, self, button, ...)
		end
	end,
	
	OnDoubleClick = function(self, ...)
		if self.rt.disabled then return end
		local data = self.row.data
		if data.expandable then
			self.rt:ToggleExpanded(data.itemString)
		end
		
		local handler = self.rt.handlers.OnDoubleClick
		if handler then
			handler(self.rt, self.row.data, self, ...)
		end
	end,
}

function TSMAPI:CreateAuctionResultsTable2(parent, handlers)
	local colInfo = {
		{name=L["Item"], width=0.42},
		{name=L["Item Level"], width=0.05, align="CENTER"},
		{name=L["Auctions"], width=0.07, align="CENTER"},
		{name=L["Stack Size"], width=0.05, align="CENTER"},
		{name=L["Time Left"], width=0.09, align="CENTER"},
		{name=L["Seller"], width=0.11, align="CENTER"},
		{name="", width=0.13, align="RIGHT", isPrice=true},
		{name=L["% Market Value"], width=0.08, align="CENTER"},
	}
	
	local rtName = "TSMAuctionResultsTable"..RT_COUNT
	RT_COUNT = RT_COUNT + 1
	local rt = CreateFrame("Frame", rtName, parent)
	rt.NUM_ROWS = TSM.db.profile.auctionResultRows
	rt.ROW_HEIGHT = (parent:GetHeight()-HEAD_HEIGHT-HEAD_SPACE)/rt.NUM_ROWS
	rt.isTSMResultsTable = true
	
	rt:SetScript("OnShow", function()
		rt:SetColHeadText(#rt.headCells-1, TSM.db.profile.pricePerUnit and L["Price Per Item"] or L["Price Per Stack"])
		rt:RefreshRowData()
	end)
	
	local contentFrame = CreateFrame("Frame", rtName.."Content", rt)
	contentFrame:SetPoint("TOPLEFT")
	contentFrame:SetPoint("BOTTOMRIGHT", -15, 0)
	contentFrame:SetScript("OnSizeChanged", function(_, width) OnSizeChanged(rt, width) end)
	rt.contentFrame = contentFrame
	
	-- frame to hold the header columns and the rows
	local scrollFrame = CreateFrame("ScrollFrame", rtName.."ScrollFrame", rt, "FauxScrollFrameTemplate")
	scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, rt.ROW_HEIGHT, function() rt:DrawRows() end) 
	end)
	scrollFrame:SetAllPoints(contentFrame)
	rt.scrollFrame = scrollFrame
	
	-- make the scroll bar consistent with the TSM theme
	local scrollBar = _G[scrollFrame:GetName().."ScrollBar"]
	scrollBar:ClearAllPoints()
	scrollBar:SetPoint("BOTTOMRIGHT", rt, -1, 1)
	scrollBar:SetPoint("TOPRIGHT", rt, -1, -HEAD_HEIGHT)
	scrollBar:SetWidth(12)
	local thumbTex = scrollBar:GetThumbTexture()
	thumbTex:SetPoint("CENTER")
	TSMAPI.Design:SetFrameColor(thumbTex)
	thumbTex:SetHeight(150)
	thumbTex:SetWidth(scrollBar:GetWidth())
	_G[scrollBar:GetName().."ScrollUpButton"]:Hide()
	_G[scrollBar:GetName().."ScrollDownButton"]:Hide()
	
	-- create the header cells
	rt.headCells = {}
	for i, info in ipairs(colInfo) do
		local cell = CreateFrame("Button", rtName.."HeadCol"..i, rt.contentFrame)
		cell:SetHeight(HEAD_HEIGHT)
		if i == 1 then
			cell:SetPoint("TOPLEFT")
		else
			cell:SetPoint("TOPLEFT", rt.headCells[i-1], "TOPRIGHT")
		end
		cell.info = info
		cell.rt = rt
		cell:RegisterForClicks("AnyUp")
		cell:SetScript("OnClick", OnColumnClick)
		
		local text = cell:CreateFontString()
		text:SetJustifyH("CENTER")
		text:SetJustifyV("CENTER")
		text:SetFont(TSMAPI.Design:GetContentFont("small"))
		TSMAPI.Design:SetWidgetTextColor(text)
		cell:SetFontString(text)
		cell:SetText(info.name or "")
		text:SetAllPoints()

		local tex = cell:CreateTexture()
		tex:SetAllPoints()
		tex:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScore-Highlight")
		tex:SetTexCoord(0.017, 1, 0.083, 0.909)
		tex:SetAlpha(0.5)
		cell:SetNormalTexture(tex)

		local tex = cell:CreateTexture()
		tex:SetAllPoints()
		tex:SetTexture("Interface\\Buttons\\UI-Listbox-Highlight")
		tex:SetTexCoord(0.025, 0.957, 0.087, 0.931)
		tex:SetAlpha(0.2)
		cell:SetHighlightTexture(tex)
		
		tinsert(rt.headCells, cell)
	end
	
	-- create the rows
	rt.rows = {}
	for i=1, rt.NUM_ROWS do
		local row = CreateFrame("Frame", rtName.."Row"..i, rt.contentFrame)
		row:SetHeight(rt.ROW_HEIGHT)
		if i == 1 then
			row:SetPoint("TOPLEFT", 0, -(HEAD_HEIGHT+HEAD_SPACE))
			row:SetPoint("TOPRIGHT", 0, -(HEAD_HEIGHT+HEAD_SPACE))
		else
			row:SetPoint("TOPLEFT", rt.rows[i-1], "BOTTOMLEFT")
			row:SetPoint("TOPRIGHT", rt.rows[i-1], "BOTTOMRIGHT")
		end
		local highlight = row:CreateTexture()
		highlight:SetAllPoints()
		highlight:SetTexture(1, .9, 0, .5)
		highlight:Hide()
		row.highlight = highlight
		row.rt = rt
		
		row.cells = {}
		for j=1, #colInfo do
			local cell = CreateFrame("Button", nil, row)
			local text = cell:CreateFontString()
			text:SetFont(TSMAPI.Design:GetContentFont(), min(12, rt.ROW_HEIGHT))
			text:SetJustifyH(colInfo[j].align or "LEFT")
			text:SetJustifyV("MIDDLE")
			text:SetPoint("TOPLEFT", 1, -1)
			text:SetPoint("BOTTOMRIGHT", -1, 1)
			cell:SetFontString(text)
			cell:SetHeight(rt.ROW_HEIGHT)
			cell:RegisterForClicks("AnyUp")
			for name, func in pairs(defaultCellScripts) do
				cell:SetScript(name, func)
			end
			cell.rt = rt
			cell.row = row
			cell.rowNum = i
			
			if j == 1 then
				cell:SetPoint("TOPLEFT")
			else
				cell:SetPoint("TOPLEFT", row.cells[j-1], "TOPRIGHT")
			end
			
			-- slightly different color for every alternating column
			if j%2 == 1 then
				local tex = cell:CreateTexture()
				tex:SetAllPoints()
				tex:SetTexture(1, 1, 1, .03)
				cell:SetNormalTexture(tex)
			end
			
			-- special first column to hold spacer / item name / item icon
			if j == 1 then
				local spacer = CreateFrame("Frame", nil, cell)
				spacer:SetPoint("TOPLEFT")
				spacer:SetHeight(rt.ROW_HEIGHT)
				spacer:SetWidth(1)
				cell.spacer = spacer
				
				local iconBtn = CreateFrame("Button", nil, cell)
				iconBtn:SetBackdrop({edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1.5})
				iconBtn:SetBackdropBorderColor(0, 1, 0, 0)
				iconBtn:SetPoint("TOPLEFT", spacer, "TOPRIGHT")
				iconBtn:SetHeight(rt.ROW_HEIGHT)
				iconBtn:SetWidth(rt.ROW_HEIGHT)
				iconBtn:SetScript("OnEnter", function(self)
					if row.data.link then
						GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
						TSMAPI:SafeTooltipLink(row.data.link)
						GameTooltip:Show()
						rt.isShowingItemTooltip = true
					end
				end)
				iconBtn:SetScript("OnLeave", function(self)
					BattlePetTooltip:Hide()
					GameTooltip:ClearLines()
					GameTooltip:Hide()
					rt.isShowingItemTooltip = false
				end)
				iconBtn:SetScript("OnClick", function(_, ...)
					if IsModifiedClick() then
						HandleModifiedItemClick(row.data.auctionRecord.itemLink)
					else
						cell:GetScript("OnClick")(cell, ...)
					end
				end)
				iconBtn:SetScript("OnDoubleClick", function(_, ...)
					cell:GetScript("OnDoubleClick")(cell, ...)
				end)
				local icon = iconBtn:CreateTexture(nil, "ARTWORK")
				icon:SetPoint("TOPLEFT", 2, -2)
				icon:SetPoint("BOTTOMRIGHT", -2, 2)
				cell.iconBtn = iconBtn
				cell.icon = icon
				
				text:ClearAllPoints()
				text:SetPoint("TOPLEFT", iconBtn, "TOPRIGHT", 2, 0)
				text:SetPoint("BOTTOMRIGHT")
			end
			tinsert(row.cells, cell)
		end
		
		-- slightly different color for every alternating
		if i%2 == 0 then
			local tex = row:CreateTexture()
			tex:SetAllPoints()
			tex:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScore-Highlight")
			tex:SetTexCoord(0.017, 1, 0.083, 0.909)
			tex:SetAlpha(0.3)
		end
		
		tinsert(rt.rows, row)
	end
	
	rt:SetAllPoints()
	rt.data = {}
	rt.expanded = {}
	rt.displayRows = {}
	rt.handlers = handlers or {}
	rt.sortInfo = {}
	
	for name, func in pairs(methods) do
		rt[name] = func
	end
	
	return rt
end