local lu = require("luaunit")
local Fixtures = require("recipes")

TestSort = {}

function TestSort:test_compareRecipeByName()
    lu.assertTrue(SkilletUtil.CompareRecipeByName(
        { name = "Apple" },
        { name = "Banana" }
    ))
    lu.assertFalse(SkilletUtil.CompareRecipeByName(
        { name = "Banana" },
        { name = "Apple" }
    ))
end

function TestSort:test_compareRecipeByNameNilHandling()
    lu.assertFalse(SkilletUtil.CompareRecipeByName(nil, { name = "A" }))
    lu.assertTrue(SkilletUtil.CompareRecipeByName({ name = "A" }, nil))
    lu.assertTrue(SkilletUtil.CompareRecipeByName(nil, nil))
end

function TestSort:test_mapSortedIndexAscendingDisplay()
    -- UI index 2 in ascending display maps to Blizzard index 1
    lu.assertEquals(1, SkilletUtil.MapSortedRecipeIndex(2, Fixtures.sorted_recipes_asc, false))
end

function TestSort:test_mapSortedIndexDescendingDisplay()
    lu.assertEquals(1, SkilletUtil.MapSortedRecipeIndex(2, Fixtures.sorted_recipes_asc, true))
end

function TestSort:test_mapSortedIndexPassthroughWhenEmpty()
    lu.assertEquals(5, SkilletUtil.MapSortedRecipeIndex(5, {}, false))
end

function TestSort:test_mapSortedIndexFirstAndLast()
    lu.assertEquals(2, SkilletUtil.MapSortedRecipeIndex(1, Fixtures.sorted_recipes_asc, false))
    lu.assertEquals(3, SkilletUtil.MapSortedRecipeIndex(3, Fixtures.sorted_recipes_asc, false))
end
