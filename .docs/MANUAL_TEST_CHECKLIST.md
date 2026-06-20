# Skillet-Enhanced Manual Smoke Test Checklist

Run this checklist after any change to UI, events, queue processing, or tradeskill data handling. Estimated time: ~10 minutes.

## Prerequisites

- Skillet-Enhanced enabled on a WotLK 3.3.5a character with at least two professions (one crafting, one gathering or enchanting preferred)
- Some materials in bags and bank for queue/craft tests
- Access to a vendor that sells a reagent used by a known recipe (optional, for merchant test)

## Checklist

- [x] **1. Window replacement** — Open each profession window; Skillet replaces the default Blizzard tradeskill UI
- [x] **2. Recipe filter** — Filter by recipe name; confirm list narrows correctly
- [x] **3. Reagent filter** — Filter by a reagent name (not the recipe name); confirm matching recipes appear
- [x] **4. Sorting** — Sort by name, difficulty, item level, and quality; toggle reverse sort; confirm order changes
- [x] **5. Recipe tooltip** — Hover a recipe in the list; tooltip shows without Lua errors
- [x] **6. Reagent tooltip** — Hover each reagent slot for a selected recipe; no `SetTradeSkillItem` errors
- [x] **7. Reverse navigation** — Click a craftable reagent; Skillet navigates to that reagent's recipe
- [x] **8. Queue items** — Queue two different recipes; confirm both appear in the queue panel
- [x] **9. Process queue** — Click Start; first queued item begins crafting
- [x] **10. Clear queue** — Clear queue; panel empties
- [x] **11. Queue persistence** — Queue an item, log out, log back in; queue is restored
- [x] **12. Shopping list** — Run `/skillet shoppinglist`; missing materials for queued recipes are listed
- [x] **13. Vendor buy** — Visit a vendor selling a needed reagent; Skillet buy button appears and purchases work
- [x] **14. Linked tradeskill** — Open a tradeskill link from chat; Skillet does **not** replace the linked view
- [x] **15. Options** — Run `/skillet config` out of combat; Waterfall options panel opens
- [ ] **16. Learn recipe in-window** — With the profession window open, learn a new recipe from a trainer without closing the window; the new recipe appears automatically with no blank rows and reagent tooltips work without `SetTradeSkillItem` errors
- [ ] **17. Learn recipe while sorted** — Repeat step 16 with sorting active (e.g. by name); confirm the new recipe appears in the correct sort order
- [ ] **18. Learn recipe while queue active** — Queue a recipe, start crafting, then learn a new recipe from a trainer without closing the window; the queue entry must still show the original recipe (not a shifted neighbor)
- [ ] **19. Scroll performance** — Scroll the recipe list rapidly; selection highlight stays on the selected recipe and the details panel does not flicker
- [ ] **20. Bag update refresh** — Craft or loot a reagent with the window open; craftable counts update without the list resorting or title bar flickering
- [ ] **21. Open scan once** — Open a profession; only one "Scanning tradeskill" message appears before the list populates
- [ ] **22. Hide uncraftable performance** — On a large profession (e.g. Engineering), toggle **Hide uncraftable**; list filters without a long freeze
- [ ] **23. Bank/alt counts** — Enable bank/alt counts in options; deposit a reagent to the bank and confirm visible `[bags/bank/alts]` brackets update correctly
- [ ] **24. Switch profession mid-scan** — Open Engineering (stale cache) and wait for scan progress; switch to Blacksmith before scan finishes; Blacksmith scan starts, progress text updates, and the recipe list populates
- [ ] **25. Close and reopen mid-scan** — Open a profession with stale cache; close the tradeskill window while progress is below 100%; reopen the same profession; scan resumes from partial cache and completes
- [ ] **26. Scan progress percentage** — On a large profession (e.g. Engineering), confirm the title bar shows increasing `Skillet: <profession> (Scanning: n/total, pct%)` while scanning; `n` must not jump backward
- [ ] **27. No list flicker during scan** — Open a profession with stale cache (e.g. Tailoring); while the title progress updates, the recipe list must not flash or repaint repeatedly; after scan completes, the list populates in one refresh. Reopen with fresh cache — no scan, no flash
- [ ] **28. Scan progress during interaction** — On a large profession with stale cache, confirm title bar shows scan progress while the recipe list stays **fully bright and clickable on the whole row** (not only the `[bags/bank/alts]` count brackets). Filter/sort/queue/craft should remain guarded during scan; after scan completes, all controls work. **Combat open:** open tradeskill while in combat — list browsable; scan starts after combat ends. **Learn recipe:** with window open, learn a new recipe; brief title-bar scan is OK; after completion, list and controls work and the new recipe appears

## Automated Tests (off-client)

Before manual testing, run unit tests from the addon root:

```powershell
lua tests/run.lua
```

Or with Lua for Windows full path:

```powershell
& "C:\Program Files (x86)\Lua\5.1\lua.exe" tests/run.lua
```

All tests should report `OK`. These cover link parsing, queue aggregation, sort index mapping, filter matching, recipe cache staleness, and inventory count helpers — not UI or live crafting.

## Reporting Failures

When filing a bug, include:

- Steps to reproduce
- Profession and recipe involved
- Any Lua error text (file, line, stack from BugSack/BugGrabber or `/script` output)
- Whether sorting or filtering was active when the error occurred

