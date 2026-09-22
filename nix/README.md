# NixOS Server Configuration

Flake-based, fully declarative configuration for the single host that runs the homelab's Docker Compose stack. It covers disk and ZFS layout, boot, firewall, hardware, Docker, secrets and the my shell environment.

## Highlights

- **Single-source flake.** One flake describes the whole host, and every input follows a single nixpkgs (`nixos-unstable`), so the system and all modules evaluate against one package set.
- **Declarative storage.** [disko](https://github.com/nix-community/disko) defines the data disk and its [ZFS](https://github.com/openzfs/zfs) pool, and Docker cannot start before its datasets are mounted.
- **Default-deny firewall.** An nftables allow-list where every entry is commented with the service it belongs to.
- **Secrets scaffolding.** [sops-nix](https://github.com/Mic92/sops-nix) is wired to decrypt with an age key derived from the host's SSH key, ready for encrypted secrets.
- **Headless hardware.** Bluetooth, audio, printing, scanning and a USB radio dongle are configured.

## Layout

| File | Purpose |
| --- | --- |
| `flake.nix` | Entry point. Defines the `server` configuration and its inputs. |
| `configuration.nix` | System configuration: boot, ZFS, networking, hardware, services, Docker, secrets. |
| `disko-configuration.nix` | Partitioning and ZFS pool layout for the data disk. |
| `home/server.nix` | [Home Manager](https://github.com/nix-community/home-manager) configuration for my `admin` user. |

`hardware-configuration.nix` (generated per machine, and the source of the root filesystem) and `secrets/` (encrypted) are referenced but not included. Inputs are nixpkgs, Home Manager, disko, sops-nix and [Stylix](https://github.com/nix-community/stylix).

## How it works

<!-- d2 diagram: flake inputs -> "server" NixOS config -> configuration.nix / disko / Home Manager (home/server.nix) -->

| Area | Approach |
| --- | --- |
| Storage and boot | A single-partition GPT disk becomes a `storage` ZFS pool (`ashift=12`, zstd, `atime=off`) with a `data` dataset for media and Docker's data root. systemd-boot on EFI, with the pool imported at boot under a fixed `hostId`. |
| Docker host | ZFS storage driver, a data root on the pool, a dedicated address pool for container networks, a Docker Hub pull-through mirror, and `docker.service` requiring `zfs-mount.service`. [nix-ld](https://github.com/nix-community/nix-ld) runs unpatched binaries, and the system Python includes the Docker SDK for [`community.docker`](https://github.com/ansible-collections/community.docker). |
| Networking | nftables default-deny with `wpan0` (Thread) and Docker bridges trusted. Sysctls and [Avahi](https://github.com/avahi/avahi) mDNS reflection, limited to Matter service types, support the [OpenThread Border Router](https://github.com/openthread/ot-br-posix). A [Samba](https://github.com/samba-team/samba) share is restricted to LAN hosts with no guest access. |
| Audio and Bluetooth | [BlueZ](https://github.com/bluez/bluez) with an upstream fix applied as a hash-pinned patch, and [PipeWire](https://gitlab.freedesktop.org/pipewire/pipewire) with [WirePlumber](https://gitlab.freedesktop.org/pipewire/wireplumber) codec and role rules. `admin` lingers so user services run without a login. |
| Printing and scanning | [CUPS](https://github.com/OpenPrinting/cups) with a declaratively provisioned Canon SELPHY printer, and [SANE](https://gitlab.com/sane-project/backends) with `saned` for network scanning. |
| RTL-SDR | Kernel DVB drivers are blacklisted and hard-disabled so the dongle stays free for the ADS-B feeder container. |
| Access and secrets | `admin` (wheel, docker) and an unprivileged `guest`, with password SSH login disabled and home directories mode `700`. sops-nix is configured with an example secret, and [sops](https://github.com/getsops/sops) is installed for editing. |
| User environment | [fish](https://github.com/fish-shell/fish-shell), [Starship](https://github.com/starship/starship), [zoxide](https://github.com/ajeetdsouza/zoxide), [fzf](https://github.com/junegunn/fzf), [tmux](https://github.com/tmux/tmux), [uv](https://github.com/astral-sh/uv) and [Atuin](https://github.com/atuinsh/atuin) with a self-hosted history server. Stylix applies Catppuccin Frappé to explicitly enabled targets only. |

## Design decisions

- **Reproducible overrides.** Anything patched or fetched from outside nixpkgs, such as the BlueZ patch, is pinned by hash.
- **LAN-only.** Service ports are open on the host firewall but not exposed beyond the local network, except the Project Zomboid game ports.
- **Ordered startup.** Docker's dependency on ZFS mounts means containers never start against an empty data root.

**Stack:** NixOS · Nix flakes · ZFS · disko · Home Manager · sops-nix · nftables · PipeWire · BlueZ
