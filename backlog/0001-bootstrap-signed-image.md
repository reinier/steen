# Bootstrap: a signed, bootable image + CI

- **Status:** done (CI-green 2026-07-20; real-boot checks in [0018](0018-first-boot-checklist.md))
- **Created:** 2026-07-19
- **Area:** image (`Containerfile`), CI (`.github/workflows/`), signing
- **Depends:** 0000 (base image decided)
- **Related:** rheniite's signing setup
  ([`README.md` "Signed updates"](../../rheniite/rheniite/README.md),
  `patch-policy.py`, `reinier.pub`, `files/reinier-registries.yaml`,
  `.github/workflows/`).

## Goal

The smallest thing that is unmistakably **Steen**: a `Containerfile` that builds
`FROM quay.io/fedora-ostree-desktops/sway-atomic:44` (see
[0000](0000-base-image-choice.md)), is **signed by CI**, **verifies its own update
stream**, passes `bootc container lint`, and is reachable with
`sudo bootc switch ghcr.io/reinier/steen:latest`.

Because the base is already a full atomic **desktop**, this first image **boots to a
working (Sway) desktop** as-is — the niri/DMS swap comes in 0002–0004. That's a nice
property: 0001 is verifiably bootable before any desktop work, so signing/CI/rebase
are proven in isolation.

## Problem

rheniite's signing **chained on top of Zirconium's** baked policy — it only had to
*add* a `ghcr.io/reinier` entry. Steen's base is a stock Fedora image with no policy
requiring *our* namespace, so Steen must **establish its own trust chain**: bake a
public key, add a `sigstoreSigned` policy entry for `ghcr.io/reinier`, and tell the
reader to fetch sigstore *attachment* signatures for that namespace via
`registries.d` (the easy-to-miss half — "a signature was required, but no signature
exists" if omitted).

## Decisions to make

- **Signing key:** reuse reinier's existing rheniite key (`reinier.pub` +
  `SIGNING_SECRET`) or mint a Steen-specific cosign key. **Recommend reuse** to
  start; a fresh key is cleaner isolation later.
- **Registry / name:** `ghcr.io/reinier/steen`. Greenfield — call it `steen`
  throughout, no internal alias (unlike the zirconium/zirconolite convention).
- **Base pin:** **none.** The `FROM` floats on `sway-atomic:44` and always takes the
  latest Fedora 44 base; the daily cron rebuild is what pulls it in. rheniite's
  `pin-stable-base` discipline is deliberately **not** carried over — Steen tracks
  latest and relies on `bootc rollback` if a base regresses.

## Implementation sketch

1. `Containerfile`:
   ```dockerfile
   FROM quay.io/fedora-ostree-desktops/sway-atomic:44
   # (niri/DMS swap + app layers land in 0002+)
   COPY reinier.pub /usr/share/pki/containers/reinier.pub
   COPY patch-policy.py /tmp/patch-policy.py
   RUN python3 /tmp/patch-policy.py && rm -f /tmp/patch-policy.py   # add sigstoreSigned for ghcr.io/reinier
   COPY files/reinier-registries.yaml /usr/share/factory/etc/containers/registries.d/reinier.yaml
   RUN mkdir -p /etc/containers/registries.d \
    && cp /usr/share/factory/etc/containers/registries.d/reinier.yaml /etc/containers/registries.d/reinier.yaml
   RUN bootc container lint
   ```
   Port `patch-policy.py`, `reinier.pub`, `files/reinier-registries.yaml` from
   rheniite (adjust namespace comments to Steen). If `patch-policy.py` assumes
   Zirconium's exact `policy.json` shape, adapt it to the Sway Atomic base's policy.
2. CI (`.github/workflows/build.yaml`): build **x86_64**, `cosign sign` with
   `SIGNING_SECRET`, push `:latest` only (no snapshot/pin tags). Build on push, PR,
   and a daily cron (new base images).
3. Copy rheniite's `.github/` and repo-secret setup.

## Progress (2026-07-20)

Deliverables written: `Containerfile` (`FROM quay.io/fedora-ostree-desktops/sway-atomic:44`),
`patch-policy.py`, `files/steen-registries.yaml`, `cosign.pub`, and
`.github/workflows/build.yaml`.

**First build is green** (run `29730188115`, 6m40s): `podman build` ✅,
`bootc container lint` ✅, and the push **signed** the image
(`Creating signature: Signing image using a sigstore signature`). `SIGNING_SECRET`
was already set, and the key is the same one rheniite signs with — so Steen and
rheniite share the `ghcr.io/reinier` trust root. The key is passphrase-less, matching
the workflow's `--sign-passphrase-file=/dev/null`.

**Decided 2026-07-20:**
- **No pinning.** `FROM` floats on `sway-atomic:44`, always latest F44. Steen also
  publishes **only `:latest`** — no dated snapshot tags. `bootc rollback` is the
  recovery path.
- **Package is public** — confirmed already public on first push. This matters beyond
  cost: a private package would make `bootc switch` fail without registry auth,
  breaking the documented install. (The repo is public too, which is what makes
  Actions minutes free.)

**Deferred:** the end-to-end `bootc switch` on a real machine/VM (Verification below)
is intentionally postponed until enough of the desktop has landed to be worth booting.
Do it once 0002–0004 are in — not now.

## Verification

- `podman build` succeeds; `bootc container lint` passes on the Sway Atomic base.
- On a throwaway VM (install any Fedora atomic desktop):
  `sudo bootc switch ghcr.io/reinier/steen:latest` succeeds, reboots to a desktop,
  `bootc status` shows the signed Steen image.
- Tamper check: an **unsigned** push (missing `SIGNING_SECRET`) is **rejected** by
  `bootc switch` — proving the baked policy works (keep the secret set, or your own
  updates lock you out).
