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
