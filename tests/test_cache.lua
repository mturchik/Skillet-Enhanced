local lu = require("luaunit")

TestCache = {}

function TestCache:test_emptyBlizzCountNotStale()
    lu.assertFalse(SkilletUtil.IsRecipeIndexCacheStale(0, {}, {}))
end

function TestCache:test_noCachedDataIsStale()
    lu.assertTrue(SkilletUtil.IsRecipeIndexCacheStale(3, { false, false, false }, nil))
end

function TestCache:test_allRecipesCachedNotStale()
    local headers = { true, false, false, true, false }
    local cached = { [2] = "a", [3] = "b", [5] = "c" }
    lu.assertFalse(SkilletUtil.IsRecipeIndexCacheStale(5, headers, cached))
end

function TestCache:test_missingRecipeIsStale()
    local headers = { true, false, false, true, false }
    local cached = { [2] = "a", [5] = "c" }
    lu.assertTrue(SkilletUtil.IsRecipeIndexCacheStale(5, headers, cached))
end

function TestCache:test_lastRowHeaderMissingCacheNotStale()
    -- Old logic falsely flagged stale when last Blizzard row was a header.
    local headers = { false, false, true }
    local cached = { [1] = "a", [2] = "b" }
    lu.assertFalse(SkilletUtil.IsRecipeIndexCacheStale(3, headers, cached))
end

function TestCache:test_newRecipeAtEndIsStale()
    local headers = { false, false, false }
    local cached = { [1] = "a", [2] = "b" }
    lu.assertTrue(SkilletUtil.IsRecipeIndexCacheStale(3, headers, cached))
end

function TestCache:test_findFirstStaleRecipeIndex()
    local headers = { true, false, false, true, false }
    local cached = { [2] = "a", [5] = "c" }
    lu.assertEquals(SkilletUtil.FindFirstStaleRecipeIndex(5, headers, cached), 3)
end

function TestCache:test_findFirstStaleRecipeIndexComplete()
    local headers = { true, false, false }
    local cached = { [2] = "a", [3] = "b" }
    lu.assertNil(SkilletUtil.FindFirstStaleRecipeIndex(3, headers, cached))
end

function TestCache:test_countNonHeaderRecipes()
    local headers = { true, false, false, true, false }
    lu.assertEquals(SkilletUtil.CountNonHeaderRecipes(5, headers), 3)
end

function TestCache:test_countCachedRecipes()
    local headers = { true, false, false, true, false }
    local cached = { [2] = "a", [5] = "c" }
    lu.assertEquals(SkilletUtil.CountCachedRecipes(5, headers, cached), 2)
end

function TestCache:test_computeScanPercent()
    lu.assertEquals(SkilletUtil.ComputeScanPercent(142, 380), 37)
    lu.assertEquals(SkilletUtil.ComputeScanPercent(0, 0), 0)
end

function TestCache:test_formatScanProgress()
    lu.assertEquals(
        SkilletUtil.FormatScanProgress("Engineering", 142, 380),
        "Engineering — 142/380 (37%)"
    )
end

local AZURE_RING_CACHE = ";1eff00|24027|Azure Moonstone Ring;d5;1;;"
local THICK_NECKLACE_LINK = "|cff0070dd|Hitem:31303:0:0:0:0:0:0:0:0|h[Thick Adamantite Necklace]|h|r"
local AZURE_RING_LINK = "|cff1eff00|Hitem:24027:0:0:0:0:0:0:0:0|h[Azure Moonstone Ring]|h|r"

function TestCache:test_getRecipeResultIdFromCacheString()
    lu.assertEquals(SkilletUtil.GetRecipeResultIdFromCacheString(AZURE_RING_CACHE), 24027)
    lu.assertNil(SkilletUtil.GetRecipeResultIdFromCacheString(nil))
end

function TestCache:test_mismatchedCacheStringIsStale()
    lu.assertTrue(SkilletUtil.IsCachedRecipeStringStale(AZURE_RING_CACHE, THICK_NECKLACE_LINK))
    lu.assertFalse(SkilletUtil.IsCachedRecipeStringStale(AZURE_RING_CACHE, AZURE_RING_LINK))
end

function TestCache:test_mismatchedIndexIsStale()
    local headers = { true, false, false }
    local cached = { [2] = AZURE_RING_CACHE, [3] = AZURE_RING_CACHE }
    local live_links = { [2] = AZURE_RING_LINK, [3] = THICK_NECKLACE_LINK }
    lu.assertTrue(SkilletUtil.IsRecipeIndexCacheStale(3, headers, cached, live_links))
    lu.assertEquals(SkilletUtil.FindFirstStaleRecipeIndex(3, headers, cached, live_links), 3)
end

function TestCache:test_missingLiveLinkDoesNotForceStale()
    lu.assertFalse(SkilletUtil.IsCachedRecipeStringStale(AZURE_RING_CACHE, nil))
end
