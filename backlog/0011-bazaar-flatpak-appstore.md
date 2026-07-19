# Bazaar + Flatpak/Flathub (replaces native VSCodium)

- **Status:** accepted (approach), **proposed** (Bazaar source TBD)
- **Created:** 2026-07-19
- **Area:** image (`Containerfile`, flatpak preinstall, systemd unit)
- **Depends:** 0002
- **Related:** rheniite bakes native `codium` from the VSCodium repo —
  **Steen drops that**; Zirconium's `flatpak-add-flathub-repos` /
  `flatpak-preinstall` presets are the precedent for wiring Flathub in an image.

## Decision

Steen does **not** bake native VSCodium. Instead it ships **Bazaar**
([github.com/kolunmi/bazaar](https://github.com/kolunmi/bazaar), the Flatpak-first
app store Bazzite popularized) and apps are installed as **Flatpaks from Flathub**
(VSCodium included, if wanted, as `com.vscodium.codium`). This trades native-host
integration (real host terminal in VSCodium — rheniite's stated reason for going
native) for a simpler, sandboxed, self-service app model.

> Consequence to accept: a Flatpak VSCodium's integrated terminal is **sandboxed**,
> not the host shell — brew/`op`/podman/distrobox won't be on its `PATH` the way
> rheniite's native codium had them. If that matters, either keep a Flatpak
> `--talk-name`/`flatpak-spawn` shim in dotfiles or reconsider native codium. Note
> it and move on.

## Open sub-question — how to ship Bazaar

Bazaar is on [Flathub](https://flathub.org/en/apps/io.github.kolunmi.Bazaar) and
reportedly in some distros' software centers. Pick at implementation time:

1. **Native RPM** if Bazaar is in Fedora main / a trusted COPR (verify) — a real
   host app store, cleanest. **Preferred if it exists in Fedora.**
2. **Bazaar as a Flatpak** (`io.github.kolunmi.Bazaar`), preinstalled from Flathub
   at image build — no extra RPM repo, but an app store running sandboxed.

## Implementation sketch

- Ensure `flatpak` is installed (0002) and add the **Flathub** remote in the image
  (Zirconium's `flatpak-add-flathub-repos` approach — system remote, so it's there
  at first boot without a per-user step).
- Preinstall the base Flatpak set (mirror the app list rheniite's dotfiles install:
  Slack, Mattermost, Obsidian, LibreOffice, gThumb, DejaDup, smile, Gradia, …) via
  a `flatpak-preinstall`-style unit or the dotfiles — **decide split with 0014**
  (image = the app store + Flathub remote; dotfiles = the personal app list is the
  natural division).
- Install Bazaar per the chosen option above.

## Verification

- Bazaar launches, sees Flathub, installs/removes a Flatpak. Flathub remote is
  present on a fresh boot with no manual `flatpak remote-add`.
