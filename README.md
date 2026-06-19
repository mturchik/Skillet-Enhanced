# Skillet-Enhanced

Enhanced tradeskill window replacement for **World of Warcraft: Wrath of the Lich King 3.3.5a** (`Interface: 30300`).

Skillet-Enhanced is a community fork of [Skillet](https://www.wowace.com/projects/skillet/) by Robert Clark (nogudnik). It is maintained independently for legacy and private-server clients.

## Features

- Larger tradeskill window with filtering, sorting, and craftable counts
- Multi-recipe crafting queue with persistence across sessions
- Cross-alt shopping list and bank material retrieval
- Vendor auto-buy for queued recipe reagents
- Per-item recipe notes and third-party mod hooks

## Installation

1. Copy the `Skillet-Enhanced` folder into `World of Warcraft/Interface/AddOns/`.
2. The folder name must match the `.toc` file: `Skillet-Enhanced/Skillet-Enhanced.toc`.
3. Enable **Skillet-Enhanced** in the character AddOns list.
4. Disable the original **Skillet** addon if installed — do not run both.

## Slash commands

| Command | Action |
|---------|--------|
| `/skillet` | Open options |
| `/skillet shoppinglist` | Open the material shopping list |

## Compatibility

- **Target client:** WotLK 3.3.5a only (legacy `GetTradeSkill*` APIs)
- **Saved variables:** Uses `SkilletDB` / `SkilletDBPC` — settings from original Skillet are preserved when replacing it
- **Third-party mods:** Retains the original Skillet frame names and public API (`ThirdPartyHooks.lua`)

## Credits

| Component | Author |
|-----------|--------|
| Skillet (original) | Robert Clark (nogudnik) |
| ATSW (inspiration) | Slartie |
| Stitch / recipe cache | Nymbia |
| Skillet-Enhanced fork | Mark |

Licensed under **GPL v3 or later** — see [LICENSE.txt](LICENSE.txt).

See [CHANGELOG.md](CHANGELOG.md) for release history.

## Development

```powershell
lua tests/run.lua
```

See `.docs/OVERVIEW.md` for architecture and `.docs/MANUAL_TEST_CHECKLIST.md` for in-game verification.
