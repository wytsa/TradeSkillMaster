-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)
local Operations = TSM:NewModule("Operations")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries
local private = {operationInfo=TSM.moduleOperationInfo}



-- ============================================================================
-- TSMAPI Functions
-- ============================================================================

function TSMAPI.Operations:GetFirstByItem(itemString, module)
	TSMAPI:Assert(itemString and module, "Invalid parameters to TSMAPI.Operations:GetFirstByItem(...)")
	local groupPath = TSM.db.profile.items[itemString]
	if not groupPath then return end
	if not TSM.db.profile.groups[groupPath][module] then return end

	for _, operation in ipairs(TSM.db.profile.groups[groupPath][module]) do
		if operation ~= "" and not TSM.Modules:IsOperationIgnored(module, operation) then
			return operation
		end
	end
end

function TSMAPI.Operations:Update(moduleName, operationName)
	if not TSM.operations[moduleName][operationName] then return end
	for key in pairs(TSM.operations[moduleName][operationName].relationships) do
		local operation = TSM.operations[moduleName][operationName]
		while operation.relationships[key] do
			local newOperation = TSM.operations[moduleName][operation.relationships[key]]
			if not newOperation then break end
			operation = newOperation
		end
		TSM.operations[moduleName][operationName][key] = operation[key]
	end
end

function TSMAPI.Operations:ShowNewOperationPopup(moduleName, group, operationName)
	if not group then return end
	StaticPopupDialogs["TSM_NEW_OPERATION_ADD"] = StaticPopupDialogs["TSM_NEW_OPERATION_ADD"] or {
		button1 = YES,
		button2 = NO,
		timeout = 0,
		OnAccept = function()
			-- the "add" button
			local group, moduleName, operationName = unpack(StaticPopupDialogs["TSM_NEW_OPERATION_ADD"].tsmInfo)
			TSM.Groups:SetOperation(group, moduleName, operationName, #TSM.db.profile.groups[group][moduleName])
			TSM:Printf(L["Applied %s to %s."], TSMAPI.Design:GetInlineColor("link")..operationName.."|r", TSMAPI.Groups:FormatPath(group, true))
		end,
	}
	StaticPopupDialogs["TSM_NEW_OPERATION_ADD"].text = format(L["Would you like to add this new operation to %s?"], TSMAPI.Groups:FormatPath(group, true))
	StaticPopupDialogs["TSM_NEW_OPERATION_ADD"].tsmInfo = {group, moduleName, operationName}
	TSMAPI.Util:ShowStaticPopupDialog("TSM_NEW_OPERATION_ADD")
end

function TSMAPI.Operations:ShowManagementTab(TSMObj, container, operationName)
	local moduleName = gsub(TSMObj.name, "TSM_", "")
	local operation = TSMObj.operations[operationName]

	local playerList = {}
	local factionrealmKey = TSM.db.keys.factionrealm
	for playerName in TSMAPI.Sync:GetTableIter(TSM.db.factionrealm.characters) do
		playerList[playerName.." - "..factionrealmKey] = playerName
	end
	
	local factionrealmList = {}
	for factionrealm in pairs(TSM.db.sv.factionrealm) do
		factionrealmList[factionrealm] = factionrealm
	end
	
	local groupList = {}
	for path, modules in pairs(TSM.db.profile.groups) do
		if modules[moduleName] then
			for i=1, #modules[moduleName] do
				if modules[moduleName][i] == operationName then
					tinsert(groupList, path)
				end
			end
		end
	end
	sort(groupList, function(a,b) return strlower(gsub(a, TSM.GROUP_SEP, "\001")) < strlower(gsub(b, TSM.GROUP_SEP, "\001")) end)
	
	local groupWidgets = {
		{
			type = "Label",
			relativeWidth = 1,
			text = L["Below is a list of groups which this operation is currently applied to. Clicking on the 'Remove' button next to the group name will remove the operation from that group."],
		},
		{
			type = "HeadingLine",
		},
	}
	for _, groupPath in ipairs(groupList) do
		tinsert(groupWidgets, {
				type = "Button",
				relativeWidth = 0.2,
				text = L["Remove"],
				callback = function()
					for i=#TSM.db.profile.groups[groupPath][moduleName], 1, -1 do
						if TSM.db.profile.groups[groupPath][moduleName][i] == operationName then
							TSM.Groups:RemoveOperation(groupPath, moduleName, i)
						end
					end
					TSM.Modules:CheckOperationRelationships(moduleName)
					private:ModuleOptionsRefresh(TSMObj, operationName)
				end,
				tooltip = L["Click this button to completely remove this operation from the specified group."],
			})
		tinsert(groupWidgets, {
				type = "Label",
				relativeWidth = 0.05,
				text = "",
			})
		tinsert(groupWidgets, {
				type = "Label",
				relativeWidth = 0.75,
				text = TSMAPI.Groups:FormatPath(groupPath, true),
			})
	end
	tinsert(groupWidgets, {type="HeadingLine"})
	tinsert(groupWidgets, {
			type = "GroupBox",
			label = L["Apply Operation to Group"],
			relativeWidth = 1,
			callback = function(self, _, path)
				TSM.db.profile.groups[path][moduleName] = TSM.db.profile.groups[path][moduleName] or {}
				local operations = TSM.db.profile.groups[path][moduleName]
				local num = #operations
				if num == 0 then
					TSM.Groups:SetOperationOverride(path, moduleName, true)
					TSM.Groups:AddOperation(path, moduleName)
					TSM.Groups:SetOperation(path, moduleName, operationName, 1)
					TSM:Printf(L["Applied %s to %s."], TSMAPI.Design:GetInlineColor("link")..operationName.."|r", TSMAPI.Groups:FormatPath(path, true))
				elseif operations[num] == "" then
					TSM.Groups:SetOperationOverride(path, moduleName, true)
					TSM.Groups:SetOperation(path, moduleName, operationName, num)
					TSM:Printf(L["Applied %s to %s."], TSMAPI.Design:GetInlineColor("link")..operationName.."|r", TSMAPI.Groups:FormatPath(path, true))
				else
					local canAdd
					for _, info in ipairs(private.operationInfo) do
						if moduleName == info.module then
							canAdd = num < info.maxOperations
							break
						end
					end
					if canAdd then
						StaticPopupDialogs["TSM_APPLY_OPERATION_ADD"] = StaticPopupDialogs["TSM_APPLY_OPERATION_ADD"] or {
							text = L["This group already has operations. Would you like to add another one or replace the last one?"],
							button1 = ADD,
							button2 = L["Replace"],
							button3 = CANCEL,
							timeout = 0,
							OnAccept = function()
								-- the "add" button
								local path, moduleName, operationName, num = unpack(StaticPopupDialogs["TSM_APPLY_OPERATION_ADD"].tsmInfo)
								TSM.Groups:SetOperationOverride(path, moduleName, true)
								TSM.Groups:AddOperation(path, moduleName)
								TSM.Groups:SetOperation(path, moduleName, operationName, num+1)
								TSM:Printf(L["Applied %s to %s."], TSMAPI.Design:GetInlineColor("link")..operationName.."|r", TSMAPI.Groups:FormatPath(path, true))
							end,
							OnCancel = function()
								-- the "replace" button
								local path, moduleName, operationName, num = unpack(StaticPopupDialogs["TSM_APPLY_OPERATION_ADD"].tsmInfo)
								TSM.Groups:SetOperationOverride(path, moduleName, true)
								TSM.Groups:SetOperation(path, moduleName, operationName, num)
								TSM:Printf(L["Applied %s to %s."], TSMAPI.Design:GetInlineColor("link")..operationName.."|r", TSMAPI.Groups:FormatPath(path, true))
							end,
						}
						StaticPopupDialogs["TSM_APPLY_OPERATION_ADD"].tsmInfo = {path, moduleName, operationName, num}
						TSMAPI.Util:ShowStaticPopupDialog("TSM_APPLY_OPERATION_ADD")
					else
						StaticPopupDialogs["TSM_APPLY_OPERATION"] = StaticPopupDialogs["TSM_APPLY_OPERATION"] or {
							text = L["This group already has the max number of operation. Would you like to replace the last one?"],
							button1 = L["Replace"],
							button2 = CANCEL,
							timeout = 0,
							OnAccept = function()
								-- the "replace" button
								local path, moduleName, operationName, num = unpack(StaticPopupDialogs["TSM_APPLY_OPERATION"].tsmInfo)
								TSM.Groups:SetOperation(path, moduleName, operationName, num)
								TSM:Printf(L["Applied %s to %s."], TSMAPI.Design:GetInlineColor("link")..operationName.."|r", TSMAPI.Groups:FormatPath(path, true))
							end,
						}
						StaticPopupDialogs["TSM_APPLY_OPERATION"].tsmInfo = {path, moduleName, operationName, num}
						TSMAPI.Util:ShowStaticPopupDialog("TSM_APPLY_OPERATION")
					end
				end
				self:SetText()
			end,
		})
	
	local page = {
		{
			type = "ScrollFrame",
			layout = "Flow",
			children = {
				{
					type = "InlineGroup",
					layout = "flow",
					title = "Operation Management",
					children = {
						{
							type = "EditBox",
							label = L["Rename Operation"],
							value = operationName,
							relativeWidth = 0.5,
							callback = function(self,_,name)
								name = (name or ""):trim()
								if name == "" then return end
								if TSMObj.operations[name] then
									self:SetText("")
									return TSMObj:Printf(L["Error renaming operation. Operation with name '%s' already exists."], name)
								end
								TSMObj.operations[name] = TSMObj.operations[operationName]
								TSMObj.operations[operationName] = nil
								for _, groupPath in ipairs(groupList) do
									for i=1, #TSM.db.profile.groups[groupPath][moduleName] do
										if TSM.db.profile.groups[groupPath][moduleName][i] == operationName then
											TSM.db.profile.groups[groupPath][moduleName][i] = name
										end
									end
								end
								TSM.Modules:CheckOperationRelationships(moduleName)
								private:ModuleOptionsRefresh(TSMObj, name)
							end,
							tooltip = L["Give this operation a new name. A descriptive name will help you find this operation later."],
						},
						{
							type = "EditBox",
							label = L["Duplicate Operation"],
							relativeWidth = 0.5,
							callback = function(self,_,name)
								name = (name or ""):trim()
								if name == "" then return end
								if TSMObj.operations[name] then
									self:SetText("")
									return TSMObj:Printf(L["Error duplicating operation. Operation with name '%s' already exists."], name)
								end
								TSMObj.operations[name] = CopyTable(TSMObj.operations[operationName])
								TSM.Modules:CheckOperationRelationships(moduleName)
								private:ModuleOptionsRefresh(TSMObj, name)
							end,
							tooltip = L["Type in the name of a new operation you wish to create with the same settings as this operation."],
						},
						{
							type = "Button",
							text = L["Delete Operation"],
							relativeWidth = 1,
							callback = function()
								StaticPopupDialogs["TSM_DELETE_OPERATION"] = StaticPopupDialogs["TSM_DELETE_OPERATION"] or {
									text = "Are you sure you want to delete this operation?",
									button1 = DELETE,
									button2 = CANCEL,
									timeout = 0,
									OnAccept = function()
										local operationName, groupList, TSMObj, moduleName = unpack(StaticPopupDialogs["TSM_DELETE_OPERATION"].tsmInfo)
										TSMObj.operations[operationName] = nil
										for _, groupPath in ipairs(groupList) do
											for i=#TSM.db.profile.groups[groupPath][moduleName], 1, -1 do
												if TSM.db.profile.groups[groupPath][moduleName][i] == operationName then
													TSM.Groups:RemoveOperation(groupPath, moduleName, i)
												end
											end
										end
										TSM.Modules:CheckOperationRelationships(moduleName)
										private:ModuleOptionsRefresh(TSMObj)
									end,
								}
								StaticPopupDialogs["TSM_DELETE_OPERATION"].tsmInfo = {operationName, groupList, TSMObj, moduleName}
								TSMAPI.Util:ShowStaticPopupDialog("TSM_DELETE_OPERATION")
							end,
						},
					},
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = "Ignores",
					children = {
						{
							type = "Dropdown",
							label = L["Ignore Operation on Faction-Realms:"],
							list = factionrealmList,
							relativeWidth = 0.5,
							settingInfo = {operation, "ignoreFactionrealm"},
							multiselect = true,
							tooltip = L["This operation will be ignored when you're on any character which is checked in this dropdown."],
						},
						{
							type = "Dropdown",
							label = L["Ignore Operation on Characters:"],
							list = playerList,
							relativeWidth = 0.5,
							settingInfo = {operation, "ignorePlayer"},
							multiselect = true,
							tooltip = L["This operation will be ignored when you're on any character which is checked in this dropdown."],
						},
					},
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = "Import / Export",
					children = {
						{
							type = "EditBox",
							label = L["Import Operation Settings"],
							relativeWidth = 0.5,
							callback = function(self, _, value)
								value = value:trim()
								if value == "" then return end
								local valid, data = LibStub("AceSerializer-3.0"):Deserialize(value)
								if not valid then
									TSM:Print(L["Invalid import string."])
									self:SetFocus()
									return
								elseif data.module ~= moduleName then
									TSM:Print(L["Invalid import string."].." "..L["You appear to be attempting to import an operation from a different module."])
									self:SetText("")
									return
								end
								data.module = nil
								data.ignorePlayer = {}
								data.ignoreFactionrealm = {}
								data.relationships = {}
								TSMObj.operations[operationName] = data
								self:SetText("")
								TSM:Print(L["Successfully imported operation settings."])
								private:ModuleOptionsRefresh(TSMObj, operationName)
							end,
							tooltip = L["Paste the exported operation settings into this box and hit enter or press the 'Okay' button. Imported settings will irreversibly replace existing settings for this operation."],
						},
						{
							type = "Button",
							text = L["Export Operation"],
							relativeWidth = 0.5,
							callback = function()
								local data = CopyTable(operation)
								data.module = moduleName
								data.ignorePlayer = nil
								data.ignoreFactionrealm = nil
								data.relationships = nil
								private:ShowOperationExportFrame(LibStub("AceSerializer-3.0"):Serialize(data))
							end,
						},
					},
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Groups"],
					children = groupWidgets,
				},
			},
		},
	}
	
	TSMAPI.GUI:BuildOptions(container, page)
end

function TSMAPI.Operations:ShowRelationshipTab(obj, container, operation, settingInfo)
	local moduleName = gsub(obj.name, "TradeSkillMaster_", "")
	moduleName = gsub(obj.name, "TSM_", "")
	local operationList = {[""]=L["<No Relationship>"]}
	local operationListOrder = {""}
	local incomingRelationships = {}
	for name, data in pairs(obj.operations) do
		if data ~= operation then
			operationList[name] = name
			tinsert(operationListOrder, name)
		end
		for key, targetOperation in pairs(data.relationships) do
			if obj.operations[targetOperation] == operation then
				incomingRelationships[key] = name
			end
		end
	end
	sort(operationListOrder)
	
	local target = ""
	local children = {
		{
			type = "InlineGroup",
			layout = "Flow",
			children = {
				{
					type = "Label",
					text = L["Here you can setup relationships between the settings of this operation and other operations for this module. For example, if you have a relationship set to OperationA for the stack size setting below, this operation's stack size setting will always be equal to OperationA's stack size setting."],
					relativeWidth = 1,
				},
				{
					type = "HeadingLine",
				},
				{
					type = "Dropdown",
					label = L["Target Operation"],
					list = operationList,
					order = operationListOrder,
					relativeWidth = 0.5,
					value = target,
					callback = function(self, _, value)
						target = value
					end,
					tooltip = L["Creating a relationship for this setting will cause the setting for this operation to be equal to the equivalent setting of another operation."],
				},
				{
					type = "Button",
					text = L["Set All Relationships to Target"],
					relativeWidth = 0.5,
					callback = function()
						for _, inline in ipairs(settingInfo) do
							for _, widget in ipairs(inline) do
								local prev = operation.relationships[widget.key]
								if target == "" then
									operation.relationships[widget.key] = nil
								else
									operation.relationships[widget.key] = target
									if private:IsCircularRelationship(moduleName, operation, widget.key) then
										operation.relationships[widget.key] = prev
									end
								end
							end
						end
						container:ReloadTab()
					end,
					tooltip = L["Sets all relationship dropdowns below to the operation selected."],
				},
			},
		},
	}
	for _, inlineData in ipairs(settingInfo) do
		local inlineChildren = {}
		for _, dropdownData in ipairs(inlineData) do
			local dropdown = {
				type = "Dropdown",
				label = dropdownData.label,
				list = operationList,
				order = operationListOrder,
				relativeWidth = 0.5,
				value = operation.relationships[dropdownData.key] or "",
				callback = function(self, _, value)
					local previousValue = operation.relationships[dropdownData.key]
					if value == "" then
						operation.relationships[dropdownData.key] = nil
					else
						operation.relationships[dropdownData.key] = value
					end
					if private:IsCircularRelationship(moduleName, operation, dropdownData.key) then
						operation.relationships[dropdownData.key] = previousValue
						obj:Print("This relationship cannot be applied because doing so would create a circular relationship.")
						self:SetValue(operation.relationships[dropdownData.key] or "")
					end
				end,
				tooltip = L["Creating a relationship for this setting will cause the setting for this operation to be equal to the equivalent setting of another operation."],
			}
			tinsert(inlineChildren, dropdown)
		end
		local inlineGroup = {
			type = "InlineGroup",
			layout = "flow",
			title = inlineData.label,
			children = inlineChildren,
		}
		tinsert(children, inlineGroup)
	end
	
	
	local page = {
		{
			type = "ScrollFrame",
			layout = "list",
			children = children,
		},
	}
	
	TSMAPI.GUI:BuildOptions(container, page)
end



-- ============================================================================
-- Module Functions
-- ============================================================================

function Operations:LoadOperationOptions(parent)
	local tabs = {}

	for _, info in ipairs(private.operationInfo) do
		tinsert(tabs, {text=info.module, value=info.module})
	end

	if next(tabs) then
		sort(tabs, function(a, b)
			return a.text < b.text
		end)
	end

	tinsert(tabs, 1, {text=L["Help"], value="Help"})

	local tabGroup =  AceGUI:Create("TSMTabGroup")
	tabGroup:SetLayout("Fill")
	tabGroup:SetTabs(tabs)
	tabGroup:SetCallback("OnGroupSelected", function(_, _, value)
			tabGroup:ReleaseChildren()
			if value == "Help" then
				private:DrawOperationHelp(tabGroup)
			else
				for _, info in ipairs(private.operationInfo) do
					if info.module == value then
						info.callbackOptions(tabGroup, TSM.loadModuleOptionsTab and TSM.loadModuleOptionsTab.operation, TSM.loadModuleOptionsTab and TSM.loadModuleOptionsTab.group)
					end
				end
			end
		end)
	parent:AddChild(tabGroup)
	
	tabGroup:SelectTab(TSM.loadModuleOptionsTab and TSM.loadModuleOptionsTab.module or "Help")
end



-- ============================================================================
-- Operation Options Help Tab
-- ============================================================================

function private:DrawOperationHelp(container)
	local page = {
		{	-- scroll frame to contain everything
			type = "ScrollFrame",
			layout = "List",
			children = {
				{
					type = "InlineGroup",
					layout = "List",
					children = {
						{
							type = "Label",
							relativeWidth = 1,
							text = L["Use the tabs above to select the module for which you'd like to configure operations and general options."],
						},
					},
				},
			},
		},
	}
	
	TSMAPI.GUI:BuildOptions(container, page)
end



-- ============================================================================
-- Helper Functions
-- ============================================================================

function private:ModuleOptionsRefresh(TSMObj, ...)
	TSMObj.Options:UpdateTree()
	TSMObj.Options.treeGroup:SelectByPath(#TSMObj.Options.treeGroup.tree, ...)
	if select('#', ...) > 0 then
		TSMObj.Options.treeGroup.children[1]:SelectTab(#TSMObj.Options.treeGroup.children[1].tablist)
	end
end

function private:IsCircularRelationship(moduleName, operation, key, visited)
	visited = visited or {}
	if visited[operation] then return true end
	visited[operation] = true
	if not operation.relationships[key] then return end
	return private:IsCircularRelationship(moduleName, TSM.operations[moduleName][operation.relationships[key]], key, visited)
end

function private:ShowOperationExportFrame(text)
	local f = AceGUI:Create("TSMWindow")
	f:SetCallback("OnClose", function(self) AceGUI:Release(self) end)
	f:SetTitle("TradeSkillMaster - "..L["Export Operation"])
	f:SetLayout("Fill")
	f:SetHeight(300)
	
	local eb = AceGUI:Create("TSMMultiLineEditBox")
	eb:SetLabel(L["Operation Data"])
	eb:SetMaxLetters(0)
	eb:SetText(text)
	f:AddChild(eb)
	
	f.frame:SetFrameStrata("FULLSCREEN_DIALOG")
	f.frame:SetFrameLevel(100)
end