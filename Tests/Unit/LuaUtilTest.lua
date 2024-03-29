-- boilerplate requires
package.path = package.path .. ";" .. os.getenv("TSM_FAKES_PATH") .. "?.lua"
require('tsmunit')
luaunit = require('luaunit')

-- code under test
require('CoreAPI.LuaUtil')


TestRound = {}
function TestRound:testPositive()
    luaunit.assertEquals(TSMAPI.Util:Round(1.234, 0.01), 1.23)
    luaunit.assertEquals(TSMAPI.Util:Round(1.235, 0.01), 1.24)
    luaunit.assertEquals(TSMAPI.Util:Round(1.236, 0.01), 1.24)
end

function TestRound:testNegative()
    luaunit.assertEquals(TSMAPI.Util:Round(-1.234, 0.01), -1.23)
    luaunit.assertEquals(TSMAPI.Util:Round(-1.235, 0.01), -1.24)
    luaunit.assertEquals(TSMAPI.Util:Round(-1.236, 0.01), -1.24)
end

function TestRound:testSingleParameter()
    luaunit.assertEquals(TSMAPI.Util:Round(1.4), 1)
    luaunit.assertEquals(TSMAPI.Util:Round(1.5), 2)
    luaunit.assertEquals(TSMAPI.Util:Round(1.6), 2)
end


TestWipeOrCreateTable = {}
function TestWipeOrCreateTable:testCreate()
	luaunit.assertItemsEquals(TSMAPI.Util:WipeOrCreateTable(nil), {})
end

function TestWipeOrCreateTable:testWipe()
	luaunit.assertItemsEquals(TSMAPI.Util:WipeOrCreateTable({1,2,"3","4"}), {})
end


TestSafeStrSplit = {}
function TestSafeStrSplit:TestSplit()
	luaunit.assertItemsEquals(TSMAPI.Util:SafeStrSplit("a,b,c,d",","), {"a","b","c","d"})
end


TestSelect = {}
function TestSelect:TestNumber()
	luaunit.assertEquals(TSMAPI.Util:Select(3, "a","b","c","d","e"), "c")
end

function TestSelect:TestTable()
	luaunit.assertItemsEquals({TSMAPI.Util:Select({1,3,5}, "a","b","c","d","e")}, {"a","c","e"})
end


os.exit(luaunit.LuaUnit.run())
