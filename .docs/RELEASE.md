# Publishing a Release

Tag-triggered GitHub Actions builds a WoW-ready zip and publishes it to [GitHub Releases](https://github.com/mturchik/Skillet-Enhanced/releases).

## Before you tag

1. Bump `## Version:` in `Skillet-Enhanced.toc` (must match the tag, without the `v` prefix).
2. Add a matching `## Skillet-Enhanced X.Y.Z` section to `CHANGELOG.md` — the workflow copies this into the release notes.
3. Run tests locally:
   ```powershell
   lua tests/run.lua
   ```
4. Commit and push to `main`.

## Publish

```powershell
git tag v1.14.1
git push origin v1.14.1
```

Replace `v1.14.1` with the version you set in the `.toc` file. The tag must start with `v` and match the toc version exactly (e.g. tag `v1.14.1` ↔ toc `1.14.1`).

## What the workflow does

1. Runs `lua5.1 tests/run.lua` — release fails if tests fail.
2. Verifies tag version matches `Skillet-Enhanced.toc`.
3. Builds `Skillet-Enhanced-X.Y.Z.zip` with a top-level `Skillet-Enhanced/` folder.
4. Creates a GitHub Release with notes from `CHANGELOG.md` and attaches the zip.

## Zip contents

**Included:** all addon runtime files (`UI/`, `Locale/`, `Libs/`, `.lua`/`.xml`, `LICENSE.txt`, `README.md`, `CHANGELOG.md`).

**Excluded:** `tests/`, `luaunit.lua`, `.cursor/`, `.docs/`, `.github/`, `.git/`, `.gitignore`, `.vs/`, `exampleError.txt`.

## Verify the first release

After pushing a tag:

1. Open [Actions](https://github.com/mturchik/Skillet-Enhanced/actions) and confirm the **Release** workflow succeeded.
2. Open [Releases](https://github.com/mturchik/Skillet-Enhanced/releases) and download the zip.
3. Confirm the archive contains:
   - Top-level folder `Skillet-Enhanced/`
   - `Skillet-Enhanced/Skillet-Enhanced.toc`
   - No `tests/`, `luaunit.lua`, or `.cursor/` inside

Extract into `Interface/AddOns/` and smoke-test in game using `.docs/MANUAL_TEST_CHECKLIST.md`.
