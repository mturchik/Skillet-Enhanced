local lu = require("luaunit")

TestQueue = {}

function TestQueue:test_appendNewEntry()
    local list = {}
    SkilletUtil.UpdateQueuedList(list, "Alice", "Copper Bar", "|Hitem:2840|", 4)
    lu.assertEquals(1, #list)
    lu.assertEquals("Copper Bar", list[1].name)
    lu.assertEquals(4, list[1].count)
    lu.assertEquals("Alice", list[1].player)
end

function TestQueue:test_mergeExistingEntry()
    local list = {
        { name = "Copper Bar", link = "|Hitem:2840|", count = 2, player = "Alice" },
    }
    SkilletUtil.UpdateQueuedList(list, "Alice", "Copper Bar", "|Hitem:2840|", 3)
    lu.assertEquals(1, #list)
    lu.assertEquals(5, list[1].count)
    lu.assertEquals("Alice", list[1].player)
end

function TestQueue:test_appendPlayerName()
    local list = {
        { name = "Copper Bar", link = "|Hitem:2840|", count = 2, player = "Alice" },
    }
    SkilletUtil.UpdateQueuedList(list, "Bob", "Copper Bar", "|Hitem:2840|", 1)
    lu.assertEquals(3, list[1].count)
    lu.assertEquals("Alice, Bob", list[1].player)
end

function TestQueue:test_doesNotDuplicatePlayerName()
    local list = {
        { name = "Goldthorn", link = "|Hitem:3821|", count = 1, player = "Alice" },
    }
    SkilletUtil.UpdateQueuedList(list, "Alice", "Goldthorn", "|Hitem:3821|", 2)
    lu.assertEquals(3, list[1].count)
    lu.assertEquals("Alice", list[1].player)
end

function TestQueue:test_findRecipeIndexAfterLearnShiftsList()
    local gold_core = "Gold Power Core;2840|link;o1;;"
    local bronze = "Bronze Framework;2841|link;o1;;"
    local gyro = "Gyrochronatom;2842|link;o1;;"

    local new_data = {
        [1] = gyro,
        [2] = bronze,
        [4] = gold_core,
    }

    lu.assertEquals(4, SkilletUtil.FindRecipeIndexByDataString(new_data, gold_core))
    lu.assertEquals(2, SkilletUtil.FindRecipeIndexByDataString(new_data, bronze))
    lu.assertNil(SkilletUtil.FindRecipeIndexByDataString(new_data, "missing"))
end

function TestQueue:test_findRecipeIndexByItemId()
    local ids = {
        [1] = 2842,
        [2] = 2841,
        [4] = 2840,
    }

    lu.assertEquals(4, SkilletUtil.FindRecipeIndexByItemId(ids, 2840))
    lu.assertEquals(1, SkilletUtil.FindRecipeIndexByItemId(ids, 2842))
    lu.assertNil(SkilletUtil.FindRecipeIndexByItemId(ids, 9999))
end
