# Native 1Password (app + CLI)

- **Status:** done (CI-green 2026-07-20; real-boot checks in [0018](0018-first-boot-checklist.md))
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

- **The setgid groups must come from `sysusers.d`, not the RPM's `groupadd`.** This is
  the one real departure, forced by a first-boot bug (2026-07-20): the RPM creates
  `onepassword`/`onepassword-cli` via imperative `groupadd` in `%post`, whose
  `/etc/group` entry does **not** survive a `bootc switch`. On the running machine the
  groups were gone — `1Password-BrowserSupport` was setgid to a dead GID (browser
  integration's `SO_PEERCRED` peer check failed) and `op` was setgid to **gid 1000, the
  first user's own group** (broken + a small privilege bug).
  - Fix: ship `files/1password-sysusers.conf` (**fixed** GIDs) to `/usr/lib/sysusers.d/`,
    run `systemd-sysusers` on it *before* the dnf install (the `%post` groupadds are
    conditional, so they skip), then `chgrp` to the fixed-GID groups. The drop-in
    recreates the groups on every boot with the exact GIDs the setgid bits reference.
  - The guard asserts the groups' GIDs and the binaries' setgid GIDs match — so a GID
    collision or a regressed group fails the build. This is what the original guard
    missed (it checked *that* a setgid bit existed, not *which group* it pointed at).

- **The GID must be ≥ 1000** (`onepassword` 1500, `-cli` 1501, `-mcp` 1502). Found on
  real hardware (2026-07-20): with the groups at **923** (a system gid I picked to avoid
  colliding with the user), browser integration failed with *"invalid group attempted to
  connect, rejecting remote"* + `PipeAuthError(NoCreds)`. 1Password **explicitly rejects
  a helper group whose gid is < 1000** as untrusted
  ([1P community](https://www.1password.community/developers-69/why-the-requirement-for-group-id-1000-24469),
  [ublue #94](https://github.com/ublue-os/homebrew-tap/issues/94)). Every other check
  (setgid honored, manifest, ptrace) was correct; only the number was wrong.
  - **Upgrade caveat (ostree /etc staleness):** an image that already created
    `onepassword` at the old gid leaves it in `/etc/group`; sysusers.d won't change an
    existing group's gid on upgrade, so an already-installed machine needs a one-time
    `sudo groupmod -g 1500 onepassword` (+ `-cli 1501`, `-mcp 1502`) then a re-login to
    match the new baked setgid. Fresh installs are correct from first boot.
- **x86_64 only** (aarch64 ships CLI only). Re-verify the `/opt` vs `/usr` layout at
  version bumps (it has flip-flopped before).

## Verification

- 1Password unlocks, browser integration works, `op` works, and **1PUX export**
  opens a file dialog (the ptrace regression test).
