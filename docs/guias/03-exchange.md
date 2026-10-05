# 3. Exchange

!!! warning "Diferido a fase posterior"
    Exchange **no** se construye en el MVP. `pc02` queda reservado para él. Difiere la parte
    **EWS de OilRig** (webshell TwoFace); la parte SQL de OilRig ([SQL Server](04-sql-server.md))
    no depende de esto.

**Objetivo**: Exchange Server 2019 en `exchange01` como target EWS del escenario OilRig.
**VM**: exchange01 (`10.1.0.30`, WS2019, pc02). **Depende de**: [DC / AD](02-dc-ad.md).

## Prerequisitos (cuando se retome)

- exchange01 domain-joined, 12 GB RAM.
- Prereqs **en orden**: .NET 4.8 → VC++ redist → UCMA → IIS URL Rewrite → Windows features → `PrepareAD`.

## Pasos

1. Instalar Exchange 2019 **CU14+** (o CU vulnerable pineado si se quiere **ProxyShell** real).
2. Buzones para los usuarios AD.
3. EWS + `ApplicationImpersonation` (lo usa OilRig).

## Superficie vulnerable (opcional)

- **ProxyShell**: Exchange 2019 en CU vulnerable → exploit real EWS. Aislado y snapshotteado.

## Telemetría

- Sysmon + Elastic Agent. Logs IIS/EWS + eventos Exchange.
