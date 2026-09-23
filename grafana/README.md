# Observability

Telemetry collection and dashboards for the homelab: one [Grafana Alloy](https://github.com/grafana/alloy) pipeline feeding [VictoriaMetrics](https://github.com/VictoriaMetrics/VictoriaMetrics) and [VictoriaLogs](https://github.com/VictoriaMetrics/VictoriaLogs), visualised in a single provisioned [Grafana](https://github.com/grafana/grafana) dashboard.

## Highlights

- **One collector, every source.** Alloy replaces a node exporter, a log shipper and a scrape config with one declarative pipeline: host metrics, container metrics, container logs, router metrics and HTTP probes all flow through it.
- **Labels do double duty.** The same `uptime.enable` / `uptime.address` Docker labels that drive Glance links also become Blackbox probe targets here, so one label declares monitoring in two systems.
- **File-provisioned dashboard.** The dashboard is version-controlled JSON, provisioned on a 30-second scan interval rather than clicked together in the UI.
- **Portable, not hardcoded.** A templated datasource variable means the dashboard isn't tied to one Grafana instance's datasource UID.
- **Modern schema.** The dashboard is authored in Grafana's newer `dashboard.grafana.app/v2` model (elements and layout, not a flat panels array), which diffs far more cleanly in Git than the classic schema.

## Layout

| Path | Purpose |
| --- | --- |
| `config.alloy` | The full Alloy pipeline: scrape and log configs, relabeling rules, remote-write and remote-log targets. |
| `dashboard.json` | Grafana's file-provisioning config: registers a `homelab` dashboard provider watching this folder. |
| `server-overview.json` | The "Server Overview" dashboard: host, container, network and router panels. |

Grafana supports provisioning config in either YAML or JSON; this repo uses JSON throughout. I've assumed a flat layout above since I don't have this repo's real tree — if it separates Alloy and Grafana into their own subfolders (for example to match separate bind mounts), let me know and I'll adjust the paths and diagram.

## How it works

<!-- d2 diagram: OpenWrt router + host + cAdvisor + Docker logs + Blackbox probes -> Alloy -> VictoriaMetrics / VictoriaLogs -> Grafana (Server Overview) -->

**Alloy pipeline (`config.alloy`)**

| Source | Component | Destination |
| --- | --- | --- |
| Router traffic | `prometheus.scrape` against the OpenWrt `nlbwmon` exporter | VictoriaMetrics |
| Host stats | `prometheus.exporter.unix`, with cache/tmpfs/bind-mount filesystems excluded | VictoriaMetrics |
| Container stats | `prometheus.scrape` against [cAdvisor](https://github.com/google/cadvisor) | VictoriaMetrics |
| Container logs | `discovery.docker` + `loki.source.docker`, relabeled with the Compose service and project name | VictoriaLogs |
| Uptime probes | `prometheus.exporter.blackbox`, targets built from the `uptime.*` Docker labels | VictoriaMetrics |

Every target is relabeled with `constants.hostname` as `instance`, so metrics from this host are identifiable if a second host is ever added to the same VictoriaMetrics instance.

**Dashboard (`server-overview.json`)**

Five rows, each independently filterable through the `$job` / `$nodename` / `$node`, `$docker_host` / `$container_name`, and `$target` template variables:

| Row | Panels |
| --- | --- |
| At a Glance | CPU Busy, RAM Used, Root FS Used, Uptime (gauges and a stat) |
| System Stat History | CPU, Memory, Network Traffic (timeseries) |
| Docker Container Stat History | Docker - Memory Usage, Docker - CPU Usage (timeseries), Docker Container Restarts (heatmap) |
| Network Probes | Probe Status (stat), Probe Duration (timeseries) |
| Router Traffic | Router - Top Talkers, Router - Daily Traffic Trend (timeseries) |

## Design decisions

- **Themed thresholds.** Gauge thresholds use Catppuccin Frappé's green, peach and red, matching the [Stylix theme](../nix/) applied everywhere else on the desktop and server.
- **UI edits allowed, file stays authoritative.** `allowUiUpdates` lets the dashboard be tweaked in Grafana directly, but since it's still file-provisioned, the checked-in JSON is what actually ships on redeploy.
- **Cascading variables.** `$job` narrows `$nodename`, which narrows `$node`, so the instance picker only ever offers to valid combinations instead of every known label value.

**Stack:** Grafana Alloy · Grafana · VictoriaMetrics · VictoriaLogs · cAdvisor · Blackbox Exporter
