# CLI toolkit (Fedora + Terra)

- **Status:** accepted
- **Created:** 2026-07-19
- **Area:** image (`Containerfile`), Terra repo wiring
- **Depends:** 0001
- **Related:** rheniite
  [`Containerfile`](../../rheniite/rheniite/Containerfile) "CLI toolkit" stanza,
  [`docs/third-party-repos.md`](../../rheniite/rheniite/docs/third-party-repos.md) "Terra".

## Port + one new wrinkle

Bake the toolkit so it's present at boot and updates with the image. This **is** the
CLI baseline — Steen ships no Homebrew ([0015](0015-no-homebrew.md)), so nothing here
falls back to brew:

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

## No Homebrew (0015)

There is no brew to shadow these or be shadowed by — this toolkit is the whole CLI
baseline. Anything Fedora/Terra doesn't package goes through distrobox (0017) or the
image, not brew. See [0015](0015-no-homebrew.md).

## Verification

- `fish`, `starship`, `eza`, `bat`, `jq`, `lazygit`, `yazi`, `sshfs` all on `PATH`
  and runnable in a fresh login shell (image binaries; no brew present).
