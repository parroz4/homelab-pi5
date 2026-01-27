# Architecture Decision Records (ADRs)

This document captures the key architectural decisions made for this homelab, including context, rationale, and trade-offs.

---

## ADR-001: Raspberry Pi 5 as Primary Server

### Status
Accepted

### Context
Need a low-power, always-on server for running homelab services. Options considered:
- Old desktop/laptop
- Mini PC (Intel NUC, etc.)
- Raspberry Pi 5
- Cloud VPS

### Decision
Use Raspberry Pi 5 (8GB RAM) as the primary server.

### Rationale
- **Power efficiency**: ~5-15W vs 50-100W for alternatives
- **Cost**: One-time ~€100 vs ongoing cloud costs
- **Noise**: Silent operation
- **Size**: Compact, fits anywhere
- **Community**: Large ecosystem and support
- **ARM64**: Modern architecture, good Docker support

### Trade-offs
- Limited RAM (8GB max)
- Limited CPU (4 cores)
- USB storage required for performance
- Some images not available for ARM64

### Consequences
- Must be selective about memory-hungry services
- Some services need ARM-specific images
- External SSD required for serious workloads

---

## ADR-002: Cloudflare Tunnel for External Access

### Status
Accepted

### Context
Need secure external access to services without exposing home network.

### Decision
Use Cloudflare Tunnel instead of traditional port forwarding + reverse proxy.

### Rationale
- **Zero open ports**: No attack surface on router
- **Free SSL**: Automatic certificate management
- **DDoS protection**: Enterprise-grade, included free
- **WAF**: Web Application Firewall included
- **Access control**: Built-in OAuth integration
- **Geo-restriction**: Easy to implement

### Trade-offs
- Dependency on Cloudflare (vendor lock-in)
- Domain must use Cloudflare DNS
- All traffic routes through Cloudflare
- Some latency added

### Alternatives Considered
| Option | Pros | Cons |
|--------|------|------|
| Nginx + Let's Encrypt | Full control | Exposed ports, manual certs |
| Traefik | Auto-discovery | Complex config, exposed ports |
| Tailscale | P2P, private | No public access without Funnel |
| WireGuard | Fast, secure | Requires client setup |

### Consequences
- Must configure each service in Cloudflare dashboard
- Cloudflare Access required for authentication
- Cannot use non-HTTP protocols easily (SSH, etc.)

---

## ADR-003: Multi-Tool Monitoring Strategy

### Status
Accepted

### Context
Need comprehensive monitoring of system, services, and containers.

### Decision
Use multiple specialized monitoring tools instead of one all-in-one solution.

### Rationale
Each tool excels at its specific purpose:

| Tool | Purpose | Why Not All-in-One |
|------|---------|-------------------|
| **Beszel** | System metrics | Lightweight, Pi-optimized |
| **Uptime Kuma** | Availability | Beautiful UI, flexible checks |
| **LoggiFly** | Log analysis | Real-time keyword alerts |
| **WUD** | Container updates | Specific to Docker |
| **NetAlertX** | Network devices | Specialized for discovery |

### Trade-offs
- More containers to maintain
- No single dashboard (mitigated by Homepage)
- Potential overlap in functionality

### Alternatives Considered
- **Prometheus + Grafana**: Too heavy for Pi
- **Zabbix**: Overkill, complex setup
- **Datadog/New Relic**: Costly, privacy concerns

### Consequences
- Homepage becomes the "single pane of glass"
- Each tool configured independently
- Telegram as unified alerting channel

---

## ADR-004: Telegram for All Notifications

### Status
Accepted

### Context
Need reliable alerting that reaches me anywhere.

### Decision
Use a single Telegram bot for all service notifications.

### Rationale
- **Free**: No per-message costs
- **Reliable**: Telegram infrastructure is solid
- **Instant**: Push notifications on all devices
- **Rich formatting**: Markdown, images supported
- **Easy API**: Simple HTTP calls
- **No self-hosting**: One less thing to maintain

### Trade-offs
- Dependency on Telegram service
- Messages visible if phone compromised
- No escalation policies (like PagerDuty)

### Implementation
```
All Services → Telegram Bot → My Phone
     │
     ├── LoggiFly (log alerts)
     ├── WUD (update alerts)
     ├── Uptime Kuma (downtime alerts)
     └── Home Assistant (automation alerts)
```

---

## ADR-005: External SSD for Data Storage

### Status
Accepted

### Context
SD cards have limited write endurance and poor I/O performance for databases.

### Decision
Use external USB 3.0 SSD for all data storage, keeping only OS on SD card.

### Rationale
- **Write endurance**: SSD rated for much higher writes
- **Performance**: 400+ MB/s vs ~40 MB/s for SD
- **Capacity**: 1TB affordable for SSD
- **Reliability**: Better for databases

### Trade-offs
- Additional hardware cost (~€80)
- USB bottleneck (though USB 3.0 is fast enough)
- Extra cable/device

### Storage Layout
```
SD Card (64GB)          External SSD (1TB)
├── /boot               ├── /mnt/external-drive/
├── /                   │   ├── immich/
│   └── ~/stacks/       │   ├── jellyfin/
│       └── (compose    │   ├── paperless/
│           files only) │   ├── homeassistant/
└── /var/lib/docker/    │   └── backups/
    └── (containers)    └──
```

---

## ADR-006: Docker Compose for All Services

### Status
Accepted

### Context
Need reproducible, version-controlled service deployments.

### Decision
Use Docker Compose for all services, no Kubernetes.

### Rationale
- **Simplicity**: Single-node doesn't need orchestration
- **Resource efficiency**: K8s overhead too heavy for Pi
- **Reproducibility**: Compose files are easily version-controlled
- **Portability**: Easy to migrate to another host
- **Familiarity**: Lower learning curve

### Trade-offs
- No auto-healing (use `restart: unless-stopped`)
- No rolling updates (brief downtime on updates)
- No built-in secrets management

### Alternatives Considered
- **K3s**: Lighter K8s, but still overkill for single node
- **Docker Swarm**: Dead project, limited future
- **Podman**: Good alternative, but less ecosystem support

---

## ADR-007: 3-2-1 Backup Strategy with Restic

### Status
Accepted

### Context
Need reliable backups that protect against data loss.

### Decision
Implement 3-2-1 backup strategy using Restic via Backrest.

### Rationale
**3-2-1 Rule:**
- **3** copies of data (original + local backup + cloud)
- **2** different media (SSD + cloud storage)
- **1** offsite copy (Backblaze B2)

**Why Restic:**
- Incremental backups (fast, space-efficient)
- Client-side encryption
- Deduplication
- Multiple backends supported

### Implementation

| Data | Frequency | Retention | Destination |
|------|-----------|-----------|-------------|
| Configs | Daily | 30 days | B2 |
| Databases | Daily | 30 days | B2 |
| Photos | Weekly | 90 days | B2 |
| Documents | Daily | 90 days | B2 |

### Trade-offs
- Cloud storage cost (~$5/month for ~500GB)
- Restore requires Restic installation
- Initial backup takes time

---

## ADR-008: Pi-hole for Network-wide DNS

### Status
Accepted

### Context
Want ad-blocking and DNS filtering for entire network.

### Decision
Run Pi-hole as the network's DNS server.

### Rationale
- **Network-wide blocking**: All devices protected
- **No client software**: Works on any device
- **Query logging**: Visibility into DNS traffic
- **Custom DNS**: Can create local domains
- **Performance**: Cache speeds up DNS resolution

### Configuration
```
Router DHCP → Pi-hole IP as DNS
     │
     ▼
Pi-hole → Upstream DNS (Cloudflare 1.1.1.1)
     │
     └── Blocklists (ads, trackers, malware)
```

### Trade-offs
- Pi becomes critical infrastructure
- Some sites break (need whitelisting)
- Requires router configuration

---

## Future Considerations

### Under Evaluation

1. **Kubernetes (k3s)**: For learning, not production need
2. **Prometheus + Grafana**: If monitoring needs grow
3. **Terraform**: For Cloudflare configuration as code
4. **Ansible**: For Pi configuration management

### Rejected

1. **Home cloud (Nextcloud)**: Too resource-heavy for Pi
2. **Self-hosted email**: Complexity not worth it
3. **VPN server**: Cloudflare Tunnel covers use case
