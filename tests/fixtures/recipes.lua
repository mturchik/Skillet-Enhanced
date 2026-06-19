Fixtures = {}

Fixtures.ITEM_LINK = "|cffffffff|Hitem:13928:0:0:0:0:0:0:0:0|h[Grilled Squid]|h|r"
Fixtures.ITEM_SQUISHED = "ffffff|13928|Grilled Squid"
Fixtures.ENCHANT_LINK = "|cffffd000|Henchant:7421|h[Runed Copper Rod]|h|r"
Fixtures.ENCHANT_SQUISHED = "|-7421|Runed Copper Rod"

Fixtures.recipe_alchemy = {
    name = "Elixir of Agility",
    link = "|cffffffff|Hitem:9187:0:0:0:0:0:0:0|h[Elixir of Agility]|h|r",
    [1] = { name = "Stranglekelp", link = "|cffffffff|Hitem:3820:0:0:0:0:0:0:0|h[Stranglekelp]|h|r" },
    [2] = { name = "Goldthorn", link = "|cffffffff|Hitem:3821:0:0:0:0:0:0:0|h[Goldthorn]|h|r" },
}

Fixtures.recipe_blacksmith = {
    name = "Copper Bracers",
    link = "|cffffffff|Hitem:2852:0:0:0:0:0:0:0|h[Copper Bracers]|h|r",
    [1] = { name = "Copper Bar", link = "|cffffffff|Hitem:2840:0:0:0:0:0:0:0|h[Copper Bar]|h|r" },
}

Fixtures.sorted_recipes_asc = { 3, 1, 2 }

return Fixtures
