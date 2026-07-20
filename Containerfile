# Steen — bootstrap image (backlog/0001).
# Minimal, signed, bootable image on the Fedora Sway Atomic base. No desktop
# changes yet: the niri/DankMaterialShell swap (0002-0004) and the app set
# (0005+) land in later layers. This stage only establishes identity + trust so
# signing, CI, and `bootc switch` are proven before any desktop work.
FROM quay.io/fedora-ostree-desktops/sway-atomic:44

# --- Image-update trust ---
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
