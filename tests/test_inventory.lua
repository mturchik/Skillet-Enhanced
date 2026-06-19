local lu = require("luaunit")

TestInventory = {}

function TestInventory:test_addReagentLinksDedupes()
    local links = {}
    local recipe = {
        [1] = { link = "|Hitem:2840|" },
        [2] = { link = "|Hitem:2840|" },
        [3] = { link = "|Hitem:3575|" },
    }

    SkilletUtil.AddReagentLinksFromRecipe(links, recipe, 8)

    lu.assertTrue(links["|Hitem:2840|"])
    lu.assertTrue(links["|Hitem:3575|"])
    local count = 0
    for _ in pairs(links) do
        count = count + 1
    end
    lu.assertEquals(2, count)
end

function TestInventory:test_computeCraftableCountsLimitedByScarcestReagent()
    local reagents = {
        { needed = 2, num = 10, numwbank = 10, vendor = false },
        { needed = 4, num = 8, numwbank = 12, vendor = false },
    }

    local num, numwbank = SkilletUtil.ComputeCraftableCounts(reagents, 1, true)
    lu.assertEquals(2, num)
    lu.assertEquals(3, numwbank)
end

function TestInventory:test_computeCraftableCountsWithAlts()
    local reagents = {
        { needed = 1, num = 0, numwbank = 0, numwalts = 5, vendor = false },
    }

    local _, _, numwalts = SkilletUtil.ComputeCraftableCounts(reagents, 2, true)
    lu.assertEquals(10, numwalts)
end
