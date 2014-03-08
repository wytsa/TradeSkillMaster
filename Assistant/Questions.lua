-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)
local Assistant = TSM.modules.Assistant
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local private = {}
TSMAPI:RegisterForTracing(private, "TradeSkillMaster.Questions_private")

local MAKE_GROUP_STEPS = {
	title = "How would you like to create the group?",
	buttons = {
		{
			text = "Make a new group from items in my bags",
			guides = {"openGroups", "newGroup", "selectGroup", "groupAddFromBags"},
		},
		{
			text = "Make a new group from an import list I have",
			guides = {"openGroups", "newGroup", "selectGroup", "groupImportItems"},
		},
		{
			text = "Use an existing group",
			guides = {"openGroups", "selectGroup"},
		},
		{
			text = "Use a subset of items from an existing group by creating a subgroup",
			guides = {"openGroups", "selectGroup"},
		},
	},
}

function private:GetMakeGroupSteps(steps)
	local stepInfo = CopyTable(MAKE_GROUP_STEPS)
	for _, button in ipairs(stepInfo.buttons) do
		for _, step in ipairs(steps) do
			tinsert(button.guides, step)
		end
	end
	return stepInfo
end

Assistant.INFO = {
	title = "What do you want to do?",
	buttons = {
		{
			text = "Craft items with my professions",
			children = {
				title = "How would you like to craft?",
				buttons = {
					{
						text = "Set up TSM to automatically queue things to craft",
						children = private:GetMakeGroupSteps({"craftingOperation"}),
					},
					{
						text = "Look at what's profitable to craft and manually add things to a queue",
						guides = {"openCrafting", "craftingCraftsTab", "openProfession", "useProfessionQueue"},
					},
					{
						text = "Craft specific one-off items without making a queue",
						guides = {"notYetImplemented"},
					},
				},
			},
		},
		{
			text = "Buy items from the AH",
			children = {
				title = "How would you like to shop?",
				buttons = {
					{
						text = "Set up TSM to find cheap items on the AH",
						children = private:GetMakeGroupSteps({"shoppingOperation", "shoppingGroupSearch"})
					},
					{
						text = "Search the AH for items to buy",
						children = private:GetMakeGroupSteps({"notYetImplemented"})
					},
				},
			},
		},
		{
			text = "Sell items on the AH and manage my auctions",
			guides = {"notYetImplemented"},
		},
		{
			text = "Mail items to another character",
			guides = {"notYetImplemented"},
		},
		{
			text = "Learn about other settings and features",
			guides = {"notYetImplemented"},
		},
	},
}