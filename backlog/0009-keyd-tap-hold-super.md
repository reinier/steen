# keyd (tap-hold Super key), built from source

- **Status:** accepted
- **Created:** 2026-07-19
- **Area:** image (`Containerfile` throwaway build stage), dotfiles (mapping)
- **Depends:** 0001
- **Related:** **direct carryover** from rheniite —
  [`Containerfile`](../../rheniite/rheniite/Containerfile) `keyd-build` stage,
  [`docs/third-party-repos.md`](../../rheniite/rheniite/docs/third-party-repos.md) "keyd".

## Port, not redesign

Build `keyd` from source in a throwaway `FROM registry.fedoraproject.org/fedora:44`
stage (pinned `KEYD_VERSION`, `FORCE_SYSTEMD=1` so the unit installs), then
`COPY --from=` only the artifacts into the final image — toolchain never ships.
No COPR. This is the settled choice over kanata (kanata was the brew-based,
niri-scoped user-service approach in `dotfiles-bluefin-niri`; rheniite replaced it
with root keyd — simpler, no `input` group / uinput / re-login).

## Split

- **Image (here):** the `keyd` binary + `keyd.service` + man pages; do **not**
  enable the service in the image (rheniite enables it from dotfiles via a
  `run_onchange` that also `restorecon`s and installs `/etc/keyd/default.conf`).
- **dotfiles-steen:** the mapping (`leftmeta = overloadt2(meta, M-f12, 130)` —
  tap → Super+F12 (dank-lader), hold → Super) + the enable script. Carried from
  rheniite `system/keyd/`.

## Verification

- `keyd --version` matches the pinned tag; after the dotfiles enable step, tap
  Super → dank-lader, hold Super → niri modifier.
