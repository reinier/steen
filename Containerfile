# --- keyd: built from source, pinned to an upstream release tag (backlog/0009) ---
# keyd isn't in Fedora, and a pinned source build was judged more trustworthy than
# tracking someone's COPR. Built in a throwaway stage so the toolchain (git/make/gcc)
# never ships — only the artifacts are COPYed into the final image. The builder is
# fedora:44 to match the base's Fedora release, so the binary is ABI-compatible.
#
# FORCE_SYSTEMD=1 is required: keyd's Makefile only installs keyd.service when
# /run/systemd/system exists (or FORCE_SYSTEMD is set). There's no running systemd in
# a container build, so without it the unit is silently skipped and the image ships
# the binary but no service.
FROM registry.fedoraproject.org/fedora:44 AS keyd-build
ARG KEYD_VERSION=v2.6.0
RUN dnf5 -y install git make gcc kernel-headers \
 && git clone --depth 1 --branch "$KEYD_VERSION" https://github.com/rvaiya/keyd /src \
 && make -C /src PREFIX=/usr \
 && make -C /src PREFIX=/usr DESTDIR=/out FORCE_SYSTEMD=1 install

# Steen — niri + DankMaterialShell atomic desktop on Fedora Sway Atomic.
# Built one backlog item at a time; see backlog/ for the reasoning behind each layer.
FROM quay.io/fedora-ostree-desktops/sway-atomic:44

# --- Adapt the base for niri/DMS (backlog/0002) ---
# The base is a full Sway desktop. DMS replaces its bar, launcher, notifications and
# lock, and niri replaces the compositor, so subtract Sway's stack. Package names
# audited against sway-atomic:44 — see notes/base-audit-sway-atomic-44.md.
#
# NOTE: dnf also drops orphaned dependencies, so this pulls ~21 packages, not the 12
# named. Observed extras: `sddm` (orphaned once its sway session goes — fine, 0004
# replaces it with greetd anyway), `grimshot`, `sway-config-fedora`, `sway-systemd`,
# `thunar-archive-plugin`, `firefox-langpacks`, and `blueman` (it required dunst as its
# notification daemon; DMS provides the Bluetooth UI instead).
# `system-config-printer` is dragged out too — 0012 reinstalls it with `cups-pk-helper`.
# `firefox` goes by decision — Steen ships Chromium only (0005).
# `xdg-desktop-portal-wlr` goes so portal backend selection under niri is
# unambiguous (we add -gnome below; -gtk stays).
# Kept deliberately: kanshi, brightnessctl, playerctl, wl-clipboard, imv.
RUN dnf5 -y remove \
      sway sddm-wayland-sway \
      waybar rofi dunst swaylock swayidle swaybg \
      foot Thunar firefox \
      xdg-desktop-portal-wlr \
 && dnf5 clean all

# niri uses the GNOME portal for screencast/screenshot (base shipped only -wlr/-gtk).
# nautilus replaces Thunar — Steen needs Nautilus specifically for the Synology Drive
# file-manager extension (0008); nautilus-python is added there if the extension needs it.
RUN dnf5 -y install \
      xdg-desktop-portal-gnome \
      nautilus \
 && dnf5 clean all

# JetBrainsMono Nerd Font. Fedora packages only the non-Nerd `jetbrains-mono-fonts`
# (no icon glyphs, and not installed here anyway), so bake the patched font from the
# upstream release — pinned, no Homebrew (0015), no extra repo.
ARG NERD_FONT_VERSION=v3.4.0
RUN curl -fsSL -o /tmp/JetBrainsMono.tar.xz \
      "https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONT_VERSION}/JetBrainsMono.tar.xz" \
 && mkdir -p /usr/share/fonts/jetbrainsmono-nerd \
 && tar -xJf /tmp/JetBrainsMono.tar.xz -C /usr/share/fonts/jetbrainsmono-nerd \
 && rm -f /tmp/JetBrainsMono.tar.xz \
 && fc-cache -f /usr/share/fonts/jetbrainsmono-nerd

# Guard: the removals above must not have dragged the desktop plumbing out with them
# (dnf removes reverse-dependencies *and* orphaned dependencies). Names what's missing
# so a future cascade is self-diagnosing instead of a bare exit 1.
RUN missing=""; \
    for p in pipewire wireplumber NetworkManager systemd-resolved firewalld \
             xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-gnome \
             polkit gnome-keyring flatpak plymouth \
             fwupd fprintd bolt cups nautilus; do \
      rpm -q "$p" >/dev/null 2>&1 || missing="$missing $p"; \
    done; \
    if [ -n "$missing" ]; then \
      echo "ERROR: base adaptation removed required packages:$missing" >&2; exit 1; \
    fi; \
    echo "base plumbing intact"

# --- niri + DankMaterialShell desktop (backlog/0003) ---
# niri, kitty and xwayland-satellite come from Fedora (niri 26.04 is current).
#
# DMS does NOT come from Fedora: Fedora ships DankMaterialShell 1.4.4 (2026-03-21)
# while upstream is at 1.5.2, and DMS 1.5.x needs quickshell 0.3.x where Fedora still
# has 0.2.1. So the shell and its toolkit are taken as a MATCHED PAIR from upstream's
# *stable* (tagged-release) COPRs — deliberately NOT the rolling dms-git/quickshell-git
# that historically raced ahead of Fedora's quickshell and crashed the shell.
# Mixing COPR dms 1.5 with Fedora quickshell 0.2.1 is the known-broken combination;
# the guard below enforces that we never end up in it.
#
# xwayland-satellite is required because niri has NO built-in Xwayland — unlike
# sway/Hyprland it delegates X11 entirely to the satellite, which drives the
# xorg-x11-server-Xwayland already present in the base. Without it, X11 apps can't run.
#
# No version numbers anywhere here: Steen tracks the COPR's *stable channel*, so a new
# upstream release is picked up by the next rebuild rather than needing an edit.
# `dms` pulls its own stack — `dms-cli` (a strict `= %{version}` dep) and quickshell —
# so only `dms` is named.
#
# Repos are added for this one transaction then deleted, so the booted system has no
# COPRs configured; updates arrive via image rebuilds.
COPY files/avengemedia-dms.repo files/avengemedia-danklinux.repo /etc/yum.repos.d/
# niri Recommends waybar/fuzzel/swaylock/alacritty — install it with weak deps OFF, or
# a bare `dnf install niri` re-adds the exact Sway UI that 0002 removed (this shipped a
# double bar: waybar + the DMS bar). niri's *wanted* recommends — gnome-keyring,
# wireplumber, the portals — are already present, so nothing is lost. dms is installed
# SEPARATELY, with weak deps ON, because its recommends (matugen/cava/danksearch) ARE
# wanted.
RUN dnf5 -y install --setopt=install_weak_deps=False niri kitty xwayland-satellite \
 && dnf5 -y install dms \
 && rm -f /etc/yum.repos.d/avengemedia-dms.repo \
          /etc/yum.repos.d/avengemedia-danklinux.repo \
 && dnf5 clean all

# Belt-and-suspenders: purge any Sway/menu UI that slipped in as a weak dep of anything
# (or was shipped by the base, e.g. dmenu), then ASSERT it is gone. 0002's removal had
# no absence guard, which is exactly why the waybar regression stayed green. Never again.
RUN for p in waybar fuzzel wofi rofi dmenu dunst mako swaylock swayidle swaybg \
             alacritty foot sway Thunar firefox; do \
      rpm -q "$p" >/dev/null 2>&1 && dnf5 -y remove "$p" || true; \
    done \
 && dnf5 clean all
RUN set -e; present=""; \
    for p in waybar fuzzel wofi rofi dmenu dunst mako swaylock swayidle swaybg \
             alacritty foot sway Thunar firefox; do \
      rpm -q "$p" >/dev/null 2>&1 && present="$present $p"; \
    done; \
    [ -z "$present" ] || { echo "ERROR: unwanted UI still present:$present" >&2; exit 1; }; \
    echo "no stray Sway/menu UI present"

# Guard: assert PROVENANCE, not versions.
#
# dms's quickshell dependency is the UNVERSIONED `(quickshell or quickshell-git)`, so
# rpm is equally satisfied by Fedora's much older quickshell — it only resolves to the
# COPR build because that repo is enabled and dnf takes the highest version. That makes
# the pairing an accident of repo ordering rather than something rpm enforces, and a
# silently mismatched quickshell is what crashed the shell on 2026-06-12.
#
# So: check quickshell came from the avengemedia channel (same train as dms). This
# holds for every future release without pinning a number.
RUN set -e; \
    rpm -q niri kitty xwayland-satellite dms dms-cli quickshell >/dev/null; \
    ! rpm -q DankMaterialShell >/dev/null 2>&1 \
      || { echo "ERROR: Fedora's DankMaterialShell is installed alongside COPR dms" >&2; exit 1; }; \
    command -v niri >/dev/null || { echo "ERROR: niri binary missing" >&2; exit 1; }; \
    command -v dms  >/dev/null || { echo "ERROR: dms CLI missing" >&2; exit 1; }; \
    qs_repo="$(dnf5 repoquery --installed --qf '%{from_repo}' quickshell | head -1)"; \
    case "$qs_repo" in \
      *avengemedia*) ;; \
      *) echo "ERROR: quickshell came from '${qs_repo}', not the avengemedia COPR." >&2; \
         echo "       dms only declares '(quickshell or quickshell-git)' with no version," >&2; \
         echo "       so it accepts Fedora's older build and then breaks at runtime." >&2; \
         exit 1;; \
    esac; \
    echo "desktop core: niri $(rpm -q --qf '%{VERSION}' niri), dms $(rpm -q --qf '%{VERSION}' dms), quickshell $(rpm -q --qf '%{VERSION}' quickshell) [${qs_repo}]"

# --- Remove Sway-spin leftovers (backlog/0002; audited 2026-07-21) ---
# The base ships apps/agents redundant with DMS/niri, found via an image audit:
#  - network-manager-applet / nm-connection-editor : the nm-applet wifi tray icon (DMS owns network UI)
#  - xfce4-panel / tuned-switcher / xarchiver / imv : stray launcher entries not chosen
#  - ibus + CJK engines                             : IME stack (CJK dropped in 0017)
#  - orca                                           : screen reader autostarting
# `localsearch` (the tracker file indexer) is NOT removed: nautilus HARD-Requires it
# (GNOME 50 wired tracker into Files' search), so removing it drags nautilus out. Its
# background indexing is stopped by masking its autostart instead (below).
# KEPT on purpose: pavucontrol (advanced audio routing), lxqt-policykit (the working
# polkit agent), gnome-keyring, grim/slurp/wlr-randr (useful wlroots CLI), geoclue2
# (only its demo-agent autostart is masked). Removed one-by-one and skip-if-absent so a
# renamed/missing package never fails the transaction; the absence guard is the net.
RUN for p in network-manager-applet nm-connection-editor \
             xfce4-panel tuned-switcher xarchiver imv \
             orca \
             ibus-typing-booster ibus-m17n ibus-anthy ibus-hangul ibus-chewing \
             ibus-libpinyin ibus-setup ibus-panel ibus; do \
      rpm -q "$p" >/dev/null 2>&1 && dnf5 -y remove "$p" || true; \
    done; \
    dnf5 clean all || true
# Mask the autostarts of agents we KEEP (geoclue2 for location; localsearch for
# nautilus search) so neither runs a background agent/indexer at login.
RUN rm -f /etc/xdg/autostart/geoclue-demo-agent.desktop \
          /etc/xdg/autostart/localsearch-3.desktop

# Absence guard: the leftovers must be gone, the kept-but-masked autostarts must be gone,
# AND the base plumbing / polkit agent / nautilus (+ its localsearch dep) must have
# survived any dependency cascade (the lesson from the system-config-printer / waybar
# cascades — always guard both directions).
RUN set -e; present=""; \
    for p in network-manager-applet nm-connection-editor xfce4-panel tuned-switcher \
             xarchiver imv orca ibus; do \
      rpm -q "$p" >/dev/null 2>&1 && present="$present $p"; \
    done; \
    [ -z "$present" ] || { echo "ERROR: Sway-spin leftovers still present:$present" >&2; exit 1; }; \
    for a in geoclue-demo-agent localsearch-3; do \
      ! test -e "/etc/xdg/autostart/$a.desktop" || { echo "ERROR: $a autostart still present" >&2; exit 1; }; \
    done; \
    rpm -q pipewire wireplumber NetworkManager xdg-desktop-portal-gnome polkit \
           lxqt-policykit gnome-keyring nautilus localsearch dms niri pavucontrol >/dev/null; \
    echo "sway-spin leftovers removed; nautilus+localsearch kept (indexer autostart masked); plumbing intact"

# --- Login: greetd + dms-greeter (backlog/0004) ---
# Boots straight into niri, no session picker. dms-greeter comes from the same
# avengemedia/danklinux channel already used for quickshell, so it rides the same
# release train as dms; it Requires greetd, which Fedora provides.
#
# Deliberately NOT hand-written here (unlike Zirconium, which predates these):
#   * sysusers.d / tmpfiles.d — the dms-greeter package ships its own, creating the
#     `greeter` user, /var/cache/dms-greeter and /var/lib/greeter.
#   * --cache-dir — /var/cache/dms-greeter is already dms-greeter's default.
#   * the sed that stripped a stale niri `debug {}` block from the greeter — that
#     block no longer exists as of dms-greeter 1.5.x, so the patch is obsolete.
COPY files/avengemedia-danklinux.repo /etc/yum.repos.d/
RUN dnf5 -y install dms-greeter \
 && rm -f /etc/yum.repos.d/avengemedia-danklinux.repo \
 && dnf5 clean all

COPY files/greetd-config.toml /etc/greetd/config.toml
COPY files/greetd-spawn.pam /usr/lib/pam.d/greetd-spawn
COPY files/greetd-spawn.pam_env.conf /usr/share/greetd/greetd-spawn.pam_env.conf

# greetd is the login path; dms.service (shipped by dms as a user unit) is the shell
# inside each user session.
RUN systemctl enable greetd.service \
 && systemctl --global enable dms.service

# Guard: the greeter must be installed and wired, and no second display manager may
# exist — the base's sddm was removed by 0002's cascade and must stay gone, or two
# DMs would fight over the seat. Versions are printed (not asserted) so drift between
# dms and dms-greeter is visible in the log without pinning numbers.
RUN set -e; \
    rpm -q greetd dms-greeter >/dev/null; \
    command -v dms-greeter >/dev/null || { echo "ERROR: dms-greeter binary missing" >&2; exit 1; }; \
    test -f /etc/greetd/config.toml || { echo "ERROR: greetd config missing" >&2; exit 1; }; \
    test -f /usr/lib/pam.d/greetd-spawn || { echo "ERROR: greetd-spawn PAM stack missing" >&2; exit 1; }; \
    ! rpm -q sddm >/dev/null 2>&1 || { echo "ERROR: sddm is installed alongside greetd" >&2; exit 1; }; \
    systemctl is-enabled greetd.service >/dev/null || { echo "ERROR: greetd.service is not enabled" >&2; exit 1; }; \
    echo "login: greetd $(rpm -q --qf '%{VERSION}' greetd) + dms-greeter $(rpm -q --qf '%{VERSION}' dms-greeter) (dms $(rpm -q --qf '%{VERSION}' dms))"

# --- Native Chromium + free codecs (backlog/0005) ---
# Native (non-Flatpak) so 1Password's native-messaging works with no wrappers and the
# chrome-* app_ids niri window-rules / web-app launchers rely on stay intact. Fedora's
# chromium links the system ffmpeg (H.264/AAC stripped), so libavcodec-freeworld from
# RPM Fusion *free* supplies those codecs additively — without it, Teams WebRTC video
# and <video> mp4 playback break. Only the free release repo is added, then removed.
RUN dnf5 -y install "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
 && dnf5 -y install chromium libavcodec-freeworld \
 && rm -f /etc/yum.repos.d/rpmfusion-*.repo \
 && dnf5 clean all

# --- 1Password: desktop app + CLI (backlog/0006) ---
# rpm's hardened unpacker refuses to create package directories through the
# /opt -> var/opt symlink, and /var content wouldn't ship or update with the image
# anyway. So: swap /opt for a real directory for the transaction, relocate the payload
# into /usr, restore the symlink exactly as the base had it (readlink fails loudly if a
# future base stops symlinking /opt), and let tmpfiles.d recreate /opt/1Password at boot.
# The setuid/setgid bits must be baked here because /usr is read-only at runtime.
COPY files/1password.repo /etc/yum.repos.d/1password.repo
# Ships in the image so the onepassword groups are recreated at every boot — the RPM's
# imperative groupadd does NOT survive a bootc switch (first-boot bug: groups vanished,
# setgid pointed at gid 1000 = the user's own group). See the drop-in.
COPY files/1password-sysusers.conf /usr/lib/sysusers.d/1password-steen.conf
RUN rpm --import https://downloads.1password.com/linux/keys/1password.asc \
 # Create onepassword / onepassword-cli / onepassword-mcp at FIXED GIDs *before*
 # install: the RPM's %post groupadd is conditional (`if ! getent group`), so it finds
 # them and skips, and our chgrp below bakes those fixed GIDs into the read-only /usr.
 && systemd-sysusers /usr/lib/sysusers.d/1password-steen.conf \
 && opt_link="$(readlink /opt)" \
 && rm /opt && mkdir /opt \
 # The %post scriptlet mkdir -p's under /usr/local, a dangling symlink into
 # var/usrlocal during the build; materialize it so the scriptlet succeeds.
 && mkdir -p "$(realpath -m /usr/local)" \
 && dnf5 -y install 1password 1password-cli \
 && rm -f /etc/yum.repos.d/1password.repo \
 && mkdir -p /usr/lib/opt \
 && mv /opt/1Password /usr/lib/opt/1Password \
 && rmdir /opt \
 && ln -s "$opt_link" /opt \
 # chrome-sandbox: setuid root (Electron sandbox).
 && chmod 4755 /usr/lib/opt/1Password/chrome-sandbox \
 # BrowserSupport: setgid onepassword (browser-extension <-> desktop-app link);
 # it fails its own integrity check without this.
 && chgrp onepassword /usr/lib/opt/1Password/1Password-BrowserSupport \
 && chmod 2755 /usr/lib/opt/1Password/1Password-BrowserSupport \
 # op: setgid onepassword-cli (CLI <-> desktop-app link and SSH agent).
 && chgrp onepassword-cli /usr/bin/op \
 && chmod 2755 /usr/bin/op \
 && dnf5 clean all
COPY files/1password-opt.conf /usr/lib/tmpfiles.d/1password-opt.conf
# Without restricted ptrace, 1Password's portal file pickers (1PUX export, import,
# attachments) silently no-op. See the drop-in for the full explanation.
COPY files/60-1password-ptrace.conf /usr/lib/sysctl.d/60-1password-ptrace.conf

# --- CLI toolkit (backlog/0007) ---
# Baked so it's present at boot and updates with the image. Steen ships no Homebrew
# (0015), so this is the whole CLI baseline.
# chezmoi is REQUIRED for the dotfiles bootstrap (`chezmoi init --apply`) — rheniite
# got it from the Zirconium base; Steen must bake it. ripgrep (rg) is kitty's only
# useful Recommends, dropped when 0003 installs niri/kitty with weak deps off (the
# waybar fix); add it back explicitly. (nanosvg was only a fuzzel dep — correctly gone.)
RUN dnf5 -y install fish eza bat jq zip fuse-sshfs fzf xdg-terminal-exec ripgrep chezmoi \
 && dnf5 clean all
# Terra second, and only for what Fedora lacks, so it can't shadow Fedora packages.
COPY files/terra.repo /etc/yum.repos.d/terra.repo
RUN dnf5 -y install starship yazi \
 && rm -f /etc/yum.repos.d/terra.repo \
 && dnf5 clean all
# lazygit is packaged in NEITHER Fedora nor Terra (verified for f43/f44, terra and
# terra-extras). Rather than add a third-party COPR for a single tool, bake the
# upstream release binary — the same pinned-artifact pattern as keyd and the Nerd Font.
ARG LAZYGIT_VERSION=0.63.1
RUN curl -fsSL -o /tmp/lazygit.tar.gz \
      "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_linux_x86_64.tar.gz" \
 && tar -xzf /tmp/lazygit.tar.gz -C /usr/bin lazygit \
 && chmod 0755 /usr/bin/lazygit \
 && rm -f /tmp/lazygit.tar.gz

# --- Synology Drive (backlog/0008) ---
# The -noextra variant keeps the Nautilus extension (a compiled .so in %{_libdir},
# which is why nautilus-python isn't needed) but drops the GNOME-Shell-only
# appindicator weak deps — dead weight on niri, where DMS provides the SNI tray.
# Same /opt relocation as 1Password above.
COPY files/synology-drive.repo /etc/yum.repos.d/synology-drive.repo
RUN opt_link="$(readlink /opt)" \
 && rm /opt && mkdir /opt \
 && dnf5 -y install synology-drive-noextra \
 && rm -f /etc/yum.repos.d/synology-drive.repo \
 && mkdir -p /usr/lib/opt \
 && mv /opt/Synology /usr/lib/opt/Synology \
 && rmdir /opt \
 && ln -s "$opt_link" /opt \
 && dnf5 clean all
COPY files/synology-drive-opt.conf /usr/lib/tmpfiles.d/synology-drive-opt.conf

# --- keyd artifacts (backlog/0009) ---
# Binary + systemd unit + man pages only; the build toolchain stays in the throwaway
# stage. Deliberately NOT enabled here: the mapping and `systemctl enable keyd` live
# in dotfiles-steen, so the tap-hold behaviour is a dotfiles concern.
COPY --from=keyd-build /out/ /

# --- Tailscale (backlog/0010) ---
# From Fedora — no third-party repo needed (rheniite and Zirconium both used
# Tailscale's own repo). Enabled at boot so the daemon's socket exists and the
# dotfiles' `tailscale set --operator` works; only `tailscale up` is left interactive.
RUN dnf5 -y install tailscale \
 && systemctl enable tailscaled.service \
 && dnf5 clean all

# --- Flathub remote (backlog/0011) ---
# Configured via /etc/flatpak/remotes.d rather than `flatpak remote-add`, because the
# latter writes to /var/lib/flatpak — machine-local state a bootc image can't ship.
# This way Flathub is present on first boot with no per-user step.
RUN mkdir -p /etc/flatpak/remotes.d \
 && curl -fsSL -o /etc/flatpak/remotes.d/flathub.flatpakrepo \
      https://dl.flathub.org/repo/flathub.flatpakrepo

# --- Printer management GUI (backlog/0012) ---
# No GNOME Control Center on niri, and 0002's Sway subtraction orphaned the base's
# system-config-printer, so reinstall it. cups-pk-helper is what lets a wheel user
# add/remove printers via polkit with their own password instead of root.
RUN dnf5 -y install system-config-printer cups-pk-helper \
 && dnf5 clean all

# --- Dev containers (backlog/0017) ---
# distrobox is *the* ad-hoc CLI-tooling path now that Steen ships no Homebrew (0015).
# The base already has podman + toolbox but not distrobox. The audit also showed the
# Framework essentials — fprintd, fwupd, bolt — are already present, so 0017 reduces
# to this one package. ddcutil (external-monitor brightness) is deliberately skipped
# until it's actually wanted; framework_tool and iio-niri autorotate likewise.
RUN dnf5 -y install distrobox \
 && dnf5 clean all

# Guard for the whole app layer (0005-0012). The /opt relocations and setuid bits are
# the fragile parts: a silent failure there gives an app that simply never launches, or
# a 1Password that fails its own integrity check at runtime.
RUN set -e; \
    rpm -q chromium libavcodec-freeworld 1password 1password-cli \
           fish eza bat jq zip fuse-sshfs fzf xdg-terminal-exec ripgrep chezmoi starship yazi \
           synology-drive-noextra tailscale system-config-printer cups-pk-helper \
           distrobox podman >/dev/null; \
    command -v lazygit >/dev/null || { echo "ERROR: lazygit binary missing" >&2; exit 1; }; \
    ! rpm -q firefox >/dev/null 2>&1 || { echo "ERROR: firefox reappeared" >&2; exit 1; }; \
    test -L /opt || { echo "ERROR: /opt is no longer a symlink — ostree layout broken" >&2; exit 1; }; \
    test -d /usr/lib/opt/1Password || { echo "ERROR: 1Password payload not relocated into /usr" >&2; exit 1; }; \
    test -d /usr/lib/opt/Synology  || { echo "ERROR: Synology payload not relocated into /usr" >&2; exit 1; }; \
    test -u /usr/lib/opt/1Password/chrome-sandbox || { echo "ERROR: chrome-sandbox lost its setuid bit" >&2; exit 1; }; \
    test -g /usr/lib/opt/1Password/1Password-BrowserSupport || { echo "ERROR: 1Password-BrowserSupport lost its setgid bit" >&2; exit 1; }; \
    test -g /usr/bin/op || { echo "ERROR: op lost its setgid bit" >&2; exit 1; }; \
    test -f /usr/lib/sysusers.d/1password-steen.conf || { echo "ERROR: 1password sysusers drop-in missing (groups won't survive a bootc switch)" >&2; exit 1; }; \
    getent group onepassword     | grep -q ':1500:' || { echo "ERROR: onepassword group not at fixed gid 1500 (must be >=1000 for 1Password; collision? -> pick another >=1000)" >&2; exit 1; }; \
    getent group onepassword-cli | grep -q ':1501:' || { echo "ERROR: onepassword-cli group not at fixed gid 1501" >&2; exit 1; }; \
    [ "$(stat -c %g /usr/lib/opt/1Password/1Password-BrowserSupport)" = 1500 ] || { echo "ERROR: BrowserSupport setgid is $(stat -c '%g(%G)' /usr/lib/opt/1Password/1Password-BrowserSupport), not onepassword(1500)" >&2; exit 1; }; \
    [ "$(stat -c %g /usr/bin/op)" = 1501 ] || { echo "ERROR: op setgid is $(stat -c '%g(%G)' /usr/bin/op), not onepassword-cli(1501)" >&2; exit 1; }; \
    test -f /usr/lib/sysctl.d/60-1password-ptrace.conf || { echo "ERROR: ptrace_scope drop-in missing" >&2; exit 1; }; \
    command -v keyd >/dev/null || { echo "ERROR: keyd binary missing" >&2; exit 1; }; \
    test -f /usr/lib/systemd/system/keyd.service || { echo "ERROR: keyd.service missing — FORCE_SYSTEMD did not take" >&2; exit 1; }; \
    test -s /etc/flatpak/remotes.d/flathub.flatpakrepo || { echo "ERROR: Flathub remote missing" >&2; exit 1; }; \
    systemctl is-enabled tailscaled.service >/dev/null || { echo "ERROR: tailscaled is not enabled" >&2; exit 1; }; \
    echo "apps OK: chromium $(rpm -q --qf '%{VERSION}' chromium), 1password $(rpm -q --qf '%{VERSION}' 1password), synology $(rpm -q --qf '%{VERSION}' synology-drive-noextra), tailscale $(rpm -q --qf '%{VERSION}' tailscale), keyd at $(command -v keyd)"

# --- Update policy: manual only (backlog/0016) ---
# Steen updates in two manual streams (bootc + flatpak); nothing updates unattended.
# The base ships two OS auto-update timers — mask BOTH so they can never fire, even if
# something tries to pull them in (mask is stronger than disable: the unit is symlinked
# to /dev/null and cannot be started at all). `rpm-ostree-countme.timer` is left alone:
# it's privacy-respecting install-count telemetry, not an updater.
# To ever re-enable unattended updates you'd `systemctl unmask` first — intended.
RUN systemctl mask bootc-fetch-apply-updates.timer rpm-ostreed-automatic.timer \
 && for t in bootc-fetch-apply-updates.timer rpm-ostreed-automatic.timer; do \
      [ "$(readlink -f "/etc/systemd/system/$t")" = /dev/null ] \
        || { echo "ERROR: $t not masked" >&2; exit 1; }; \
    done \
 && echo "update timers masked: bootc-fetch-apply-updates + rpm-ostreed-automatic"

# --- Image-update trust (backlog/0001) ---
# Steen boots this image, so it must verify its own update stream
# (ghcr.io/reinier/steen). The fedora-ostree-desktops base ships only Fedora's
# default container policy, so establish the ghcr.io/reinier trust chain from
# scratch: bake the public key and add a sigstoreSigned policy.json entry.
COPY cosign.pub /usr/share/pki/containers/cosign.pub
COPY patch-policy.py /tmp/patch-policy.py
RUN python3 /tmp/patch-policy.py && rm -f /tmp/patch-policy.py

# sigstoreSigned above only takes effect if the reader is told to fetch sigstore
# *attachment* signatures for this namespace — otherwise verification looks in the
# wrong place ("a signature was required, but no signature exists"). Write it to
# both the factory template and /etc (whichever the system reads).
COPY files/steen-registries.yaml /usr/share/factory/etc/containers/registries.d/steen.yaml
RUN mkdir -p /etc/containers/registries.d \
 && cp /usr/share/factory/etc/containers/registries.d/steen.yaml \
       /etc/containers/registries.d/steen.yaml

# Fail the build on real bootc issues (warnings are fine).
RUN bootc container lint
