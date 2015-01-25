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


local methods = {
	-- ============================================================================
	-- GUI Event Callbacks
	-- ============================================================================

	OnContentSizeChanged = function(self, width)
		local rt = self:GetParent()
		for i, cell in ipairs(rt.headCells) do
			cell:SetWidth(cell.info.width*width)
		end
		
		for _, row in ipairs(rt.rows) do
			for i, cell in ipairs(row.cells) do
				cell:SetWidth(rt.headCells[i].info.width*width)
			end
		end
	end,

	OnHeadColumnClick = function(self, button)
		local rt = self.rt
		
		if button == "RightButton" and rt.colInfo[self.columnIndex].isPrice then
			TSM.db.profile.pricePerUnit = not TSM.db.profile.pricePerUnit
			rt.headCells[7]:SetText(TSM.db.profile.pricePerUnit and "Bid Per Item" or "Bid Per Stack")
			rt.headCells[8]:SetText(TSM.db.profile.pricePerUnit and L["Price Per Item"] or L["Price Per Stack"])
			return
		end
		
		local descending = false
		if rt.sortInfo.columnIndex == self.columnIndex then
			descending = not rt.sortInfo.descending
		end
		rt:SetSort((descending and -1 or 1)*self.columnIndex)
	end,
	
	OnIconEnter = function(self)
		local rowData = self:GetParent().row.data
		if rowData and rowData.record then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			TSMAPI:SafeTooltipLink(rowData.record.itemLink)
			GameTooltip:Show()
			self:GetParent().row.rt.isShowingItemTooltip = true
		end
	end,
	
	OnIconLeave = function(self)
		BattlePetTooltip:Hide()
		GameTooltip:ClearLines()
		GameTooltip:Hide()
		self:GetParent().row.rt.isShowingItemTooltip = nil
	end,
	
	OnIconClick = function(self, ...)
		if IsModifiedClick() then
			HandleModifiedItemClick(self:GetParent().row.data.auctionRecord.itemLink)
		else
			self:GetParent():GetScript("OnClick")(self:GetParent(), ...)
		end
	end,
	
	OnIconDoubleClick = function(self, ...)
		self:GetParent():GetScript("OnDoubleClick")(self:GetParent(), ...)
	end,
	
	OnCellEnter = function(self, ...)
		-- if self ~= self.row.cells[1] or not self.rt.isShowingItemTooltip then
			-- GameTooltip:SetOwner(self, "ANCHOR_NONE")
			-- GameTooltip:SetPoint("BOTTOMLEFT", self, "TOPLEFT")

			-- if self.rt.expanded[self.row.data.itemString] then
				-- GameTooltip:AddLine(L["Double-click to collapse this item and show only the cheapest auction."], 1, 1, 1, true)
			-- elseif self.row.data.expandable then
				-- GameTooltip:AddLine(L["Double-click to expand this item and show all the auctions."], 1, 1, 1, true)
			-- else
				-- GameTooltip:AddLine(L["There is only one price level and seller for this item."], 1, 1, 1, true)
			-- end
			-- GameTooltip:Show()
		-- end
		
		-- show highlight for this row
		self.row.highlight:Show()
	end,
	
	OnCellLeave = function(self, ...)
		-- hide highlight if it's not selected
		if self.rt.selected ~= self.row.data.recordIndex then
			self.row.highlight:Hide()
		end
	end,
	
	OnCellClick = function(self, button, ...)
		self.rt:SetSelectedRow(self.row)
	end,
	
	OnCellDoubleClick = function(self, ...)
		local rt = self.rt
		local rowData = self.row.data
		local expand = not rt.expanded[rowData.record.baseItemString]
		if expand and not rowData.expandable then return end
		
		rt.expanded[rowData.record.baseItemString] = expand
		rt:UpdateRowInfo()
		rt:UpdateRows()
		-- select this row if it's not indented
		if not rowData.indented then
			rt:SetSelectedRow(self.row)
		end
	end,
	
	
	
	-- ============================================================================
	-- Internal Results Table Methods
	-- ============================================================================
	
	GetRecordPercent = function(rt, record)
		if not record or not rt.marketValueFunc or not record.itemBuyout or record.itemBuyout <= 0 then return end
		local marketValue = rt.marketValueFunc(record.itemString)
		if marketValue and marketValue > 0 then
			return TSMAPI:Round(100 * record.itemBuyout / marketValue, 1)
		end
	end,
	
	UpdateRowInfo = function(rt)
		wipe(rt.rowInfo)
		rt.rowInfo.numDisplayRows = 0
		rt.sortInfo.isSorted = nil
		rt:SetSelectedRow(nil, true)
		
		-- get the records
		if not rt.dbView then return end
		local records = rt.dbView:Execute()
		if #records == 0 then return end
		
		-- Populate the row info from the database by combining identical auctions and auctions
		-- of the same base item. Also, get the number of rows which will be shown.
		for i=1, #records do
			if i == 1 then
				tinsert(rt.rowInfo, {baseItemString=records[i].baseItemString, children={{numAuctions=1, record=records[i], recordIndex=i}}})
				rt.rowInfo.numDisplayRows = rt.rowInfo.numDisplayRows + 1
			elseif rt.dbView:CompareRecords(records[i], records[i-1]) == 0 then
				-- it's an identical auction to the previous row so increment the number of auctions
				rt.rowInfo[#rt.rowInfo].children[#rt.rowInfo[#rt.rowInfo].children].numAuctions = rt.rowInfo[#rt.rowInfo].children[#rt.rowInfo[#rt.rowInfo].children].numAuctions + 1
			elseif records[i].baseItemString == records[i-1].baseItemString then
				-- it's the same base item as the previous row so insert a new auction
				tinsert(rt.rowInfo[#rt.rowInfo].children, {numAuctions=1, record=records[i], recordIndex=i})
				if rt.expanded[rt.rowInfo[#rt.rowInfo].baseItemString] then
					rt.rowInfo.numDisplayRows = rt.rowInfo.numDisplayRows + 1
				end
			else
				-- it's a different base item from the previous row
				tinsert(rt.rowInfo, {baseItemString=records[i].baseItemString, children={{numAuctions=1, record=records[i], recordIndex=i}}})
				rt.rowInfo.numDisplayRows = rt.rowInfo.numDisplayRows + 1
			end
		end
		
		for _, info in ipairs(rt.rowInfo) do
			local totalAuctions, totalPlayerAuctions = 0, 0
			for _, childInfo in ipairs(info.children) do
				totalAuctions = totalAuctions + childInfo.numAuctions
				if TSMAPI:IsPlayer(childInfo.record.seller) then
					totalPlayerAuctions = totalPlayerAuctions + childInfo.numAuctions
				end
			end
			info.totalAuctions = totalAuctions
			info.totalPlayerAuctions = totalPlayerAuctions
		end
		
		-- if there's only one item in the result, expand it
		if #rt.rowInfo == 1 and rt.expanded[rt.rowInfo[1].baseItemString] == nil then
			rt.expanded[rt.rowInfo[1].baseItemString] = true
			rt.rowInfo.numDisplayRows = #rt.rowInfo[1].children
		end
	end,
	
	UpdateRows = function(rt)
		-- hide all the rows
		for _, row in ipairs(rt.rows) do row:Hide() end
		
		-- update sorting highlights
		for _, cell in ipairs(rt.headCells) do
			local tex = cell:GetNormalTexture()
			tex:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScore-Highlight")
			tex:SetTexCoord(0.017, 1, 0.083, 0.909)
			tex:SetAlpha(0.5)
		end
		if rt.sortInfo.descending then
			rt.headCells[rt.sortInfo.columnIndex]:GetNormalTexture():SetTexture(0.8, 0.6, 1, 0.8)
		else
			rt.headCells[rt.sortInfo.columnIndex]:GetNormalTexture():SetTexture(0.6, 0.8, 1, 0.8)
		end
		
		-- update the scroll frame
		FauxScrollFrame_Update(rt.scrollFrame, rt.rowInfo.numDisplayRows, #rt.rows, rt.ROW_HEIGHT)
		
		-- make sure the offset is not too high
		local maxOffset = max(rt.rowInfo.numDisplayRows - #rt.rows, 0)
		if FauxScrollFrame_GetOffset(rt.scrollFrame) > maxOffset then
			FauxScrollFrame_SetOffset(rt.scrollFrame, maxOffset)
		end
		
		if not rt.sortInfo.isSorted then
			local doDebug = true
			local function SortHelperFunc(a, b)
				local aVal, bVal = nil, nil
				if a.children then
					aVal = a.children[1].record
					bVal = b.children[1].record
				else
					aVal = a.record
					bVal = b.record
				end
				if rt.sortInfo.sortKey == "percent" then
					aVal = rt:GetRecordPercent(aVal) or ((rt.sortInfo.descending and -1 or 1)*math.huge)
					bVal = rt:GetRecordPercent(bVal) or ((rt.sortInfo.descending and -1 or 1)*math.huge)
				elseif rt.sortInfo.sortKey == "numAuctions" then
					if a.children then
						aVal = a.totalAuctions
						bVal = b.totalAuctions
					else
						aVal = a.numAuctions
						bVal = b.numAuctions
					end
				else
					aVal = aVal[rt.sortInfo.sortKey]
					bVal = bVal[rt.sortInfo.sortKey]
				end
				if type(aVal) == "string" or type(bVal) == "string" then
					aVal = aVal or ""
					bVal = bVal or ""
				else
					aVal = tonumber(aVal) or 0
					bVal = tonumber(bVal) or 0
				end
				if aVal == bVal then
					return tostring(a) < tostring(b)
				end
				if rt.sortInfo.descending then
					return aVal > bVal
				else
					return aVal < bVal
				end
			end
			-- sort the row info
			for i, info in ipairs(rt.rowInfo) do
				sort(info.children, SortHelperFunc)
			end
			sort(rt.rowInfo, SortHelperFunc)
			rt.sortInfo.isSorted = true
		end
		
		-- update all the rows
		local rowIndex = 1 - FauxScrollFrame_GetOffset(rt.scrollFrame)
		for i, info in ipairs(rt.rowInfo) do
			if rt.expanded[info.baseItemString] then
				-- show each of the rows for this base item since it's expanded
				for j, childInfo in ipairs(info.children) do
					rt:SetRowInfo(rowIndex, childInfo.recordIndex, childInfo.record, childInfo.numAuctions, 0, j > 1, false)
					rowIndex = rowIndex + 1
				end
			else
				-- just show one row for this base item since it's not expanded
				rt:SetRowInfo(rowIndex, info.children[1].recordIndex, info.children[1].record, info.totalAuctions, info.totalPlayerAuctions, false, #info.children > 1)
				rowIndex = rowIndex + 1
			end
		end
	end,
	
	SetRowInfo = function(rt, rowIndex, recordIndex, record, numAuctions, numPlayerAuctions, indented, expandable)
		if rowIndex <= 0 or rowIndex > #rt.rows then return end
		local row = rt.rows[rowIndex]
		-- show this row
		row:Show()
		if recordIndex == rt.selected then
			row.highlight:Show()
		else
			row.highlight:Hide()
		end
		row.data = {record=record, expandable=expandable, indented=indented, recordIndex=recordIndex, numAuctions=numAuctions}
		
		-- set first cell
		row.cells[1].icon:SetTexture(record.texture)
		if indented then
			row.cells[1].spacer:SetWidth(10)
			row.cells[1].icon:SetAlpha(0.5)
			row.cells[1]:GetFontString():SetAlpha(0.7)
		else
			row.cells[1].spacer:SetWidth(1)
			row.cells[1].icon:SetAlpha(1)
			row.cells[1]:GetFontString():SetAlpha(1)
		end
		row.cells[1]:SetText(gsub(record.itemLink, "[%[%]]", ""))
		row.cells[2]:SetText(record.itemLevel)
		local numAuctionsText = expandable and (TSMAPI.Design:GetInlineColor("link2")..numAuctions.."|r") or numAuctions
		if numPlayerAuctions > 0 then
			numAuctionsText = numAuctionsText..(" |cffffff00("..numPlayerAuctions..")|r")
		end
		row.cells[3]:SetText(numAuctionsText)
		row.cells[4]:SetText(record.stackSize)
		row.cells[5]:SetText(TSMAPI:GetAuctionTimeLeftText(record.timeLeft))
		row.cells[6]:SetText(record.seller)
		local bid, buyout
		if TSM.db.profile.pricePerUnit then
			bid = record.itemDisplayedBid
			buyout = record.itemBuyout
		else
			bid = record.displayedBid
			buyout = record.buyout
		end
		row.cells[7]:SetText(bid > 0 and TSMAPI:FormatTextMoney(bid, nil, true) or "---")
		row.cells[8]:SetText(buyout > 0 and TSMAPI:FormatTextMoney(buyout, nil, true) or "---")
		local pct = rt:GetRecordPercent(record)
		row.cells[9]:SetText(pct and format("%s%d%%|r", TSMAPI:GetAuctionPercentColor(pct), pct) or "---")
	end,
	
	SetSelectedRow = function(rt, row, silent)
		rt.selected = row and row.data.recordIndex or nil
		-- clear previous selection
		for _, row in ipairs(rt.rows) do
			row.highlight:Hide()
		end
		
		if rt.selected then
			-- highlight selected row and set selection
			row.highlight:Show()
		end
		if not silent and rt.handlers.OnSelectionChanged and not rt.scrollDisabled then
			rt.handlers.OnSelectionChanged(rt, row and row.data or nil)
		end
	end,
	
	
	
	-- ============================================================================
	-- General Results Table Methods
	-- ============================================================================
	
	Clear = function(rt)
		wipe(rt.expanded)
		rt.dbView = nil
		rt:UpdateRowInfo()
		rt:UpdateRows()
	end,

	SetDatabase = function(rt, database)
		if not rt.dbView or rt.dbView.database ~= database then
			rt.dbView = database:CreateView():OrderBy("baseItemString"):OrderBy("buyout"):OrderBy("requiredBid"):OrderBy("stackSize"):OrderBy("seller"):OrderBy("timeLeft")
		end
		local selectedRow = nil
		local selectedItem = nil
		for i, row in ipairs(rt.rows) do
			if row:IsVisible() and row.data and row.data.recordIndex == rt.selected then
				selectedRow = i
				selectedItem = row.data.record.baseItemString
				break
			end
		end
		rt:UpdateRowInfo()
		rt:UpdateRows()
		
		-- try and re-select the row at the same index (or the next highest one)
		local recordIndex = nil
		if selectedRow and selectedItem then
			if rt.rows[selectedRow] and rt.rows[selectedRow].data.record.baseItemString == selectedItem then
				rt:SetSelectedRow(rt.rows[selectedRow])
			elseif rt.rows[selectedRow-1] and rt.rows[selectedRow-1].data.record.baseItemString == selectedItem then
				rt:SetSelectedRow(rt.rows[selectedRow-1])
			else
				rt:SetSelectedRow()
			end
		else
			rt:SetSelectedRow()
		end
	end,
	
	RemoveSelectedRecord = function(rt, count)
		TSMAPI:Assert(rt.dbView)
		count = count or 1
		for i=1, count do
			rt.dbView:Remove(rt.selected)
		end
		rt:SetDatabase(rt.dbView.database)
	end,
	
	SetSort = function(rt, sortIndex)
		local sortIndexLookup = {"name", "itemLevel", "numAuctions", "stackSize", "timeLeft", "seller", "itemDisplayedBid", "itemBuyout", "percent"}
		rt.sortInfo.descending = sortIndex < 0
		rt.sortInfo.columnIndex = abs(sortIndex)
		TSMAPI:Assert(rt.sortInfo.columnIndex > 0 and rt.sortInfo.columnIndex <= #rt.headCells)
		rt.sortInfo.sortKey = sortIndexLookup[rt.sortInfo.columnIndex]
		rt.sortInfo.isSorted = nil
		rt:UpdateRows()
	end,
	
	SetMarketValueFunc = function(rt, marketValueFunc)
		rt.marketValueFunc = marketValueFunc
	end,
	
	SetScrollDisabled = function(rt, disabled)
		rt.scrollDisabled = disabled
	end,
	
	SetHandler = function(rt, event, handler)
		rt.handlers[event] = handler
	end,
}

function TSMAPI:CreateAuctionResultsTable2(parent)
	local colInfo = {
		{name=L["Item"], width=0.35},
		{name="ilvl", width=0.035, align="CENTER"},
		{name=L["Auctions"], width=0.06, align="CENTER"},
		{name=L["Stack Size"], width=0.055, align="CENTER"},
		{name=L["Time Left"], width=0.04, align="CENTER"},
		{name=L["Seller"], width=0.13, align="CENTER"},
		{name=BID, width=0.125, align="RIGHT", isPrice=true},
		{name=BUYOUT, width=0.125, align="RIGHT", isPrice=true},
		{name=L["% Market Value"], width=0.08, align="CENTER"},
	}
	
	local rtName = "TSMAuctionResultsTable"..RT_COUNT
	RT_COUNT = RT_COUNT + 1
	local rt = CreateFrame("Frame", rtName, parent)
	local numRows = TSM.db.profile.auctionResultRows
	rt.ROW_HEIGHT = (parent:GetHeight()-HEAD_HEIGHT-HEAD_SPACE)/numRows
	rt.isTSMResultsTable = true
	rt.colInfo = colInfo
	rt.scrollDisabled = nil
	rt.expanded = {}
	rt.handlers = {}
	rt.sortInfo = {}
	rt.rowInfo = {numDisplayRows=0}
	
	for name, func in pairs(methods) do
		rt[name] = func
	end
	
	rt:SetScript("OnShow", function(self)
		self.headCells[7]:SetText(TSM.db.profile.pricePerUnit and "Bid Per Item" or "Bid Per Stack")
		self.headCells[8]:SetText(TSM.db.profile.pricePerUnit and L["Price Per Item"] or L["Price Per Stack"])
	end)
	
	local contentFrame = CreateFrame("Frame", rtName.."Content", rt)
	contentFrame:SetPoint("TOPLEFT")
	contentFrame:SetPoint("BOTTOMRIGHT", -15, 0)
	contentFrame:SetScript("OnSizeChanged", rt.OnContentSizeChanged)
	rt.contentFrame = contentFrame
	
	-- frame to hold the header columns and the rows
	local scrollFrame = CreateFrame("ScrollFrame", rtName.."ScrollFrame", rt, "FauxScrollFrameTemplate")
	scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
		if not rt.scrollDisabled then
			FauxScrollFrame_OnVerticalScroll(self, offset, rt.ROW_HEIGHT, function() rt:UpdateRows() end)
		end
	end)
	scrollFrame:SetAllPoints(contentFrame)
	rt.scrollFrame = scrollFrame
	FauxScrollFrame_Update(rt.scrollFrame, 0, numRows, rt.ROW_HEIGHT)
	
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
		cell.columnIndex = i
		cell:RegisterForClicks("AnyUp")
		cell:SetScript("OnClick", rt.OnHeadColumnClick)
		
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
	for i=1, numRows do
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
			text:SetFont(TSMAPI.Design:GetContentFont(), min(14, rt.ROW_HEIGHT))
			text:SetJustifyH(colInfo[j].align or "LEFT")
			text:SetJustifyV("MIDDLE")
			text:SetPoint("TOPLEFT", 1, -1)
			text:SetPoint("BOTTOMRIGHT", -1, 1)
			cell:SetFontString(text)
			cell:SetHeight(rt.ROW_HEIGHT)
			cell:RegisterForClicks("AnyUp")
			cell:SetScript("OnEnter", rt.OnCellEnter)
			cell:SetScript("OnLeave", rt.OnCellLeave)
			cell:SetScript("OnClick", rt.OnCellClick)
			cell:SetScript("OnDoubleClick", rt.OnCellDoubleClick)
			cell.rt = rt
			cell.row = row
			
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
				iconBtn:SetScript("OnEnter", rt.OnIconEnter)
				iconBtn:SetScript("OnLeave", rt.OnIconLeave)
				iconBtn:SetScript("OnClick", rt.OnIconClick)
				iconBtn:SetScript("OnDoubleClick", rt.OnIconDoubleClick)
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
	return rt
end