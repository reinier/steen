# Native 1Password (app + CLI)

- **Status:** accepted
- **Created:** 2026-07-19
- **Area:** image (`Containerfile`, `files/1password-opt.conf`, `files/60-1password-ptrace.conf`)
- **Depends:** 0002 (sysusers/tmpfiles), 0005 (native browsers for the integration)
- **Related:** **direct carryover** from rheniite —
  [`Containerfile`](../../rheniite/rheniite/Containerfile) "1Password" stanza,
  [`backlog/1password-opt-layout.md`](../../rheniite/rheniite/backlog/1password-opt-layout.md).

## Port, not redesign

The full rheniite treatment — this is one of the trickiest carryovers, port it
carefully:

- Install `1password` + `1password-cli` from `downloads.1password.com` stable repo
  (`1password.repo`, key imported, repo removed after).
- **`/opt` relocation:** 1Password 8.12.28+ ships its payload in `/opt/1Password`;
  on bootc `/opt` is a symlink into `/var`. Swap `/opt` for a real dir for the dnf
  transaction, `mv /opt/1Password /usr/lib/opt/1Password`, restore the symlink, and
  ship `files/1password-opt.conf` (tmpfiles.d) to recreate the path at boot. Also
  materialize `/usr/local` so the `%post` scriptlet doesn't fail.
- **setuid/setgid baked into `/usr`** (read-only at runtime): `chrome-sandbox`
  4755; `1Password-BrowserSupport` setgid `onepassword`; `op` setgid
  `onepassword-cli`. Create the groups first via `systemd-sysusers`.
- **`kernel.yama.ptrace_scope = 1`** (`files/60-1password-ptrace.conf`) — or the
  portal file pickers (1PUX export/import/attach) silently no-op. This is what let
  rheniite drop the earlier distrobox/Flatpak workarounds; keep it.

## Changes vs rheniite

- None expected — copy the stanza and both `files/*.conf` verbatim. **x86_64 only**
  (aarch64 ships CLI only). Re-verify the current 1Password version's `/opt` vs
  `/usr` layout at implementation time (it has flip-flopped before).

## Verification

- 1Password unlocks, browser integration works, `op` works, and **1PUX export**
  opens a file dialog (the ptrace regression test).
