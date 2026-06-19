local lu = require("luaunit")
local Fixtures = require("recipes")

TestLinks = {}

function TestLinks:test_squishItemLink()
    lu.assertEquals(Fixtures.ITEM_SQUISHED, SkilletUtil.SquishLink(Fixtures.ITEM_LINK))
end

function TestLinks:test_squishEnchantLink()
    lu.assertEquals(Fixtures.ENCHANT_SQUISHED, SkilletUtil.SquishLink(Fixtures.ENCHANT_LINK))
end

function TestLinks:test_unsquishItemLink()
    local link, isenchant = SkilletUtil.UnsquishLink(Fixtures.ITEM_SQUISHED)
    lu.assertEquals(Fixtures.ITEM_LINK, link)
    lu.assertFalse(isenchant)
end

function TestLinks:test_unsquishEnchantLink()
    local link, isenchant = SkilletUtil.UnsquishLink(Fixtures.ENCHANT_SQUISHED)
    lu.assertEquals(Fixtures.ENCHANT_LINK, link)
    lu.assertTrue(isenchant)
end

function TestLinks:test_itemLinkRoundTrip()
    local squished = SkilletUtil.SquishLink(Fixtures.ITEM_LINK)
    local restored = SkilletUtil.UnsquishLink(squished)
    lu.assertEquals(Fixtures.ITEM_LINK, restored)
end

function TestLinks:test_getItemIDFromItemLink()
    lu.assertEquals(13928, SkilletUtil.GetItemIDFromLink(Fixtures.ITEM_LINK))
end

function TestLinks:test_getItemIDFromEnchantLink()
    lu.assertEquals(7421, SkilletUtil.GetItemIDFromLink(Fixtures.ENCHANT_LINK))
end

function TestLinks:test_getItemIDFromNil()
    lu.assertNil(SkilletUtil.GetItemIDFromLink(nil))
end

function TestLinks:test_getItemIDFromMalformed()
    lu.assertNil(SkilletUtil.GetItemIDFromLink("not a link"))
end
