# 5. App Server

**Objetivo**: servidor de aplicación Linux con app web vulnerable + telemetría cross-platform.
**VM**: appserver01 (`10.1.0.50`, Ubuntu 22.04, pc03, 6 GB). **Depende de**: [Hosts Proxmox](01-proxmox.md).

!!! note "En construcción"
    Script de post-install (app + telemetría) = incremento pendiente. La provisión base
    (cloud-init) ya existe en [`scripts/proxmox/provision-appserver01.sh`](https://github.com/ollerenac-uni/cyber-range/blob/master/scripts/proxmox/provision-appserver01.sh).

## Prerequisitos

- appserver01 provisionado (headless, IP `10.1.0.50`, gw `10.1.0.1`, DNS `10.1.0.20`).
- Join a AD opcional vía SSSD.

## Pasos

1. Stack web (nginx/apache + app).
2. **App web vulnerable** (superficie, capa C): DVWA o app con CVE pineado (ej. Log4Shell/Struts)
   → vector de acceso inicial por web.
3. `auditd` + **sysmonforlinux** (vía Elastic Agent).

## Verificación

- App responde en su puerto.
- Elastic Agent Healthy en Fleet; llegan eventos Linux.

## Telemetría

- sysmonforlinux + auditd → Elastic Agent → Fleet (`10.3.0.10:8220`).
