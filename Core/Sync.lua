-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file handled multi-account syncing and communication

-- register this file with Ace libraries
local TSM = select(2, ...)
local Sync = TSM:NewModule("Sync", "AceComm-3.0", "AceEvent-3.0")
TSMAPI.Sync = {}
local private = {addedFriends={}, invalidPlayers={}, connections={}, threadId=nil}
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local RECEIVE_TIMEOUT = 5
local SYNC_VERSION = 1
local PING_TIMEOUT = 10



function private:ShowSVCopyError()
	TSMAPI:ConfigVerify(false, "It appears that you've manually copied your saved variables between accounts which will cause TSM's automatic sync'ing to not work. You'll need to undo this, and/or delete the TradeSkillMaster, TSM_Crafting, and TSM_ItemTracker saved variables files on both accounts (with WoW closed) in order to fix this.")
end


function private:SendMetaData(dataType, targetPlayer)
	-- set a header
	local packet = {dataType=dataType, sourceAccount=TSMAPI.Sync:GetAccountKey(), sourcePlayer=UnitName("player"), version=SYNC_VERSION, data=nil}
	Sync:SendCommMessage("TSMSyncData", TSMAPI:Compress(packet), "WHISPER", targetPlayer)
end

function private:SendData(data, targetPlayer)
	local packet = {dataType="DATA", sourceAccount=TSMAPI.Sync:GetAccountKey(), sourcePlayer=UnitName("player"), version=SYNC_VERSION, data=data}
	Sync:SendCommMessage("TSMSyncData", TSMAPI:Compress(packet), "WHISPER", targetPlayer)
end

function private:ReceiveData(packet, source)
	-- remove realm name from source
	source = ("-"):split(source)
	source = source:trim()
	
	-- decompress the packet
	packet = TSMAPI:Decompress(packet)
	
	-- validate the packet
	if not packet or not packet.dataType or not packet.sourceAccount or not packet.sourcePlayer then return end
	if packet.sourcePlayer ~= source then return end
	if packet.sourceAccount == TSMAPI.Sync:GetAccountKey() or TSM.db.factionrealm.characters[packet.sourcePlayer] then
		private:ShowSVCopyError()
		return
	end
	if packet.version ~= SYNC_VERSION then return end
	
	if packet.dataType == "WHOAMI_ACCOUNT" or packet.dataType == "WHOAMI_ACK" then
		-- we don't yet have a connection, so treat seperately
		if private.newPlayer and strlower(private.newPlayer) == strlower(source) then
			TSMAPI.Threading:SendMsg(private.threadId, {packet.dataType, packet.sourceAccount})
		end
	else
		if not private.connections[packet.sourceAccount] then return end
		
		local threadId = private.connections[packet.sourceAccount].threadId
		if not threadId then return end
		
		-- send the data to the connection thread
		TSMAPI.Threading:SendMsg(threadId, {packet.dataType, packet})
	end
end


function private:GetTargetPlayer(account)
	local targetPlayer = nil
	
	-- find the player to connect to without adding to the friends list
	for player in pairs(TSM.db.factionrealm.syncAccounts[account]) do
		if private:IsPlayerOnline(player, true) then
			return player
		end
	end
	-- if we failed, try again with adding to friends list
	for player in pairs(TSM.db.factionrealm.syncAccounts[account]) do
		if private:IsPlayerOnline(player) then
			return player
		end
	end
end

function private:WaitForMsgThread(self, expectedMsg)
	local args = self:ReceiveMsgWithTimeout(RECEIVE_TIMEOUT + random(0, 1000) / 1000)
	if not args then return end
	if tremove(args, 1) ~= expectedMsg then return end
	return args
end

function private.ConnectionThread(self, account)
	self:SetThreadName("SYNC_CONNECTION_"..account)
	local connectionInfo = private.connections[account]
	
	-- wait for a target player to be online for the account
	local targetPlayer = nil
	while true do
		targetPlayer = private:GetTargetPlayer(account)
		if targetPlayer then
			break
		else
			self:Sleep(1)
		end
	end
	
	local isServer = account < TSMAPI.Sync:GetAccountKey() -- the lower account key is the server, other is the client
	if isServer then
		-- wait for connection request from the client
		if not private:WaitForMsgThread(self, "CONNECTION_REQUEST") then return end
		-- send an connection request ACK back to the client
		private:SendMetaData("CONNECTION_REQUEST_ACK", targetPlayer)
	else
		-- send a connection request to the server
		private:SendMetaData("CONNECTION_REQUEST", targetPlayer)
		-- wait for the connection request ACK
		if not private:WaitForMsgThread(self, "CONNECTION_REQUEST_ACK") then return end
	end
	
	-- now that we are connected, data can flow in both directions freely
	TSM:LOG_INFO("CONNECTED TO: %s %s", account, targetPlayer)
	local pingStatus = {lastSend=time(), lastReceive=time()}
	while true do
		if #connectionInfo.receiveQueue > 0 then
			-- process received data
		end
		if not private:IsPlayerOnline(targetPlayer, true) then return end -- they logged off
		if time() - pingStatus.lastReceive > PING_TIMEOUT then
			return -- ping timeout
		end
		if #connectionInfo.sendQueue > 0 then
			-- send out data
		end
		if time() - pingStatus.lastSend > PING_TIMEOUT / 2 then
			private:SendMetaData("PING", targetPlayer)
			pingStatus.lastSend = time()
		end
		while self:GetNumMsgs() > 0 do
			local event = unpack(self:ReceiveMsg())
			if event == "PING" then
				pingStatus.lastReceive = time()
			else
				-- unexpected event so just return (and re-establish) after ensuring the other side will timeout
				self:Sleep(PING_TIMEOUT * 2)
				return
			end
		end
		self:Yield(true)
	end
end

function private.SyncThread(self)
	self:SetThreadName("SYNC_MAIN")
	-- wait for friend info to populate
	ShowFriends()
	local retriesLeft = 600
	while true do
		local isValid = true
		for i=1, GetNumFriends() do
			if not GetFriendInfo(i) then
				isValid = false
				break
			end
		end
		if isValid then
			break
		elseif retriesLeft == 0 then
			TSMAPI:Assert(false, "Could not get friend list information.")
		else
			retriesLeft = retriesLeft - 1
			self:Sleep(0.1)
		end
	end
	
	-- continuously spawn connection threads with online players
	local localAccountKey = TSMAPI.Sync:GetAccountKey()
	local lastNewPlayerSend = 0
	while true do
		if private.newPlayer and time() - lastNewPlayerSend > 1 then
			if not private:IsPlayerOnline(private.newPlayer) then
				private.newPlayer = nil
				private.newAccount = nil
			else
				private:SendMetaData("WHOAMI_ACCOUNT", private.newPlayer)
				lastNewPlayerSend = time()
				TSM:LOG_INFO("SENT WHOAMI")
			end
		end
		while self:GetNumMsgs() > 0 do
			local args = self:ReceiveMsg()
			local event = tremove(args, 1)
			if private.newPlayer then
				if event == "WHOAMI_ACCOUNT" then
					-- got the account key of the new player
					private.newAccount = unpack(args)
					TSM:LOG_INFO("WHOAMI_ACCOUNT %s %s", private.newPlayer, private.newAccount)
					if private.newAccount then
						private:SendMetaData("WHOAMI_ACK", private.newPlayer)
					end
				elseif event == "WHOAMI_ACK" then
					-- they ACK'd the WHOAMI so we are good to setup a connection
					TSM:LOG_INFO("WHOAMI_ACK %s", private.newAccount)
					if private.newAccount then
						TSM.db.factionrealm.syncAccounts[private.newAccount] = {[private.newPlayer]=true}
						private.newPlayer = nil
						private.newAccount = nil
					end
				else
					error("Unexpected event: "..tostring(event))
				end
			end
		end
		for account, players in pairs(TSM.db.factionrealm.syncAccounts) do
			if account == localAccountKey then
				private:ShowSVCopyError()
				wipe(private.connections)
				return
			end
			if private.connections[account] and not TSMAPI.Threading:IsValid(private.connections[account].threadId) then
				private.connections[account] = nil
			end
			if not private.connections[account] then
				local threadId = TSMAPI.Threading:Start(private.ConnectionThread, 0.5, function() TSM:LOG_INFO("CONNECTION DIED TO %s", account) private.connections[account] = nil end, account, self:GetThreadId())
				private.connections[account] = {threadId=threadId, connected=nil, receiveQueue={}, sendQueue={}}
			end
		end
		self:Sleep(0.1)
	end
end




function Sync:OnEnable()
	Sync:RegisterComm("TSMSyncData")
	Sync:RegisterEvent("CHAT_MSG_SYSTEM")
	private.threadId = TSMAPI.Threading:Start(private.SyncThread, 0.5)
end

function Sync:OnCommReceived(_, data, _, source)
	private:ReceiveData(data, source)
end

function Sync:CHAT_MSG_SYSTEM(_, msg)
	if #private.addedFriends == 0 then return end
	if msg == ERR_FRIEND_NOT_FOUND then
		tremove(private.addedFriends, 1)
	else
		for i, v in ipairs(private.addedFriends) do
			if format(ERR_FRIEND_ADDED_S, v) == msg then
				tremove(private.addedFriends, i)
				private.invalidPlayers[strlower(v)] = true
			end
		end
	end
end

function private:IsPlayerOnline(target, noAdd)
	for i=1, GetNumFriends() do
		local name, _, _, _, connected = GetFriendInfo(i)
		if name and strlower(name) == strlower(target) then
			return connected
		end
	end
	
	if not noAdd and not private.invalidPlayers[strlower(target)] and GetNumFriends() ~= 50 then
		-- add them as a friend
		AddFriend(target)
		tinsert(private.addedFriends, target)
		for i=1, GetNumFriends() do
			local name, _, _, _, connected = GetFriendInfo(i)
			if name and strlower(name) == strlower(target) then
				return connected
			end
		end
	end
end


function TSM:DoSyncSetup(targetPlayer)
	if strlower(targetPlayer) == strlower(UnitName("player")) then
		TSM:Print("Sync Setup Error: You entered the name of the current character and not the character on the other account.")
		return
	elseif not private:IsPlayerOnline(targetPlayer) then
		TSM:Print("Sync Setup Error: The specified player on the other account is not currently online.")
		return
	end
	for player in pairs(TSM.db.factionrealm.syncAccounts) do
		if strlower(player) == targetPlayer then
			TSM:Print("Sync Setup Error: This character is already part of a known account.")
			return
		end
	end
	private.newPlayer = targetPlayer
	private.newAccount = nil
	return true
	-- TSM.db.factionrealm.syncAccounts[data.accountKey] = data.characters
end

function TSMAPI.Sync:GetAccountKey()
	return TSM.db.factionrealm.accountKey
end


function TSM:RegisterSyncCallback(module, callback)
	-- TO BE REMOVED
end
function TSMAPI.Sync:SendData(module, key, data, target)
	-- TO BE REMOVED
end
function TSMAPI.Sync:BroadcastData(module, key, data)
	-- TO BE REMOVED
end