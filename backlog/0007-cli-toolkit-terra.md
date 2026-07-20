# CLI toolkit (Fedora + Terra)

- **Status:** done (CI-green 2026-07-20; real-boot checks in [0018](0018-first-boot-checklist.md))
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

## Implemented (2026-07-20), in three sources

| Source | Packages |
|---|---|
| **Fedora** | `fish` 4.6.0, `eza`, `bat`, `jq`, `zip`, `fuse-sshfs`, `fzf`, `xdg-terminal-exec`, `ripgrep`, **`chezmoi`** |
| **Terra** | `starship` 1.26.0, `yazi` 26.5.6 |
| **Upstream release binary** | `lazygit` 0.63.1 (pinned `ARG LAZYGIT_VERSION`) |

Fedora packages install **first**; `terra.repo` is dropped in only for the second
transaction and removed straight after, with `priority=200` (higher number = lower
priority) so Terra can never quietly shadow a Fedora package present in both.

> **Correction.** An earlier pass claimed lazygit was now in Fedora and dropped it from
> Terra. That was wrong — the check had been run against a workstation with a
> `copr:dejan:lazygit` repo enabled, so it was reading a COPR, not Fedora. The build
> caught it (`No match for argument: lazygit`). Verified properly since: lazygit is in
> **neither** Fedora (43 or 44) **nor** Terra (main or extras).
>
> Rather than add a third-party COPR for one tool, it's baked from the upstream
> release tarball — the same pinned-artifact pattern already used for keyd and the
> Nerd Font. Being outside rpm, it's guarded with `command -v` instead of `rpm -q`.

## Two more added after the dotfiles work (2026-07-20)

- **`chezmoi`** — the dotfiles bootstrap (`chezmoi init --apply`) *requires* it; rheniite
  inherited it from the Zirconium base, Steen had no such base and it was missed. Now
  baked. (The bootstrap literally can't run without it.)
- **`ripgrep`** — `rg`. It's kitty's only useful `Recommends`, and 0003 installs
  niri/kitty with `--setopt=install_weak_deps=False` (the waybar fix), which skipped it.
  Re-added explicitly. `nanosvg` (a `fuzzel` dependency, not an app) was correctly
  dropped with fuzzel and is *not* re-added — nothing Steen keeps needs it.

## No Homebrew (0015)

There is no brew to shadow these or be shadowed by — this toolkit is the whole CLI
baseline. Anything Fedora/Terra doesn't package goes through distrobox (0017) or the
image, not brew. See [0015](0015-no-homebrew.md).

## Verification

- `fish`, `starship`, `eza`, `bat`, `jq`, `lazygit`, `yazi`, `sshfs` all on `PATH`
  and runnable in a fresh login shell (image binaries; no brew present).
