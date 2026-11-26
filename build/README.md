# Building a Debian chroot for an embedded device

The fleet recipe, two stages:

**Stage 1 — on any Linux PC** (needs `debootstrap`; cross-arch is fine):

```sh
debootstrap --foreign --arch=$ARCH $SUITE rootfs http://ftp.debian.org/debian
tar -C rootfs -cf ${SUITE}_${ARCH}.tar .
# copy the tarball to the device's USB storage, extract to <disk>/debian/
```

Architectures in use: `armhf` (R9000 routers), `armel` (util-ap — its st80
kernel exposes no VFP, so hard-float is impossible; works fine on ARMv7
silicon regardless). Debian ships both for trixie.

**Stage 2 — on the device**, inside the extracted rootfs:

```sh
chroot /path/to/rootfs /build/chroot-install.sh
```

(chroot-install.sh must be copied into the rootfs first; it finishes
debootstrap, writes sources, installs the base toolset, and sets the
root password.)

Then wire the tree per the framework: `dd-wrt.sh` / `debian.sh` from this
repo, a `chroot-services.list` for the host's services, and the shared
`root/.ssh`. Per-device config lives in the `home-network` repo.
