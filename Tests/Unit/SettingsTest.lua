-- function TSMSettingsTest()
	-- _G["TSMTESTDB"] = {}
	-- local tblDefault = {entry=23}
	-- local settingsInfo = {
		-- version = 1,
		-- global = {
			-- tblSetting1 = {type="table", default=tblDefault, lastModifiedVersion=1},
		-- },
		-- profile = {
			-- strSetting0 = {type="string", default="test!", lastModifiedVersion=1},
			-- strSetting1 = {type="string", default="test!", lastModifiedVersion=1},
		-- },
		-- factionrealm = {
			-- boolSetting1 = {type="boolean", default=true, lastModifiedVersion=1},
			-- numSetting1 = {type="number", default=3, lastModifiedVersion=1},
		-- },
	-- }
	-- local settingsDB = private.SettingsDB("TSMTESTDB", settingsInfo, function() TSMAPI:Assert(false) end)
	
	-- -- all the settings should be their default values
	-- TSMAPI:Assert(settingsDB.factionrealm.boolSetting1 == true)
	-- TSMAPI:Assert(settingsDB.factionrealm.numSetting1 == 3)
	-- TSMAPI:Assert(settingsDB.profile.strSetting1 == "test!")
	-- TSMAPI:Assert(settingsDB.global.tblSetting1.entry == tblDefault.entry)
	
	-- -- change a few settings
	-- settingsDB.factionrealm.numSetting1 = nil
	-- settingsDB.profile.strSetting1 = "another test"
	-- TSMAPI:Assert(settingsDB.factionrealm.numSetting1 == nil)
	-- TSMAPI:Assert(settingsDB.profile.strSetting1 == "another test")
	
	-- -- reload the DB and it should keep the same settings
	-- local settingsDB = private.SettingsDB("TSMTESTDB", settingsInfo, function() TSMAPI:Assert(false) end)
	-- TSMAPI:Assert(settingsDB.factionrealm.boolSetting1 == true)
	-- TSMAPI:Assert(settingsDB.factionrealm.numSetting1 == nil)
	-- TSMAPI:Assert(settingsDB.profile.strSetting1 == "another test")
	-- TSMAPI:Assert(settingsDB.global.tblSetting1.entry == tblDefault.entry)
	
	-- -- create a second profile and the profile setting should reset to its default value
	-- settingsDB:SetProfile("Test")
	-- TSMAPI:Assert(settingsDB.profile.strSetting1 == "test!")
	-- TSMAPI:Assert(settingsDB.factionrealm.boolSetting1 == true)
	-- TSMAPI:Assert(settingsDB.factionrealm.numSetting1 == nil)
	-- TSMAPI:Assert(settingsDB.global.tblSetting1.entry == tblDefault.entry)
	-- settingsDB.profile.strSetting1 = "test profile!"
	-- TSMAPI:Assert(settingsDB.profile.strSetting1 == "test profile!")
	
	-- -- set the profile back and make sure the old values remain
	-- settingsDB:SetProfile("Default")
	-- TSMAPI:Assert(settingsDB.factionrealm.boolSetting1 == true)
	-- TSMAPI:Assert(settingsDB.factionrealm.numSetting1 == nil)
	-- TSMAPI:Assert(settingsDB.profile.strSetting1 == "another test")
	-- TSMAPI:Assert(settingsDB.global.tblSetting1.entry == tblDefault.entry)
	
	-- -- set back to second profile
	-- settingsDB:SetProfile("Test")
	-- TSMAPI:Assert(settingsDB.profile.strSetting1 == "test profile!")
	-- TSMAPI:Assert(settingsDB.factionrealm.boolSetting1 == true)
	-- TSMAPI:Assert(settingsDB.factionrealm.numSetting1 == nil)
	-- TSMAPI:Assert(settingsDB.global.tblSetting1.entry == tblDefault.entry)
	
	-- -- do an upgrade
	-- local settingsInfo2 = {
		-- version = 2,
		-- global = {
			-- tblSetting1 = {type="table", default=tblDefault, lastModifiedVersion=1},
		-- },
		-- profile = {
			-- strSetting1 = {type="string", default="test!", lastModifiedVersion=1},
			-- strSetting2 = {type="string", default="new setting", lastModifiedVersion=2},
		-- },
		-- factionrealm = {
			-- numSetting1 = {type="number", default=7, lastModifiedVersion=2},
		-- },
	-- }
	-- local settingsDB = private.SettingsDB("TSMTESTDB", settingsInfo2)
	-- TSMAPI:Assert(settingsDB.factionrealm.numSetting1 == 7)
	-- TSMAPI:Assert(settingsDB.profile.strSetting1 == "test profile!")
	-- TSMAPI:Assert(settingsDB.global.tblSetting1.entry == tblDefault.entry)
	-- TSMAPI:Assert(settingsDB.profile.strSetting2 == "new setting")
	
	-- -- change back to the default profile and check that it got upgraded
	-- settingsDB:SetProfile("Default")
	-- TSMAPI:Assert(settingsDB.profile.strSetting1 == "another test")
	-- TSMAPI:Assert(settingsDB.profile.strSetting2 == "new setting")
	
	-- -- delete and re-create the second profile and check that its settings got reset to default values
	-- settingsDB:DeleteProfile("Test")
	-- settingsDB:SetProfile("Test")
	-- TSMAPI:Assert(settingsDB.factionrealm.numSetting1 == 7)
	-- TSMAPI:Assert(settingsDB.profile.strSetting1 == "test!")
	-- TSMAPI:Assert(settingsDB.global.tblSetting1.entry == tblDefault.entry)
	-- TSMAPI:Assert(settingsDB.profile.strSetting2 == "new setting")
	
	-- -- delete the default profile
	-- settingsDB:DeleteProfile("Default")
	-- local settingsDB = private.SettingsDB("TSMTESTDB", settingsInfo2, function() TSMAPI:Assert(false) end)
	
	-- -- emulate renaming a setting
	-- local settingsInfo3 = {
		-- version = 3,
		-- global = {
			-- tblSetting2 = {type="table", default=tblDefault, lastModifiedVersion=3},
		-- },
		-- profile = {
			-- strSetting1 = {type="string", default="test!", lastModifiedVersion=1},
			-- strSetting2 = {type="string", default="new setting", lastModifiedVersion=2},
		-- },
		-- factionrealm = {
			-- numSetting1 = {type="number", default=7, lastModifiedVersion=2},
		-- },
	-- }
	-- local numChanged = 0
	-- local function UpgradeCallback(newSettingsDB, key, oldValue)
		-- if key == "tblSetting1" then
			-- newSettingsDB.global.tblSetting2 = oldValue
			-- numChanged = numChanged + 1
		-- end
	-- end
	-- local settingsDB = private.SettingsDB("TSMTESTDB", settingsInfo3, UpgradeCallback)
	-- TSMAPI:Assert(numChanged == 1)
	-- TSMAPI:Assert(settingsDB.global.tblSetting2.entry == tblDefault.entry)
	-- TSMAPI:Assert(settingsDB.factionrealm.numSetting1 == 7)
	-- TSMAPI:Assert(settingsDB.profile.strSetting1 == "test!")
	-- TSMAPI:Assert(settingsDB.profile.strSetting2 == "new setting")
	
	-- -- change the scope of some settings
	-- local settingsInfo4 = {
		-- version = 4,
		-- profile = {
			-- strSetting2 = {type="string", default="new setting", lastModifiedVersion=2},
		-- },
		-- factionrealm = {
			-- numSetting1 = {type="number", default=7, lastModifiedVersion=2},
		-- },
		-- char = {
			-- strSetting1 = {type="string", default="char test!", lastModifiedVersion=4},
			-- tblSetting2 = {type="table", default=tblDefault, lastModifiedVersion=4},
		-- },
	-- }
	-- local settingsDB = private.SettingsDB("TSMTESTDB", settingsInfo4)
	-- TSMAPI:Assert(settingsDB.char.tblSetting2.entry == tblDefault.entry)
	-- TSMAPI:Assert(settingsDB.factionrealm.numSetting1 == 7)
	-- TSMAPI:Assert(settingsDB.char.strSetting1 == "char test!", tostring(settingsDB.char.strSetting1))
	-- TSMAPI:Assert(settingsDB.profile.strSetting2 == "new setting")
	
	-- return settingsDB
-- end