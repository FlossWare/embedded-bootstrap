#!/bin/sh -x
# Stage 2 of a Debian chroot build — run INSIDE the extracted rootfs on the
# target device (after stage-1 `debootstrap --foreign` was done on a PC).
# Recovered 2026-11-26 from the fleet's working lineage (server-ap).
#
# Usage: edit $distro, then:  chroot <rootfs> /chroot-install.sh

distro=trixie
export LANG=C
set -e

/debootstrap/debootstrap --second-stage

cat <<EOT > /etc/apt/sources.list
deb http://ftp.debian.org/debian $distro main contrib non-free non-free-firmware
deb http://ftp.debian.org/debian $distro-updates main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security $distro-security main contrib non-free non-free-firmware
EOT

apt-get update -y
apt-get upgrade -y

# Base fleet toolset — host-specific services come from chroot-services.list
apt-get install -y dialog locales lsb-release ntp ntpdate openssh-server \
    rsync sshfs vim htop wget curl screen

dpkg-reconfigure locales
dpkg-reconfigure tzdata
passwd
