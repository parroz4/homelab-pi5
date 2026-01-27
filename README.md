# Homelab Infrastructure - Raspberry Pi 5

> A production-grade self-hosted infrastructure running 23 containerized services on a Raspberry Pi 5, demonstrating DevOps practices, Infrastructure as Code, and system administration skills.

[![Docker](https://img.shields.io/badge/Docker-23_containers-blue?logo=docker)](https://www.docker.com/)
[![Raspberry Pi](https://img.shields.io/badge/Raspberry_Pi-5_(8GB)-red?logo=raspberrypi)](https://www.raspberrypi.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## About This Project

This repository documents a fully functional homelab infrastructure that I built and maintain. It showcases practical experience with:

- **Container Orchestration**: 23 Docker services managed via compose files
- **Infrastructure as Code**: All configurations versioned and reproducible
- **Networking & Security**: Zero-trust architecture with Cloudflare Tunnel
- **Monitoring & Observability**: Multi-layer monitoring stack with alerting
- **Backup & Disaster Recovery**: Automated 3-2-1 backup strategy
- **CI/CD Practices**: Automated sync scripts with secret sanitization

## Skills Demonstrated

| Area | Technologies |
|------|-------------|
| **Containerization** | Docker, Docker Compose, container networking |
| **Networking** | DNS (Pi-hole), reverse proxy, Cloudflare Tunnel, OAuth |
| **Monitoring** | Beszel, Uptime Kuma, LoggiFly, WUD, Telegram alerts |
| **Automation** | Home Assistant, N8N workflows, bash scripting |
| **Security** | Secret management, geo-restriction, HTTPS everywhere |
| **Backup** | Restic, Backrest, Backblaze B2, 3-2-1 strategy |
| **Linux Admin** | Debian/Raspberry Pi OS, systemd, permissions, storage |

## Architecture Overview

```
                                    INTERNET
                                        │
                                        ▼
                              ┌─────────────────┐
                              │  Cloudflare     │
                              │  (WAF + Tunnel) │
                              └────────┬────────┘
                                       │
                    ┌──────────────────┼──────────────────┐
                    │           RASPBERRY PI 5            │
                    │                                     │
                    │  ┌─────────────┐  ┌─────────────┐   │
                    │  │  Pi-hole    │  │ Cloudflared │   │
                    │  │  (DNS)      │  │  (Tunnel)   │   │
                    │  └─────────────┘  └─────────────┘   │
                    │                                     │
                    │  ┌───────────────────────────────┐  │
                    │  │     DOCKER CONTAINERS         │  │
                    │  │  ┌─────┐ ┌─────┐ ┌─────┐      │  │ 
                    │  │  │Media│ │ Mon │ │ Mgmt│ ...  │  │
                    │  │  └─────┘ └─────┘ └─────┘      │  │
                    │  └───────────────────────────────┘  │
                    │                  │                  │
                    └──────────────────┼──────────────────┘
                                       │
                              ┌────────┴────────┐
                              │   External SSD  │
                              │   (Data Store)  │
                              └─────────────────┘
```

## Services Stack (23 containers)

### Media & Storage
| Service | Purpose | Why I Chose It |
|---------|---------|----------------|
| **Immich** | Photo management | Google Photos alternative, full AI features |
| **Jellyfin** | Media streaming | Open-source Plex alternative |
| **Paperless-ngx** | Document management | OCR + full-text search |
| **Filebrowser** | Web file manager | Simple, lightweight |
| **Syncthing** | P2P file sync | No cloud dependency |

### Monitoring & Observability
| Service | Purpose | Why I Chose It |
|---------|---------|----------------|
| **Beszel** | System metrics | Lightweight, Pi-optimized |
| **Uptime Kuma** | Service monitoring | Beautiful UI, flexible alerts |
| **NetAlertX** | Network discovery | Track all devices |
| **WUD** | Container updates | Know when to update |
| **LoggiFly** | Log monitoring | Real-time Telegram alerts |
| **Speedtest Tracker** | ISP monitoring | Historical bandwidth data |
| **ChangeDetection** | Website monitoring | Track external changes |

### Networking & Security
| Service | Purpose | Why I Chose It |
|---------|---------|----------------|
| **Pi-hole** | DNS + Ad-blocking | Network-wide protection |
| **Cloudflared** | Secure tunnel | Zero exposed ports |

### Management
| Service | Purpose | Why I Chose It |
|---------|---------|----------------|
| **Portainer** | Container UI | Visual management |
| **Homepage** | Dashboard | Single pane of glass |
| **Backrest** | Backup orchestration | Restic made easy |

### Automation
| Service | Purpose | Why I Chose It |
|---------|---------|----------------|
| **Home Assistant** | Smart home | Local-first automation |
| **N8N** | Workflow automation | Self-hosted Zapier |

## Key Architecture Decisions

### 1. Cloudflare Tunnel vs Traditional Reverse Proxy
**Decision**: Use Cloudflare Tunnel instead of exposing ports with nginx/Traefik

**Rationale**:
- Zero open ports on router (security)
- Free SSL certificates and WAF
- DDoS protection included
- Geo-restriction capabilities

**Trade-off**: Dependency on Cloudflare, but benefits outweigh for home use

### 2. External SSD for Data, SD Card for OS
**Decision**: Separate storage tiers

**Rationale**:
- SD cards have limited write cycles
- SSD provides better I/O for databases and media
- Easy to backup/migrate data independently

### 3. Multi-layer Monitoring
**Decision**: Multiple specialized tools vs single solution

**Rationale**:
- Beszel: Low-overhead system metrics
- Uptime Kuma: Service availability
- LoggiFly: Real-time log analysis
- WUD: Container update tracking

Each tool excels at its specific job rather than one mediocre all-in-one

### 4. Telegram for Alerting
**Decision**: Telegram bot for all notifications

**Rationale**:
- Free, reliable, instant push notifications
- Works globally without self-hosting
- Easy API integration
- Supports rich formatting

## Security Implementation

```
┌─────────────────────────────────────────────────────────┐
│                    SECURITY LAYERS                      │
├─────────────────────────────────────────────────────────┤
│  Layer 1: Cloudflare WAF + DDoS Protection              │
│  Layer 2: Cloudflare Access (OAuth authentication)      │
│  Layer 3: Geo-restriction (Italy only for most)         │
│  Layer 4: Pi-hole DNS filtering                         │
│  Layer 5: Container isolation (Docker networks)         │
│  Layer 6: No default passwords, env-based secrets       │
└─────────────────────────────────────────────────────────┘
```

**Secrets Management**:
- All secrets in `.env` files (gitignored)
- Compose files use `${VARIABLE}` placeholders
- Automated sanitization script before commits
- Git history cleaned of any leaked secrets

## Backup Strategy (3-2-1 Rule)

| Data Type | Local | Cloud | Frequency |
|-----------|-------|-------|-----------|
| Docker configs | SSD | Backblaze B2 | Daily |
| Databases | SSD | Backblaze B2 | Daily |
| Photos (Immich) | SSD | Backblaze B2 | Weekly |
| Documents | SSD | Backblaze B2 | Daily |

Managed via **Backrest** with **Restic** backend - incremental, encrypted, deduplicated.

## Lessons Learned

1. **RAM is the bottleneck** on Pi 5 - careful service selection matters
2. **Monitoring your monitoring** - LoggiFly catches issues before users do
3. **Secrets in git history** are forever - sanitize BEFORE committing
4. **Document everything** - this repo is the documentation
5. **Start simple, add complexity** - each service earned its place

## Repository Structure

```
homelab-pi5/
├── README.md                 # This file
├── stacks/                   # Docker compose files by category
│   ├── media/               # Immich, Jellyfin, Paperless...
│   ├── monitoring/          # Beszel, Uptime Kuma, WUD...
│   ├── network/             # Pi-hole, Cloudflared
│   ├── management/          # Portainer, Homepage, Backrest
│   ├── automation/          # Home Assistant, N8N
│   └── utilities/           # Various tools
├── scripts/                  # Automation scripts
│   └── sync-homelab-docs.sh # Sanitizes and syncs configs
└── docs/                     # Additional documentation
```

## Quick Start

```bash
# Clone and deploy any service
git clone https://github.com/YOUR_USERNAME/homelab-pi5.git
cd homelab-pi5/stacks/media/jellyfin

# Configure environment
cp .env.example .env
nano .env

# Deploy
docker compose up -d
```

## Hardware

| Component | Specification |
|-----------|---------------|
| SBC | Raspberry Pi 5 (8GB RAM) |
| OS Storage | 64GB SD Card |
| Data Storage | 1TB External SSD (USB 3.0) |
| Network | Gigabit Ethernet |
| OS | Raspberry Pi OS (Debian Bookworm, 64-bit) |

## Documentation

| Guide | Description |
|-------|-------------|
| [Initial Setup](docs/setup/initial-setup.md) | Pi 5 setup, Docker installation, SSD mounting |
| [Cloudflare Tunnel](docs/setup/cloudflare-tunnel.md) | Zero-trust external access configuration |
| [Storage Configuration](docs/setup/storage-configuration.md) | Storage tiers, directories, permissions |
| [Architecture Decisions](docs/architecture/decisions.md) | ADRs explaining key technical choices |
| [Troubleshooting](docs/troubleshooting/common-issues.md) | Common issues and solutions |

## Future Improvements

- [ ] Kubernetes migration (k3s) for learning
- [ ] Prometheus + Grafana stack
- [ ] Automated testing for compose files
- [ ] Terraform for Cloudflare configuration

## License

MIT License - Feel free to use and adapt for your own homelab.

---

**Note**: All sensitive values (IPs, tokens, passwords) have been replaced with placeholders. This is a sanitized version of a production configuration.
