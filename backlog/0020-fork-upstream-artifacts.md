# Pull keyd / Nerd Font from personal forks, not upstream

- **Status:** proposed
- **Created:** 2026-07-21
- **Area:** image (`Containerfile`; the `keyd-build` stage + the Nerd Font fetch)
- **Depends:** the keyd fork must exist first (prerequisites below)
- **Related:** rheniite's "personal fork fallback" for the Zirconium base
  ([`rheniite/README.md`](../../rheniite/rheniite/README.md)) — same reasoning, applied to
  the artifacts Steen fetches directly from upstream; [0009](0009-keyd-tap-hold-super.md)
  (keyd), [0002](0002-base-desktop-plumbing.md) (Nerd Font).

> **lazygit is no longer in scope.** It was the third build-time fetch (a hand-bumped
> upstream release binary), but it's been **removed from the image entirely** and moved to
> the Fedora `apps` distrobox (dejan/lazygit COPR, exported to `~/.local/bin`) — see
> `dotfiles-steen`'s `run_onchange_create-apps-distrobox.sh`. A self-contained CLI with no
> system integration doesn't belong in the signed image; the container updates it on its own
> cadence. That leaves only keyd and the Nerd Font here.

## Why

Two artifacts are fetched at build time from third-party upstreams by URL:

| Artifact | Current source | Containerfile |
|---|---|---|
| keyd | `github.com/rvaiya/keyd` (git clone, `ARG KEYD_VERSION=v2.6.0`) | source build in the `keyd-build` stage |
| JetBrainsMono Nerd Font | `github.com/ryanoasis/nerd-fonts` release asset (`ARG NERD_FONT_VERSION=v3.4.0`) | `curl … JetBrainsMono.tar.xz` |

A daily rebuild fetches whatever those URLs serve. Owning a fork gives **resilience** (an
upstream deleting/retagging a release can't break Steen's build), **reproducibility** (the
fork's tags are frozen under our control), and **trust** (we bump the fork deliberately
after reviewing upstream, instead of auto-inheriting). It's exactly rheniite's base-image
fork rationale, one layer down.

## The gotcha: GitHub forks do NOT carry release *assets*

Forking copies the git tree (and tags, if you fork with them), but **not Releases or their
attached binaries/tarballs**. So "use my fork" is trivial for a source build and non-trivial
for a release-asset download. That splits the three:

### keyd — easy (already a source build)

Change the clone URL only:
```dockerfile
-  && git clone --depth 1 --branch "$KEYD_VERSION" https://github.com/rvaiya/keyd /src \
+  && git clone --depth 1 --branch "$KEYD_VERSION" https://github.com/reinier/keyd /src \
```
Prereq: fork `rvaiya/keyd` and ensure the `v2.6.0` **tag** exists in the fork (forking with
tags, or pushing the tag). Nothing else changes — we already compile from source.

### Nerd Font — forking the 3,600-font monorepo is the wrong shape

`ryanoasis/nerd-fonts` is huge, and its `JetBrainsMono.tar.xz` is a **release asset** a fork
won't carry. Three ways, decide when implementing:

1. **Vendor the font into the steen repo** *(recommended)* — commit the `JetBrainsMono NF`
   `.ttf`s (a few MB) under `files/fonts/` and `COPY` them in; drop the `curl` entirely. No
   fork, no network fetch at build, fully self-contained and reproducible. The cost is a few
   MB of binary in the repo, bumped by hand on font updates.
2. **A small personal asset repo** — e.g. `reinier/steen-assets` holding just the font (or a
   release with it); `curl` from there. Lighter than forking nerd-fonts; still a network dep.
3. **Fork nerd-fonts + cut a release** with the `JetBrainsMono.tar.xz` asset — faithful to
   "use my fork" but drags a giant repo for one font. Not recommended.

## Complementary hardening (worth doing with this)

The current fetches have **no checksum verification** — a fork fixes *provenance* but a hash
pin fixes *integrity*. Whichever source each ends up on, add a `sha256sum -c` against a
recorded digest (baked in the Containerfile) so a corrupted/tampered artifact fails the
build. The guards already assert presence (`command -v keyd`, the Nerd Font glyph check);
this adds content verification.

## Ownership note

Pinning to forks means **we own the bump cadence**: pull upstream into the fork, review,
re-tag, bump the `ARG`. That's the point (deliberate over automatic), but it is manual work —
budget for it, or wire a Renovate-style reminder on the fork tags later.

## Prerequisites (before implementing)

- [ ] Fork `rvaiya/keyd` → `reinier/keyd`, ensure `v2.6.0` tag present.
- [ ] Decide the Nerd Font approach (recommend option 1: vendor into `files/fonts/`).

## Verification

- Build stays green; `command -v keyd` and `fc-list | grep -i jetbrainsmono` still pass
  (existing guards), now sourced from the fork/vendored copy.
- (If added) the `sha256sum -c` steps pass, and a deliberately wrong digest fails the build.
