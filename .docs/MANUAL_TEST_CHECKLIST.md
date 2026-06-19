# Skillet Manual Smoke Test Checklist

Run this checklist after any change to UI, events, queue processing, or tradeskill data handling. Estimated time: ~10 minutes.

## Prerequisites

- Skillet enabled on a WotLK 3.3.5a character with at least two professions (one crafting, one gathering or enchanting preferred)
- Some materials in bags and bank for queue/craft tests
- Access to a vendor that sells a reagent used by a known recipe (optional, for merchant test)

## Checklist

- [ ] **1. Window replacement** — Open each profession window; Skillet replaces the default Blizzard tradeskill UI
- [ ] **2. Recipe filter** — Filter by recipe name; confirm list narrows correctly
- [ ] **3. Reagent filter** — Filter by a reagent name (not the recipe name); confirm matching recipes appear
- [ ] **4. Sorting** — Sort by name, difficulty, item level, and quality; toggle reverse sort; confirm order changes
- [ ] **5. Recipe tooltip** — Hover a recipe in the list; tooltip shows without Lua errors
- [ ] **6. Reagent tooltip** — Hover each reagent slot for a selected recipe; no `SetTradeSkillItem` errors (see `exampleError.txt`)
- [ ] **7. Reverse navigation** — Click a craftable reagent; Skillet navigates to that reagent's recipe
- [ ] **8. Queue items** — Queue two different recipes; confirm both appear in the queue panel
- [ ] **9. Process queue** — Click Start; first queued item begins crafting
- [ ] **10. Clear queue** — Clear queue; panel empties
- [ ] **11. Queue persistence** — Queue an item, log out, log back in; queue is restored
- [ ] **12. Shopping list** — Run `/skillet shoppinglist`; missing materials for queued recipes are listed
- [ ] **13. Vendor buy** — Visit a vendor selling a needed reagent; Skillet buy button appears and purchases work
- [ ] **14. Linked tradeskill** — Open a tradeskill link from chat; Skillet does **not** replace the linked view
- [ ] **15. Options** — Run `/skillet config` out of combat; Waterfall options panel opens

## Automated Tests (off-client)

Before manual testing, run unit tests from the addon root:

```powershell
lua tests/run.lua
```

Or with Lua for Windows full path:

```powershell
& "C:\Program Files (x86)\Lua\5.1\lua.exe" tests/run.lua
```

All tests should report `OK`. These cover link parsing, queue aggregation, sort index mapping, and filter matching — not UI or live crafting.

## Reporting Failures

When filing a bug, include:

- Steps to reproduce
- Profession and recipe involved
- Any Lua error text from `exampleError.txt` format (file, line, stack)
- Whether sorting or filtering was active when the error occurred

