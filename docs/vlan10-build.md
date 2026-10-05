# VLAN10 Build — Target / Enterprise

Red víctima (`10.1.0.0/24`, gw `10.1.0.1`), puertos switch 1–4 → **pc01–pc04** con Proxmox.
Es el entorno enterprise que atacan los APTs (APT29 / OilRig / Wizard Spider).

## Decisiones (locked)

- **Workstations**: Windows 10/11 Enterprise (evaluación).
- **Dominio**: `lab.local`.
- **Exchange**: **DIFERIDO** — se construye en fase posterior. `pc02` queda reservado. IP `10.1.0.30` reservada.
- **appserver01**: 6 GB RAM.

## Placement + RAM (hosts ~16 GB)

| Host | VM(s) | RAM VMs | Estado |
|------|-------|---------|--------|
| pc01 | dc01 `.20` | 4 GB | ✓ |
| pc02 | *reservado para exchange01 (diferido)* | — | libre |
| pc03 | sql01 `.40` + appserver01 `.50` | 4 + 6 = 10 GB | ✓ |
| pc04 | ws01 `.60` + ws02 `.70` | 6 + 6 = 12 GB | ✓ |

## Capa host — Proxmox (pc01–pc04)

- Proxmox VE 8.x bare metal.
- 1 NIC → puerto access VLAN10; bridge `vmbr0` sobre la NIC; IP mgmt host `.11–.14`, gw `10.1.0.1`, DNS → `dc01` (10.1.0.20).
- Storage LVM-thin (habilita snapshots).
- Cada VM: VirtIO drivers + QEMU guest agent.
- Reset: `qm snapshot` / `qm rollback`; snapshot `clean_state` al final.
- El host NUNCA lleva agente CALDERA ni es objetivo — es infraestructura.

## Capa VM — software + config

### dc01 — WS2019 · Domain Controller `.20`
- AD DS + DNS (DHCP opcional). `Install-ADDSForest`, nivel funcional WinThreshold.
- DNS self = 127.0.0.1. IP estática, gw 10.1.0.1.
- OUs / usuarios / grupos realistas + cuentas de servicio con **SPN** (realismo Kerberoasting).
- Rol en escenarios: compromiso de dominio (APT29 esc.2), Kerberos / DCSync.

### sql01 — WS2019 · SQL Server 2019 Developer `.40`
- Install silencioso. DB `sitedata` + datos de muestra. Puerto 1433.
- Login `LAB\svc` como DBO. SPN `MSSQLSvc/sql01.lab.local:1433`. Domain-joined.
- Rol: OilRig "critical infrastructure data" → exfiltración.

### appserver01 — Ubuntu 22.04 · App server `.50` · 6 GB
- Stack web (nginx/apache + app). Join AD opcional vía SSSD.
- `auditd` + **sysmonforlinux** (vía Elastic Agent).
- Rol: amplía superficie; telemetría cross-platform.

### ws01 / ws02 — Windows 10/11 Enterprise `.60` / `.70`
- Domain-joined, perfiles de usuario, Office + navegador con credenciales guardadas (Chrome DPAPI = paso manual, no scriptable por WinRM). Config por-usuario estilo CTID.
- Rol: **acceso inicial** (phishing/malware) de los 3 APTs; espionaje APT29; landing Emotet (Wizard Spider).

### exchange01 — WS2019 · Exchange 2019 `.30` — **DIFERIDO**
- Se construye en fase posterior (en pc02). Prereqs en orden: .NET 4.8 → VC++ redist → UCMA → IIS URL Rewrite → Windows features → `PrepareAD` → CU14+.
- EWS + `ApplicationImpersonation`. Buzones para usuarios AD.
- Difiere la parte **EWS de OilRig** (webshell TwoFace). La parte SQL de OilRig (sql01) no depende de esto.

## Telemetría (todas las VMs de VLAN10)

- **Sysmon 15.x** + `olafhartong/sysmon-modular` (full en workstations, reducida en servers).
- **Elastic Agent 8.x** (= versión del stack) enrolado a **Fleet** en VLAN30 (`10.3.0.10:8220`), con **Elastic Defend** modo **Detect**, integración Windows Event Log + System.
- Eventos Windows Security: 4624/4625/4672/4698/7045.
- appserver01: sysmonforlinux + auditd por el mismo agente.

> **Red**: telemetría VLAN10→VLAN30 = **inter-VLAN** → cruza el router (Fa0/0 100 Mbps). La ACL del router debe permitir Target→SIEM en **8220** (Fleet) y **9200** (ES output). Flujo continuo más pesado del lab.

## Baseline de seguridad (realismo de emulación)

- **Defender** en modo **Detect** durante runs (no Prevent). Desactivable selectivo para tests de credenciales.
- **WDigest** `UseLogonCredential=1` → Mimikatz saca plaintext.
- LSA protection OFF, Credential Guard OFF (WS2019 lo permite → razón de WS2019 sobre 2022).
- Reglas de firewall para tráfico del lab.

## Orden de instalación

```
1. Proxmox en pc01, pc03, pc04   (pc02 reservado)
2. dc01 → promover DC, DNS, usuarios/OUs/SPNs   (ANTES del join)
3. Resto VMs → DNS = 10.1.0.20 → domain join
4. sql01 + datos
5. appserver01
6. ws01 / ws02 config + perfiles
7. baseline seguridad en todas
8. Sysmon + Elastic Agent → enrolar a Fleet (VLAN30)
9. snapshot clean_state
--  exchange01 → fase posterior (pc02)
```
