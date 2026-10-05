#!/usr/bin/env bash
# Provision appserver01 (Ubuntu 22.04) on Proxmox for cyber-range VLAN10.
#
# Fully headless via cloud-init: static IP, SSH key, hostname. No console step.
# Access-port VLAN: net0 on vmbr0 without tag= (switch applies VLAN10).
#
# Usage: SSHKEY=~/.ssh/id_ed25519.pub ./provision-appserver01.sh
set -euo pipefail

VMID="${VMID:-150}"
NAME="appserver01"

# ---- config (override via env) ----
BRIDGE="${BRIDGE:-vmbr0}"
STORAGE="${STORAGE:-local-lvm}"
IMG="${IMG:-/var/lib/vz/template/iso/jammy-server-cloudimg-amd64.img}"
RAM="${RAM:-6144}"
CORES="${CORES:-4}"
DISK_GB="${DISK_GB:-40}"
IP="${IP:-10.1.0.50/24}"
GW="${GW:-10.1.0.1}"
DNS="${DNS:-10.1.0.20}"          # dc01 (AD DNS)
SEARCH="${SEARCH:-lab.local}"
CIUSER="${CIUSER:-labadmin}"
SSHKEY="${SSHKEY:?set SSHKEY=/path/to/id.pub}"

if qm status "$VMID" &>/dev/null; then
  echo "VMID $VMID ($NAME) ya existe — skip"
  exit 0
fi

qm create "$VMID" \
  --name "$NAME" \
  --ostype l26 \
  --machine q35 \
  --cpu host --sockets 1 --cores "$CORES" \
  --memory "$RAM" \
  --scsihw virtio-scsi-single \
  --net0 "virtio,bridge=${BRIDGE}" \
  --agent enabled=1

qm importdisk "$VMID" "$IMG" "$STORAGE"
qm set "$VMID" --scsi0 "${STORAGE}:vm-${VMID}-disk-0,discard=on"
qm disk resize "$VMID" scsi0 "${DISK_GB}G"
qm set "$VMID" --ide2 "${STORAGE}:cloudinit"
qm set "$VMID" --boot "order=scsi0"
qm set "$VMID" --ciuser "$CIUSER" --sshkeys "$SSHKEY"
qm set "$VMID" --ipconfig0 "ip=${IP},gw=${GW}"
qm set "$VMID" --nameserver "$DNS" --searchdomain "$SEARCH"

echo "appserver01 (${VMID}) provisionado headless → qm start ${VMID}"
echo "  (config de servicios + sysmonforlinux/Elastic Agent = script post-install)"
