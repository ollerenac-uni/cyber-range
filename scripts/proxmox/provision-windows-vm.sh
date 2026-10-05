#!/usr/bin/env bash
# Provision a Windows VM on Proxmox for cyber-range VLAN10 (Target/Enterprise).
#
# Access-port VLAN: net0 goes on vmbr0 WITHOUT tag= — the switch applies VLAN10.
# Base Windows install is a console (noVNC) step; this script creates the VM and
# attaches the Windows + VirtIO ISOs. q35+OVMF+TPM2.0 so the same script serves
# Win11 (set OSTYPE_=win11) as well as WS2019/Win10.
#
# Usage: WIN_ISO=local:iso/WS2019.iso ./provision-windows-vm.sh VMID NAME RAM_MB CORES
set -euo pipefail

VMID="${1:?usage: provision-windows-vm.sh VMID NAME RAM_MB CORES}"
NAME="${2:?usage: provision-windows-vm.sh VMID NAME RAM_MB CORES}"
RAM="${3:?usage: ... RAM_MB}"
CORES="${4:?usage: ... CORES}"

# ---- config (override via env) ----
BRIDGE="${BRIDGE:-vmbr0}"
STORAGE="${STORAGE:-local-lvm}"
DISK_GB="${DISK_GB:-80}"
WIN_ISO="${WIN_ISO:?set WIN_ISO=local:iso/<windows>.iso}"
VIRTIO_ISO="${VIRTIO_ISO:-local:iso/virtio-win.iso}"
OSTYPE_="${OSTYPE_:-win10}"   # win10 = WS2019/Win10 ; set win11 for Windows 11

if qm status "$VMID" &>/dev/null; then
  echo "VMID $VMID ($NAME) ya existe — skip"
  exit 0
fi

qm create "$VMID" \
  --name "$NAME" \
  --ostype "$OSTYPE_" \
  --machine q35 \
  --bios ovmf \
  --efidisk0 "${STORAGE}:1,efitype=4m,pre-enrolled-keys=1" \
  --tpmstate0 "${STORAGE}:1,version=v2.0" \
  --cpu host --sockets 1 --cores "$CORES" \
  --memory "$RAM" \
  --scsihw virtio-scsi-single \
  --scsi0 "${STORAGE}:${DISK_GB},cache=writeback,discard=on" \
  --net0 "virtio,bridge=${BRIDGE}" \
  --ide2 "${WIN_ISO},media=cdrom" \
  --ide3 "${VIRTIO_ISO},media=cdrom" \
  --agent enabled=1 \
  --boot "order=ide2;scsi0"

echo "VM ${VMID} (${NAME}) creada."
echo "  1) Instala Windows por noVNC — carga el driver VirtIO SCSI desde virtio-win.iso."
echo "  2) Instala QEMU guest agent."
echo "  3) Al terminar:  qm set ${VMID} --boot order=scsi0  y quita los ISOs (--ide2 none --ide3 none)."
