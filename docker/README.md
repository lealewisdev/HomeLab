# Docker Compose Stack

70+ self-hosted services defined in one
 [Docker Compose](https://github.com/docker/compose) project, plus three custom
container images.

## Highlights

- **Single source of truth.** YAML anchors factor out shared concerns (restart
  and logging, networks, health-gated dependencies, VPN membership, privileged
  host access), reducing most service definitions to an image, volumes, labels
  and one merge line.
- **Label-driven configuration.** [Traefik](https://github.com/traefik/traefik)
  discovers routes from Docker labels, with certificates issued through an ACME
  DNS-01 challenge against Porkbun. The same labels declare uptime probes and
  dashboard categories for [Glance](https://github.com/glanceapp/glance).
- **Network segmentation.** A dedicated edge network, an `internal: true` data
  network with no route out, and host networking only for hardware-bound IoT
  services.
- **Health-gated startup.** Apps wait for a healthy database, the scraper waits
  for the VPN, and Zigbee2MQTT and the Matter server wait for the MQTT broker
  and border router respectively.
- **Shared data tier.** One custom
  [PostgreSQL](https://github.com/postgres/postgres) image serves 16
  applications, and one [Valkey](https://github.com/valkey-io/valkey) instance
  is shared through separate logical databases.

## Layout

| Path | Purpose |
| --- | --- |
| `compose.yaml` | The full stack: services, networks and shared configuration fragments, all under a `prod` [profile](https://docs.docker.com/compose/how-tos/profiles/). |
| `custom-images/byparr.Dockerfile` | SSH-client image that tunnels to a remote [Byparr](https://github.com/ThePhaseless/Byparr) instance. |
| `custom-images/postgres.Dockerfile` | Shared PostgreSQL 18 with vector search and geospatial support. |
| `custom-images/semaphore.Dockerfile` | [Semaphore UI](https://github.com/semaphoreui/semaphore) with the Ansible Docker collection added. |

On the host, each Dockerfile sits in its own build context (`./byparr`,
 `./postgres`, `./semaphore`) next to `compose.yaml`, alongside environment
 files, configuration and data directories that are not included here.

## How it works

<!-- d2 diagram to be added: LAN clients -> gluetun (WireGuard, publishes :8191)
 + byparr SSH container (shared namespace) -> external server running Byparr -->

| Area | Approach |
| --- | --- |
| Networks | `traefik` (edge bridge, static Traefik address, dynamic allocation confined to the upper half of the subnet), `data` (internal bridge for Postgres, Valkey, [MariaDB](https://github.com/MariaDB/server), [Meilisearch](https://github.com/meilisearch/meilisearch)), `gluetun` (VPN container), `wings0` (game servers via [Pelican Wings](https://github.com/pelican-dev/wings)), plus host networking for mDNS, Thread and Bluetooth. |
| Observability | [Grafana Alloy](https://github.com/grafana/alloy) collects telemetry, [VictoriaMetrics](https://github.com/VictoriaMetrics/VictoriaMetrics) and [VictoriaLogs](https://github.com/VictoriaMetrics/VictoriaLogs) store it, [Grafana](https://github.com/grafana/grafana) visualises it, and [cAdvisor](https://github.com/google/cadvisor) covers containers. Alerts go out through [ntfy](https://github.com/binwiederhier/ntfy) and [Apprise](https://github.com/caronc/apprise-api). The Alloy pipeline and dashboard live in [`grafana/`](../grafana/). |
| Home automation | [Home Assistant](https://github.com/home-assistant/core), [Zigbee2MQTT](https://github.com/Koenkk/zigbee2mqtt), the [Matter server](https://github.com/matter-js/matterjs-server) and the [OpenThread Border Router](https://github.com/openthread/ot-br-posix) run with host networking through one privileged anchor. |
| Scraping offload | Byparr's headless browser is CPU-heavy, so it runs on an external server. The local container shares [Gluetun](https://github.com/qdm12/gluetun)'s network namespace, so its SSH tunnel leaves through WireGuard, and Gluetun publishes the forwarded port on the LAN. |

## Custom images

| Image | Notable details |
| --- | --- |
| `byparr` | Multi-stage build on [Docker Hardened Images](https://github.com/docker-hardened-images/catalog), digest-pinned, runs as `nonroot`. Only the `ssh` binary, its config and libraries reach the runtime stage, and the key and config are mounted at runtime, never baked in. |
| `postgres` | Immich's [Postgres 18 image](https://github.com/immich-app/base-images) (with [VectorChord](https://github.com/tensorchord/VectorChord)) plus [PostGIS](https://github.com/postgis/postgis), digest-pinned. Installs without recommended packages, clears apt lists in the same layer and returns to the `postgres` user. |
| `semaphore` | Pinned to an exact release and digest, runs as the unprivileged `semaphore` user, and adds [`community.docker`](https://github.com/ansible-collections/community.docker) so playbooks can manage Docker hosts (see [`semaphore/`](../semaphore/)). |

## Design decisions

- **Least privilege.** Privileged mode is limited to hardware-bound IoT services
  plus Alloy and cAdvisor. The Docker socket is read-only wherever it is used
  only for discovery or metrics, and read-write only for the
  [Forgejo runner](https://code.forgejo.org/forgejo/runner) and Pelican Wings,
  which launch containers. Published ports bind to a specific host address
  rather than every interface.
- **Versioning.** Most application images track `:latest` and are pinned only
  when an upstream change breaks something. Custom images are pinned by digest
  from the start.
- **LAN-only, single host.** Everything is reachable only from the local network
  except one game server.

**Stack:** Docker Compose · Traefik · PostgreSQL · Valkey · Grafana Alloy ·
 VictoriaMetrics · Gluetun · Home Assistant
