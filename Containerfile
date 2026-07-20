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
