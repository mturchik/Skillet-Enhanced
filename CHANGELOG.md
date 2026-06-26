# Changelog

All notable changes to Skillet-Enhanced are documented in this file.

## Skillet-Enhanced 1.14.2

### Recipe favorites

- **Per-character favorites** — Star recipes on the current character; stored by crafted result item or enchant ID so favorites survive recipe rescans
- **List star column** — Raid targeting star beside each recipe (gold = favorited, dim gray = not)
- **Toggle favorite** — Right-click a recipe, or use the Favorite / Unfavorite button in the detail pane
- **Favorite filter** — Checkbox to show only favorited recipes (combinable with text search and other filters)
- **Addon API** — `Skillet:IsRecipeFavorite`, `Skillet:ToggleRecipeFavorite`, and `Skillet:GetRecipeFavoriteId` on the global `Skillet` object

### UI and filtering

- **Affirmative filters** — Craftable, Relevant, and Favorite checkboxes replace the old “hide uncraftable” / “hide trivial” controls (same behavior, clearer labels)
- **Saved filter migration** — Legacy `hideuncraftable` / `hidetrivial` keys convert to `showcraftable` / `showrelevant` on login
- **Recipe list layout** — Category expand/collapse icons, favorite star column, and craft-count bracket alignment fixes

### Code and tests

- `SkilletUtil.IsRecipeIdFavorited` — shared favorites lookup helper
- Unit test for favorites lookup (`tests/test_favorites.lua`)
- `README.md` — installation, usage, persistence, and API documentation for favorites and filters

## Skillet-Enhanced 1.14.1

### Recipe scan (Stitch cache)

- **Chunked scanning** — Recipe cache builds in ~30-row chunks per frame instead of blocking the UI in one pass; scan driver runs at 50 ms intervals
- **Title-bar progress** — Active scans show `Skillet: <profession> (Scanning: n / total, pct%)` in the window title; legacy scanning text area is hidden
- **Per-profession sessions** — Switching professions cancels the old scan and starts a new one when needed; closing the window preserves partial cache and resumes from the first stale index on reopen
- **Smarter staleness** — Cached entries are stale when the result item id no longer matches the live `GetTradeSkillItemLink` at that index (handles recipe index shifts after learning)
- **Anti-flicker** — Recipe list is frozen during an active scan; `TRADE_SKILL_UPDATE` and refresh paths update only the title until scan completes, then one full list refresh runs
- **Shred retry fix** — Incomplete link retries clear scan session state before rescheduling, avoiding a stuck `scan_in_progress` deadlock

### UI and filtering

- **Hide trivial** — Uses live `GetTradeSkillInfo` difficulty (batched per refresh) instead of scan-time cached difficulty, so trivial filtering stays accurate as skill level changes
- **Section headers** — Headers hide when every recipe in the section is filtered out (unless the section is collapsed)
- **Scroll list** — Visible recipe rows are built once per paint for correct filtering and scroll sizing
- **Filter box** — Resets recipe list scroll offset when the filter text changes
- **Title bar** — Smaller font, left-aligned layout with room for long scan progress text

### Code and tests

- `SkilletUtil` — Scan progress helpers, result-id cache validation, `BuildTradeSkillHeaderMaps`, link-based queue remap fallback in `FindRecipeIndexByDataString`
- `SkilletStitch` — `ScanIndexRange`, consolidated vendor-reagent detection and craftable-count logic
- `LibPossessions` — Bank/alt item counts use `SkilletUtil.GetItemIDFromLink`
- Unit tests expanded for cache staleness, scan progress, and queue index remap (`tests/test_cache.lua`, `tests/test_queue.lua`)

## Skillet-Enhanced 1.14

Fork release — renamed from upstream Skillet for independent publication.

- Addon folder and `.toc` file: `Skillet-Enhanced`
- Display title: Skillet-Enhanced
- Internal API, SavedVariables (`SkilletDB`), and `/skillet` slash commands unchanged for compatibility
- Removed upstream CurseForge/WoWAce publish metadata from `.toc`
- Added `README.md` with installation, features, and fork attribution

Based on Skillet 1.13 (r167) by Robert Clark (nogudnik).

### Upstream Skillet history (pre-fork)

- **r167** (2010-07-10): Updated `.toc`; Ace2 library repackaging
- **r166** (2009-06-11): MainFrame button position change (`Locale-enUS`, `Locale-ruRU`, `MainFrame`)
