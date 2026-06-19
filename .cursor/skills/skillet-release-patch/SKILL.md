---
name: skillet-release-patch
description: >-
  Bumps Skillet-Enhanced patch version and updates CHANGELOG.md and
  Skillet-Enhanced.toc when git history or working-tree changes exist since
  the last release. Compares against git tags, last version commit, and pending
  diffs. Use when the user asks to release a patch, bump version, update the
  changelog, or document changes since the last tagged version.
---

# Skillet-Enhanced Patch Release

Increment **patch** version and document notable changes when the repo has moved since the last release baseline.

Patch-only by default (`1.14` → `1.14.1`, `1.14.1` → `1.14.2`). Do not bump minor/major unless the user explicitly asks.

## Quick checklist

```
- [ ] 1. Determine current version and release baseline
- [ ] 2. Collect all changes since baseline (commits + working tree)
- [ ] 3. Decide: skip (no changes) or bump patch
- [ ] 4. Update Skillet-Enhanced.toc ## Version
- [ ] 5. Prepend CHANGELOG.md section for new version
- [ ] 6. Run lua tests/run.lua if production .lua changed
```

Do **not** commit or push unless the user asks.

---

## Step 1: Current version and baseline

Run in parallel:

```powershell
git status
git tag -l --sort=-v:refname
git log -5 --oneline
```

Read version from [`Skillet-Enhanced.toc`](Skillet-Enhanced.toc) (`## Version:` line) and the top entry in [`CHANGELOG.md`](CHANGELOG.md).

**Release baseline** (first match wins):

1. **Newest semver git tag** matching `X.Y` or `X.Y.Z` (e.g. `1.14`, `1.14.1`)
2. **Last commit that changed** `## Version:` in `Skillet-Enhanced.toc` or added a `## Skillet-Enhanced X.Y.Z` heading in `CHANGELOG.md`
3. If neither exists, use the initial fork commit as baseline

Record: `baseline_ref` (tag or commit), `current_version`.

---

## Step 2: Collect changes since baseline

Run in parallel:

```powershell
git diff baseline_ref..HEAD
git diff HEAD
git log baseline_ref..HEAD --oneline
```

Include **both**:

- Commits on the current branch after `baseline_ref`
- Uncommitted/staged changes (`git diff HEAD`, `git diff --cached`)

If the combined diff is empty or only touches files that should not trigger a release (see below), **stop** and tell the user the tree is already at the documented version.

**Skip bump** (report only) when changes are limited to:

- `.cursor/`, editor config, or local-only tooling
- Whitespace/line-ending-only diffs with no behavioral change

When in doubt, include the change in the changelog.

---

## Step 3: Compute new patch version

Parse `current_version` as `major.minor` or `major.minor.patch`:

| Current   | New        |
|-----------|------------|
| `1.14`    | `1.14.1`   |
| `1.14.1`  | `1.14.2`   |
| `1.14.12` | `1.14.13`  |

If `CHANGELOG.md` already documents the computed version and `Skillet-Enhanced.toc` matches, verify the changelog content covers all diffs since baseline. Update the section if it is incomplete; do not re-bump.

---

## Step 4: Update Skillet-Enhanced.toc

Change only the version line:

```toc
## Version: <new_version>
```

Do not alter load order or other metadata unless the diff itself changed them.

---

## Step 5: Update CHANGELOG.md

Insert a new section **immediately after** the file header and **before** the previous version block:

```markdown
## Skillet-Enhanced <new_version>

### <Theme 1 — user-facing area>

- **Short label** — One sentence: what changed and why it matters in-game

### <Theme 2>

- ...
```

**Grouping themes** (use only what applies):

| Area | Typical files |
|------|----------------|
| Recipe scan (Stitch cache) | `Skillet.lua`, `SkilletStitch-1.1.lua`, `SkilletUtil.lua`, `TradeskillInfo.lua` |
| UI and filtering | `UI/MainFrame.lua`, `Locale/Locale-enUS.lua` |
| Queue / shopping list | `SkilletQueue.lua`, `SkilletUtil.lua` |
| Alt / bank inventory | `LibPossessions.lua` |
| Code and tests | refactors, `tests/*.lua` |
| Docs only | `.docs/*`, `README.md` — mention briefly; still bump if user requested release |

**Writing rules:**

- User-facing bullets first; implementation detail last
- Bold lead phrase per bullet (`**Label** — detail`)
- No commit SHAs or internal-only noise
- Preserve older version sections unchanged below the new entry

---

## Step 6: Verify

If any addon-authored `.lua` under the repo root (excluding `Libs/`) changed since baseline:

```powershell
lua tests/run.lua
```

All tests must pass before finishing. Fix code or update tests only when behavior intentionally changed (see `.cursor/rules/skillet-testing.mdc`).

---

## Example

**Baseline:** tag `1.14`, working tree has chunked scan + UI anti-flicker.

**Actions:**

- Bump `Skillet-Enhanced.toc` → `## Version: 1.14.1`
- Add `## Skillet-Enhanced 1.14.1` with subsections *Recipe scan*, *UI and filtering*, *Code and tests*
- Run `lua tests/run.lua` → 48 successes

**No-op example:** `git diff 1.14.1..HEAD` and `git diff HEAD` empty → report "already at 1.14.1, nothing to release."
