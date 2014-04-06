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
						children = private:GetMakeGroupSteps({"craftingOperation", "openProfession", "professionRestock", "useProfessionQueue"}),
					},
					{
						text = "Look at what's profitable to craft and manually add things to a queue",
						guides = {"openCrafting", "craftingCraftsTab", "openProfession", "useProfessionQueue"},
					},
					{
						text = "Craft specific one-off items without making a queue",
						guides = {"openProfession", "craftFromProfession"},
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
						children = private:GetMakeGroupSteps({"shoppingOperation", "openShoppingAHTab", "shoppingGroupSearch", "shoppingWaitForScan"}),
					},
					{
						text = "Search the AH for items to buy",
						guides = {"openShoppingAHTab", "shoppingFilterSearch", "shoppingWaitForScan"},
					},
					{
						text = "Buy materials for my TSM_Crafting queue",
						guides = {"notYetImplemented"},
					},
					{
						text = "Advanced topics...",
						children = {
							title = "How would you like to shop?",
							buttons = {
								{
									text = "Snipe items as they are being posted to the AH",
									guides = {"openShoppingAHTab", "shoppingSniperSearch"},
								},
								{
									text = "Look for items which can be destroyed to get raw mats",
									guides = {"openShoppingAHTab", "shoppingDestroySearch", "shoppingWaitForScan"},
								},
								{
									text = "Look for items which can be vendored for a profit",
									guides = {"openShoppingAHTab", "shoppingVendorSearch", "shoppingWaitForScan"},
								},
								{
									text = "Setup TSM to automatically reset specific markets",
									guides = private:GetMakeGroupSteps({"auctioningOperation", "openAuctioningAHTab", "notYetImplemented", "auctioningWaitForScan"}),
								},
							},
						},
					},
				},
			},
		},
		{
			text = "Sell items on the AH and manage my auctions",
			children = {
				title = "What do you want to do?",
				buttons = {
					{
						text = "Set up TSM to automatically post auctions",
						children = private:GetMakeGroupSteps({"auctioningOperation", "openAuctioningAHTab", "auctioningPostScan", "auctioningWaitForScan"}),
					},
					{
						text = "Set up TSM to automatically cancel undercut auctions",
						children = private:GetMakeGroupSteps({"auctioningOperation", "openAuctioningAHTab", "auctioningCancelScan", "auctioningWaitForScan"}),
					},
					{
						text = "Post items manually from my bags",
						children = {
							title = "How would you like to post?",
							buttons = {
								{
									text = "View current auctions and choose what price to post at",
									guides = {"openShoppingAHTab", "notYetImplemented"},
								},
								{
									text = "Quickly post my items at some pre-determined price",
									guides = {"openShoppingAHTab", "notYetImplemented"},
								},
							},
						},
					},
				},
			},
		},
		{
			text = "Mail items to another character",
			children = {
				title = "How would you like to mail items?",
				buttons = {
					{
						text = "Setup TSM to mail items automatically",
						guides = {"notYetImplemented"},
					},
					{
						text = "Quickly send a specific item to another player (with or without COD)",
						guides = {"notYetImplemented"},
					},
					{
						text = "Mail disenchantable items to another character",
						guides = {"notYetImplemented"},
					},
					{
						text = "Send excess gold to another character",
						guides = {"notYetImplemented"},
					},
				},
			},
		},
		{
			text = "Move items between my bags, bank, and guild bank",
			children = {
				title = "How would you like to move items?",
				buttons = {
					{
						text = "Setup TSM to move items automatically",
						guides = {"notYetImplemented"},
					},
					{
						text = "Move a few items quickly between my bags and bank or guild bank",
						guides = {"notYetImplemented"},
					},
					{
						text = "Get items out of the bank or guild bank to post on the AH",
						guides = {"notYetImplemented"},
					},
				},
			},
		},
	},
}