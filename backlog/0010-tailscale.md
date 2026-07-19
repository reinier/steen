# Tailscale (baked + enabled)

- **Status:** accepted
- **Created:** 2026-07-19
- **Area:** image (`Containerfile`, systemd preset)
- **Depends:** 0002
- **Related:** rheniite
  [`Containerfile`](../../rheniite/rheniite/Containerfile) `systemctl enable tailscaled`.

## Port, not redesign

Install `tailscale` and **enable `tailscaled`** in the image (or via preset) so the
daemon runs from first boot — otherwise its socket doesn't exist and the dotfiles'
`tailscale set --operator` fails. Only the interactive `tailscale up` is left to
the user.

## Notes

- Source: Tailscale's own stable RPM repo (as rheniite/Zirconium use), added then
  removed; record in `docs/third-party-repos.md`. Confirm whether `tailscale` is
  now in Fedora/Terra to avoid the extra repo.
- Zirconium enables `tailscaled` via its system preset — match that mechanism once
  0002 establishes a Steen preset file.

## Verification

- `systemctl is-enabled tailscaled` → enabled; after `tailscale up`, the node
  joins the tailnet.
