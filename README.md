# Skillet-Enhanced

Enhanced tradeskill window replacement for **World of Warcraft: Wrath of the Lich King 3.3.5a** (`Interface: 30300`). Current release version: **1.14.2** (see `Skillet-Enhanced.toc`).

Skillet-Enhanced is a community fork of [Skillet](https://www.wowace.com/projects/skillet/) by Robert Clark (nogudnik). It is maintained independently for legacy and private-server clients. Internal globals and SavedVariables remain `Skillet` / `SkilletDB` for compatibility with upstream data and third-party hooks.

## Features

- Larger tradeskill window with text search, sorting, and craftable counts
- **Recipe favorites** — star recipes per character; filter to favorites only
- **Affirmative recipe filters** — Craftable, Relevant (non-trivial), and Favorite checkboxes (combinable with text search)
- Multi-recipe crafting queue with persistence across sessions
- Cross-alt shopping list and bank material retrieval
- Vendor auto-buy for queued recipe reagents
- Per-item recipe notes (shared on realm/faction via `SkilletDB.server`)
- Third-party mod hooks and stable public API (`ThirdPartyHooks.lua`)

## Install

### From GitHub Releases (recommended)

1. Download the latest `Skillet-Enhanced-X.Y.Z.zip` from [GitHub Releases](https://github.com/mturchik/Skillet-Enhanced/releases).
2. Extract the `Skillet-Enhanced` folder into `World of Warcraft/Interface/AddOns/`.
3. Enable **Skillet-Enhanced** in the character AddOns list.
4. Disable the original **Skillet** addon if installed — do not run both.

### From source

1. Copy the `Skillet-Enhanced` folder into `World of Warcraft/Interface/AddOns/`.
2. The folder name must match the `.toc` file: `Skillet-Enhanced/Skillet-Enhanced.toc`.
3. Enable **Skillet-Enhanced** in the character AddOns list.
4. Disable the original **Skillet** addon if installed — do not run both.

## Usage

Open any profession to use the Skillet window instead of the default tradeskill UI.

### Recipe list

| Control | Action |
|---------|--------|
| Text **Filter** box | Plain-text match on recipe or reagent names |
| **Craftable** | When checked, show only recipes craftable with current bags/bank |
| **Relevant** | When checked, show only non-trivial recipes |
| **Favorite** | When checked, show only favorited recipes |
| **Sorting** dropdown | Sort recipe list: None, By Name, By Difficulty, By Level, By Quality |
| **Sort direction** (arrow) | Toggle ascending vs descending for the active sort |
| Category **+/-** | Expand or collapse a recipe category |
| **Star** (left column) | Filled = favorited; dim = not favorited |
| **Right-click** recipe | Toggle favorite |
| **Favorite** / **Unfavorite** button | Toggle favorite for the selected recipe (detail pane) |
| **Shift+left-click** recipe | Insert recipe link into chat when the chat edit box is focused |

Craftable, Relevant, and Favorite filters default **off** (show all recipes). When multiple filters are checked, a recipe must pass **all** active filters plus any text search. Filters and sort method are saved **per profession** on the current character (`SkilletDBPC.char.tradeskill_options`).

### Slash commands

| Command | Action |
|---------|--------|
| `/skillet` | Open options |
| `/skillet shoppinglist` | Open the material shopping list |

## File layout

```
Skillet-Enhanced/
├── Skillet-Enhanced.toc    # Manifest (Interface 30300), load order
├── Skillet.lua             # Lifecycle, events, options, favorites API
├── SkilletUtil.lua         # Shared helpers (links, filters, favorites lookup)
├── SkilletStitch-1.1.lua   # Recipe cache, scan, queue engine
├── SkilletQueue.lua        # Queue persistence
├── TradeskillInfo.lua      # Data accessors
├── ThirdPartyHooks.lua     # Public API for other addons
├── Upgrades.lua            # SavedVariables migration
├── LibPossessions.lua      # Alt-inventory bridge
├── UI/                     # Main window, shopping list, merchant, notes
├── Locale/                 # AceLocale strings (8 languages)
├── Libs/                   # Embedded Ace2 stack (vendored)
└── tests/                  # Off-client Lua unit tests (not packaged in .toc)
```

## Architecture

Load order is defined in `Skillet-Enhanced.toc`: embedded libs → locales → core modules (`SkilletUtil`, Stitch, `Skillet`, …) → UI (`Utils`, `Sorting`, `MainFrame`, …).

Skillet intercepts `TRADE_SKILL_*` events, caches recipes via Stitch, and paints the custom frame in `UI/MainFrame.lua`. Scan lifecycle and UI refresh tiers are documented in `.docs/OVERVIEW.md` and `.cursor/rules/`.

## Data / persistence

| Scope | Variable | Contents |
|-------|----------|----------|
| Profile | `SkilletDB` | User preferences (tooltips, vendor, scale, transparency) |
| Server | `SkilletDB.server` | Recipe cache, queues, shared notes (per realm/faction) |
| Character | `SkilletDBPC.char` | Per-profession UI options, `favorite_recipes`, `include_alts` |

**Favorites** are stored under `SkilletDBPC.char.favorite_recipes[professionName][itemOrEnchantId] = true`, keyed by the crafted result item or enchant ID so favorites survive recipe rescans.

**Per-profession filter keys** (in `char.tradeskill_options[profession]`): `filtertext`, `showcraftable`, `showrelevant`, `showfavorites`, `sortmethod`, and sort-direction flags. Legacy `hideuncraftable` / `hidetrivial` keys are migrated to `showcraftable` / `showrelevant` on login (`Upgrades.lua`).

## Public API

### Favorites (`Skillet.lua`)

Other addons can call these on the global `Skillet` object (not yet listed in the `ThirdPartyHooks.lua` stability contract):

| Method | Description |
|--------|-------------|
| `Skillet:IsRecipeFavorite(trade, skill_index)` | Returns whether the recipe is favorited on this character |
| `Skillet:ToggleRecipeFavorite(trade, skill_index)` | Toggles favorite state and refreshes the list |
| `Skillet:GetRecipeFavoriteId(trade, skill_index)` | Returns stable result item/enchant id, or `nil` |

Off-client lookup helper: `SkilletUtil.IsRecipeIdFavorited(favorites_by_trade, trade, recipe_id)`.

### Third-party hooks (`ThirdPartyHooks.lua`)

Stable hook and query API for other mods: `AddButtonToTradeskillWindow`, `AddRecipeSorter`, profession/character queries, tooltip extensions, and related methods documented in that file.

## Compatibility

- **Target client:** WotLK 3.3.5a only (legacy `GetTradeSkill*` APIs; no `C_TradeSkillUI`)
- **Saved variables:** `SkilletDB` / `SkilletDBPC` — settings from original Skillet are preserved when replacing it
- **Third-party mods:** Retains original Skillet frame names and public API surface

## Known limitations

- Favorites are per character, not account-wide
- Filter, sort, favorite, and queue actions are blocked while a recipe scan is in progress (`BlocksScanActions`)
- UI, scan triggers, and queue execution require manual in-game verification (see `.docs/MANUAL_TEST_CHECKLIST.md`)
- Unit tests cover `SkilletUtil` helpers (links, queue, sort, filter, cache, favorites); WoW frames and Blizzard APIs are not tested off-client

## Development

```powershell
lua tests/run.lua
```

Or: `"C:\Program Files (x86)\Lua\5.1\lua.exe" tests/run.lua` from the addon root.

See `.docs/OVERVIEW.md` for architecture, `.docs/MANUAL_TEST_CHECKLIST.md` for in-game verification, and `.docs/RELEASE.md` for publishing tagged releases to GitHub.

## Credits

| Component | Author |
|-----------|--------|
| Skillet (original) | Robert Clark (nogudnik) |
| ATSW (inspiration) | Slartie |
| Stitch / recipe cache | Nymbia |
| Skillet-Enhanced fork | Mark Turchik |

Licensed under **GPL v3 or later** — see [LICENSE.txt](LICENSE.txt).

See [CHANGELOG.md](CHANGELOG.md) for release history.


## Documentation sync

<!-- docs-sync
commit: 56acb86f005294d9a92f3889fe823ab77084c0c5
message: Release 1.14.2: Add recipe favorites and affirmative recipe filters.
-->
