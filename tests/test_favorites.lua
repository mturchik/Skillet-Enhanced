local lu = require("luaunit")

TestFavorites = {}

function TestFavorites:test_is_recipe_id_favorited()
    local favorites = {
        Blacksmithing = {
            [12345] = true,
        },
    }

    lu.assertTrue(SkilletUtil.IsRecipeIdFavorited(favorites, "Blacksmithing", 12345))
    lu.assertFalse(SkilletUtil.IsRecipeIdFavorited(favorites, "Blacksmithing", 99999))
    lu.assertFalse(SkilletUtil.IsRecipeIdFavorited(favorites, "Alchemy", 12345))
    lu.assertFalse(SkilletUtil.IsRecipeIdFavorited(nil, "Blacksmithing", 12345))
end
