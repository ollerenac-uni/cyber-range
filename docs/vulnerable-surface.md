# Superficie Vulnerable Intencional — Cyber Range

Diseño de **qué** hace explotables a los targets y **cómo** garantizarlo de forma
reproducible, para que la emulación APT (APT29 / OilRig / Wizard Spider vía CALDERA)
siempre pueda ejecutar sus TTPs y generar telemetría de detección.

## Principio

La emulación CTID/CALDERA es **basada en comportamiento, no en explotar CVEs**. Arranca
de *assumed breach* o *el usuario ejecuta el payload*, y de ahí corre TTPs (robo de
credenciales, lateral con creds robadas, LOLBins). **Un OS parcheado no bloquea la
emulación — lo que la bloquea es el hardening.**

> **Estrategia**: parchear todo **excepto los agujeros intencionales**. La superficie
> vulnerable es deliberada y documentada aquí, no "todo sin parchar".

## OS de servidores: Windows Server 2019

| Criterio | WS2019 |
|---|---|
| Disponibilidad | ISO evaluación 180 días (gratis); `slmgr /rearm` ×5 → ~900 días |
| Servicios | AD DS, Exchange 2019, SQL 2019 |
| Exploitabilidad | hardening **opcional** — se puede apagar lo que bloquea los TTPs. WS2022 lo fuerza → inviable |

appserver01 = Ubuntu 22.04 (telemetría Linux + app web vulnerable).

## Capa A — Hardening-down (garantiza robo de credenciales + lateral)

Aplicado en el baseline de todas las VMs Windows:

| Toggle | Habilita (ATT&CK) |
|---|---|
| WDigest `UseLogonCredential=1` | Mimikatz plaintext — T1003.001 |
| Defender modo **Detect** (no Prevent) | implante vive → genera telemetría |
| LSA protection OFF · Credential Guard OFF | dump LSASS |
| SMB signing not required | Pass-the-Hash / relay — T1550.002 |

## Capa B — Misconfiguraciones AD deliberadas (sembradas por dc01)

La superficie real que explotan los APTs en enterprise; descubribles con BloodHound:

| Misconfig | ATT&CK |
|---|---|
| Cuentas de servicio Kerberoastables (SPN + password débil) | T1558.003 |
| Cuentas AS-REP roastable (sin preauth) | T1558.004 |
| Admin local reusado entre hosts | T1078 / lateral |
| Delegación no restringida | T1558 / abuse |
| ACLs sobre-permisivas, GPP passwords | T1484 / T1552 |

## Capa C — CVEs reales sembrados (acceso inicial realista)

Versión vulnerable **pineada, aislada, snapshotteada, documentada**:

| Exploit | Host | Config | Escenario |
|---|---|---|---|
| **EternalBlue / MS17-010** | sql01 (member server) | SMBv1 habilitado + **NO** aplicar parche MS17-010 | Wizard Spider — lateral/acceso |
| **App web vulnerable** | appserver01 (Ubuntu) | DVWA o app con CVE pineado (ej. Log4Shell/Struts) | acceso inicial por web |
| **ProxyShell** | exchange01 | Exchange 2019 en CU vulnerable | OilRig — EWS. **DIFERIDO** con Exchange |

> `sql01` recibe parches **excepto MS17-010** (conserva SMBv1). Documentar en su baseline
> que ese parche queda fuera a propósito.

## Mapeo por escenario

| APT | Capas | CVE real |
|---|---|---|
| APT29 | A + B | — (behavior-only) |
| OilRig | A + B + Exchange EWS | ProxyShell (diferido) |
| Wizard Spider | A + B + lateral SMB | EternalBlue (sql01) |

## Seguridad y reproducibilidad

- VLANs **internas/air-gapped** (sin uplink físico; solo NAT saliente) → correr sistemas
  intencionalmente vulnerables es seguro.
- **Snapshots** `clean_state` → reset tras cada run.
- Superficie vulnerable **documentada aquí** → reproducible, no accidental.
- El host Proxmox nunca es target ni corre payloads — solo infraestructura.

## Patch strategy por host

| Host | Parches | Agujero intencional |
|---|---|---|
| dc01 | estable | misconfigs AD (capa B) + hardening-down |
| sql01 | todos **menos MS17-010** | EternalBlue + hardening-down |
| appserver01 | Ubuntu al día | app web vulnerable pineada |
| exchange01 (diferido) | CU vulnerable pineado | ProxyShell |
| ws01 / ws02 | al día | hardening-down (acceso inicial por user-exec) |
