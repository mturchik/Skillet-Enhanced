# WoW Addon Repository Onboarding Playbook

A repeatable process for analyzing a legacy World of Warcraft addon, documenting it, establishing AI/editor rules, and adding practical regression testing. Derived from the Skillet (WotLK 3.3.5a) onboarding workflow.

Use this document when starting work on a **brand-new addon repository** — not when continuing work on one already onboarded.

---

## What We Did on Skillet (Condensed)

| Phase | Outcome | Location |
|-------|---------|----------|
| **1. Explore & document** | Architecture overview, module map, event flow, SavedVariables schema, known issues | `.docs/OVERVIEW.md` |
| **2. Cursor rules** | Always-on project context + file-scoped conventions (core, UI, API, persistence, locale, testing) | `.cursor/rules/*.mdc` |
| **3. Test strategy** | Honest assessment: ~80% needs in-game; unit-test pure logic only | Plan → implementation |
| **4. Test harness** | luaunit vendored at repo root; `tests/run.lua` bootstrap; WoW API mocks | `luaunit.lua`, `tests/` |
| **5. Extract testables** | Pure helpers moved to `SkilletUtil.lua`; callers wired; no Ace2 in tests | `SkilletUtil.lua` |
| **6. Unit tests** | 24 tests: links, queue aggregation, sort mapping, filters | `tests/test_*.lua` |
| **7. Manual checklist** | In-game smoke tests for UI/events/crafting | `.docs/MANUAL_TEST_CHECKLIST.md` |
| **8. Testing rule** | Require passing tests + new coverage for testable changes | `.cursor/rules/skillet-testing.mdc` |

**Explicitly skipped:** Luacheck (optional static analysis; not required), CI/GitHub Actions (local-only workflow), vendored `Libs/` changes, Ace2→Ace3 migration.

---

## Prerequisites

Before starting, confirm:

- [ ] Addon loads on target client (e.g. WotLK 3.3.5a — check `Interface:` in `.toc`)
- [ ] Git repo initialized (optional but recommended)
- [ ] **Lua 5.1** installed locally ([Lua for Windows](https://github.com/rjpcomputing/luaforwindows/releases) matches WoW's Lua version)
- [ ] `luaunit.lua` vendored at project root ([luaunit releases](https://github.com/bluebird75/luaunit))

---

## Phase 1 — Repository Analysis & Overview

**Goal:** One authoritative reference so anyone (human or AI) understands the addon without re-exploring.

### Steps

1. **Inventory the tree**
   - Read `.toc` (load order, SavedVariables, Interface version)
   - Map directories: core Lua, UI (`.lua`/`.xml`), `Locale/`, embedded `Libs/`
   - Note line counts for addon-authored files (exclude vendored libs)

2. **Identify architecture**
   - Entry point and lifecycle (`OnInitialize`, `OnEnable`, event registration)
   - Data layer (AceDB scopes, cache libraries, persistence)
   - UI layer (frames, update chains)
   - Public/third-party API (if any)

3. **Document behavior**
   - What the addon replaces or hooks
   - Guard conditions (when it activates / stays hidden)
   - Event → handler → UI refresh flow
   - Known bugs (e.g. error logs, `exampleError.txt`)

4. **Write `.docs/OVERVIEW.md`**

   Include at minimum:
   - Executive summary table (name, version, author, license, framework, target client)
   - Architecture diagram (Mermaid flowchart)
   - Directory structure and load order
   - Module-by-module responsibilities
   - SavedVariables schema
   - Slash commands / user-facing entry points
   - Compatibility notes (API era, private-server caveats)
   - Known issues
   - Quick reference globals

### Skillet reference

See [`.docs/OVERVIEW.md`](OVERVIEW.md) for a complete example (~500 lines).

### Exit criteria

- [ ] New contributor can answer "where does X live?" from the overview alone
- [ ] Event flow and data persistence are documented
- [ ] Known issues are listed with file/line hints where possible

---

## Phase 2 — Cursor Rules (AI & Consistency)

**Goal:** Enforce existing behavior and consistent change patterns without re-explaining context every session.

### Rule set (adapt names per addon)

| Rule file | `alwaysApply` | Scope | Purpose |
|-----------|---------------|-------|---------|
| `{addon}-project.mdc` | **true** | Whole repo | Platform target, preserve behavior, scope discipline, module ownership |
| `{addon}-core-lua.mdc` | false | Core `.lua` globs | Framework patterns, naming, event handlers |
| `{addon}-ui.mdc` | false | `UI/**` | XML/Lua pairing, update chains, combat lockdown |
| `{addon}-public-api.mdc` | false | API module | Stability contract for third-party hooks |
| `{addon}-persistence.mdc` | false | DB/migration files | SavedVariables scopes, migration pattern |
| `{addon}-localization.mdc` | false | `Locale/**` | Locale key workflow |
| `{addon}-testing.mdc` | **true** | Whole repo | Tests must pass; new logic covered; manual checklist when needed |

### How to derive rules

1. Read `.docs/OVERVIEW.md` and existing code conventions
2. One concern per rule; keep each under ~50 lines where possible
3. Always-on rules: project context + testing requirements
4. File-scoped rules: match globs to actual paths (`Skillet.lua`, `UI/**/*.lua`, etc.)
5. Document **do not** lists: vendored libs, deprecated APIs, known crash workarounds

### Skillet reference

Seven rules in [`.cursor/rules/`](../.cursor/rules/).

### Exit criteria

- [ ] `alwaysApply` rules point to `.docs/OVERVIEW.md`
- [ ] Module ownership table matches real file layout
- [ ] Public API stability boundary is explicit (if addon exposes hooks)

---

## Phase 3 — Testing Strategy (Honest Assessment)

**Goal:** Prevent regression where automation is feasible; document where it is not.

### Decision tree

```
Can the logic run without WoW client globals?
├── Yes, pure string/table math → unit test (extract to Util module if local)
├── Mostly, with mocked GetItemInfo etc. → unit test with tests/wow_mock.lua
└── No (frames, Ace events, DoTradeSkill) → manual checklist only
```

### What is usually testable off-client

- Link parsing / ID extraction
- Data serialization (squish/unsquish, cache string formats)
- List aggregation (shopping lists, queues)
- Sort comparators and index remapping
- Filter matching (plain-text search)
- SavedVariables migration logic (with fixture tables)

### What is usually not testable off-client

- Frame layout and XML handlers
- Event interception lifecycle
- Live crafting / combat lockdown
- Full Ace2/Ace3 addon enable/disable
- Third-party addon integration shims (smoke test in-game)

### Write a short strategy note

Either a plan doc or a section in `.docs/OVERVIEW.md`:

- Estimated % of code automatable vs manual
- List of testable units with file paths
- Explicit "will not pursue" list (headless client, full UI mock, CI if local-only)

### Skillet result

- ~24 unit tests covering data logic
- ~15-step manual checklist for UI/crafting
- Luacheck **skipped** (optional; not required)

---

## Phase 4 — Test Harness Implementation

**Goal:** `lua tests/run.lua` exits 0 with all tests passing.

### Directory layout (template)

```
{AddonRoot}/
├── luaunit.lua              # vendored; NOT in .toc
├── {Addon}Util.lua          # optional; pure helpers extracted for testing
├── tests/
│   ├── run.lua              # bootstrap: package.path, load Util, mocks, specs
│   ├── wow_mock.lua         # stub _G WoW APIs
│   ├── fixtures/            # shared test data
│   │   └── *.lua
│   ├── test_links.lua       # one file per domain
│   ├── test_queue.lua
│   └── ...
└── .docs/
    └── MANUAL_TEST_CHECKLIST.md
```

### `tests/run.lua` bootstrap pattern

```lua
local function addon_root()
    local script = arg and arg[0]
    if script then
        local root = script:match("^(.*)[/\\]tests[/\\]run%.lua$")
        if root and root ~= "" then return root .. "/" end
    end
    return "./"
end

local root = addon_root()
package.path = root .. "?.lua;" .. root .. "tests/?.lua;" .. root .. "tests/fixtures/?.lua;" .. package.path

dofile(root .. "{Addon}Util.lua")   -- if extracted
dofile(root .. "tests/wow_mock.lua")

local lu = require("luaunit")
require("test_links")
-- require other test modules...

os.exit(lu.LuaUnit.run())
```

### Extract testables (minimal prod change)

When logic is `local` inside a module:

1. Add `{Addon}Util.lua` with pure functions
2. Register in `.toc` **before** modules that depend on it
3. Replace inline/local implementations with `Util` calls
4. Tests load `Util` directly — no framework, no frames

**Do not** add `tests/` or `luaunit.lua` to `.toc`.

### Run command

```powershell
cd {AddonRoot}
lua tests/run.lua
# or
& "C:\Program Files (x86)\Lua\5.1\lua.exe" tests/run.lua
```

### Skillet reference

- [`SkilletUtil.lua`](../SkilletUtil.lua) — 6 exported helpers
- [`tests/run.lua`](../tests/run.lua) — 24 passing tests
- [`.docs/MANUAL_TEST_CHECKLIST.md`](MANUAL_TEST_CHECKLIST.md)

### Exit criteria

- [ ] All unit tests pass locally
- [ ] New pure logic has a corresponding test file or test case
- [ ] Manual checklist covers every non-automated critical path

---

## Phase 5 — Testing Rule & Maintenance

**Goal:** Every future change follows the same gate.

### Always-on testing rule (`{addon}-testing.mdc`)

Require:

1. Run `lua tests/run.lua` — all tests pass
2. Add/update tests when changing testable logic
3. Do not weaken tests to mask regressions
4. Run manual checklist after UI/event/queue changes
5. Never ship test artifacts in `.toc`

### When to update docs

| Change type | Update |
|-------------|--------|
| New module or major feature | `.docs/OVERVIEW.md` |
| New SavedVariables key | OVERVIEW schema + `{addon}-persistence.mdc` |
| New public hook | `{addon}-public-api.mdc` + OVERVIEW |
| New testable helper | `{Addon}Util.lua` + `tests/test_*.lua` |
| New in-game-only behavior | `.docs/MANUAL_TEST_CHECKLIST.md` |

---

## Master Checklist (New Repository)

Copy and track when onboarding a new addon:

### Analysis
- [ ] Read `.toc` and map load order
- [ ] Identify framework (Ace2/Ace3/standalone)
- [ ] Identify target client (`Interface:` version)
- [ ] Write `.docs/OVERVIEW.md`

### Rules
- [ ] Create `.cursor/rules/{addon}-project.mdc` (always apply)
- [ ] Create scoped rules for core, UI, API, persistence, locale as needed
- [ ] Create `.cursor/rules/{addon}-testing.mdc` (always apply)

### Testing
- [ ] Install Lua 5.1 + vendor `luaunit.lua`
- [ ] Assess testable vs manual-only scope
- [ ] Create `tests/run.lua`, `wow_mock.lua`, fixtures
- [ ] Extract pure logic to `{Addon}Util.lua` if needed
- [ ] Write initial unit tests for highest-value pure logic
- [ ] Write `.docs/MANUAL_TEST_CHECKLIST.md`
- [ ] Verify: `lua tests/run.lua` → OK

### Explicit skips (unless requested)
- [ ] Luacheck / static analysis
- [ ] CI pipeline
- [ ] Vendored `Libs/` edits
- [ ] Framework migration (Ace2→Ace3, etc.)

---

## Adaptation Notes by Addon Type

| Addon type | Overview focus | Test focus | Manual focus |
|------------|----------------|------------|--------------|
| **UI replacement** (Skillet) | Event interception, guard conditions | Sort/filter/map indices, data cache | Window open, tooltips, crafting |
| **Combat addon** | Combat log events, timers | Cooldown math, spell ID parsing | Rotation in target dummy / dungeon |
| **Data broker / display** | Update frequency, data sources | Formatting, aggregation | Visual correctness in-game |
| **Library-only** | Public API surface | All exported functions | N/A or minimal |

---

## Artifacts Produced (Skillet Instance)

| Artifact | Path |
|----------|------|
| Overview | `.docs/OVERVIEW.md` |
| Manual checklist | `.docs/MANUAL_TEST_CHECKLIST.md` |
| This playbook | `.docs/ADDON_REPOSITORY_ONBOARDING.md` |
| Cursor rules | `.cursor/rules/skillet-*.mdc` (7 files) |
| Pure helpers | `SkilletUtil.lua` |
| Test runner | `tests/run.lua` |
| Test framework | `luaunit.lua` (dev-only) |
| Unit tests | `tests/test_{links,queue,sort,filter}.lua` |
| WoW mocks | `tests/wow_mock.lua` |
| Fixtures | `tests/fixtures/recipes.lua` |

---

## Estimated Effort (New Repo)

| Phase | Time (typical legacy addon) |
|-------|----------------------------|
| Overview | 2–4 hours |
| Cursor rules | 1–2 hours |
| Test harness + Util extraction | 2–3 hours |
| Initial unit tests | 1–2 hours |
| Manual checklist | 30 minutes |
| **Total** | **~6–12 hours** |

Smaller addons or those with more pure logic may finish faster; UI-heavy addons gain less from unit tests but still benefit from overview, rules, and manual checklist.

---

## Quick Start Prompt (New Repo)

When opening a new addon in Cursor, use:

> Explore this WoW addon repository and follow `.docs/ADDON_REPOSITORY_ONBOARDING.md` (or the Skillet playbook if not yet copied). Target client: [e.g. WotLK 3.3.5a]. Produce `.docs/OVERVIEW.md` first, then Cursor rules, then test harness for pure logic only. Do not edit vendored Libs. Skip Luacheck and CI unless asked.

Copy this playbook to the new repo's `.docs/` folder before starting, or reference it from a shared team template.
