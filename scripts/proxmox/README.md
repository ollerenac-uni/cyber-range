# Proxmox provisioning — VLAN10 (Target / Enterprise)

Crea las VMs de VLAN10 en los hosts Proxmox (pc01, pc03, pc04).

> **Puerto switch = access VLAN10** → `net0` va en `vmbr0` **sin `tag=`**; el switch
> aplica la VLAN. No taguear en Proxmox (sería doble etiquetado).

## Prerequisitos (en cada host Proxmox)

- ISOs en un storage de Proxmox: Windows (WS2019 y Win10/11) + `virtio-win.iso`.
- Ubuntu 22.04 cloud image (`jammy-server-cloudimg-amd64.img`) para appserver01.
- Storage LVM-thin (default `local-lvm`; override con `STORAGE=`).

## VMIDs ( = 100 + último octeto de la IP )

| VM | VMID | Host | IP | RAM | OS |
|----|------|------|----|-----|----|
| dc01 | 120 | pc01 | 10.1.0.20 | 4096 | WS2019 |
| exchange01 | 130 | pc02 | 10.1.0.30 | — | **DIFERIDO** |
| sql01 | 140 | pc03 | 10.1.0.40 | 4096 | WS2019 |
| appserver01 | 150 | pc03 | 10.1.0.50 | 6144 | Ubuntu 22.04 |
| ws01 | 160 | pc04 | 10.1.0.60 | 6144 | Win10/11 |
| ws02 | 170 | pc04 | 10.1.0.70 | 6144 | Win10/11 |

## Invocaciones (por host)

**pc01**
```bash
WIN_ISO=local:iso/WS2019.iso ./provision-windows-vm.sh 120 dc01 4096 4
```

**pc03**
```bash
WIN_ISO=local:iso/WS2019.iso ./provision-windows-vm.sh 140 sql01 4096 4
SSHKEY=~/.ssh/id_ed25519.pub ./provision-appserver01.sh
```

**pc04**
```bash
WIN_ISO=local:iso/Win11.iso OSTYPE_=win11 ./provision-windows-vm.sh 160 ws01 6144 4
WIN_ISO=local:iso/Win11.iso OSTYPE_=win11 ./provision-windows-vm.sh 170 ws02 6144 4
```

## Post-provision

- **Windows**: instalar por noVNC (cargar driver **VirtIO SCSI** desde `virtio-win.iso`),
  luego QEMU guest agent. Al terminar: `qm set <VMID> --boot order=scsi0` y quitar ISOs.
- **appserver01**: headless → `qm start 150`.
- Config de dominio / servicios / telemetría (promote DC, join, SQL, Sysmon + Elastic
  Agent) = scripts **post-install** (siguiente incremento; manejan credenciales vía
  archivo gitignored, nunca hardcodeadas).

Orden global de build: ver `docs/vlan10-build.md`.
