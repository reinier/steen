# Native Synology Drive

- **Status:** done (CI-green 2026-07-20; real-boot checks in [0018](0018-first-boot-checklist.md))
- **Created:** 2026-07-19
- **Area:** image (`Containerfile`, `synology-drive.repo`, `files/synology-drive-opt.conf`)
- **Depends:** 0002
- **Related:** **direct carryover** from rheniite —
  [`Containerfile`](../../rheniite/rheniite/Containerfile) "Synology Drive" stanza,
  [`backlog/synology-drive.md`](../../rheniite/rheniite/backlog/synology-drive.md).

## Port, not redesign

`synology-drive-noextra` from the `emixampp/synology-drive` COPR (the `-noextra`
variant keeps the Nautilus extension, drops the GNOME-Shell-only appindicator weak
deps — right for niri, where DMS provides the SNI tray). Same `/opt` relocation
dance as 1Password (`/opt/Synology` → `/usr/lib/opt/Synology`, tmpfiles.d restores
`/var/opt/Synology` at boot). Repo added for the one install, then removed.

## Notes

- This is an **app-layer COPR** — one of Steen's third-party sources; record it in
  `docs/third-party-repos.md`. (Distinct from the desktop `dms-greeter` COPR: this
  one is elective, kept only because you use Synology Drive.)
- HiDPI: rheniite ships a `rl-synology-drive` wrapper + a `run_onchange` HiDPI
  fixup in dotfiles — that stays a **dotfiles-steen** concern, not image.

## Verification

- Synology Drive launches, syncs, and its Nautilus extension shows sync emblems
  alongside any other extensions.
