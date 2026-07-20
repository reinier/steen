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
RUN dnf5 -y install \
      niri kitty xwayland-satellite \
      dms \
 && rm -f /etc/yum.repos.d/avengemedia-dms.repo \
          /etc/yum.repos.d/avengemedia-danklinux.repo \
 && dnf5 clean all

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
