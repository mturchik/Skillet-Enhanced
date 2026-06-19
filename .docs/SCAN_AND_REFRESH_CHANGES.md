# Skillet — Scan, Cache, and UI Refresh Changes

This document records the behavioral and architectural changes made to reduce unnecessary tradeskill scanning and to tier UI refresh work. It is written as an explicit **before → after** reference so the intent of each pattern change is clear.

**Scope:** WotLK 3.3.5a (`Interface: 30300`). No Retail APIs. Recipe cache still persists in `SkilletDB.server.recipes[character][profession]`.

**Related manual checks:** `.docs/MANUAL_TEST_CHECKLIST.md` steps 16–23.

---

## Executive summary

| Area | Before | After |
|------|--------|-------|
| When recipes are scanned | Often on every window open, every bag change, every craft, and during list paint | Only when the saved cache is **actually stale** (missing recipe data), on manual rescan, or on incomplete scan retry |
| When inventory counts update | Full window refresh (including possible recipe rescan) | Targeted inventory-count refresh; bag changes never trigger recipe scan |
| UI refresh on minor events | Single monolithic `UpdateTradeSkillWindow()` for almost everything | Tiered refresh: chrome, recipe list, inventory counts, or full update |
| Learn recipe while open | Stale cache; blank rows; queue index drift | Stale detection triggers one rescan; selection and queue remapped by stable recipe string |
| Session start | No login scan (unchanged) | Still no login scan; reopen with valid SavedVariables skips scan |

---

## Part 1 — Recipe cache and scanning

### 1.1 Previous functionality (before)

Skillet stores compressed recipe strings per profession in SavedVariables via **SkilletStitch**. A **scan** (`ScanTrade`) walks every Blizzard tradeskill index while the profession window is open and writes those strings to `stitch.data[profession][index]`.

**When scans were triggered (problematic behavior):**

1. **Window open** — Skillet and Stitch both scanned on `TRADE_SKILL_SHOW`, often producing duplicate scans.
2. **Stale detection was wrong** — `cache_recipes_if_needed` treated the cache as missing if the *last* Blizzard row had no cached data. Because the last row is often a **header**, the cache was almost always considered incomplete.
3. **Count comparison was wrong** — Staleness logic compared `GetNumTradeSkills()` (includes headers) to `#stitch.data[prof]` (Lua length on a sparse table). These rarely matched even when every recipe was cached.
4. **Every bag change** — Debounced `BAG_UPDATE` called `cache_recipes_if_needed`, which could trigger a full recipe scan after looting or crafting.
5. **Bag change while window closed** — Set `need_rescan_on_open = true`, which **forced** a full recipe scan on the next open even when SavedVariables were complete.
6. **List paint** — If a visible row lacked decoded cache data, `paint_recipe_scroll_list` called `RescanTrade(false)` immediately.
7. **Skill-up chat** — `CHAT_MSG_SKILL` always called `SkilletStitch_AutoRescan()` → `ScanTrade()`, including routine skill-ups during crafting.
8. **TRADE_SKILL_UPDATE** — Always scheduled a full UI refresh; did not distinguish “recipe list changed” from “craft finished, counts changed”.

**What did not change (still true):**

- No scan at login/reload; cache is loaded from SavedVariables in `OnEnable`.
- Scan requires an open profession window (Blizzard API constraint).
- Manual **Rescan** button still forces a full scan.

---

### 1.2 New functionality (after)

**Core rule:** A recipe scan runs only when `IsRecipeCacheStale(trade)` is true, the user forces rescan, or Stitch’s incomplete-link retry (`shred`) schedules `AutoRescan`.

**Staleness detection (`IsRecipeCacheStale` / `IsRecipeIndexCacheStale`):**

- Walk indices `1 .. GetNumTradeSkills()`.
- Skip rows where `GetTradeSkillInfo(i)` returns `skillType == "header"`.
- For every other index, require `stitch.data[trade][i]` to exist.
- Empty Blizzard list → not stale (nothing to scan).

**Scan trigger matrix (after):**

| Event | Recipe scan? | What runs instead |
|-------|--------------|-------------------|
| Login / `/reload` | No | Load SavedVariables only |
| Open profession, cache complete | No | UI refresh from saved cache |
| Open profession, cache incomplete | Yes (once) | `cache_recipes_if_needed` → `RescanTrade` |
| Reopen same profession same session | No | Stitch skips scan if not stale |
| Craft / loot (window open) | No | `internal_RefreshInventoryCounts` (debounced 250 ms) |
| Craft / loot (window closed) | No | Flag `need_inventory_refresh_on_open`; counts refresh on next show |
| Learn recipe (window open) | Yes | `TRADE_SKILL_UPDATE` → stale → one rescan + queue/selection remap |
| `CHAT_MSG_SKILL` (skill-up) | Only if stale | Guarded `AutoRescan` |
| Scroll recipe list | No | `internal_RefreshRecipeList` |
| Manual Rescan button | Yes | `RescanTrade(true)` |

---

### 1.3 Pattern change — staleness check

| | Before | After | Intent |
|---|--------|-------|--------|
| **Algorithm** | Compare row counts; require data at last index | Per-index check; skip headers | Last row is often a header; count mismatch was a false positive |
| **Implementation** | Inline in `cache_recipes_if_needed` | `SkilletUtil.IsRecipeIndexCacheStale` (testable) + `Skillet:IsRecipeCacheStale` (live API) | Correctness + unit tests in `tests/test_cache.lua` |
| **`GetNumSkills`** | `#self.data[prof]` | Max numeric key in sparse table | `#` under-counted cached recipes |

---

### 1.4 Pattern change — who calls `ScanTrade`

| Caller | Before | After | Intent |
|--------|--------|-------|--------|
| `SkilletStitch:TRADE_SKILL_SHOW` | Always `ScanTrade()` | Skip if Skillet scan in progress, just completed, or cache not stale | Eliminate duplicate scan on every open |
| `cache_recipes_if_needed` | Stale if last row empty or counts differ | Stale only via `IsRecipeCacheStale` | Scan on open only when data actually missing |
| `Skillet_rescan_bags` | Called `cache_recipes_if_needed` then full UI update | `internal_RefreshInventoryCounts` only | Bag changes affect counts, not recipe definitions |
| `need_rescan_on_open` | Forced `cache_recipes_if_needed(..., true)` on next open | Renamed `need_inventory_refresh_on_open`; triggers inventory refresh only | Mats changed offline ≠ recipes changed |
| `paint_recipe_scroll_list` | `RescanTrade(false)` on nil cache during paint | Removed | Paint must not side-effect scan; `TRADE_SKILL_UPDATE` handles real staleness |
| `SkilletStitch_AutoRescan` | Always scanned | Skip if scan in progress or cache not stale | Skill-ups during craft are not learn events |

---

### 1.5 Pattern change — rescan side effects (selection and queue)

When a rescan **does** run (learn recipe, first open, manual), indices shift. New helpers preserve user state:

| | Before | After | Intent |
|---|--------|-------|--------|
| Selected recipe | Could point at wrong row after rescan | `capture_selected_recipe` / `restore_selected_recipe` match by stored recipe string | Selection follows recipe, not index |
| Queue entries | Stored Blizzard index only; drift on learn | `RemapQueueAfterRescan` in `SkilletQueue.lua`; also called from `ProcessQueue` | Queue keeps crafting the intended recipe |
| `SetSelectedSkill` | UI-only selection | Calls `SelectTradeSkill` for ArmorCraft compatibility | External mods see correct Blizzard selection |
| `ScanCompleted` | UI refresh when scan was Skillet-initiated | Always remaps queue, restores selection, resorts, full UI refresh | Learn-while-open and post-scan consistency |

---

## Part 2 — UI refresh tiering

### 2.1 Previous functionality (before)

Almost every event and option toggle called **`UpdateTradeSkillWindow()`** → **`internal_UpdateTradeSkillWindow()`**, which:

- Refreshed title, rank, filters, sorting chrome
- Rebuilt the full recipe scroll list
- Called `GetItemCount` (and alt lookup) per visible reagent repeatedly
- Updated details panel and queue
- Ran on scroll, bag update, queue change, filter change, transparency change, etc.

This was correct but expensive; bag and scroll events caused unnecessary work and contributed to “feels like scanning” behavior when combined with recipe rescan.

---

### 2.2 New functionality (after)

**Tiered refresh API** in `UI/MainFrame.lua`:

| Function | Updates | Typical callers |
|----------|---------|-----------------|
| `internal_RefreshWindowChrome()` | Title, rank bar, filter UI, frame chrome | Transparency, scale options |
| `internal_RefreshRecipeList(syncSelection)` | Recipe scroll buttons only | Scroll, filter, display options |
| `internal_RefreshInventoryCounts()` | Craftable `[n]` brackets via batched snapshot | Bag update, queue change, bank/alt option |
| `internal_UpdateTradeSkillWindow()` | All of the above | Trade change, scan complete, structural changes |

**Route events to the narrowest tier** — full refresh only when recipe structure or scan data changes.

---

### 2.3 Pattern change — inventory count batching

| | Before | After | Intent |
|---|--------|-------|--------|
| Reagent counts | Each `reagentmeta` access called `GetItemCount` live | `BuildInventorySnapshot` / `SetInventorySnapshot` during refresh; snapshot cleared after paint | One pass over unique links per refresh |
| Hide uncraftable filter | Could call `GetItemCount` per recipe during filter | Optional `craftable_count_cache` built once per full refresh | Large professions (Engineering) stay responsive |
| Stitch API | N/A | `SetInventorySnapshot`, `ClearInventorySnapshot`, `BuildInventorySnapshot` | Snapshot scoped to refresh; live API fallback when no snapshot |

Helpers and tests: `SkilletUtil.AddReagentLinksFromRecipe`, `ComputeCraftableCounts` — `tests/test_inventory.lua`.

---

### 2.4 Pattern change — event → refresh routing

| Event / action | Before | After |
|----------------|--------|-------|
| `SkillList_OnScroll` | `UpdateTradeSkillWindow()` | `internal_RefreshRecipeList(false)` |
| `Skillet_rescan_bags` | `cache_recipes_if_needed` + full window | `internal_RefreshInventoryCounts` |
| `QueueChanged` (debounced) | `UpdateTradeSkillWindow` | `internal_RefreshInventoryCounts` |
| `UpdateFilter` | Full window | `internal_RefreshRecipeList(true)` |
| Options: craft counts, enhanced display, required level | Full window | `internal_RefreshRecipeList(true)` |
| Options: transparency, scale | Full window | `internal_RefreshWindowChrome()` |
| Options: bank/alt counts | Full window | `internal_RefreshInventoryCounts()` |
| `TRADE_SKILL_UPDATE` (not stale) | Full window (debounced) | Full window (immediate reset + update; no scan) |
| `ScanCompleted` | Partial (scan-in-progress path only) | Queue remap, selection restore, resort, full window |

Public hook **`Skillet:UpdateTradeSkillWindow()`** in `ThirdPartyHooks.lua` is unchanged — it still delegates to `internal_UpdateTradeSkillWindow()` for third-party mods.

---

## Part 3 — Session and persistence behavior

### 3.1 Before and after (unchanged vs changed)

| Scenario | Before | After |
|----------|--------|-------|
| `/reload`, logout, client restart | Cache in SavedVariables; no login scan | **Same** — no login scan |
| First open profession ever on character | Scan once | **Same** — scan once |
| Reopen profession with complete SavedVariables | Often scanned again (false stale + Stitch always scanned + `need_rescan_on_open`) | **No scan** if cache matches live list |
| Learn recipe on previous session, open today | Scan once (cache missing new index) | **Same** — scan once |
| Bag changed while window was closed | Forced full recipe scan on open | **Inventory counts only** on open |

**Lazy-load model (explicit):**

- **Persist:** Full profession strings saved after each successful scan.
- **Load:** Pointer to SavedVariables on `OnEnable`.
- **Decode:** Per-recipe on first `GetItemDataByIndex` (in-memory weak cache).
- **Scan:** Lazy per profession open, only when stale.
- **Counts:** Always live at refresh time; never persisted.

There is no eager “scan all professions at login” — WotLK does not expose tradeskill APIs without opening each profession.

---

## Part 4 — Files touched

| File | Role |
|------|------|
| `Skillet.lua` | Scan flags, bag routing, `TRADE_SKILL_UPDATE` stale path, selection capture, inventory refresh on open |
| `SkilletStitch-1.1.lua` | Skip scan when fresh; guarded `AutoRescan`; inventory snapshot in `reagentmeta`; `GetNumSkills` fix |
| `TradeskillInfo.lua` | `IsRecipeCacheStale` |
| `SkilletUtil.lua` | `IsRecipeIndexCacheStale`, queue/link helpers, craftable math |
| `SkilletQueue.lua` | `RemapQueueAfterRescan` |
| `UI/MainFrame.lua` | Tiered refresh, snapshot build, removed paint-time rescan, Lua 5.1 local ordering |
| `UI/Sorting.lua` | `ResortRecipes` integration with scan complete |
| `tests/test_cache.lua` | Staleness unit tests |
| `tests/test_inventory.lua` | Snapshot / craftable helpers |
| `tests/test_lua_scope.lua` | Lua 5.1 forward-reference regression |
| `tests/test_queue.lua` | Queue remap tests |
| `.docs/MANUAL_TEST_CHECKLIST.md` | Steps 16–23 |

---

## Part 5 — Intended invariants (do not regress)

1. **Scan only when stale or forced** — Bag events, scroll, and craft completion must not call `ScanTrade` / `RescanTrade` unless `IsRecipeCacheStale()` is true.
2. **Single scan per stale open** — Skillet and Stitch must not both scan for the same open (`IsScanInProgress` / `IsScanJustCompleted` / stale check).
3. **Learn while open** — New recipe appears after one rescan; no `SetTradeSkillItem` errors; queue and selection stay on the correct recipe.
4. **Counts stay fresh** — Inventory brackets update on bag/queue events without full recipe rescan.
5. **SavedVariables trust** — Complete on-disk cache survives relog and skips scan until the live list changes (learn, unlearn, first visit).
6. **Public API** — `UpdateTradeSkillWindow`, `ShowTradeSkillWindow`, `RescanTrade` remain hookable entry points.

---

## Part 6 — Verification

**Automated (off-client):**

```powershell
& "C:\Program Files (x86)\Lua\5.1\lua.exe" tests/run.lua
```

Expect **37 tests, 0 failures** — includes cache staleness, queue remap, inventory helpers, Lua scope.

**In-game (manual):**

- Step **21** — One “Scanning tradeskill” on first visit; none on immediate reopen.
- Steps **16–18** — Learn recipe while open / sorted / queue active.
- Steps **19–20** — Scroll and craft without list resort flicker or scan spam.
- Steps **22–23** — Hide uncraftable and bank/alt count performance.

---

## Part 7 — Quick reference diagram

```
                    TRADE_SKILL_SHOW
                           |
            +--------------+--------------+
            |                             |
     UpdateTradeSkill              Stitch TRADE_SKILL_SHOW
            |                             |
   cache_recipes_if_needed          skip if fresh / in-progress
   (only if IsRecipeCacheStale)            |
            |                         ScanTrade (if needed)
            v                             |
     ShowTradeSkillWindow                 |
            |                             |
   need_inventory_refresh?                |
   -> internal_RefreshInventoryCounts     |
            |                             |
            +--------------+--------------+
                           |
                  User crafts / bags change
                           |
                   BAG_UPDATE (debounced)
                           |
              internal_RefreshInventoryCounts
                  (never ScanTrade)
```

---

*Document version: reflects working tree changes through scan deduplication, refresh tiering, learn-recipe remapping, and inventory snapshot batching.*
