# Pull keyd / Nerd Font / lazygit from personal forks, not upstream

- **Status:** proposed
- **Created:** 2026-07-21
- **Area:** image (`Containerfile`; the `keyd-build` stage + the Nerd Font and lazygit fetches)
- **Depends:** the forks must exist first (prerequisites below)
- **Related:** rheniite's "personal fork fallback" for the Zirconium base
  ([`rheniite/README.md`](../../rheniite/rheniite/README.md)) — same reasoning, applied to
  the three artifacts Steen fetches directly from upstream; [0007](0007-cli-toolkit-terra.md)
  (lazygit), [0009](0009-keyd-tap-hold-super.md) (keyd), [0002](0002-base-desktop-plumbing.md)
  (Nerd Font).

## Why

Three artifacts are fetched at build time from third-party upstreams by URL:

| Artifact | Current source | Containerfile |
|---|---|---|
| keyd | `github.com/rvaiya/keyd` (git clone, `ARG KEYD_VERSION=v2.6.0`) | source build in the `keyd-build` stage |
| JetBrainsMono Nerd Font | `github.com/ryanoasis/nerd-fonts` release asset (`ARG NERD_FONT_VERSION=v3.4.0`) | `curl … JetBrainsMono.tar.xz` |
| lazygit | `github.com/jesseduffield/lazygit` release binary (`ARG LAZYGIT_VERSION=0.63.1`) | `curl … lazygit_*_linux_x86_64.tar.gz` |

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

### lazygit — switch from release-binary to a source build

lazygit is Go, so rather than mirror a release binary into the fork, **build it from source**
in a throwaway stage (same pattern as keyd). That needs nothing published in the fork beyond
the tag:
```dockerfile
FROM registry.fedoraproject.org/fedora:44 AS lazygit-build
ARG LAZYGIT_VERSION=v0.63.1
RUN dnf5 -y install git golang \
 && git clone --depth 1 --branch "$LAZYGIT_VERSION" https://github.com/reinier/lazygit /src \
 && cd /src && go build -o /out/lazygit .
# final stage: COPY --from=lazygit-build /out/lazygit /usr/bin/lazygit
```
Prereq: fork `jesseduffield/lazygit` with the `v0.63.1` tag. (Alternative: publish a release
in the fork carrying the `linux_x86_64` tarball and keep the `curl` — more manual upkeep per
bump; the source build is preferred, and consistent with keyd.)

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
build. The guards already assert presence (`command -v keyd`, `lazygit`, the Nerd Font glyph
check); this adds content verification.

## Ownership note

Pinning to forks means **we own the bump cadence**: pull upstream into the fork, review,
re-tag, bump the `ARG`. That's the point (deliberate over automatic), but it is manual work —
budget for it, or wire a Renovate-style reminder on the fork tags later.

## Prerequisites (before implementing)

- [ ] Fork `rvaiya/keyd` → `reinier/keyd`, ensure `v2.6.0` tag present.
- [ ] Fork `jesseduffield/lazygit` → `reinier/lazygit`, ensure `v0.63.1` tag present.
- [ ] Decide the Nerd Font approach (recommend option 1: vendor into `files/fonts/`).

## Verification

- Build stays green; `command -v keyd`, `command -v lazygit`, and `fc-list | grep -i
  jetbrainsmono` all still pass (existing guards), now sourced from the forks/vendored copy.
- (If added) the `sha256sum -c` steps pass, and a deliberately wrong digest fails the build.
