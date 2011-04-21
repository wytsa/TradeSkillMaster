-- This is a helper file for displaying tips in the status bar of the main TSM frame.
local TSM = select(2, ...)

local currentTip = {time=0}

local modules = {"tsm", "auctiondb", "auctioning", "crafting", "gathering", "mailing", "shopping"}

local tips = {
	tsm = {},
	auctiondb = {},
	auctioning = {},
	crafting = {
		"If the Craft Management Window is too big, you can scale it down in the Crafting options.",
		"Crafting can make Auctioning groups for you. Just click on a profession icon, a category, and then the \"Create Auctioning Groups\" button.",
		"Any craft that is disabled in the category pages of one of the Crafting profession icons in the main TSM window won't show up in the Craft Management Window.",
		
	},
	gathering = {},
	mailing = {},
	shopping = {},
}

function TSM:GetTip()
	-- new tip every minute at most
	if (GetTime() - currentTip.time) > 60 then
		local totalTips = 0
		for i=1, #modules do
			totalTips = totalTips + #tips[modules[i]]
		end
		
		-- get a new tipNum that's different than the current one
		local tipNum
		while true do
			tipNum = random(1, totalTips)
			if tipNum ~= currentTip.num then
				break
			end
		end
		
		currentTip.num = tipNum
		
		for i=1, #modules do
			local moduleTips = #tips[modules[i]]
			if tipNum <= moduleTips then
				currentTip.text = tips[modules[i]][tipNum]
				break
			else
				tipNum = tipNum - moduleTips
			end
		end
		currentTip.time = GetTime()
	end
	
	return currentTip.text
end

function TSMAPI:ForceNewTip()
	currentTip.time = 0
	TSMAPI:SetStatusText()
end