# 1. Hosts Proxmox

**Objetivo**: instalar Proxmox VE 8.x en los PCs de VLAN10 y provisionar las VMs.
**Hosts**: pc01, pc03, pc04 (pc02 reservado para Exchange diferido).
**Depende de**: red física (switch L2 / VLANs / router) operativa.

## Prerequisitos

- Proxmox VE 8.x instalado en cada PC (bare metal).
- 1 NIC por PC → puerto **access** VLAN10. Bridge `vmbr0` sobre la NIC **sin `tag=`** (el switch aplica la VLAN).
- IP mgmt host `.11–.14`, gateway `10.1.0.1`, DNS → `dc01` (`10.1.0.20`).
- Storage **LVM-thin** (`local-lvm`) para discos de VM (habilita snapshots).
- ISOs en un storage de Proxmox: `WS2019`, `Win10/11`, `virtio-win.iso`, Ubuntu 22.04 cloud image.

## VMs de VLAN10

| VM | VMID | Host | IP | RAM | OS |
|----|------|------|----|-----|----|
| dc01 | 120 | pc01 | 10.1.0.20 | 4096 | WS2019 |
| exchange01 | 130 | pc02 | 10.1.0.30 | — | **diferido** |
| sql01 | 140 | pc03 | 10.1.0.40 | 4096 | WS2019 |
| appserver01 | 150 | pc03 | 10.1.0.50 | 6144 | Ubuntu 22.04 |
| ws01 | 160 | pc04 | 10.1.0.60 | 6144 | Win10/11 |
| ws02 | 170 | pc04 | 10.1.0.70 | 6144 | Win10/11 |

!!! tip "Convención"
    `VMID = 100 + último octeto de la IP` → mapea IP ↔ VMID de memoria.

## Provisión

Scripts en [`scripts/proxmox/`](https://github.com/ollerenac-uni/cyber-range/tree/master/scripts/proxmox):

```bash
# pc01
WIN_ISO=local:iso/WS2019.iso ./provision-windows-vm.sh 120 dc01 4096 4

# pc03
WIN_ISO=local:iso/WS2019.iso ./provision-windows-vm.sh 140 sql01 4096 4
SSHKEY=~/.ssh/id_ed25519.pub ./provision-appserver01.sh

# pc04
WIN_ISO=local:iso/Win11.iso OSTYPE_=win11 ./provision-windows-vm.sh 160 ws01 6144 4
WIN_ISO=local:iso/Win11.iso OSTYPE_=win11 ./provision-windows-vm.sh 170 ws02 6144 4
```

## Instalación del OS

=== "Windows (dc01, sql01, ws01, ws02)"
    1. Instalar por consola noVNC.
    2. Cargar el driver **VirtIO SCSI** desde `virtio-win.iso` durante el setup.
    3. Instalar **QEMU guest agent**.
    4. Al terminar: `qm set <VMID> --boot order=scsi0` y quitar los ISOs (`--ide2 none --ide3 none`).

=== "appserver01 (Ubuntu)"
    Headless vía cloud-init (IP/DNS/SSH automáticos). Solo: `qm start 150`.

## Verificación

- `qm list` muestra las VMs en cada host.
- Cada VM pinguea su gateway `10.1.0.1`.
- Tras construir dc01, las VMs resuelven DNS contra `10.1.0.20`.

## Snapshot

Tras dejar todo sano (todas las VMs + agentes Elastic Healthy):

```bash
qm snapshot <VMID> clean_state
```

!!! warning "No incluir en el reset"
    El host Proxmox nunca lleva agente CALDERA ni es target — es infraestructura.
    La VM SIEM (VLAN30) **nunca** se resetea: es el sink de datos.

Siguiente: **[DC / Active Directory](02-dc-ad.md)**.
