-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--          http://www.curse.com/addons/wow/tradeskillmaster_warehousing          --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file contains various settings APIs
local TSM = select(2, ...)
local private = {context={}, proxies={}}

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
	_scopeKeys = {
		profile = {},
		realm = {},
		factionrealm = {},
		char = {},
	},
}


function private:CopyData(data)
	if type(data) == "table" then
		return CopyTable(data)
	elseif type(data) == "number" or type(data) == "string" or type(data) == "boolean" or type(data) == "nil" then
		return data
	end
end

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
	if type(db._scopeKeys) ~= "table" then return end
	for scopeType, keys in pairs(db._scopeKeys) do
		if not SCOPE_TYPES[scopeType] then return end
		for i, name in pairs(keys) do
			if type(i) ~= "number" or i > #keys or i <= 0 or type(name) ~= "string" then return end
		end
	end
	if type(db._currentProfile) ~= "table" then return end
	for key, value in pairs(db._currentProfile) do
		if type(key) ~= "string" or type(value) ~= "string" then return end
	end
	return true
end

function private:SetScropeDefaults(db, settingsInfo, searchPattern, removedKeys)
	-- remove any existing entries for matching keys
	for key in pairs(db) do
		if strmatch(key, searchPattern) then
			if removedKeys then
				removedKeys[key] = db[key]
			end
			db[key] = nil
		end
	end
	
	local scopeType = strsub(searchPattern, 1, 1)
	local scopeKeys = nil
	if scopeType == SCOPE_TYPES.global then
		scopeKeys = {GLOBAL_SCOPE_KEY}
	else
		local reserveScopeTypeLookup = {}
		for key, value in pairs(SCOPE_TYPES) do
			reserveScopeTypeLookup[value] = key
		end
		scopeKeys = db._scopeKeys[reserveScopeTypeLookup[scopeType]]
		TSMAPI:Assert(scopeKeys, "Couldn't find scopeKeys for type: "..tostring(scopeType))
	end
	
	-- set any matching keys to their default values
	for settingKey, info in pairs(settingsInfo) do
		for _, scopeKey in ipairs(scopeKeys) do
			local key = strjoin(KEY_SEP, SCOPE_TYPES[info.scope], scopeKey, settingKey)
			if strmatch(key, searchPattern) then
				if removedKeys then
					removedKeys[key] = db[key]
				end
				db[key] = info.default
			end
		end
	end
end

private.SettingsDBMethods = {
	GetProfile = function(self)
		return private.context[self].currentScopeKeys.profile
	end,
	
	SetProfile = function(self, profileName)
		TSMAPI:Assert(not strfind(profileName, KEY_SEP))
		TSMAPI:Assert(type(profileName) == "string")
		local context = private.context[self]
		
		-- change the current profile for this character
		context.db._currentProfile[SCOPE_KEYS.char] = profileName
		context.currentScopeKeys.profile = context.db._currentProfile[SCOPE_KEYS.char]
		
		if not tContains(context.db._scopeKeys.profile, profileName) then
			tinsert(context.db._scopeKeys.profile, profileName)
			-- this is a new profile, so set all the settings to their default values
			private:SetScropeDefaults(context.db, context.settingsInfo, strjoin(KEY_SEP, SCOPE_TYPES.profile, TSMAPI.Util:StrEscape(profileName), ".+"))
		end
	end,
	
	DeleteScope = function(self, scopeType, scopeKey)
		TSMAPI:Assert(SCOPE_TYPES[scopeType])
		TSMAPI:Assert(type(scopeKey) == "string")
		local context = private.context[self]
		TSMAPI:Assert(scopeKey ~= context.currentScopeKeys[scopeType])
		
		-- remove all settings for the specified profile
		local searchPattern = strjoin(KEY_SEP, SCOPE_TYPES[scopeType], TSMAPI.Util:StrEscape(scopeKey), ".+")
		for key in pairs(context.db) do
			if strmatch(key, searchPattern) then
				context.db[key] = nil
			end
		end
		
		-- remove the scope key from the list
		for i=1, #context.db._scopeKeys[scopeType] do
			if context.db._scopeKeys[scopeType][i] == scopeKey then
				tremove(context.db._scopeKeys[scopeType], i)
				break
			end
		end
	end,
	
	DeleteProfile = function(self, profileName)
		self:DeleteScope("profile", profileName)
	end,
	
	RegisterCallback = function(self, event, callback)
		-- TODO
	end,
}

private.SettingsDBScopeProxy = setmetatable({}, {
	-- constructor
	__call = function(_, settingsDB, scope)
		TSMAPI:Assert(private.context[settingsDB])
		local new = setmetatable({}, getmetatable(private.SettingsDBScopeProxy))
		private.proxies[new] = {settingsDB=settingsDB, scope=scope}
		return new
	end,
	
	-- getter
	__index = function(self, key)
		TSMAPI:Assert(type(key) == "string", format("Invalid setting key type (%s)!", type(key)), 1)
		local proxyInfo = private.proxies[self]
		local context = private.context[proxyInfo.settingsDB]
		TSMAPI:Assert(context.settingsInfo[key], "Setting does not exist!", 1)
		TSMAPI:Assert(context.settingsInfo[key].scope == proxyInfo.scope, "Setting does not exist in this scope!", 1)
		return context.db[strjoin(KEY_SEP, SCOPE_TYPES[proxyInfo.scope], context.currentScopeKeys[proxyInfo.scope], key)]
	end,
	
	-- setter
	__newindex = function(self, key, value)
		TSMAPI:Assert(type(key) == "string", format("Invalid setting key type (%s)!", type(key)), 1)
		local proxyInfo = private.proxies[self]
		local context = private.context[proxyInfo.settingsDB]
		TSMAPI:Assert(context.settingsInfo[key], "Setting does not exist!", 1)
		TSMAPI:Assert(context.settingsInfo[key].scope == proxyInfo.scope, "Setting does not exist in this scope!", 1)
		TSMAPI:Assert(value == nil or type(value) == context.settingsInfo[key].type, format("Value is of wrong type (%s).", type(value)), 1)
		context.db[strjoin(KEY_SEP, SCOPE_TYPES[proxyInfo.scope], context.currentScopeKeys[proxyInfo.scope], key)] = value
	end,
})

private.SettingsDB = setmetatable({}, {
	-- constructor
	__call = function(_, name, rawSettingsInfo, upgradeCallback)
		TSMAPI:Assert(type(name) == "string")
		TSMAPI:Assert(type(rawSettingsInfo) == "table")
		local version = rawSettingsInfo.version
		rawSettingsInfo.version = nil
		TSMAPI:Assert(type(version) == "number" and version >= 1)
		
		-- get (and create if necessary) the global table
		local db = _G[name]
		if not db then
			db = {}
			_G[name] = db
		end
		
		-- flatten and validate rawSettingsInfo and generate hash data
		local settingsInfo = {}
		local hashDataParts = {}
		for scope, scopeSettingsInfo in pairs(rawSettingsInfo) do
			TSMAPI:Assert(SCOPE_TYPES[scope], "Invalid scope: "..tostring(scope))
			for key, info in pairs(scopeSettingsInfo) do
				TSMAPI:Assert(type(key) == "string" and type(info) == "table", "Invalid type for key: "..tostring(key))
				TSMAPI:Assert(not strfind(key, KEY_SEP))
				for k, v in pairs(info) do
					if k == "type" then
						TSMAPI:Assert(VALID_TYPES[info.type], "Invalid type for key: "..key)
					elseif k == "default" then
						TSMAPI:Assert(v == nil or type(v) == info.type, "Invalid default for key: "..key)
					elseif k == "lastModifiedVersion" then
						TSMAPI:Assert(type(v) == "number" and v <= version, "Invalid lastModifiedVersion for key: "..key)
					else
						TSMAPI:Assert(false, "Unexpected key in settingsInfo for key: "..key)
					end
				end
				settingsInfo[key] = {scope=scope, type=info.type, default=info.default, lastModifiedVersion=info.lastModifiedVersion}
				tinsert(hashDataParts, strjoin(",", key, scope, info.type, type(info.default) == "table" and "table" or tostring(info.default)))
			end
		end
		rawSettingsInfo.version = version
		sort(hashDataParts)
		
		-- reset the DB if it's not valid
		local hash = private:CalculateHash(table.concat(hashDataParts, ";"))
		local isValid = true
		local preUpgradeDB = nil
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
				db[key] = private:CopyData(value)
			end
		end
		db._hash = hash
		
		-- setup current scope keys and set defaults for new keys
		db._currentProfile[SCOPE_KEYS.char] = db._currentProfile[SCOPE_KEYS.char] or DEFAULT_PROFILE_NAME
		local currentScopeKeys = CopyTable(SCOPE_KEYS)
		currentScopeKeys.profile = db._currentProfile[SCOPE_KEYS.char]
		for scopeType, scopeKey in pairs(currentScopeKeys) do
			if scopeType ~= "global" and not tContains(db._scopeKeys[scopeType], scopeKey) then
				tinsert(db._scopeKeys[scopeType], scopeKey)
				private:SetScropeDefaults(db, settingsInfo, strjoin(KEY_SEP, SCOPE_TYPES[scopeType], TSMAPI.Util:StrEscape(scopeKey), ".+"))
			end
		end
		
		-- do any necessary upgrading or downgrading if the version changed
		local removedKeys = {}
		if version ~= db._version then
			-- clear any settings which no longer exist, and set new/updated settings to their default values
			local processedKeys = {}
			for key, value in pairs(db) do
				-- ignore metadata (keys starting with "_")
				if strsub(key, 1, 1) ~= "_" then
					local scopeType, settingKey = strmatch(key, "^(.+)"..KEY_SEP..".+"..KEY_SEP.."(.+)$")
					TSMAPI:Assert(settingKey)
					local info = settingsInfo[settingKey]
					if not info or SCOPE_TYPES[settingsInfo[settingKey].scope] ~= scopeType then
						-- this setting was removed so remove it from the db
						removedKeys[key] = db[key]
						db[key] = nil
					elseif info.lastModifiedVersion > db._version or version < db._version then
						-- this setting was updated (or this is a downgrade) so reset it to its default value
						removedKeys[key] = db[key]
						db[key] = info.default
					end
					processedKeys[scopeType..KEY_SEP..settingKey] = true
				end
			end
			for settingKey, info in pairs(settingsInfo) do
				if not processedKeys[info.scope..KEY_SEP..settingKey] and (info.lastModifiedVersion > db._version or version < db._version) then
					-- this is either a new setting or was changed and previously set to nil or this is a downgrade - either way set it to the default value
					private:SetScropeDefaults(db, settingsInfo, strjoin(KEY_SEP, SCOPE_TYPES[info.scope], ".+", settingKey), removedKeys)
				end
			end
		end
		local oldVersion = db._version
		db._version = version
		
		-- create the new object and return it
		local new = setmetatable({}, getmetatable(private.SettingsDB))
		private.context[new] = {db=db, settingsInfo=settingsInfo, currentScopeKeys=currentScopeKeys}
		
		-- if this is an upgrade, call the upgrade callback for each of the keys which were changed / removed
		if isValid and version > oldVersion and upgradeCallback then
			local reserveScopeTypeLookup = {}
			for key, value in pairs(SCOPE_TYPES) do
				reserveScopeTypeLookup[value] = key
			end
			for key, oldValue in pairs(removedKeys) do
				local settingKey = strmatch(key, "^.+"..KEY_SEP..".+"..KEY_SEP.."(.+)$")
				upgradeCallback(new, settingKey, oldValue)
			end
		end
		return new, oldVersion
	end,
	
	-- getter
	__index = function(self, key)
		if private.SettingsDBMethods[key] then
			return private.SettingsDBMethods[key]
		elseif SCOPE_TYPES[key] then
			return private.SettingsDBScopeProxy(self, key)
		else
			TSMAPI:Assert(false, "Invalid scope: "..tostring(key), 1)
		end
	end,
	
	-- setter
	__newindex = function(self, key, value) TSMAPI:Assert(false, "You cannot set values in this table! You're probably missing a scope.", 1) end,
})

function TSMAPI.Settings:Init(svTableName, settingsInfo)
	if _G[svTableName] and _G[svTableName].profileKeys then
		-- this is an old AceDB table which we will convert to a SettingsDB
		-- create a new SettingsDB with default values and then go through and set any applicable values found in the old AceDB table
		local oldDB = _G[svTableName]
		_G[svTableName] = {}
		local newSettingsDB = private.SettingsDB(svTableName, settingsInfo)
		local context = private.context[newSettingsDB]
		local version = settingsInfo.version
		settingsInfo.version = nil
		for scopeType, scopeSettingsInfo in pairs(settingsInfo) do
			for key, info in pairs(scopeSettingsInfo) do
				if scopeType == "global" then
					if oldDB.global and oldDB.global[key] ~= nil and type(oldDB.global[key]) == info.type then
						context.db[strjoin(KEY_SEP, SCOPE_TYPES[scopeType], GLOBAL_SCOPE_KEY, key)] = oldDB.global[key]
					end
				elseif oldDB[scopeType] then
					for scopeKey, scopeSettings in pairs(oldDB[scopeType]) do
						local preservedKey = false
						if scopeSettings[key] ~= nil and type(scopeSettings[key]) == info.type then
							context.db[strjoin(KEY_SEP, SCOPE_TYPES[scopeType], scopeKey, key)] = scopeSettings[key]
							preservedKey = true
						end
						if preservedKey and not tContains(context.db._scopeKeys[scopeType], scopeKey) then
							tinsert(context.db._scopeKeys[scopeType], scopeKey)
						end
					end
				end
			end
		end
		settingsInfo.version = version
		return newSettingsDB
	else
		return private.SettingsDB(svTableName, settingsInfo)
	end
end

function TSMTEST()
	_G["TSMTESTDB"] = {}
	local tblDefault = {}
	local settingsInfo = {
		version = 1,
		global = {
			tblSetting1 = {type="table", default=tblDefault, lastModifiedVersion=1},
		},
		profile = {
			strSetting0 = {type="string", default="test!", lastModifiedVersion=1},
			strSetting1 = {type="string", default="test!", lastModifiedVersion=1},
		},
		factionrealm = {
			boolSetting1 = {type="boolean", default=true, lastModifiedVersion=1},
			numSetting1 = {type="number", default=3, lastModifiedVersion=1},
		},
	}
	local settingsDB = private.SettingsDB("TSMTESTDB", settingsInfo, function() TSMAPI:Assert(false) end)
	
	-- all the settings should be their default values
	TSMAPI:Assert(settingsDB.factionrealm.boolSetting1 == true)
	TSMAPI:Assert(settingsDB.factionrealm.numSetting1 == 3)
	TSMAPI:Assert(settingsDB.profile.strSetting1 == "test!")
	TSMAPI:Assert(settingsDB.global.tblSetting1 == tblDefault)
	
	-- change a few settings
	settingsDB.factionrealm.numSetting1 = nil
	settingsDB.profile.strSetting1 = "another test"
	TSMAPI:Assert(settingsDB.factionrealm.numSetting1 == nil)
	TSMAPI:Assert(settingsDB.profile.strSetting1 == "another test")
	
	-- reload the DB and it should keep the same settings
	local settingsDB = private.SettingsDB("TSMTESTDB", settingsInfo, function() TSMAPI:Assert(false) end)
	TSMAPI:Assert(settingsDB.factionrealm.boolSetting1 == true)
	TSMAPI:Assert(settingsDB.factionrealm.numSetting1 == nil)
	TSMAPI:Assert(settingsDB.profile.strSetting1 == "another test")
	TSMAPI:Assert(settingsDB.global.tblSetting1 == tblDefault)
	
	-- create a second profile and the profile setting should reset to its default value
	settingsDB:SetProfile("Test")
	TSMAPI:Assert(settingsDB.profile.strSetting1 == "test!")
	TSMAPI:Assert(settingsDB.factionrealm.boolSetting1 == true)
	TSMAPI:Assert(settingsDB.factionrealm.numSetting1 == nil)
	TSMAPI:Assert(settingsDB.global.tblSetting1 == tblDefault)
	settingsDB.profile.strSetting1 = "test profile!"
	TSMAPI:Assert(settingsDB.profile.strSetting1 == "test profile!")
	
	-- set the profile back and make sure the old values remain
	settingsDB:SetProfile("Default")
	TSMAPI:Assert(settingsDB.factionrealm.boolSetting1 == true)
	TSMAPI:Assert(settingsDB.factionrealm.numSetting1 == nil)
	TSMAPI:Assert(settingsDB.profile.strSetting1 == "another test")
	TSMAPI:Assert(settingsDB.global.tblSetting1 == tblDefault)
	
	-- set back to second profile
	settingsDB:SetProfile("Test")
	TSMAPI:Assert(settingsDB.profile.strSetting1 == "test profile!")
	TSMAPI:Assert(settingsDB.factionrealm.boolSetting1 == true)
	TSMAPI:Assert(settingsDB.factionrealm.numSetting1 == nil)
	TSMAPI:Assert(settingsDB.global.tblSetting1 == tblDefault)
	
	-- do an upgrade
	local settingsInfo2 = {
		version = 2,
		global = {
			tblSetting1 = {type="table", default=tblDefault, lastModifiedVersion=1},
		},
		profile = {
			strSetting1 = {type="string", default="test!", lastModifiedVersion=1},
			strSetting2 = {type="string", default="new setting", lastModifiedVersion=2},
		},
		factionrealm = {
			numSetting1 = {type="number", default=7, lastModifiedVersion=2},
		},
	}
	local settingsDB = private.SettingsDB("TSMTESTDB", settingsInfo2)
	TSMAPI:Assert(settingsDB.factionrealm.numSetting1 == 7)
	TSMAPI:Assert(settingsDB.profile.strSetting1 == "test profile!")
	TSMAPI:Assert(settingsDB.global.tblSetting1 == tblDefault)
	TSMAPI:Assert(settingsDB.profile.strSetting2 == "new setting")
	
	-- change back to the default profile and check that it got upgraded
	settingsDB:SetProfile("Default")
	TSMAPI:Assert(settingsDB.profile.strSetting1 == "another test")
	TSMAPI:Assert(settingsDB.profile.strSetting2 == "new setting")
	
	-- delete and re-create the second profile and check that its settings got reset to default values
	settingsDB:DeleteProfile("Test")
	settingsDB:SetProfile("Test")
	TSMAPI:Assert(settingsDB.factionrealm.numSetting1 == 7)
	TSMAPI:Assert(settingsDB.profile.strSetting1 == "test!")
	TSMAPI:Assert(settingsDB.global.tblSetting1 == tblDefault)
	TSMAPI:Assert(settingsDB.profile.strSetting2 == "new setting")
	
	-- delete the default profile
	settingsDB:DeleteProfile("Default")
	local settingsDB = private.SettingsDB("TSMTESTDB", settingsInfo2, function() TSMAPI:Assert(false) end)
	
	-- emulate renaming a setting
	local settingsInfo3 = {
		version = 3,
		global = {
			tblSetting2 = {type="table", default=tblDefault, lastModifiedVersion=3},
		},
		profile = {
			strSetting1 = {type="string", default="test!", lastModifiedVersion=1},
			strSetting2 = {type="string", default="new setting", lastModifiedVersion=2},
		},
		factionrealm = {
			numSetting1 = {type="number", default=7, lastModifiedVersion=2},
		},
	}
	local numChanged = 0
	local function UpgradeCallback(newSettingsDB, key, oldValue)
		if key == "tblSetting1" then
			newSettingsDB.global.tblSetting2 = oldValue
			numChanged = numChanged + 1
		end
	end
	local settingsDB = private.SettingsDB("TSMTESTDB", settingsInfo3, UpgradeCallback)
	TSMAPI:Assert(numChanged == 1)
	TSMAPI:Assert(settingsDB.global.tblSetting2 == tblDefault)
	TSMAPI:Assert(settingsDB.factionrealm.numSetting1 == 7)
	TSMAPI:Assert(settingsDB.profile.strSetting1 == "test!")
	TSMAPI:Assert(settingsDB.profile.strSetting2 == "new setting")
	
	-- change the scope of some settings
	local settingsInfo4 = {
		version = 4,
		profile = {
			strSetting2 = {type="string", default="new setting", lastModifiedVersion=2},
		},
		factionrealm = {
			numSetting1 = {type="number", default=7, lastModifiedVersion=2},
		},
		char = {
			strSetting1 = {type="string", default="char test!", lastModifiedVersion=4},
			tblSetting2 = {type="table", default=tblDefault, lastModifiedVersion=4},
		},
	}
	local settingsDB = private.SettingsDB("TSMTESTDB", settingsInfo4)
	TSMAPI:Assert(settingsDB.char.tblSetting2 == tblDefault)
	TSMAPI:Assert(settingsDB.factionrealm.numSetting1 == 7)
	TSMAPI:Assert(settingsDB.char.strSetting1 == "char test!", tostring(settingsDB.char.strSetting1))
	TSMAPI:Assert(settingsDB.profile.strSetting2 == "new setting")
	
	return settingsDB
end