-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file contains all the code for moving items between bags / bank.

local TSM = select(2, ...)
local Mover = TSM:NewModule("Mover", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries
local private = {}

private.moves, private.bagState, private.callback = {}, {}, {}, {}
private.includeSoulbound = nil

-- this is a set of wrapper functions so that I can switch
-- between GuildBank and bank function easily (taken from warehousing)

-- source functions
private.pickupContainerItemSrc = nil
private.getContainerItemIDSrc = nil
private.getContainerNumSlotsSrc = nil
private.getContainerItemLinkSrc = nil
private.getContainerNumFreeSlotsSrc = nil
private.splitContainerItemSrc = nil
-- dest functions
private.pickupContainerItemDest = nil
private.getContainerItemIDDest = nil
private.getContainerNumSlotsDest = nil
private.getContainerItemLinkDest = nil
private.getContainerNumFreeSlotsDest = nil
-- misc functions
private.autoStoreItem = nil
private.getContainerItemQty = nil

function Mover:OnEnable()
	TSM:RegisterEvent("GUILDBANKFRAME_OPENED", function(event)
		private.bankType = "GuildBank"
	end)

	TSM:RegisterEvent("BANKFRAME_OPENED", function(event)
		private.bankType = "Bank"
	end)

	TSM:RegisterEvent("GUILDBANKFRAME_CLOSED", function(event, addon)
		private.bankType = nil
		private.includeSoulbound = nil
		TSM:UnregisterEvent("GUILDBANKBAGSLOTS_CHANGED")
		if private.sendThreadId then
			TSMAPI.Threading:Kill(private.sendThreadId)
			private.sendThreadId = nil
		end
	end)

	TSM:RegisterEvent("BANKFRAME_CLOSED", function(event)
		private.bankType = nil
		private.includeSoulbound = nil
		TSM:UnregisterEvent("BAG_UPDATE")
		if private.sendThreadId then
			TSMAPI.Threading:Kill(private.sendThreadId)
			private.sendThreadId = nil
		end
	end)
end

function private.setSrcBagFunctions(bagType)
	if bagType == "GuildBank" then
		private.autoStoreItem = function(bag, slot) AutoStoreGuildBankItem(bag, slot)
		end
		private.getContainerItemQty = function(bag, slot) return select(2, GetGuildBankItemInfo(bag, slot))
		end
		private.splitContainerItemSrc = function(bag, slot, need) SplitGuildBankItem(bag, slot, need);
		end
		private.pickupContainerItemSrc = function(bag, slot) PickupGuildBankItem(bag, slot)
		end
		private.getContainerNumSlotsSrc = function(bag) return MAX_GUILDBANK_SLOTS_PER_TAB or 98
		end
		private.getContainerItemLinkSrc = function(bag, slot) return GetGuildBankItemLink(bag, slot)
		end
		private.getContainerNumFreeSlotsSrc = function(bag) return MAX_GUILDBANK_SLOTS_PER_TAB or 98
		end --need to change this eventually
		private.getContainerItemIDSrc = function(bag, slot)
			local tmpLink = GetGuildBankItemLink(bag, slot)
			local quantity = select(2, GetGuildBankItemInfo(bag, slot))
			if tmpLink then
				return TSMAPI:GetBaseItemString(tmpLink, true), quantity
			else
				return nil
			end
		end
	else
		private.autoStoreItem = function(bag, slot) UseContainerItem(bag, slot)
		end
		private.getContainerItemQty = function(bag, slot) return select(2, GetContainerItemInfo(bag, slot))
		end
		private.splitContainerItemSrc = function(bag, slot, need) SplitContainerItem(bag, slot, need)
		end
		private.pickupContainerItemSrc = function(bag, slot) PickupContainerItem(bag, slot)
		end
		private.getContainerItemIDSrc = function(bag, slot)
			local tmpLink = GetContainerItemLink(bag, slot)
			local quantity = select(2, GetContainerItemInfo(bag, slot))
			return TSMAPI:GetBaseItemString(tmpLink, true), quantity
		end
		private.getContainerNumSlotsSrc = function(bag) return GetContainerNumSlots(bag)
		end
		private.getContainerItemLinkSrc = function(bag, slot) return GetContainerItemLink(bag, slot)
		end
		private.getContainerNumFreeSlotsSrc = function(bag) return GetContainerNumFreeSlots(bag)
		end
	end
end

function private.setDestBagFunctions(bagType)
	if bagType == "GuildBank" then
		private.pickupContainerItemDest = function(bag, slot) PickupGuildBankItem(bag, slot)
		end
		private.getContainerNumSlotsDest = function(bag) return MAX_GUILDBANK_SLOTS_PER_TAB or 98
		end
		private.getContainerNumFreeSlotsDest = function(bag) return private.GetEmptySlotCountThread(bag)
		end --need to change this eventually
		private.getContainerItemLinkDest = function(bag, slot) return GetGuildBankItemLink(bag, slot)
		end
		private.getDestContainerItemQty = function(bag, slot) return select(2, GetGuildBankItemInfo(bag, slot))
		end
		private.getContainerItemIDDest = function(bag, slot)
			local tmpLink = GetGuildBankItemLink(bag, slot)
			local quantity = select(2, GetGuildBankItemInfo(bag, slot))
			if tmpLink then
				return TSMAPI:GetBaseItemString(tmpLink, true), quantity
			else
				return nil
			end
		end
	else
		private.pickupContainerItemDest = function(bag, slot) PickupContainerItem(bag, slot)
		end
		private.getContainerItemIDDest = function(bag, slot)
			local tmpLink = GetContainerItemLink(bag, slot)
			local quantity = select(2, GetContainerItemInfo(bag, slot))
			return TSMAPI:GetBaseItemString(tmpLink, true), quantity
		end
		private.getContainerNumSlotsDest = function(bag) return GetContainerNumSlots(bag)
		end
		private.getContainerItemLinkDest = function(bag, slot) return GetContainerItemLink(bag, slot)
		end
		private.getDestContainerItemQty = function(bag, slot) return select(2, GetContainerItemInfo(bag, slot))
		end
		private.getContainerNumFreeSlotsDest = function(bag) return GetContainerNumFreeSlots(bag)
		end
	end
end

function private.getContainerTableThread(self, cnt)
	local t = {}

	if cnt == "Bank" then
		local numSlots, _ = GetNumBankSlots()
		local maxSlot, increment = 1, 3
		if IsReagentBankUnlocked() then
			maxSlot = 2
			increment = 2
		end

		for i = 1, numSlots + maxSlot do
			if i == 1 then
				t[i] = -1
			elseif i == 2 and maxSlot == 2 then
				t[i] = -3
			else
				t[i] = i + increment
			end
			self:Yield()
		end

		return t

	elseif cnt == "GuildBank" then
		for i = 1, GetNumGuildBankTabs() do
			local canView, canDeposit, stacksPerDay = GetGuildBankTabInfo(i);
			if canView and canDeposit and stacksPerDay then
				t[i] = i
			end
			self:Yield()
		end

		return t
	elseif cnt == "bags" then
		for i = 1, NUM_BAG_SLOTS + 1 do
			t[i] = i - 1
			self:Yield()
		end
		return t
	end
end

function private.GetEmptySlotsThread(self, container, limitBag)
	local emptySlots = {}
	for i, bag in ipairs(private.getContainerTableThread(self, container)) do
		if not limitBag or limitBag == bag then
			if private.getContainerNumSlotsDest(bag) > 0 then
				for slot = 1, private.getContainerNumSlotsDest(bag) do
					if not private.getContainerItemIDDest(bag, slot) then
						if not emptySlots[bag] then emptySlots[bag] = {}
						end
						table.insert(emptySlots[bag], slot)
					end
					self:Yield()
				end
			end
		end
	end
	return emptySlots
end

function private.GetEmptySlotCountThread(self, bag)
	local count = 0
	for slot = 1, private.getContainerNumSlotsDest(bag) do
		if not private.getContainerItemLinkDest(bag, slot) then
			count = count + 1
		end
		self:Yield()
	end
	if count ~= 0 then
		return count
	else
		return false
	end
end

function private.canGoInBagThread(self, itemString, destTable, isCraftingReagent)
	local itemFamily = GetItemFamily(itemString)
	local default
	if isCraftingReagent and IsReagentBankUnlocked() then
		if private.GetEmptySlotCountThread(self, REAGENTBANK_CONTAINER) then
			return REAGENTBANK_CONTAINER
		end
	end
	for _, bag in pairs(destTable) do
		local bagFamily = GetItemFamily(GetBagName(bag)) or 0
		if itemFamily and bagFamily and bagFamily > 0 and bit.band(itemFamily, bagFamily) > 0 then
			if private.GetEmptySlotCountThread(self, bag) then
				return bag
			end
		elseif bagFamily == 0 then
			if private.GetEmptySlotCountThread(self, bag) then
				if not default then
					default = bag
				end
			end
		end
		self:Yield()
	end
	return default
end

function private:HasPendingMoves(destBag, destSlot, destTargetQty)
	local count = private.getDestContainerItemQty(destBag, destSlot)
	if count ~= destTargetQty then
		return true
	else
		return false
	end
end

function private.findExistingStackThread(self, itemLink, dest, quantity, gbank)
	for i, bag in ipairs(private.getContainerTableThread(self, dest)) do
		if gbank then
			if bag == GetCurrentGuildBankTab() then
				for slot = 1, private.getContainerNumSlotsDest(bag) do
					if private.getContainerItemIDDest(bag, slot) == TSMAPI:GetBaseItemString(itemLink, true) then
						local maxStack = select(8, TSMAPI:GetSafeItemInfo(itemLink))
						local _, currentQuantity = private.getContainerItemIDDest(bag, slot)
						if currentQuantity and (currentQuantity + quantity) <= maxStack then
							return bag, slot, currentQuantity
						end
					end
					self:Yield()
				end
			end
		else
			for slot = 1, private.getContainerNumSlotsDest(bag) do
				if private.getContainerItemIDDest(bag, slot) == TSMAPI:GetBaseItemString(itemLink, true) then
					local maxStack = select(8, TSMAPI:GetSafeItemInfo(itemLink))
					local _, currentQuantity = private.getContainerItemIDDest(bag, slot)
					if currentQuantity and (currentQuantity + quantity) <= maxStack then
						return bag, slot, currentQuantity
					end
				end
				self:Yield()
			end
		end
	end
end

function private.getTotalItemsThread(self, src)
	local results = {}
	if src == "Bank" then
		for _, _, itemString, quantity in TSMAPI:GetBankIterator(true, true) do
			results[itemString] = (results[itemString] or 0) + quantity
			if self then self:Yield() end
		end

		return results
	elseif src == "GuildBank" then
		for bag = 1, GetNumGuildBankTabs() do
			for slot = 1, MAX_GUILDBANK_SLOTS_PER_TAB or 98 do
				local link = GetGuildBankItemLink(bag, slot)
				local itemString = TSMAPI:GetBaseItemString(link, true)
				if itemString then
					local quantity = select(2, GetGuildBankItemInfo(bag, slot))
					results[itemString] = (results[itemString] or 0) + quantity
				end
				if self then self:Yield() end
			end
		end

		return results
	elseif src == "bags" then
		for _, _, itemString, quantity in TSMAPI:GetBagIterator(true, true) do
			results[itemString] = (results[itemString] or 0) + quantity
			if self then self:Yield() end
		end

		return results
	end
end

function private.generateMovesThread(self)
	private.bagsFull, private.bankFull = false, false
	local bagMoves, bankMoves = {}, {}
	private.moves = {}

	local currentBagState = private.getTotalItemsThread(self, "bags")

	for itemString, quantity in pairs(private.bagState) do
		local currentQty = currentBagState[itemString] or 0
		if quantity < currentQty then
			bagMoves[itemString] = currentQty - quantity
		elseif quantity > currentQty then
			bankMoves[itemString] = quantity - currentQty
		end
		self:Yield()
	end

	if next(bagMoves) ~= nil then -- generate moves from bags to bank
		private.setSrcBagFunctions("bags")
		private.setDestBagFunctions(private.bankType)
		for item, _ in pairs(bagMoves) do
			for i, bag in ipairs(private.getContainerTableThread(self, "bags")) do
				for slot = 1, private.getContainerNumSlotsSrc(bag) do
					local itemLink = private.getContainerItemLinkSrc(bag, slot)
					local itemString = TSMAPI:GetBaseItemString(itemLink, true)
					if itemString and itemString == item then
						if not TSMAPI:IsSoulbound(bag, slot) or private.includeSoulbound then
							local have = private.getContainerItemQty(bag, slot)
							local need = bagMoves[itemString]
							if have and need then
								-- check if the source item stack can fit into a destination bag
								local destBag
								if private.bankType == "GuildBank" then
									destBag = private.findExistingStackThread(self, itemLink, private.bankType, min(have, need), true)
									if not destBag then
										if private.GetEmptySlotCountThread(self, GetCurrentGuildBankTab()) ~= false then
											destBag = GetCurrentGuildBankTab()
										end
									end
								else
									destBag = private.findExistingStackThread(self, itemLink, private.bankType, min(have, need))
									if not destBag then
										if next(private.GetEmptySlotsThread(self, private.bankType)) ~= nil then
											destBag = private.canGoInBagThread(self, itemString, private.getContainerTableThread(self, private.bankType), TSMAPI:IsCraftingReagent(itemLink))
										end
									end
								end
								if destBag then
									if have > need then
										tinsert(private.moves, { src = "bags", bag = bag, slot = slot, quantity = need, split = true })
										bagMoves[itemString] = nil
									else
										tinsert(private.moves, { src = "bags", bag = bag, slot = slot, quantity = have, split = false })
										bagMoves[itemString] = bagMoves[itemString] - have
										if bagMoves[itemString] <= 0 then
											bagMoves[itemString] = nil
										end
									end
								else
									private.bankFull = true
								end
							end
						end
					end
					self:Yield()
				end
			end
		end
	end


	if next(bankMoves) ~= nil then -- generate moves from bank to bags
		private.setSrcBagFunctions(private.bankType)
		private.setDestBagFunctions("bags")
		for item, _ in pairs(bankMoves) do
			for i, bag in ipairs(private.getContainerTableThread(self, private.bankType)) do
				for slot = 1, private.getContainerNumSlotsSrc(bag) do
					local itemLink = private.getContainerItemLinkSrc(bag, slot)
					local itemString = TSMAPI:GetBaseItemString(itemLink, true)
					if itemString and itemString == item then
						local have = private.getContainerItemQty(bag, slot)
						local need = bankMoves[itemString]
						if have and need then
							if (not TSMAPI:IsSoulbound(bag, slot) or private.includeSoulbound) then
								local destBag = private.findExistingStackThread(self, itemLink, "bags", min(have, need)) or private.canGoInBagThread(self, itemString, private.getContainerTableThread(self, "bags"))
								if destBag then
									if have > need then
										tinsert(private.moves, { src = private.bankType, bag = bag, slot = slot, quantity = need, split = true })
										bankMoves[itemString] = nil
									else
										tinsert(private.moves, { src = private.bankType, bag = bag, slot = slot, quantity = have, split = false })
										bankMoves[itemString] = bankMoves[itemString] - have
										if bankMoves[itemString] <= 0 then
											bankMoves[itemString] = nil
										end
									end
								else
									private.bagsFull = true
								end
							end
						end
					end
					self:Yield()
				end
			end
		end
	end

	if next(private.moves) then
		sort(private.moves, function(a, b)
			if a.bag == b.bag then
				return a.slot < b.slot
			end
			return a.bag < b.bag
		end)

		for _, move in pairs(private.moves) do
			private.moveItemThread(self, { move.src, move.bag, move.slot, move.quantity, move.split })
		end

		private.generateMovesThread(self)
	end
end

function private.moveItemThread(self, move)
	local src, bag, slot, need, split = unpack(move)
	if src == "bags" then
		private.setSrcBagFunctions("bags")
		private.setDestBagFunctions(private.bankType)
		local itemString = TSMAPI:GetBaseItemString(private.getContainerItemLinkSrc(bag, slot), true)
		local itemLink = private.getContainerItemLinkSrc(bag, slot)
		local reagent = TSMAPI:IsCraftingReagent(itemLink)
		local have = private.getContainerItemQty(bag, slot)
		if have and need then
			if split or reagent then
				local destBag, destSlot, destExistingQty
				if private.bankType == "GuildBank" then
					destBag, destSlot, destExistingQty = private.findExistingStackThread(self, itemLink, private.bankType, need, true)
				else
					destBag, destSlot, destExistingQty = private.findExistingStackThread(self, itemLink, private.bankType, need)
				end
				if destBag and destSlot then
					local destTargetQty = destExistingQty + need
					private.splitContainerItemSrc(bag, slot, need)
					private.pickupContainerItemDest(destBag, destSlot)
					-- wait for move to complete
					while private:HasPendingMoves(destBag, destSlot, destTargetQty) do self:Yield(true) end
				else
					local emptyBankSlots
					if private.bankType == "GuildBank" then
						emptyBankSlots = private.GetEmptySlotsThread(self, private.bankType, GetCurrentGuildBankTab())
						destBag = GetCurrentGuildBankTab()
					else
						emptyBankSlots = private.GetEmptySlotsThread(self, private.bankType)
						destBag = private.canGoInBagThread(self, itemString, private.getContainerTableThread(self, private.bankType), reagent)
					end
					if emptyBankSlots[destBag] then
						destSlot = emptyBankSlots[destBag][1]
					end
					if destBag and destSlot then
						if private.bankType == "GuildBank" then
							if GetCurrentGuildBankTab() ~= destBag then
								SetCurrentGuildBankTab(destBag)
							end
						end
						if private.GetEmptySlotCountThread(self, destBag) then
							private.splitContainerItemSrc(bag, slot, need)
							private.pickupContainerItemDest(destBag, destSlot)
							-- wait for move to complete
							if private.bankType == "GuildBank" then
								while not GetGuildBankItemInfo(destBag, destSlot) do self:Yield(true) end
							else
								while not GetContainerItemInfo(destBag, destSlot) do self:Yield(true) end
							end
						end
					end
				end
			else
				if private.bankType == "GuildBank" then
					local destBag, destSlot, destExistingQty = private.findExistingStackThread(self, itemLink, private.bankType, need, true)
					if destBag and destSlot then
						local destTargetQty = destExistingQty + need
						private.pickupContainerItemSrc(bag, slot)
						private.pickupContainerItemDest(destBag, destSlot)
						-- wait for move to complete
						while private:HasPendingMoves(destBag, destSlot, destTargetQty) do self:Yield(true) end
					else
						local emptyBankSlots = private.GetEmptySlotsThread(self, private.bankType, GetCurrentGuildBankTab())
						destBag = GetCurrentGuildBankTab()
						if emptyBankSlots[destBag] then
							destSlot = emptyBankSlots[destBag][1]
						end
						if destBag and destSlot then
							if private.bankType == "GuildBank" then
								if GetCurrentGuildBankTab() ~= destBag then
									SetCurrentGuildBankTab(destBag)
								end
							end
							if private.GetEmptySlotCountThread(self, destBag) then
								private.pickupContainerItemSrc(bag, slot)
								private.pickupContainerItemDest(destBag, destSlot)
								-- wait for move to complete
								while private:HasPendingMoves(destBag, destSlot, need) do self:Yield(true) end
							end
						end
					end
				else
					if private.findExistingStackThread(self, itemLink, private.bankType, need) then
						private.autoStoreItem(bag, slot)
						-- wait for move to complete
						while GetContainerItemInfo(bag, slot) do self:Yield(true) end
					elseif next(private.GetEmptySlotsThread(self, private.bankType)) ~= nil and private.canGoInBagThread(self, itemString, private.getContainerTableThread(self, private.bankType)) then
						private.autoStoreItem(bag, slot)
						-- wait for move to complete
						while GetContainerItemInfo(bag, slot) do self:Yield(true) end
					end
				end
			end
		end
	else
		private.setSrcBagFunctions(private.bankType)
		private.setDestBagFunctions("bags")
		local itemString = TSMAPI:GetBaseItemString(private.getContainerItemLinkSrc(bag, slot), true)
		local itemLink = private.getContainerItemLinkSrc(bag, slot)
		local have = private.getContainerItemQty(bag, slot)
		if have and need then
			if split then
				local destBag, destSlot, destExistingQty
				destBag, destSlot, destExistingQty = private.findExistingStackThread(self, itemLink, "bags", need)
				if destBag and destSlot then
					if private.bankType == "GuildBank" then
						if GetCurrentGuildBankTab() ~= bag then
							SetCurrentGuildBankTab(bag)
						end
					end
					local destTargetQty = destExistingQty + need
					private.splitContainerItemSrc(bag, slot, need)
					private.pickupContainerItemDest(destBag, destSlot)
					-- wait for move to complete
					while private:HasPendingMoves(destBag, destSlot, destTargetQty) do self:Yield(true) end
				else
					local emptyBagSlots = private.GetEmptySlotsThread(self, "bags")
					destBag = private.canGoInBagThread(self, itemString, private.getContainerTableThread(self, "bags"))
					if emptyBagSlots[destBag] then
						destSlot = emptyBagSlots[destBag][1]
					end
					if destBag and destSlot then
						if private.bankType == "GuildBank" then
							if GetCurrentGuildBankTab() ~= bag then
								SetCurrentGuildBankTab(bag)
							end
						end
						private.splitContainerItemSrc(bag, slot, need)
						private.pickupContainerItemDest(destBag, destSlot)
						-- wait for move to complete
						while not GetContainerItemInfo(destBag, destSlot) do self:Yield(true) end
					end
				end
			else
				if private.bankType == "GuildBank" then
					local destBag, destSlot, destExistingQty = private.findExistingStackThread(self, itemLink, "bags", need)
					if destBag and destSlot then
						local destTargetQty = destExistingQty + need
						private.pickupContainerItemSrc(bag, slot)
						private.pickupContainerItemDest(destBag, destSlot)
						-- wait for move to complete
						while private:HasPendingMoves(destBag, destSlot, destTargetQty) do self:Yield(true) end
					else
						local emptyBagSlots = private.GetEmptySlotsThread(self, "bags")
						destBag = private.canGoInBagThread(self, itemString, private.getContainerTableThread(self, "bags"))
						if emptyBagSlots[destBag] then
							destSlot = emptyBagSlots[destBag][1]
						end
						if destBag and destSlot then
							if private.GetEmptySlotCountThread(self, destBag) then
								private.pickupContainerItemSrc(bag, slot)
								private.pickupContainerItemDest(destBag, destSlot)
								-- wait for move to complete
								while not GetContainerItemInfo(destBag, destSlot) do self:Yield(true) end
							end
						end
					end
				else
					if private.findExistingStackThread(self, itemLink, "bags", need) then
						private.autoStoreItem(bag, slot)
						-- wait for move to complete
						while GetContainerItemInfo(bag, slot) do self:Yield(true) end
					elseif next(private.GetEmptySlotsThread(self, "bags")) ~= nil and private.canGoInBagThread(self, itemString, private.getContainerTableThread(self, "bags")) then
						private.autoStoreItem(bag, slot)
						-- wait for move to complete
						while GetContainerItemInfo(bag, slot) do self:Yield(true) end
					end
				end
			end
		end
	end
end

function TSMAPI:MoveItems(requestedItems, callback, includeSoulbound)
	if private.sendThreadId or not TSM:areBanksVisible() then return end
	wipe(private.bagState)

	private.callback = callback
	if includeSoulbound then
		private.includeSoulbound = true
	else
		private.includeSoulbound = false
	end

	private.bagState = private.getTotalItemsThread(nil, "bags") -- create initial bagstate

	-- iterates over the requested items and adjusts bagState quantities , negative removes from bagState, positive adds to bagState
	-- this gives the final states to generate the moves from
	for itemString, qty in pairs(requestedItems) do
		if not private.bagState[itemString] then private.bagState[itemString] = 0
		end
		private.bagState[itemString] = private.bagState[itemString] + qty
		if private.bagState[itemString] < 0 then
			private.bagState[itemString] = 0
		end
	end

	private.sendThreadId = TSMAPI.Threading:Start(private.startMovingThread, 0.7, private.DoneSending, { requestedItems, includeSoulbound })
	private.callback = callback
end

function private.startMovingThread(self, args)
	self:SetThreadName("MOVER_MAIN")
	local requestedItems, includeSoulbound = unpack(args)
	wipe(private.bagState)

	if includeSoulbound then
		private.includeSoulbound = true
	else
		private.includeSoulbound = false
	end

	private.bagState = private.getTotalItemsThread(nil, "bags") -- create initial bagstate

	-- iterates over the requested items and adjusts bagState quantities , negative removes from bagState, positive adds to bagState
	-- this gives the final states to generate the moves from
	for itemString, qty in pairs(requestedItems) do
		if not private.bagState[itemString] then private.bagState[itemString] = 0
		end
		private.bagState[itemString] = private.bagState[itemString] + qty
		if private.bagState[itemString] < 0 then
			private.bagState[itemString] = 0
		end
		self:Yield()
	end
	private.generateMovesThread(self)
end

function TSM:areBanksVisible()
	if BagnonFrameGuildBank and BagnonFrameGuildBank:IsVisible() then
		return true
	elseif BagnonFramebank and BagnonFramebank:IsVisible() then
		return true
	elseif GuildBankFrame and GuildBankFrame:IsVisible() then
		return true
	elseif BankFrame and BankFrame:IsVisible() then
		return true
	elseif (ARKINV_Frame4 and ARKINV_Frame4:IsVisible()) or (ARKINV_Frame3 and ARKINV_Frame3:IsVisible()) then
		return true
	elseif (BagginsBag8 and BagginsBag8:IsVisible()) or (BagginsBag9 and BagginsBag9:IsVisible()) or (BagginsBag10 and BagginsBag10:IsVisible()) or (BagginsBag11 and BagginsBag11:IsVisible()) or (BagginsBag12 and BagginsBag12:IsVisible()) then
		return true
	elseif (CombuctorFrame2 and CombuctorFrame2:IsVisible()) then
		return true
	elseif (BaudBagContainer2_1 and BaudBagContainer2_1:IsVisible()) then
		return true
	elseif (AdiBagsContainer2 and AdiBagsContainer2:IsVisible()) then
		return true
	elseif (OneBankFrame and OneBankFrame:IsVisible()) then
		return true
	elseif (EngBank_frame and EngBank_frame:IsVisible()) then
		return true
	elseif (TBnkFrame and TBnkFrame:IsVisible()) then
		return true
	elseif (famBankFrame and famBankFrame:IsVisible()) then
		return true
	elseif (LUIBank and LUIBank:IsVisible()) then
		return true
	elseif (ElvUI_BankContainerFrame and ElvUI_BankContainerFrame:IsVisible()) then
		return true
	elseif (TukuiBank and TukuiBank:IsShown()) then
		return true
	elseif (AdiBagsContainer1 and AdiBagsContainer1.isBank and AdiBagsContainer1:IsVisible()) or (AdiBagsContainer2 and AdiBagsContainer2.isBank and AdiBagsContainer2:IsVisible()) then
		return true
	elseif BagsFrameBank and BagsFrameBank:IsVisible() then
		return true
	elseif AspUIBank and AspUIBank:IsVisible() then
		return true
	elseif NivayacBniv_Bank and NivayacBniv_Bank:IsVisible() then
		return true
	elseif DufUIBank and DufUIBank:IsVisible() then
		return true
	elseif SVUI_BankContainerFrame and SVUI_BankContainerFrame:IsVisible() then
		return true
	end
	return nil
end

function private:DoneSending()
	if private.cancelled then
		private.callback(L["Cancelled - You must be at a bank or GuildBank"])
	elseif private.bagsFull and not private.bankFull then
		private.callback(L["Cancelled - Bags are full"])
	elseif private.bankFull and not private.bagsFull then
		private.callback("Cancelled - " .. private.bankType .. " is full")
	elseif private.bagsFull and private.bankFull then
		private.callback("Cancelled - Bags and " .. private.bankType .. " are full")
	else
		private.callback(L["Done"])
	end
	private.moves = {}
	private.sendThreadId = nil
	private.callback, private.cancelled, private.bagsFull, private.bankFull, private.includeSoulbound = nil, nil, nil, nil, nil
end