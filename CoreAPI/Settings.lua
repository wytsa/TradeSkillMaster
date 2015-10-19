-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--          http://www.curse.com/addons/wow/tradeskillmaster_warehousing          --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file contains various settings APIs
local TSM = select(2, ...)
local private = {context={}}

local VALID_TYPES = {boolean=true, string=true, table=true, number=true}
local KEY_SEP = "@"
local GLOBAL_SCOPE_KEY = " "
local DEFAULT_PROFILE_NAME = "Default"
local SCOPE_TYPES = {
	global = "g",
	profile = "p",
	realm = "r",
	factionrealm = "f",
	char = "c",
}
local SCOPE_KEYS = {
	global = " ",
	profile = nil, -- set per-DB
	realm = GetRealmName(),
	factionrealm = UnitFactionGroup("player").." - "..GetRealmName(),
	char = UnitName("player").." - "..GetRealmName()
}
local DEFAULT_DB = {
	_version = -math.huge, -- DB version
	_currentProfile = {}, -- lookup table of the current profile name for different characters
	_hash = 0,
	_profiles = {},
	_realms = {},
	_factionrealms = {},
	_chars = {},
}


function private:CalculateHash(str)
	-- calculate the hash using the djb2 algorithm (http://www.cse.yorku.ca/~oz/hash.html)
	local hash = 5381
	local maxValue = 2 ^ 24
	for i=1, #str do
		hash = (hash * 33 + strbyte(str, i)) % maxValue
	end
	return hash
end

function private:ValidateDB(db)
	-- make sure the DB we are loading from is valid
	if #db > 0 then return end
	if type(db._version) ~= "number" then return end
	if type(db._hash) ~= "number" then return end
	if type(db._profiles) ~= "table" then return end
	for i, name in pairs(db._profiles) do
		if type(i) ~= "number" or i > #db._profiles or i <= 0 or type(name) ~= "string" then return end
	end
	if type(db._realms) ~= "table" then return end
	for i, name in pairs(db._realms) do
		if type(i) ~= "number" or i > #db._realms or i <= 0 or type(name) ~= "string" then return end
	end
	if type(db._factionrealms) ~= "table" then return end
	for i, name in pairs(db._factionrealms) do
		if type(i) ~= "number" or i > #db._factionrealms or i <= 0 or type(name) ~= "string" then return end
	end
	if type(db._chars) ~= "table" then return end
	for i, name in pairs(db._chars) do
		if type(i) ~= "number" or i > #db._chars or i <= 0 or type(name) ~= "string" then return end
	end
	if type(db._currentProfile) ~= "table" then return end
	for key, value in pairs(db._currentProfile) do
		if type(key) ~= "string" or type(value) ~= "string" then return end
	end
	return true
end

function private:SetScropeDefaults(db, settingsInfo, searchPattern)
	-- remove any existing entries for matching keys
	for key in pairs(db) do
		if strmatch(key, searchPattern) then
			db[key] = nil
		end
	end
	
	local scopeType = strsub(searchPattern, 1, 1)
	local scopeKeys = nil
	if scopeType == SCOPE_TYPES.global then
		scopeKeys = {GLOBAL_SCOPE_KEY}
	elseif scopeType == SCOPE_TYPES.profile then
		scopeKeys = db._profiles
	elseif scopeType == SCOPE_TYPES.realm then
		scopeKeys = db._realms
	elseif scopeType == SCOPE_TYPES.factionrealm then
		scopeKeys = db._factionrealms
	elseif scopeType == SCOPE_TYPES.char then
		scopeKeys = db._chars
	else
		TSMAPI:Assert(false)
	end
	
	-- set any matching keys to their default values
	for settingKey, info in pairs(settingsInfo) do
		for _, scopeKey in ipairs(scopeKeys) do
			local key = strjoin(KEY_SEP, SCOPE_TYPES[info.scope], scopeKey, settingKey)
			if strmatch(key, searchPattern) then
				db[key] = info.default
			end
		end
	end
end

private.SettingsDBMetatable = {
	-- make this table read-only
	__newindex = function() error("Attempt to modify read-only table") end,
	__metatable = false,
	
	__index = {
		objType = "SettingsDatabase",
		
		Get = function(self, key)
			TSMAPI:Assert(type(key) == "string")
			local context = private.context[self]
			local scope = context.settingsInfo[key].scope
			return context.db[strjoin(KEY_SEP, SCOPE_TYPES[scope], context.currentScopeKeys[scope], key)]
		end,
		
		Set = function(self, key, value)
			TSMAPI:Assert(type(key) == "string")
			local context = private.context[self]
			TSMAPI:Assert(value == nil or type(value) == context.settingsInfo[key].type)
			local scope = context.settingsInfo[key].scope
			context.db[strjoin(KEY_SEP, SCOPE_TYPES[scope], context.currentScopeKeys[scope], key)] = value
		end,
		
		GetProfile = function(self)
			return private.context[self].currentScopeKeys.profile
		end,
		
		SetProfile = function(self, profileName)
			TSMAPI:Assert(type(profileName) == "string")
			local context = private.context[self]
			
			-- change the current profile for this character
			context.db._currentProfile[SCOPE_KEYS.char] = profileName
			context.currentScopeKeys.profile = context.db._currentProfile[SCOPE_KEYS.char]
			
			if not tContains(context.db._profiles, profileName) then
				tinsert(context.db._profiles, profileName)
				-- this is a new profile, so set all the settings to their default values
				private:SetScropeDefaults(context.db, context.settingsInfo, strjoin(KEY_SEP, SCOPE_TYPES.profile, TSMAPI.Util:StrEscape(profileName), ".+"))
			end
		end,
		
		DeleteProfile = function(self, profileName)
			TSMAPI:Assert(type(profileName) == "string")
			local context = private.context[self]
			TSMAPI:Assert(profileName ~= context.currentScopeKeys.profile)
			
			-- remove all settings for the specified profile
			local searchPattern = strjoin(KEY_SEP, SCOPE_TYPES.profile, TSMAPI.Util:StrEscape(profileName), ".+")
			for key in pairs(context.db) do
				if strmatch(key, searchPattern) then
					context.db[key] = nil
				end
			end
			
			-- remove the profile from the list
			for i=1, #context.db._profiles do
				if context.db._profiles[i] == profileName then
					tremove(context.db._profiles, i)
					break
				end
			end
		end,
	},
}

function private:NewSettingsDB(name, settingsInfo, version)
	TSMAPI:Assert(type(name) == "string")
	TSMAPI:Assert(type(settingsInfo) == "table")
	TSMAPI:Assert(type(version) == "number")
	
	local db = _G[name]
	if not db then
		db = {}
		_G[name] = db
	end
	
	-- validate settingsInfo and generate checksum data
	local hashDataParts = {}
	for key, info in pairs(settingsInfo) do
		TSMAPI:Assert(type(key) == "string" and type(info) == "table", "Invalid type for key: "..tostring(key))
		TSMAPI:Assert(VALID_TYPES[info.type] and (info.default == nil or type(info.default) == info.type), "Invalid default/type for key: "..key)
		TSMAPI:Assert(SCOPE_TYPES[info.scope], "Invalid scope for key: "..key)
		tinsert(hashDataParts, strjoin(",", key, info.scope, info.type, type(info.default) == "table" and "table" or tostring(info.default)))
	end
	sort(hashDataParts)
	
	-- reset the DB if it's not valid
	local hash = private:CalculateHash(table.concat(hashDataParts, ";"))
	local isValid = true
	if not next(db) then
		-- new DB
		isValid = false
	elseif not private:ValidateDB(db) then
		-- corrupted DB
		TSMAPI:Assert(GetAddOnMetadata("TradeSkillMaster", "version") ~= "@project-version@", "DB is not valid!")
		isValid = false
	elseif db._version == version and db._hash ~= hash then
		-- the hash didn't match
		TSMAPI:Assert(GetAddOnMetadata("TradeSkillMaster", "version") ~= "@project-version@", "Invalid settings hash! Did you forget to increase the version?")
		isValid = false
	elseif db._version > version then
		-- this is a downgrade
		TSMAPI:Assert(GetAddOnMetadata("TradeSkillMaster", "version") ~= "@project-version@", "Unexpected DB version! If you really want to downgrade, comment out this line.")
		isValid = false
	end
	if not isValid then
		-- wipe the DB and start over
		wipe(db)
		for key, value in pairs(DEFAULT_DB) do
			db[key] = type(value) == "table" and CopyTable(value) or value
		end
	end
	db._hash = hash
	
	-- setup current scope keys and set defaults for new keys
	db._currentProfile[SCOPE_KEYS.char] = db._currentProfile[SCOPE_KEYS.char] or DEFAULT_PROFILE_NAME
	local currentScopeKeys = CopyTable(SCOPE_KEYS)
	currentScopeKeys.profile = db._currentProfile[SCOPE_KEYS.char]
	for scopeType, scopeKey in pairs(currentScopeKeys) do
		local list = db["_"..scopeType.."s"]
		if scopeType ~= "global" and not tContains(list, scopeKey) then
			tinsert(list, scopeKey)
			private:SetScropeDefaults(db, settingsInfo, strjoin(KEY_SEP, SCOPE_TYPES[scopeType], TSMAPI.Util:StrEscape(scopeKey), ".+"))
		end
	end
	
	-- do any necessary upgrading or downgrading if the version changed
	if version ~= db._version then
		-- clear any settings which no longer exist, and set new/updated settings to their default values
		local processedKeys = {}
		for key, value in pairs(db) do
			-- ignore non-setting metadata
			if strsub(key, 1, 1) ~= "_" then
				local settingKey = strmatch(key, "^.+"..KEY_SEP..".+"..KEY_SEP.."(.+)$")
				TSMAPI:Assert(settingKey)
				local info = settingsInfo[settingKey]
				if not info then
					-- this setting was removed so remove it from the db
					db[key] = nil
				elseif info.lastModifiedVersion > db._version or version < db._version then
					-- this setting was updated (or this is a downgrade) so reset it to its default value
					db[key] = info.default
				end
				processedKeys[settingKey] = true
			end
		end
		for settingKey, info in pairs(settingsInfo) do
			if not processedKeys[settingKey] and (info.lastModifiedVersion > db._version or version < db._version) then
				-- this is either a new setting or was changed and previously set to nil or this is a downgrade - either way set it to the default value
				private:SetScropeDefaults(db, settingsInfo, strjoin(KEY_SEP, SCOPE_TYPES[info.scope], ".+", settingKey))
			end
		end
	end
	db._version = version
	
	-- create the new object and return it
	local new = setmetatable({}, private.SettingsDBMetatable)
	private.context[new] = {db=db, settingsInfo=settingsInfo, currentScopeKeys=currentScopeKeys}
	return new
end

function TSMAPI.Settings:Init(svTableName, settingsInfo, version)
	if _G[svTableName] and _G[svTableName].profileKeys then
		-- this is an old AceDB table which we will convert to a SettingsDB
		-- create a new SettingsDB with default values and then go through and set any applicable values found in the old AceDB table
		local oldDB = _G[svTableName]
		_G[svTableName] = {}
		local newSettingsDB = private:NewSettingsDB(svTableName, settingsInfo, version)
		local context = private.context[newSettingsDB]
		for key, info in pairs(settingsInfo) do
			local scopeType = info.scope
			if scopeType == "global" then
				if oldDB.global and oldDB.global[key] ~= nil and type(oldDB.global[key]) == info.type then
					newSettingsDB:Set(key, oldDB.global[key])
				end
			elseif oldDB[scopeType] then
				for scopeKey, scopeSettings in pairs(oldDB[scopeType]) do
					local preservedKey = false
					if scopeSettings[key] ~= nil and type(scopeSettings[key]) == info.type then
						context.db[strjoin(KEY_SEP, SCOPE_TYPES[scopeType], scopeKey, key)] = scopeSettings[key]
						preservedKey = true
					end
					local list = context.db["_"..scopeType.."s"]
					if preservedKey and not tContains(list, scopeKey) then
						tinsert(context.db["_"..scopeType.."s"], scopeKey)
					end
				end
			end
		end
		return newSettingsDB
	else
		return private:NewSettingsDB(svTableName, settingsInfo, version)
	end
end

function TSMTEST2()
	local settingsInfo = {
		defaultMailTab = {scope="global", type="boolean", default=true, lastModifiedVersion=1},
		autoCheck = {scope="global", type="boolean", default=true, lastModifiedVersion=1},
		displayMoneyCollected = {scope="global", type="boolean", default=true, lastModifiedVersion=1},
		sendItemsIndividually = {scope="global", type="boolean", default=false, lastModifiedVersion=1},
		deleteEmptyNPCMail = {scope="global", type="boolean", default=false, lastModifiedVersion=1},
		inboxMessages = {scope="global", type="boolean", default=true, lastModifiedVersion=1},
		sendMessages = {scope="global", type="boolean", default=true, lastModifiedVersion=1},
		showReloadBtn = {scope="global", type="boolean", default=true, lastModifiedVersion=1},
		resendDelay = {scope="global", type="number", default=1, lastModifiedVersion=1},
		sendDelay = {scope="global", type="number", default=0.5, lastModifiedVersion=1},
		defaultPage = {scope="global", type="number", default=1, lastModifiedVersion=1},
		keepMailSpace = {scope="global", type="number", default=0, lastModifiedVersion=1},
		deMaxQuality = {scope="global", type="number", default=2, lastModifiedVersion=1},
		openMailSound = {scope="global", type="string", default=TSMAPI:GetNoSoundKey(), lastModifiedVersion=1},
		helpPlatesShown = {scope="global", type="table", default={inbox=nil, groups=nil, quickSend=nil, other=nil}, lastModifiedVersion=1},
		deMailTarget = {scope="factionrealm", type="string", default="", lastModifiedVersion=1},
		goldMailTarget = {scope="char", type="string", default="", lastModifiedVersion=1},
		goldKeepAmount = {scope="char", type="number", default=1000000, lastModifiedVersion=1},
	}
	return TSMAPI.Settings:Init("TradeSkillMaster_MailingDB", settingsInfo, 1)
end

function TSMTEST()
	_G["TSMTESTDB"] = {}
	local tblDefault = {}
	local settingsInfo = {
		boolSetting1 = {scope="factionrealm", type="boolean", default=true, lastModifiedVersion=1},
		numSetting1 = {scope="factionrealm", type="number", default=3, lastModifiedVersion=1},
		strSetting0 = {scope="profile", type="string", default="test!", lastModifiedVersion=1},
		strSetting1 = {scope="profile", type="string", default="test!", lastModifiedVersion=1},
		tblSetting1 = {scope="global", type="table", default=tblDefault, lastModifiedVersion=1},
	}
	local settingsDB = private:NewSettingsDB("TSMTESTDB", settingsInfo, 1)
	
	-- all the settings should be their default values
	TSMAPI:Assert(settingsDB:Get("boolSetting1") == true)
	TSMAPI:Assert(settingsDB:Get("numSetting1") == 3)
	TSMAPI:Assert(settingsDB:Get("strSetting1") == "test!")
	TSMAPI:Assert(settingsDB:Get("tblSetting1") == tblDefault)
	
	-- change a few settings
	settingsDB:Set("numSetting1", nil)
	settingsDB:Set("strSetting1", "another test")
	TSMAPI:Assert(settingsDB:Get("numSetting1") == nil)
	TSMAPI:Assert(settingsDB:Get("strSetting1") == "another test")
	
	-- reload the DB and it should keep the same settings
	local settingsDB = private:NewSettingsDB("TSMTESTDB", settingsInfo, 1)
	TSMAPI:Assert(settingsDB:Get("boolSetting1") == true)
	TSMAPI:Assert(settingsDB:Get("numSetting1") == nil)
	TSMAPI:Assert(settingsDB:Get("strSetting1") == "another test")
	TSMAPI:Assert(settingsDB:Get("tblSetting1") == tblDefault)
	
	-- create a second profile and the profile setting should reset to its default value
	settingsDB:SetProfile("Test")
	TSMAPI:Assert(settingsDB:Get("strSetting1") == "test!", tostring(settingsDB:Get("strSetting1")))
	TSMAPI:Assert(settingsDB:Get("boolSetting1") == true)
	TSMAPI:Assert(settingsDB:Get("numSetting1") == nil)
	TSMAPI:Assert(settingsDB:Get("tblSetting1") == tblDefault)
	settingsDB:Set("strSetting1", "test profile!")
	TSMAPI:Assert(settingsDB:Get("strSetting1") == "test profile!")
	
	-- set the profile back and make sure the old values remain
	settingsDB:SetProfile("Default")
	TSMAPI:Assert(settingsDB:Get("boolSetting1") == true)
	TSMAPI:Assert(settingsDB:Get("numSetting1") == nil)
	TSMAPI:Assert(settingsDB:Get("strSetting1") == "another test")
	TSMAPI:Assert(settingsDB:Get("tblSetting1") == tblDefault)
	
	-- set back to second profile
	settingsDB:SetProfile("Test")
	TSMAPI:Assert(settingsDB:Get("strSetting1") == "test profile!")
	TSMAPI:Assert(settingsDB:Get("boolSetting1") == true)
	TSMAPI:Assert(settingsDB:Get("numSetting1") == nil)
	TSMAPI:Assert(settingsDB:Get("tblSetting1") == tblDefault)
	
	-- do an upgrade
	local settingsInfo2 = {
		numSetting1 = {scope="factionrealm", type="number", default=7, lastModifiedVersion=2},
		strSetting1 = {scope="profile", type="string", default="test!", lastModifiedVersion=1},
		tblSetting1 = {scope="global", type="table", default=tblDefault, lastModifiedVersion=1},
		strSetting2 = {scope="profile", type="string", default="new setting", lastModifiedVersion=2},
	}
	local settingsDB = private:NewSettingsDB("TSMTESTDB", settingsInfo2, 2)
	TSMAPI:Assert(settingsDB:Get("numSetting1") == 7)
	TSMAPI:Assert(settingsDB:Get("strSetting1") == "test profile!")
	TSMAPI:Assert(settingsDB:Get("tblSetting1") == tblDefault)
	TSMAPI:Assert(settingsDB:Get("strSetting2") == "new setting")
	
	-- change back to the default profile and check that it got upgraded
	settingsDB:SetProfile("Default")
	TSMAPI:Assert(settingsDB:Get("strSetting1") == "another test")
	TSMAPI:Assert(settingsDB:Get("strSetting2") == "new setting")
	
	-- delete and re-create the second profile and check that its settings got reset to default values
	settingsDB:DeleteProfile("Test")
	settingsDB:SetProfile("Test")
	TSMAPI:Assert(settingsDB:Get("numSetting1") == 7)
	TSMAPI:Assert(settingsDB:Get("strSetting1") == "test!")
	TSMAPI:Assert(settingsDB:Get("tblSetting1") == tblDefault)
	TSMAPI:Assert(settingsDB:Get("strSetting2") == "new setting")
	
	return db
end