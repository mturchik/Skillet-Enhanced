local lu = require("luaunit")
local Fixtures = require("recipes")

TestFilter = {}

function TestFilter:test_emptyFilterMatchesAll()
    lu.assertTrue(SkilletUtil.RecipeMatchesFilter(Fixtures.recipe_alchemy, ""))
    lu.assertTrue(SkilletUtil.RecipeMatchesFilter(Fixtures.recipe_alchemy, nil))
end

function TestFilter:test_matchRecipeName()
    lu.assertTrue(SkilletUtil.RecipeMatchesFilter(Fixtures.recipe_alchemy, "agility"))
    lu.assertTrue(SkilletUtil.RecipeMatchesFilter(Fixtures.recipe_alchemy, "ELIXIR"))
end

function TestFilter:test_matchReagentName()
    lu.assertTrue(SkilletUtil.RecipeMatchesFilter(Fixtures.recipe_alchemy, "stranglekelp"))
    lu.assertTrue(SkilletUtil.RecipeMatchesFilter(Fixtures.recipe_alchemy, "goldthorn"))
end

function TestFilter:test_noMatch()
    lu.assertFalse(SkilletUtil.RecipeMatchesFilter(Fixtures.recipe_alchemy, "copper"))
    lu.assertFalse(SkilletUtil.RecipeMatchesFilter(Fixtures.recipe_blacksmith, "agility"))
end

function TestFilter:test_plainTextNotPattern()
    lu.assertFalse(SkilletUtil.RecipeMatchesFilter(Fixtures.recipe_alchemy, "."))
end
