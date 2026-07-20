# First-boot defaults — dropped

- **Status:** dropped (2026-07-20)
- **Created:** 2026-07-19
- **Area:** was image (`Containerfile`)
- **Related:** rheniite
  [`Containerfile`](../../rheniite/rheniite/Containerfile) "System defaults";
  successors: [0014](0014-config-and-dotfiles-steen.md) (timezone),
  [0018](0018-first-boot-checklist.md) (clock/NTP verification).

## Why this was dropped

The item carried two things, and neither survives as image work.

### Timezone → dotfiles (or nothing at all)

rheniite baked `Europe/Amsterdam` for a concrete reason: to avoid a `sudo
timedatectl` prompt landing late in a long `chezmoi apply`, which times out if you've
stepped away. That rationale **doesn't transfer to Steen**:

- **The installer already sets it.** Steen's install path is "install a Fedora atomic
  desktop, then `bootc switch`" — Anaconda prompts for timezone during that install,
  so the value is already correct before Steen ever boots. Baking `/etc/localtime`
  wouldn't fix a problem; it would *override a correct answer* with a hardcoded one,
  and `/etc` three-way merge semantics make that override murky rather than clean.
- **It's personal, and the image is public.** Steen has a public package and an
  end-user README. One person's timezone doesn't belong in a distributed image.

If it ever *does* need setting, it's a one-line `timedatectl set-timezone` in
`dotfiles-steen` — machine-local, no rebuild, no image opinion.

### Time sync → verify, don't add

Enabling a time daemon is genuinely image-level (root, early boot) — but Fedora
enables `chronyd` by default, so the base almost certainly already does it. The right
move is the same discipline that shrank 0002 and 0017: **verify on first boot and add
only if missing**, rather than installing something that's already there. Tracked as a
check in [0018](0018-first-boot-checklist.md) §F.

## Nothing left

No other concrete "first-boot default" was ever identified for this item, so it's
dropped rather than left as a stale plan.
