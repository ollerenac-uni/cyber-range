# 4. SQL Server

**Objetivo**: SQL Server 2019 en `sql01` con los "datos de infraestructura crítica" del escenario OilRig.
**VM**: sql01 (`10.1.0.40`, WS2019, pc03). **Depende de**: [DC / AD](02-dc-ad.md).

!!! note "SQL Server, no MySQL"
    El diseño usa **SQL Server 2019** (MSSQL) por el escenario CTID OilRig. Si necesitas
    MySQL en su lugar, avísame y ajusto.

!!! note "En construcción"
    Scripts de install + carga de datos = incremento pendiente.

## Prerequisitos

- sql01 domain-joined, 4 GB RAM.

## Pasos

1. Install silencioso de **SQL Server 2019 Developer** (gratis) vía `ConfigurationFile.ini`.
2. DB `sitedata` + import de datos de muestra.
3. Puerto **1433**; regla de firewall.
4. Login de dominio (`LAB\svc`) como DBO; SPN `MSSQLSvc/sql01.lab.local:1433`.

## Superficie vulnerable (EternalBlue)

- sql01 recibe parches **excepto MS17-010** (conserva **SMBv1**) → target **EternalBlue**
  (Wizard Spider). Documentar que ese parche queda fuera a propósito.

## Verificación

- `sqlcmd` conecta a `sitedata`.
- Kerberos: ticket de servicio `MSSQLSvc/...` emitido (4769).

## Telemetría

- Sysmon + Elastic Agent. Eventos SQL audit + SMB (lateral/EternalBlue).

Siguiente: **[App Server](05-appserver.md)**.
