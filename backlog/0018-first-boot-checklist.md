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
backlog item for anything that fails.

---

## A. Rebase and trust (0001)

- [ ] `sudo bootc switch ghcr.io/reinier/steen:latest` succeeds and reboots into Steen.
- [ ] `bootc status` shows the Steen image and confirms the **signature verified**.
- [ ] Negative test: an unsigned/tampered image is **rejected** (the baked policy
      requires a signature — this is the whole point of the trust chain).
- [ ] `sudo bootc upgrade` pulls a newer build and `bootc rollback` returns to the
      previous deployment (the no-pinning recovery path, 0016).

## B. The session comes up (0003, 0004)

- [ ] The greeter appears and logs **straight into niri — no session picker**.
- [ ] `niri msg` responds; DMS bar, launcher (spotlight), and notifications are up.
- [ ] `dms ipc call spotlight toggle` works (the CLI every keybind depends on).
- [ ] matugen theming applies and survives a wallpaper change.
- [ ] **X11 apps run** — proves `xwayland-satellite` is actually started, not just
      installed (niri has no built-in Xwayland). If not, wire its startup in
      `dotfiles-steen` / niri config.
- [ ] kitty opens as the terminal; Nerd Font glyphs render (`fc-list | grep -i jetbrains`).

## C. Base plumbing survived the Sway subtraction (0002)

- [ ] Audio works (`wpctl status`, sound out of speakers *and* headphones).
- [ ] WiFi connects (`nmcli`), and DNS resolves.
- [ ] **Screen sharing / screenshot works** — the real test of swapping
      `xdg-desktop-portal-wlr` for `-gnome`.
- [ ] Nautilus opens, and file dialogs (GTK portal) work from apps.
- [ ] No stray Sway leftovers: no waybar/dunst/swaybg processes.
- [ ] **`lxqt-policykit` actually prompts under niri** — it's the base's polkit agent,
      wired for Sway. If it doesn't autostart/prompt, autostart it from the dotfiles or
      replace it. *(Open question from 0002.)*
- [ ] **Keyring/ssh-agent works with `gcr3`** — the base ships gcr3, not gcr(4) which
      Zirconium used. If DMS's ssh-agent path wants gcr4, add it. *(Open question from 0002.)*
- [ ] **Bluetooth** — `blueman` was removed as a cascade of dropping dunst. Confirm
      DMS's Bluetooth UI is sufficient, or add a manager back.

## D. Hardware — Framework (0017)

- [ ] `fprintd-enroll` registers a fingerprint; it unlocks login and `sudo`.
- [ ] `fwupdmgr get-devices` lists firmware; an update applies. Framework BIOS needs
      `DisableCapsuleUpdateOnDisk=true` in `/etc/fwupd/uefi_capsule.conf`.
- [ ] Thunderbolt/USB-C dock authorizes (`boltctl`), external display output works.
- [ ] Suspend/resume, lid close, battery reporting, and screen brightness keys.
- [ ] Decide from real use whether `ddcutil` (external-monitor brightness) is wanted.

## E. Apps (0005–0012)

- [ ] Chromium plays an **H.264** video and Teams shows video (the `libavcodec-freeworld`
      test); no Firefox present.
- [ ] 1Password unlocks; browser integration works; `op` works; and **1PUX export opens
      a file dialog** — the `ptrace_scope=1` regression test that drove the whole fix.
- [ ] Synology Drive syncs and its Nautilus extension shows sync emblems.
- [ ] Printing: add a network printer via `system-config-printer` with a **polkit
      password prompt** (not root), and print a test page.
- [ ] **Flathub remote is present on a fresh boot** with no `flatpak remote-add`
      (the image ships it via `/etc/flatpak/remotes.d/` — the one part of 0011 that
      can only be proven on a real boot).
- [ ] After `chezmoi apply`: Bazaar is installed from the dotfiles' Flatpak list,
      launches, sees Flathub, and installs/removes a Flatpak.
- [ ] `tailscale up` joins the tailnet (`tailscaled` enabled from boot).

## F. Tooling and updates (0015, 0016)

- [ ] **No brew**: `brew` is not on `PATH` and `/home/linuxbrew` doesn't exist.
- [ ] CLI toolkit present and working (fish, starship, eza, bat, jq, lazygit, yazi, sshfs).
- [ ] `distrobox create` works — the ad-hoc CLI-tooling path that replaces brew.
- [ ] `systemctl list-timers` shows **no OS auto-update timer**; `flatpak update` and
      `bootc upgrade` are separate manual actions.
- [ ] Clock/timezone correct and NTP synced (`timedatectl`).

## G. Config layer (0014)

- [ ] `chezmoi apply` from `dotfiles-steen` produces a themed, bound desktop with no
      schema errors against **stable** niri/DMS (`niri validate`, DMS logs clean).
- [ ] keyd tap-hold Super works after the dotfiles enable step (tap → menu, hold → modifier).

---

## Findings log

Record what actually failed here, with the follow-up item it produced.

| Date | Check | Result | Follow-up |
|---|---|---|---|
| | | | |
