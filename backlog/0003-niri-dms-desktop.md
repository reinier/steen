# niri + DankMaterialShell desktop, from Fedora stable

- **Status:** accepted
- **Created:** 2026-07-19
- **Area:** image (`Containerfile`)
- **Depends:** 0002
- **Related:** the proven stable-Fedora layering in
  [`dotfiles-bluefin-niri/README.md`](../../conium/dotfiles-bluefin-niri) +
  `notes/gnome-coexistence.md`; rheniite
  [`backlog/stabilize-git-packages.md`](../../rheniite/rheniite/backlog/stabilize-git-packages.md)
  (now superseded — its "best case" was COPR; ours is Fedora main).

## The payoff item

This is *why* Steen exists. The entire desktop core is one `dnf5 install` from
**Fedora main** — no `yalter/niri-git`, no `avengemedia/danklinux`, no
`avengemedia/dms-git`:

```dockerfile
RUN dnf5 -y install \
      niri DankMaterialShell quickshell kitty xwayland-satellite \
 && dnf5 clean all
```

`DankMaterialShell` `Requires` the whole DMS runtime, so it transitively pulls
**quickshell, dgop, matugen, danksearch, cliphist, cava** — the same set
`dotfiles-bluefin-niri` relies on. Naming `quickshell` explicitly is belt-and-
braces; drop it if the dep is reliable.

## Points to nail down

- **Package name casing:** the Fedora binary package is `DankMaterialShell`
  (capitalized), `1.4.4` on F44/F45.
- **The `dms` CLI comes with it.** `dms` is the Go-based CLI+daemon that powers
  `dms ipc call …`, `dms restart`, and matugen theming — every dank-lader entry
  and niri keybind that talks to the shell depends on it. The old COPRs split this
  into `dms` (QML shell) + `dms-cli` (Go binary), which is why Zirconium installed
  `dms dms-cli dms-greeter dgop dsearch quickshell-git`. Fedora folds the CLI into
  (or auto-pulls it with) `DankMaterialShell`: proof is that `dotfiles-bluefin-niri`
  installs **only** `DankMaterialShell` and its dank-lader `dms ipc` calls work. So
  don't name a separate CLI package — but **verify at build time** (`which dms`,
  `dms ipc call spotlight toggle`) and, if a distinct `dms-cli` subpackage turns out
  to exist on F44, add it. (`dms-greeter` is a separate COPR package — 0004.)
- **`xwayland-satellite`** is needed for X11 apps under niri (bluefin layers it).
- **`kitty`** is Steen's terminal (rheniite baked it; carried over).
- **Version:** niri `26.04`, DMS/quickshell whatever F44 currently ships — the
  point is they're **co-tested together**, unlike the git COPRs that raced ahead
  and crashed the shell (bluefin's `2026-06-12` breakage note).

## Config caveat (hand-off to 0014)

DMS normally generates niri's config via `dms setup`, which **can't run at image
build time**. On an atomic base the config must be **vendored** — exactly what
`dotfiles-bluefin-niri` does (`dot_config/niri/config.kdl` is a vendored
DMS-generated base with a final `include "local.kdl"`). Decide in
[0014](0014-config-and-dotfiles-steen.md) whether Steen bakes a default config
into `/usr/share/steen/...` (like Zirconium's zdots) or ships it purely via
`dotfiles-steen`. **Do not** carry Zirconium's zdots — it's authored against
git-HEAD DMS/niri and will skew against these stable binaries.

## Verification

- After 0004's greeter lands: log in, DMS bar/launcher/notifications come up,
  matugen theming applies, `niri msg` responds, `dms` IPC verbs work.
- `xwayland-satellite` running → an X11 app (e.g. an Electron app forced to X11)
  displays.
