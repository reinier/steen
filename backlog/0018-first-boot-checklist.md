# First-boot checklist — what to verify on real hardware

- **Status:** open (living document — stays open until the machine is a daily driver)
- **Created:** 2026-07-20
- **Area:** verification (no image changes)
- **Depends:** everything — this is the collection point

## Why this exists

Almost nothing in this backlog can be *fully* proven in CI. A build that goes green
says the packages resolve and the image lints; it says nothing about whether niri
starts, the fingerprint reader enrolls, or 1Password's file picker opens. Rather than
leave a dozen items half-open forever, **an item may be closed once it's implemented
and CI-green, provided its real-hardware checks are migrated here.**

Work top-to-bottom on first boot; check things off as they pass, and open a new
backlog item for anything that fails. Each section has a **Test** block — copy-paste
commands, with the expected result noted where it isn't obvious.

---

## A. Rebase and trust (0001)

- [ ] `bootc switch` succeeds and reboots into Steen.
- [ ] `bootc status` shows the Steen image and the signature verified.
- [ ] Negative test: an unsigned/tampered image is **rejected** by the policy.
- [ ] `bootc upgrade` then `bootc rollback` both work (the no-pinning recovery path, 0016).

```sh
sudo bootc switch ghcr.io/reinier/steen:latest && sudo systemctl reboot
# after reboot:
bootc status                       # booted image = ghcr.io/reinier/steen, no "unverified"
grep -A3 '"ghcr.io/reinier"' /etc/containers/policy.json   # sigstoreSigned entry present
# signature is enforced by the switch itself; CI already proved an unsigned push is
# rejected, so a manual negative test is optional.
sudo bootc upgrade                 # pulls newer :latest (if any), stages it
sudo bootc rollback                # flips back to the prior deployment
```

## B. The session comes up (0003, 0004)

- [ ] Greeter appears and logs **straight into niri — no session picker**.
- [ ] `niri msg` responds; DMS bar, launcher, notifications are up.
- [ ] `dms ipc` works (the CLI every keybind depends on).
- [ ] **X11 apps run** — proves `xwayland-satellite` is *started*, not just installed.
- [ ] kitty opens; Nerd Font glyphs render.

```sh
niri msg version
echo "$XDG_SESSION_TYPE"                       # -> wayland
loginctl show-session "$XDG_SESSION_ID" -p Type # -> Type=wayland
dms ipc call spotlight toggle                  # launcher opens/closes
pgrep -af xwayland-satellite                    # MUST show a running process
DISPLAY=:0 xeyes                                # or any X11 app; if it displays, Xwayland works
fc-list | grep -i jetbrainsmono                 # font is present
# kitty should show powerline/nerd glyphs, e.g.:
printf '  \n'                 #  (arrow, distro, home) — no tofu
```

## C. Base plumbing survived the Sway subtraction (0002)

- [ ] Audio out (speakers *and* headphones).
- [ ] WiFi connects, DNS resolves.
- [ ] **Screencast/screenshot works** — the real test of `-wlr` → `-gnome`.
- [ ] Nautilus + GTK file dialogs work.
- [x] No stray Sway processes — leftover cleanup verified: no wifi tray icon, launcher shows only chosen apps.
- [x] **`lxqt-policykit` prompts under niri** — `pkexec true` pops a dialog ✓ (0002 open question RESOLVED).
- [x] **Keyring/ssh-agent works with `gcr3`** ✓ (0002 open question RESOLVED — no `gcr4` needed).
- [ ] **Bluetooth** works (blueman was cascade-removed).

```sh
wpctl status                                    # sink + source present; switch output and listen
nmcli device status ; resolvectl status | head  # connected + DNS servers
busctl --user list | grep xdg-desktop-portal    # portal running on the session bus
# screencast: open chromium -> https://webrtc.github.io/samples/src/content/getusermedia/gum/
#   -> "Share screen"; the picker that appears is the gnome portal (this is the real test).
pgrep -af 'waybar|dunst|swaybg|mako|swayidle'    # expect NOTHING
pgrep -af polkit                                 # lxqt-policykit-agent should be running
pkexec true                                      # MUST pop a password dialog (not just fail)
echo "$SSH_AUTH_SOCK"; systemctl --user status gcr-ssh-agent.socket 2>&1 | head -3
bluetoothctl show                                # controller present + powered
```

## D. Hardware — Framework (0017)

- [ ] Fingerprint enrolls and unlocks login + `sudo`.
- [x] `fwupd` sees firmware (`fwupdmgr get-devices` ✓); an update applies.
- [ ] Thunderbolt/dock authorizes; external display works.
- [ ] Suspend/resume, lid, battery, brightness keys.

```sh
fprintd-enroll                                   # follow prompts to enroll
sudo -k; sudo true                               # should offer fingerprint, then unlock
fwupdmgr get-devices                             # lists BIOS/EC/retimer etc.
# Framework BIOS needs this before an update applies:
echo 'DisableCapsuleUpdateOnDisk=true' | sudo tee -a /etc/fwupd/uefi_capsule.conf
fwupdmgr refresh --force && fwupdmgr get-updates
boltctl                                          # TB devices; `boltctl authorize <uuid>` if needed
systemctl suspend                                # then resume and confirm wifi/audio/display return
cat /sys/class/power_supply/BAT*/capacity        # battery reports a number
```

## E. Apps (0005–0012)

- [x] Chromium plays **H.264** (the `libavcodec-freeworld` test) ✓; no Firefox.
- [x] 1Password unlocks, integrates, `op` works, and **1PUX export opens a dialog** ✓
      (the `ptrace_scope=1` regression test — and browser integration works after the gid≥1000 fix, 0006).
- [ ] Synology Drive syncs; Nautilus emblems show.
- [ ] Printer adds via a **polkit prompt** (not root); test page prints.
- [x] **Flathub present + Bazaar installs Flatpaks** ✓ (no `remote-add` needed).
- [x] `tailscale up` joins the tailnet ✓.

```sh
rpm -q firefox || echo "no firefox (good)"
# H.264: open chromium to https://www.w3schools.com/html/mov_bbb.mp4 — it should play.
op --version && op signin                         # CLI auth
# 1Password GUI: unlock -> Settings -> Advanced -> Export -> a FILE DIALOG must appear.
#   (silent no-op here = ptrace_scope regression.)
flatpak remotes                                   # 'flathub' listed on first boot, no setup
systemctl is-enabled tailscaled                   # enabled
sudo tailscale up && tailscale status
# Synology Drive + system-config-printer are GUI; launch and exercise them.
```

## F. Tooling and updates (0015, 0016)

- [ ] **No brew** anywhere.
- [ ] CLI toolkit works.
- [ ] `distrobox create` works (the brew replacement).
- [ ] **No OS auto-update timer** active; updates are manual.
- [ ] Clock correct + time daemon enabled.

```sh
command -v brew && echo "BREW PRESENT (bad)" || echo "no brew (good)"
test -e /home/linuxbrew && echo "linuxbrew dir exists (bad)" || echo "clean"
for c in fish starship eza bat jq lazygit yazi sshfs; do command -v "$c" || echo "MISSING $c"; done
distrobox create -Y -n scratch -i registry.fedoraproject.org/fedora:44 && distrobox enter scratch -- true
# updates: NOTHING bootc/rpm-ostree should be listed as an active timer.
systemctl list-timers --all | grep -Ei 'bootc|rpm-ostree|update' || echo "no auto-update timer (good)"
timedatectl                                       # correct TZ + "System clock synchronized: yes"
# If 0016's mask landed, these read 'masked':
systemctl is-enabled bootc-fetch-apply-updates.timer rpm-ostreed-automatic.timer 2>&1
```

## G. Config layer (0014)

- [x] `chezmoi apply` from `dotfiles-steen` gives a bound desktop, `niri validate` clean ✓.
- [x] keyd tap-hold Super works after the dotfiles enable step ✓.

```sh
chezmoi apply                                     # or `chezmoi init --apply <repo>`
niri validate                                     # config parses against stable niri
journalctl --user -u dms -b | grep -iE 'error|warn' | head   # DMS log clean
systemctl status keyd                             # active after the dotfiles enable step
# then: tap Super -> app menu; hold Super -> window modifier.
```

---

## Findings log

Record what actually failed here, with the follow-up item it produced.

| Date | Check | Result | Follow-up |
|---|---|---|---|
| 2026-07-20 | C: no stray Sway UI | ❌ waybar ran alongside DMS bar; dmenu present | Fixed (image) — `niri` Recommends re-added them; weak-deps-off + purge + absence guard (0002/0003) |
| 2026-07-20 | B: niri using DMS config | ❌ install had niri's **stock default** config.kdl (waybar); `dms setup` then **failed — policy-disabled on immutable systems** | Fixed (dotfiles) — **vendor** config.kdl + dms/*.kdl (dms setup can't run on atomic); chezmoi deploys them (0014). Patch known 1.4→1.5 verb drift; validate remaining binds |
| 2026-07-20 | E: 1Password browser integration | ❌ extension can't reach app; `onepassword` group missing at runtime, `op` setgid to gid 1000 (user) | Fixed — groups via `sysusers.d` at fixed GIDs, not RPM `groupadd` (0006) |
| 2026-07-20 | B: DMS + niri + greeter | ✅ desktop core and DMS greeter come up | — |
| 2026-07-21 | E: 1Password browser integration | ✅ works after the gid≥1000 fix | 0006 done |
| 2026-07-21 | C: polkit prompt + gcr3 keyring | ✅ both work under niri | 0002 open questions RESOLVED |
| 2026-07-21 | Leftover cleanup verified | ✅ no wifi tray, launcher clean | 0002 |
| 2026-07-21 | E/D: H.264, 1PUX export, fwupd, Bazaar, tailscale, keyd tap-hold | ✅ all pass | — |
