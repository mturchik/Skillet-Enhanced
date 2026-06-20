local lu = require("luaunit")

TestCache = {}

local AZURE_RING_CACHE = ";1eff00|24027|Azure Moonstone Ring;d5;1;;"
local THICK_NECKLACE_LINK = "|cff0070dd|Hitem:31303:0:0:0:0:0:0:0:0|h[Thick Adamantite Necklace]|h|r"
local AZURE_RING_LINK = "|cff1eff00|Hitem:24027:0:0:0:0:0:0:0:0|h[Azure Moonstone Ring]|h|r"

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
    lu.assertEquals(SkilletUtil.ComputeScanPercent(119, 36), 100)
end

function TestCache:test_countNonHeaderRecipesUpTo()
    local headers = { true, false, false, true, false }
    lu.assertEquals(SkilletUtil.CountNonHeaderRecipesUpTo(5, headers, 0), 0)
    lu.assertEquals(SkilletUtil.CountNonHeaderRecipesUpTo(5, headers, 3), 2)
    lu.assertEquals(SkilletUtil.CountNonHeaderRecipesUpTo(5, headers, 5), 3)
end

function TestCache:test_syncScanSessionProgress()
    local headers = { true, false, false, true, false }
    local cached = { [2] = "a", [3] = "b" }
    local session = {
        blizz_count = 5,
        is_header = headers,
        forced = false,
        next_index = 4,
    }
    SkilletUtil.SyncScanSessionProgress(session, cached, nil)
    lu.assertEquals(session.recipe_total, 3)
    lu.assertEquals(session.recipe_done, 2)
    lu.assertEquals(session.recipe_done_display, 2)

    session.forced = true
    session.next_index = 4
    SkilletUtil.SyncScanSessionProgress(session, cached, nil)
    lu.assertEquals(session.recipe_done, 2)
    lu.assertEquals(session.recipe_done_display, 2)

    SkilletUtil.SyncScanSessionProgress(session, cached, 1)
    lu.assertEquals(session.recipe_done, 2)
    lu.assertEquals(session.recipe_done_display, 2)
end

function TestCache:test_countFreshCachedRecipes()
    local headers = { true, false, false }
    local cached = { [2] = AZURE_RING_CACHE, [3] = AZURE_RING_CACHE }
    local live_links = { [2] = AZURE_RING_LINK, [3] = THICK_NECKLACE_LINK }
    lu.assertEquals(SkilletUtil.CountCachedRecipes(3, headers, cached), 2)
    lu.assertEquals(SkilletUtil.CountFreshCachedRecipes(3, headers, cached, live_links), 1)
end

function TestCache:test_syncScanSessionProgressStaleNotComplete()
    local headers = { true, false, false }
    local cached = { [2] = AZURE_RING_CACHE, [3] = AZURE_RING_CACHE }
    local live_links = { [2] = AZURE_RING_LINK, [3] = THICK_NECKLACE_LINK }
    local session = {
        blizz_count = 3,
        is_header = headers,
        live_links = live_links,
        forced = false,
        next_index = 3,
    }
    SkilletUtil.SyncScanSessionProgress(session, cached, nil)
    lu.assertEquals(session.recipe_total, 2)
    lu.assertEquals(session.recipe_done_display, 1)
end

function TestCache:test_syncScanSessionProgressMonotonicDisplay()
    local headers = { true, false, false, true, false }
    local cached = { [2] = "a", [3] = "b", [5] = "c" }
    local session = {
        blizz_count = 5,
        is_header = headers,
        forced = false,
        next_index = 5,
        recipe_done_display = 3,
    }
    cached[3] = nil
    SkilletUtil.SyncScanSessionProgress(session, cached, 4)
    lu.assertEquals(session.recipe_done, 2)
    lu.assertEquals(session.recipe_done_display, 3)

    SkilletUtil.SyncScanSessionProgress(session, cached, 5)
    lu.assertEquals(session.recipe_done, 3)
    lu.assertEquals(session.recipe_done_display, 3)
end

function TestCache:test_isScanSessionUIActive()
    lu.assertFalse(SkilletUtil.IsScanSessionUIActive(nil))
    lu.assertFalse(SkilletUtil.IsScanSessionUIActive({ pending = true, profession = "Engineering" }))
    lu.assertTrue(SkilletUtil.IsScanSessionUIActive({ pending = false, profession = "Engineering" }))
    lu.assertTrue(SkilletUtil.IsScanSessionUIActive({
        pending = false,
        waiting_retry = true,
        profession = "Engineering",
        recipe_done = 30,
        recipe_total = 380,
    }))
end

function TestCache:test_isScanSessionRunnable()
    lu.assertFalse(SkilletUtil.IsScanSessionRunnable(nil))
    lu.assertFalse(SkilletUtil.IsScanSessionRunnable({ pending = true, profession = "Engineering" }))
    lu.assertTrue(SkilletUtil.IsScanSessionRunnable({ pending = false, profession = "Engineering" }))
    lu.assertFalse(SkilletUtil.IsScanSessionRunnable({
        pending = false,
        waiting_retry = true,
        profession = "Engineering",
    }))
end

function TestCache:test_syncScanSessionBlizzCount()
    local session = { blizz_count = 0, recipe_total = 0 }
    SkilletUtil.SyncScanSessionBlizzCount(session, 5)
    lu.assertEquals(session.blizz_count, 5)
    lu.assertEquals(session.recipe_total, SkilletUtil.CountNonHeaderRecipes(5, session.is_header))
    lu.assertEquals(#session.is_header, 5)
end

function TestCache:test_formatScanProgress()
    lu.assertEquals(
        SkilletUtil.FormatScanProgress("Engineering", 142, 380),
        "Engineering — 142/380 (37%)"
    )
end

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

function TestCache:test_resyncScanRewindsCursorWhenEarlierRowStale()
    local session = {
        blizz_count = 2,
        next_index = 5,
        is_header = { false, false },
        live_links = { [1] = "a", [2] = "b" },
    }
    local cached = { [1] = "a" }
    local changed = SkilletUtil.ResyncScanSessionAfterRecipeListChange(session, 3, cached)
    lu.assertTrue(changed)
    lu.assertEquals(3, session.blizz_count)
    lu.assertEquals(2, session.next_index)
end

function TestCache:test_resyncScanKeepsCursorWhenStaleIsAhead()
    local session = {
        blizz_count = 3,
        next_index = 2,
        is_header = { false, false, false },
        live_links = { [1] = "a", [2] = "b", [3] = "c" },
    }
    local cached = { [1] = "a", [2] = "b" }
    local changed = SkilletUtil.ResyncScanSessionAfterRecipeListChange(session, 4, cached)
    lu.assertTrue(changed)
    lu.assertEquals(4, session.blizz_count)
    lu.assertEquals(2, session.next_index)
end
