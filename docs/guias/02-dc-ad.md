# 2. DC / Active Directory

**Objetivo**: promover `dc01` como Domain Controller de `lab.local` y sembrar la superficie AD.
**VM**: dc01 (`10.1.0.20`, WS2019, pc01). **Depende de**: [Hosts Proxmox](01-proxmox.md).

!!! note "En construcción"
    Scripts de post-install (promote + misconfigs) = incremento en curso. Esta página
    documenta el procedimiento; los scripts se enlazan al completarse.

## Prerequisitos

- dc01 con WS2019 instalado, IP estática `10.1.0.20`, DNS self = `127.0.0.1`.
- Credenciales (DSRM, domain admin) en `.secrets/lab.env` (**gitignored**, nunca hardcodeadas).

## Pasos

1. **Promover forest**: `Install-ADDSForest` → dominio `lab.local`, nivel funcional WinThreshold
   (Exchange 2019 exige ≥ 2016).
2. **DNS**: rol instalado junto con AD DS. DHCP opcional.
3. **Estructura**: OUs / usuarios / grupos realistas (departamentos, admins, service accounts).
4. **Misconfiguraciones intencionales** (superficie vulnerable, capa B):

    | Misconfig | ATT&CK |
    |-----------|--------|
    | Cuentas de servicio Kerberoastables (SPN + password débil) | T1558.003 |
    | AS-REP roastable (sin preauth) | T1558.004 |
    | Delegación no restringida | abuse |
    | ACLs sobre-permisivas / GPP | T1484 / T1552 |

## Verificación

- `Get-ADDomain` responde `lab.local`.
- Un cliente une al dominio y resuelve `_ldap._tcp.dc._msdcs.lab.local`.
- BloodHound (desde VLAN20) descubre los paths sembrados.

## Telemetría

- Sysmon + Elastic Agent → Fleet (`10.3.0.10:8220`).
- Eventos clave: 4624/4625 (logon), 4672 (priv), 4768/4769 (Kerberos TGT/TGS), 4698 (sched task).

Siguiente: **[Exchange](03-exchange.md)** *(diferido)* o **[SQL Server](04-sql-server.md)**.
