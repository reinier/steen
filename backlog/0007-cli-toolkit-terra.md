# CLI toolkit (Fedora + Terra)

- **Status:** accepted
- **Created:** 2026-07-19
- **Area:** image (`Containerfile`), Terra repo wiring
- **Depends:** 0001
- **Related:** rheniite
  [`Containerfile`](../../rheniite/rheniite/Containerfile) "CLI toolkit" stanza,
  [`docs/third-party-repos.md`](../../rheniite/rheniite/docs/third-party-repos.md) "Terra".

## Port + one new wrinkle

Bake the toolkit so it's present at boot and updates with the image (rheniite moved
this off per-user Homebrew):

- **From Fedora main:** `fish eza bat jq zip fuse-sshfs`.
- **From Terra:** `starship lazygit yazi`.

**The wrinkle:** rheniite inherited `terra-release` (repo pre-enabled + trusted)
from the Zirconium base. Steen has **no such base**, so it must **add Terra
itself** — install `terra-release` (from `terra.fyralabs.com`), do the one install,
and decide whether to leave Terra enabled (Zirconium did) or remove it after (the
rheniite third-party discipline). **Recommend leave enabled** only if something
depends on live Terra updates; otherwise remove-after like the other sources.

> Before wiring Terra, **check whether `lazygit`/`yazi` are now in Fedora main** —
> if so, trim them off Terra and shrink the third-party surface to just
> `starship` (or drop Terra entirely).

## Relationship to Homebrew (0015)

Baking the toolkit here is what lets brew stay **thin** — brew is not load-bearing
for the core CLI experience, only for the long tail Fedora/Flatpak don't package
(`claude-code`, `framework-tool`). See [0015](0015-homebrew.md). Ensure PATH order
resolves these image copies **before** any brew copies.

## Verification

- `fish`, `starship`, `eza`, `bat`, `jq`, `lazygit`, `yazi`, `sshfs` all on `PATH`
  and runnable in a fresh login shell, resolving to the **image** binaries.
