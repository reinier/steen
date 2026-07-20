# Tailscale (baked + enabled)

- **Status:** done (CI-green 2026-07-20; real-boot checks in [0018](0018-first-boot-checklist.md))
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

## Implemented (2026-07-20) — no third-party repo needed

**`tailscale` is in Fedora 44.** rheniite and Zirconium both added Tailscale's own RPM
repo; Steen doesn't have to. So this reduces to a plain `dnf5 install tailscale` plus
`systemctl enable tailscaled.service`, and Tailscale drops off the third-party source
list entirely.
- Zirconium enables `tailscaled` via its system preset — match that mechanism once
  0002 establishes a Steen preset file.

## Verification

- `systemctl is-enabled tailscaled` → enabled; after `tailscale up`, the node
  joins the tailnet.
