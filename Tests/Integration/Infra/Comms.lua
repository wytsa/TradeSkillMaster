-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file contains code used for TSM integration testing

local TSM = select(2, ...)
local Testing = TSM:GetModule("Testing")
local private = {pixels={clk=nil, data={}, endMarker=nil}, ticks=0, msgQueue={}, sleep=0, justSent=false, setup=false}

local TICK_INTERVAL = 0.2
local NUM_DATA_ROWS = 10
local NUM_DATA_PIXELS = 1000
local PIXEL_TYPES = {
	CLOCK = 79,
	DATA = 24,
}
local CLOCK_VALUES = {
	LOW = 11, -- nothing being sent
	HIGH = 122, -- data is valid
}



-- ============================================================================
-- Module Functions
-- ============================================================================

function Testing:CommsSetup()
	if private.setup then
		return
	end
	C_Timer.NewTicker(TICK_INTERVAL, private.Run)

	-- create data pixels in the bottom-left such that the origin is in the top-left of the block of pixels
	for row=NUM_DATA_ROWS-1, 0, -1 do
		for col=0, NUM_DATA_PIXELS-1 do
			local pixelType = PIXEL_TYPES.DATA
			if (row + col) % 2 == 0 then
				-- set the high bit
				pixelType = pixelType + 128
			end
			local pixel = private.CreatePixel(pixelType)
			pixel:SetPoint("BOTTOMLEFT", col, row)
			pixel:SetData(0, 0)
			tinsert(private.pixels.data, pixel)
		end
	end

	-- create metadata pixels in the bottom-right
	local pixel = private.CreatePixel(PIXEL_TYPES.CLOCK)
	pixel:SetPoint("BOTTOMRIGHT", 0, 0)
	pixel:SetAsserted(false)
	private.pixels.clk = pixel

	private.setup = true
end

function Testing:CommsSend(msg)
	tinsert(private.msgQueue, msg)
	private.sleep = private.sleep + 1
end



-- ============================================================================
-- Helper Functions
-- ============================================================================

function private.AssertOneByte(val)
	assert(val >= 0 and val < 256)
end

local function SetDataPixelData(self, value1, value2)
	private.AssertOneByte(value1)
	private.AssertOneByte(value2)
	self:GetNormalTexture():SetTexture(value1 / 255, value2 / 255, self.pixelType / 255, 1)
end

local function SetClockPixelAsserted(self, isAsserted)
	local val = isAsserted and CLOCK_VALUES.HIGH or CLOCK_VALUES.LOW
	self:GetNormalTexture():SetTexture(val / 255, (val + 128) / 255, self.pixelType / 255, 1)
end

function private.CreatePixel(pixelType)
	private.AssertOneByte(pixelType)
	-- creates a pixel that'll be used to send data out of the game
	local btn = CreateFrame("Button")
	btn:SetNormalTexture("Interface\\Buttons\\WHITE8X8")
	btn:SetFrameStrata("TOOLTIP")
	btn:SetWidth(1)
	btn:SetHeight(1)
	btn:Show()
	btn.pixelType = pixelType
	if pixelType % 128 == PIXEL_TYPES.DATA then
		btn.SetData = SetDataPixelData
	elseif pixelType % 128 == PIXEL_TYPES.CLOCK then
		btn.SetAsserted = SetClockPixelAsserted
	else
		error("Invalid pixelType: "..tostring(pixelType))
	end
	return btn
end

function private.Run()
	-- This is called every tick interval to drive the sending of messages
	if private.sleep > 0 then
		-- we're sleeping
		private.sleep = private.sleep - 1
		return
	end

	if private.justSent then
		-- set the clock low for one tick
		private.justSent = false
		private.pixels.clk:SetAsserted(false)
	elseif #private.msgQueue > 0 then
		-- we have a message to send
		local msg = tremove(private.msgQueue, 1)
		for i=1, NUM_DATA_PIXELS * NUM_DATA_ROWS do
			local value1 = strbyte(msg, (i * 2) - 1) or 0
			local value2 = strbyte(msg, i * 2) or 0
			private.pixels.data[i]:SetData(value1, value2)
		end
		private.pixels.clk:SetAsserted(true)
		private.sleep = 1
		private.justSent = true
	end
end
