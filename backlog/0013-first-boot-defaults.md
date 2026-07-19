# First-boot defaults

- **Status:** accepted
- **Created:** 2026-07-19
- **Area:** image (`Containerfile`)
- **Depends:** 0001
- **Related:** rheniite
  [`Containerfile`](../../rheniite/rheniite/Containerfile) "System defaults".

## Port, not redesign

Small non-interactive defaults so a fresh install is sane without a mid-`chezmoi
apply` sudo prompt:

- **Timezone** `Europe/Amsterdam` baked (`ln -sf ../usr/share/zoneinfo/... /etc/localtime`),
  overridable per machine with `timedatectl set-timezone`.
- **NTP:** ensure a time-sync daemon is enabled (Zirconium uses `ntpd-rs`; Fedora
  default is `chronyd`). Pick one in 0002's preset and confirm here.
- Any other one-shot `/usr`-baked defaults that shouldn't need interactive sudo.

## Notes

- Keep this small — most machine setup belongs in `dotfiles-steen`, not the image.
- The `ptrace_scope=1` sysctl is 0006's concern, not here.

## Verification

- Fresh boot shows the right clock and an enabled, synced time daemon
  (`timedatectl` shows `System clock synchronized: yes`).
