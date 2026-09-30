#!/usr/bin/env bash
set -euo pipefail
# Portabel: BASE = folder script ini, jadi jalan dari mana saja
BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION=25.12.5
export IB="$BASE/extract/openwrt-imagebuilder-${VERSION}-x86-64.Linux-x86_64"
export SHELL=/bin/bash
export TMPDIR="$IB/tmp"
mkdir -p "$TMPDIR"
# gawk (butuh GNU awk, bukan mawk) + tools lokal (make/file/unzip/wget)
# host/bin imagebuilder rusak (symlink loop) -> JANGAN masukkan PATH
export LD_LIBRARY_PATH=/opt/data/tools/gawkdeb/usr/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
export STAGING_DIR_HOST="$IB/staging_dir/host"
GAWK=/opt/data/tools/gawkdeb/usr/bin
MKLOCAL=/opt/data/projects/openwrt-builder/25.12.5/make-local/usr/bin
HOSTBIN=/opt/data/projects/openwrt-builder/hostbin/usr/bin
export PATH="$GAWK:$MKLOCAL:$HOSTBIN:/usr/bin:/bin"
cd "$IB"

# Create files dir with README
mkdir -p files/etc/uci-defaults files/etc/config
cat > files/README-OPENWRT.txt <<'EOF'
OpenWrt 25.12.5 x86-64 UEFI — custom build "Masta-GOHIM"

AKSES (default)
  Router / LuCI : http://192.168.1.1
  SSH           : ssh root@192.168.1.1
  Username      : root
  Password      : (kosong / no password)
  Wireless      : Masta Gohim  (open, no password)
  Hostname      : Masta-GOHIM

DRIVER
  WiFi  : MT7921/MT7922 (mt7921e, mt7921s, mt7921u, mt792x-usb), MT7615, MT7915, MT76
  5G    : Quectel RM520N-GL — MHI PCIe (mhi_bus/mhi_net/mhi_wwan_ctrl)
          + USB QMI/MBIM/NCM (qmi_wwan, cdc_mbim, cdc_ncm, option)
  USB   : xHCI/EHCI/OHCI/UHCI, storage, hub

PAKET
  LuCI (theme openwrt) · PassWall · OpenClash · MWAN3 · Tailscale
  AdGuardHome · FileBrowser · Watchcat · Statistics · SQM · nlbwmon
  Samba · ModemManager · uqmi/libqmi/qmi-utils · parted/gdisk/smartmontools
  block-mount · htop · nano · bash · tmux
EOF

# board.json dibiarkan kosong agar 02_network deteksi dinamis


PACKAGES="luci luci-app-passwall luci-app-openclash luci-app-filebrowser luci-app-adguardhome adguardhome luci-app-mwan3 mwan3 luci-app-banip"

# rootfs unpacked = 165 MiB, squashfs = 46 MiB + packages -> 512 MiB partition
sed -i 's/^CONFIG_TARGET_ROOTFS_PARTSIZE=.*/CONFIG_TARGET_ROOTFS_PARTSIZE=512/' .config 2>/dev/null || \
  echo "CONFIG_TARGET_ROOTFS_PARTSIZE=512" >> .config
echo "[*] Building OpenWrt 25.12.5 x86-64 UEFI image (rootfs 512 MB)..."
make image PROFILE=generic PACKAGES="$PACKAGES" FILES=files/ BIN_DIR=bin IGNORE_ERRORS=m -j"$(nproc)"

echo "[*] Build done"
ls -la bin/targets/x86/64/*.img* 2>/dev/null || ls -la bin/