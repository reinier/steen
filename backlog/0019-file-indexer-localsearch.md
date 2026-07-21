# Decide what to do with the file indexer (localsearch / tracker)

- **Status:** open (decision deferred 2026-07-21 — currently at the upstream default: runs)
- **Created:** 2026-07-21
- **Area:** image (`Containerfile` — an autostart mask and/or a tracker config drop-in)
- **Related:** [0002](0002-base-desktop-plumbing.md) (the leftover sweep this came out of);
  nautilus HARD-Requires `localsearch`, so it can't simply be removed.

## The question

`localsearch` (Fedora's rename of the tracker-3 file miner) crawls `$HOME` and builds a
search index of file **contents + metadata**. It came in with the Sway Atomic base and
**can't be removed** — nautilus 50 hard-`Requires` it for Files' search. So the only
lever is whether it **runs in the background** (indexes at login) or not.

Deliberately **not decided yet.** The image currently leaves it at the **upstream default
(runs)** — nothing done to it — so behaviour matches stock GNOME until this is resolved.

## Options

1. **Leave it running (current / default).** Nautilus content-search "just works"; after
   the initial crawl it's light on SSD + throttles on battery. Cost: an initial full-index
   spike, amplified if it crawls a large `~/SynologyDrive` mirror.
2. **Keep it running but exclude heavy dirs.** Ship a tracker config drop-in that excludes
   `~/SynologyDrive` (and similar sync/media dirs) from indexing. Best of both — content
   search of real docs, no churning through the sync mirror. A bit more config to own.
3. **Stop it at login (mask the autostart).** `rm /etc/xdg/autostart/localsearch-3.desktop`.
   No background indexer; rely on the CLI search Steen already ships (`ripgrep`, `fzf`,
   `yazi`). Nautilus content-search degrades to slow filename-only (though it can still be
   D-Bus-activated on demand). This was the first cut, reverted pending this decision.

## Considerations

- Steen's actual search workflow leans terminal (`rg`/`fzf`/`yazi`), which makes the GNOME
  indexer partly redundant — but Nautilus is still used (Synology extension), so its search
  isn't nothing.
- The one concrete downside of "runs" is the initial crawl over synced/media folders →
  option 2 targets exactly that.
- Fully masking (option 3) doesn't fully stop it — Nautilus can D-Bus-activate the miner on
  demand; to truly disable, also mask the `localsearch-3.service` user unit.

## To decide

Pick 1 / 2 / 3 after living with it. If 2, the deliverable is a
`~/.config/tracker/` (or `/etc/xdg`) exclude drop-in — small, and could live in
`dotfiles-steen` rather than the image since it's a per-user preference.
