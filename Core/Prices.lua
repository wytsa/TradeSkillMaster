-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file contains price related TSMAPI functions.

local TSM = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster") -- loads the localization table
local private = {context={}, itemValueKeyCache={}, moduleObjects=TSM.moduleObjects}


local ITEM_STRING_PATTERN = "b?a?t?t?l?[ei][pt]e[tm]:[0-9]+:?[0-9]*:?[0-9]*:?[0-9]*:?[0-9]*:?[0-9]*:?[0-9]*"

local MONEY_PATTERNS = {
	"([0-9]+g[ ]*[0-9]+s[ ]*[0-9]+c)", 	-- g/s/c
	"([0-9]+g[ ]*[0-9]+s)", 				-- g/s
	"([0-9]+g[ ]*[0-9]+c)", 				-- g/c
	"([0-9]+s[ ]*[0-9]+c)", 				-- s/c
	"([0-9]+g)", 								-- g
	"([0-9]+s)", 								-- s
	"([0-9]+c)",								-- c
}
local MATH_FUNCTIONS = {
	["avg"] = "self._avg",
	["min"] = "self._min",
	["max"] = "self._max",
	["first"] = "self._first",
	["check"] = "self._check",
}

local NAN = math.huge*0
local NAN_STR = tostring(NAN)
local function isNAN(num)
	return tostring(num) == NAN_STR
end
private.customPriceFunctions = {
	NAN = NAN,
	NAN_STR = NAN_STR,
	isNAN = isNAN,
	loopError = function(str)
		TSM:Printf(L["Loop detected in the following custom price:"].." "..TSMAPI.Design:GetInlineColor("link")..str.."|r")
	end,
	_avg = function(...)
		local total, count = 0, 0
		for i=1, select('#', ...) do
			local num = select(i, ...)
			if type(num) == "number" and not isNAN(num) then
				total = total + num
				count = count + 1
			end
		end
		if count == 0 then return NAN end
		return floor(total / count + 0.5)
	end,
	_min = function(...)
		local minVal
		for i=1, select('#', ...) do
			local num = select(i, ...)
			if type(num) == "number" and not isNAN(num) and (not minVal or num < minVal) then
				minVal = num
			end
		end
		return minVal or NAN
	end,
	_max = function(...)
		local maxVal
		for i=1, select('#', ...) do
			local num = select(i, ...)
			if type(num) == "number" and not isNAN(num) and (not maxVal or num > maxVal) then
				maxVal = num
			end
		end
		return maxVal or NAN
	end,
	_first = function(...)
		for i=1, select('#', ...) do
			local num = select(i, ...)
			if type(num) == "number" and not isNAN(num) then
				return num
			end
		end
		return NAN
	end,
	_check = function(...)
		if select('#', ...) > 3 then return NAN end
		local check, ifValue, elseValue = ...
		check = check or NAN
		ifValue = ifValue or NAN
		elseValue = elseValue or NAN
		return check > 0 and ifValue or elseValue
	end,
	priceHelper = function(itemString, key, extraParam)
		if not itemString then return NAN end
		local result
		if key == "convert" then
			result = TSMAPI:GetConvertCost(itemString, extraParam)
		elseif extraParam == "custom" then
			result = TSMAPI:GetCustomPriceSourceValue(itemString, key)
		else
			result = TSMAPI:GetItemValue(itemString, key)
		end
		return result or NAN
	end,
}

function private:CreateCustomPriceObj(func, origStr)
	local data = {isUnlocked=nil, globalContext=private.context, origStr=origStr}
	local proxy = newproxy(true)
	local mt = getmetatable(proxy)
	mt.__index = function(self, index)
		if private.customPriceFunctions[index] then
			return private.customPriceFunctions[index]
		elseif index == "globalContext" or index == "origStr" then
			return data[index]
		end
		if not data.isUnlocked then error("Attempt to access a hidden table", 2) end
		return data[index]
	end
	mt.__newindex = function(self, index, value)
		if not data.isUnlocked then error("Attempt to modify a hidden table", 2) end
		data[index] = value
	end
	mt.__call = function(self, item)
		data.isUnlocked = true
		local result = self.func(self, item)
		data.isUnlocked = false
		return result
	end
	mt.__metatable = false
	data.isUnlocked = true
	proxy.func = func
	data.isUnlocked = false
	return proxy
end



-- validates a price string that was passed into TSMAPI:ParseCustomPrice
local function ParsePriceString(str, badPriceSource)
	if tonumber(str) then
		return function() return tonumber(str) end
	end

	local origStr = str
	-- make everything lower case
	str = strlower(str)
	-- remove any colors around gold/silver/copper
	str = gsub(str, "\124cff[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]g\124r", "g")
	str = gsub(str, "\124cff[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]s\124r", "s")
	str = gsub(str, "\124cff[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]c\124r", "c")

	-- replace all formatted gold amount with their copper value
	local start = 1
	local goldAmountContinue = true
	while goldAmountContinue do
		goldAmountContinue = false
		local minFind = {}
		for _, pattern in ipairs(MONEY_PATTERNS) do
			local s, e, sub = strfind(str, pattern, start)
			if s and (not minFind.s or minFind.s > s) then
				minFind.s = s
				minFind.e = e
				minFind.sub = sub
			end
		end
		if minFind.s then
			local value = TSMAPI:UnformatTextMoney(minFind.sub)
			if not value then return end -- sanity check
			local preStr = strsub(str, 1, minFind.s-1)
			local postStr = strsub(str, minFind.e+1)
			str = preStr .. value .. postStr
			start = #str - #postStr + 1
			goldAmountContinue = true
		end
	end

	-- remove up to 1 occurance of convert(priceSource[, item])
	local convertPriceSource, convertItem
	local convertParams = strmatch(str, "convert%((.-)%)")
	if convertParams then
		local convertItemLink = strmatch(convertParams, "\124c.-\124r")
		local convertItemString = strmatch(convertParams, ITEM_STRING_PATTERN)
		if convertItemLink then -- check for itemLink in convert params
			convertItem = TSMAPI:GetItemString(convertItemLink)
			if not convertItem then
				return nil, L["Invalid item link."]  -- there's an invalid item link in the convertParams
			end
			convertPriceSource = strmatch(convertParams, "^ *(.-) *,")
		elseif convertItemString then -- check for itemString in convert params
			convertItem = convertItemString
			convertPriceSource = strmatch(convertParams, "^ *(.-) *,")
		else
			convertPriceSource = gsub(convertParams, ", *$", ""):trim()
		end

		local isValidPriceSource = nil
		for key in pairs(TSMAPI:GetPriceSources()) do
			if strlower(key) == convertPriceSource then
				isValidPriceSource = true
				break
			end
		end
		if not isValidPriceSource then
			return nil, L["Invalid price source in convert."]
		end
		local num = 0
		str, num = gsub(str, "convert%(.-%)", "~convert~")
		if num > 1 then
			return nil, L["A maximum of 1 convert() function is allowed."]
		end
	end
	
	while true do
		local itemLink = strmatch(str, "\124c.-\124r")
		if not itemLink then break end
		local itemString = TSMAPI:GetItemString(itemLink)
		if not itemString then return nil, L["Invalid item link."] end -- there's an invalid item link in the str
		str = gsub(str, TSMAPI:StrEscape(itemLink), itemString)
	end

	-- put a space at the start and end
	str = " "..str.." "
	-- make sure there's spaces on either side of math operators
	str = gsub(str, "[%-%+%/%*]", " %1 ")
	-- convert percentages to decimal numbers
	str = gsub(str, "([0-9%.]+)%%", "( %1 / 100 ) *")
	-- ensure a space before items and remove parentheses around items
	str = gsub(str, "%( ?("..ITEM_STRING_PATTERN..") ?%)", " %1")
	-- ensure a space on either side of parentheses and commas
	str = gsub(str, "[%(%),]", " %1 ")
	-- remove any occurances of more than one consecutive space
	str = gsub(str, " [ ]+", " ")

	-- ensure equal number of left/right parenthesis
	if select(2, gsub(str, "%(", "")) ~= select(2, gsub(str, "%)", "")) then return nil, L["Unbalanced parentheses."] end
	
	-- create array of valid price sources
	local priceSourceKeys = {}
	for key in pairs(TSMAPI:GetPriceSources()) do
		tinsert(priceSourceKeys, strlower(key))
	end
	for key in pairs(TSM.db.global.customPriceSources) do
		tinsert(priceSourceKeys, strlower(key))
	end

	-- validate all words in the string
	local parts = TSMAPI:SafeStrSplit(str:trim(), " ")
	local i = 1
	while i < #parts do
		local word = parts[i]
		if strmatch(word, "^[%-%+%/%*]$") then
			if i == #parts then
				return nil, L["Invalid operator at end of custom price."]
			end
			-- valid math operator
		elseif badPriceSource == word then
			-- price source that's explicitly invalid
			return nil, format(L["You cannot use %s as part of this custom price."], word)
		elseif tContains(priceSourceKeys, word) then
			-- valid price source
		elseif tonumber(word) then
			-- make sure it's not an itemID (incorrect)
			if i > 2 and parts[i-1] == "(" and tContains(priceSourceKeys, parts[i-2]) then
				return nil, L["Invalid parameter to price source."]
			end
			-- valid number
		elseif strmatch(word, "^"..ITEM_STRING_PATTERN.."$") then
			-- make sure previous word was a price source
			if i > 1 and tContains(priceSourceKeys, parts[i-1]) then
				-- valid item parameter
			else
				return nil, L["Item links may only be used as parameters to price sources."]
			end
		elseif word == "(" or word == ")" then
			-- valid parenthesis
		elseif word == "," then
			if not parts[i+1] or parts[i+1] == ")" then
				return nil, L["Misplaced comma"]
			else
				-- we're hoping this is a valid comma within a function, will be caught by loadstring otherwise
			end
		elseif MATH_FUNCTIONS[word] then
			if not parts[i+1] or parts[i+1] ~= "(" then
				return nil, format(L["Invalid word: '%s'"], word)
			end
			-- valid math function
		elseif word == "~convert~" then
			-- valid convert statement
		elseif word:trim() == "" then
			-- harmless extra spaces
		else
			return nil, format(L["Invalid word: '%s'"], word)
		end
		i = i + 1
	end

	for key in pairs(TSMAPI:GetPriceSources()) do
		-- replace all "<priceSource> itemString" occurances with the parameters to TSMAPI:GetItemValue (with the itemString)
		str = gsub(str, format(" (%s) (%s)", strlower(key), ITEM_STRING_PATTERN), format(" self.priceHelper(\"%%2\", \"%s\")", key))
		-- replace all "<priceSource>" occurances with the parameters to TSMAPI:GetItemValue (with _item for the item)
		str = gsub(str, format(" (%s)", strlower(key)), format(" self.priceHelper(_item, \"%s\")", key))
		if strlower(key) == convertPriceSource then
			convertPriceSource = key
		end
	end
	
	for key in pairs(TSM.db.global.customPriceSources) do
		-- price sources need to have at least 1 capital letter for this algorithm to work, so temporarily give it one
		local tempKey = strupper(strsub(key, 1, 1))..strsub(key, 2)
		-- replace all "<customPriceSource> itemString" occurances with the parameters to TSMAPI:GetCustomPriceSourceValue (with the itemString)
		str = gsub(str, format(" (%s) (%s)", strlower(key), ITEM_STRING_PATTERN), format(" self.priceHelper(\"%%2\", \"%s\", \"custom\")", tempKey))
		-- replace all "<customPriceSource>" occurances with the parameters to TSMAPI:GetCustomPriceSourceValue (with _item for the item)
		str = gsub(str, format(" (%s)", strlower(key)), format(" self.priceHelper(_item, \"%s\", \"custom\")", tempKey))
		-- change custom price sources to the correct capitalization
		str = gsub(str, tempKey, key)
	end

	-- replace "~convert~" appropriately
	if convertPriceSource then
		convertItem = convertItem and ('"'..convertItem..'"') or "_item"
		str = gsub(str, "~convert~", format("self.priceHelper(%s, \"convert\", \"%s\")", convertItem, convertPriceSource))
	end

	-- replace math functions with special custom function names
	for word, funcName in pairs(MATH_FUNCTIONS) do
		str = gsub(str, " "..word.." ", " "..funcName.." ")
	end

	-- finally, create and return the function
	local funcTemplate = [[
		return function(self, _item)
			local isTop
			local context = self.globalContext
			if not context.num then
				context.num = 0
				isTop = true
			end
			context.num = context.num + 1
			if context.num > 100 then
				if (context.lastPrint or 0) + 1 < time() then
					context.lastPrint = time()
					self.loopError(self.origStr)
				end
				return
			end
			
			local result = floor((%s) + 0.5)
			if context.num then
				context.num = context.num - 1
			end
			if isTop then
				context.num = nil
			end
			return not self.isNAN(result) and result or nil
		end
	]]
	local func, loadErr = loadstring(format(funcTemplate, str), "TSMCustomPrice")
	if loadErr then
		loadErr = gsub(loadErr:trim(), "([^:]+):.", "")
		return nil, L["Invalid function."].." Details: "..loadErr
	end
	local success, func = pcall(func)
	if not success then return nil, L["Invalid function."] end
	return private:CreateCustomPriceObj(func, origStr)
end

local customPriceCache = {}
local badCustomPriceCache = {}
function TSMAPI:ParseCustomPrice(priceString, badPriceSource)
	priceString = strlower(tostring(priceString):trim())
	if priceString == "" then return nil, L["Empty price string."] end
	if badCustomPriceCache[priceString] then return nil, badCustomPriceCache[priceString] end
	if customPriceCache[priceString] then return customPriceCache[priceString] end

	local func, err = ParsePriceString(priceString, badPriceSource)
	if err then
		badCustomPriceCache[priceString] = err
		return nil, err
	end

	customPriceCache[priceString] = func
	return func
end

function TSMAPI:GetCustomPriceSourceValue(itemString, key)
	local source = TSM.db.global.customPriceSources[key]
	if not source then return end
	local func = TSMAPI:ParseCustomPrice(source)
	if not func then return end
	return func(itemString)
end

function TSMAPI:GetPriceSources()
	local sources = {}
	for _, obj in pairs(private.moduleObjects) do
		if obj.priceSources then
			for _, info in ipairs(obj.priceSources) do
				sources[info.key] = info.label
			end
		end
	end
	return sources
end

function TSMAPI:GetItemValue(link, key)
	local itemLink = select(2, TSMAPI:GetSafeItemInfo(link)) or link
	if not itemLink then return end

	if private.itemValueKeyCache[key] then
		local info = private.itemValueKeyCache[key]
		local value = info.callback(itemLink, info.arg)
		return (type(value) == "number" and value > 0) and value or nil
	end
	-- look in module objects for this key
	for _, obj in pairs(private.moduleObjects) do
		if obj.priceSources then
			for _, info in ipairs(obj.priceSources) do
				if info.key == key then
					private.itemValueKeyCache[key] = info
					local value = info.callback(itemLink, info.arg)
					return (type(value) == "number" and value > 0) and value or nil
				end
			end
		end
	end
end



function TSMTEST()
	local function TestCustomPriceRun(priceStr, itemString)
		local func = TSMAPI:ParseCustomPrice(priceStr)
		func(itemString)
		
		local sg, st = 0, 0
		collectgarbage("stop")
		sg = collectgarbage("count")
		st = debugprofilestop()
		
		for i=1, 10000 do
			local p = func(itemString)
		end
		
		local totalTime = debugprofilestop() - st
		local totalMem = collectgarbage("count") - sg
		collectgarbage("restart")
		print(format("Finished in %.2fus and used %d bytes of memory: %s", totalTime/10, totalMem*1024/10000, priceStr))
	end
	
	local itemString = "item:79255:0:0:0:0:0:0"
	for src in pairs(TSMAPI:GetPriceSources()) do
		TestCustomPriceRun(src, itemString)
	end
	TestCustomPriceRun("check(max(2g, avg(20g + dbmarket / 2, first(vendorbuy, dbminbuyout)), min(20g, 1g)), 20g, 10g)", itemString)
end

function TSMTEST2()
	local function TestCustomPriceCreate(priceStr)
		local sg, st = 0, 0
		collectgarbage("stop")
		sg = collectgarbage("count")
		st = debugprofilestop()
		
		local func
		for i=1, 1000 do
			func = ParsePriceString(priceStr)
		end
		
		local totalTime = debugprofilestop() - st
		local totalMem = collectgarbage("count") - sg
		collectgarbage("restart")
		print(format("Finished in %.2fus and used %d bytes of memory: %s = |cff00ffff%d|r", totalTime, totalMem*1024/1000, priceStr, func()))
	end
	
	ParsePriceString("3g20s18c+20g")
	TestCustomPriceCreate("3g20s18c+20g+vendorsell(item:72092)")
	TestCustomPriceCreate("check(max(2g, avg(20g + dbmarket / 2, first(vendorbuy, dbminbuyout)), min(20g, 1g)), 20g, 10g)")
end