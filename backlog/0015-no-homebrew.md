# No Homebrew — source the residue natively or via distrobox

- **Status:** accepted
- **Created:** 2026-07-19 (revised 2026-07-20 — brew dropped **entirely**; earlier
  plan was "bake brew thin")
- **Area:** image (`Containerfile`), dotfiles
- **Depends:** 0007 (the baked toolkit is what makes this possible)
- **Related:** 0002 (Nerd Font), 0014 (dotfiles), 0016 (update streams),
  0017 (distrobox, fwupd, framework_tool); rheniite
  [`README.md`](../../rheniite/rheniite/README.md) already moved the toolkit off brew.

## Decision

Steen ships **no Homebrew**. The core CLI toolkit is baked from Fedora/Terra (0007);
the handful of things brew used to cover are sourced another way. This removes the
ublue brew mechanism (baked tarball + `brew-setup.service` + PATH wiring) and one
more upstream — consistent with Steen's "nothing between you and Fedora" ethos.

## Where brew's residue goes now

| What brew provided | Steen's source |
|---|---|
| Core toolkit (`eza`/`bat`/`yazi`/`fish`/`starship`/`jq`/`zip`/`fzf`) | Fedora + Terra, **baked** (0007) |
| `lazygit` | not in Fedora/Terra → the Fedora `apps` **distrobox** (dejan COPR, exported to `~/.local/bin`), provisioned by `dotfiles-steen` — not baked (0020) |
| `kanata` | n/a — keyd in the image (0009) |
| JetBrainsMono **Nerd Font** | **baked from the Nerd Fonts release archive** (0002) — plain `jetbrains-mono-fonts` is in Fedora but lacks the icon glyphs |
| `framework_tool` | not needed for firmware — `fwupd`/LVFS covers Framework updates (0017); the EC utility is an **optional source-build** if you want it |
| Self-updating dev CLIs | per-user via their own installers, in `dotfiles-steen` (0014) — self-updating binaries don't belong in read-only `/usr` |
| Ad-hoc CLI tools | **distrobox/toolbox** (0017) — the atomic-native `brew install X` replacement — or add to the image (Fedora/Terra) and rebuild |

## Consequence (accepted)

You lose the frictionless per-user install of *arbitrary* CLI tools without an image
rebuild. On atomic Fedora the replacement is **distrobox**: a mutable Fedora/Arch
container where you `dnf`/`pacman` freely and `distrobox-export` binaries to the host.
For anything you reach for often, prefer packaging it into the image (Fedora/Terra)
over leaving it in a container.

## Verification

- No `brew` on `PATH`; `/home/linuxbrew` does not exist; no `brew-setup` unit.
- Core toolkit present and working (0007); Nerd Font glyphs render in kitty/DMS (0002).
- `distrobox create` works (the ad-hoc CLI-tooling path).
