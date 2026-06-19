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
