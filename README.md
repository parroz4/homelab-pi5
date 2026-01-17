# Homelab Raspberry Pi 5

Documentazione completa del mio homelab basato su Raspberry Pi 5, con focus su self-hosting, privacy e automazione.

## 📋 Indice

- [Hardware](#-hardware)
- [Servizi Attivi](#-servizi-attivi)
- [Struttura Repository](#-struttura-repository)
- [Quick Start](#-quick-start)
- [Architettura](#-architettura)
- [Sicurezza](#-sicurezza)
- [Backup Strategy](#-backup-strategy)
- [Manutenzione](#-manutenzione)

## 🖥️ Hardware

| Componente | Specifica |
|------------|-----------|
| **SBC** | Raspberry Pi 5 (8GB RAM) |
| **Storage OS** | SD Card 64GB |
| **Storage Dati** | SSD esterno USB 3.0 |
| **Rete** | Ethernet Gigabit |
| **OS** | Raspberry Pi OS (64-bit, Debian Bookworm) |

## 🚀 Servizi Attivi

### 📺 Media (4 servizi)
| Servizio | Descrizione | Porta |
|----------|-------------|-------|
| [Immich](stacks/media/immich/) | Gestione foto e video self-hosted | 2283 |
| [Jellyfin](stacks/media/jellyfin/) | Media server per film e serie | 8096 |
| [Paperless-ngx](stacks/media/paperless/) | Gestione documentale con OCR | 8010 |
| [Filebrowser](stacks/media/filebrowser/) | File manager web | 8082 |

### 🤖 Automation (2 servizi)
| Servizio | Descrizione | Porta |
|----------|-------------|-------|
| [Home Assistant](stacks/automation/homeassistant/) | Smart home automation | 8123 |
| [N8N](stacks/automation/n8n/) | Workflow automation | 5678 |

### 📊 Monitoring (5 servizi)
| Servizio | Descrizione | Porta |
|----------|-------------|-------|
| [Beszel](stacks/monitoring/beszel/) | System monitoring | 8090 |
| [Uptime Kuma](stacks/monitoring/uptime-kuma/) | Service uptime monitoring | 3001 |
| [NetAlertX](stacks/monitoring/netalertx/) | Network device monitoring | 20211 |
| [Speedtest Tracker](stacks/monitoring/speedtest-tracker/) | Internet speed monitoring | 8080 |
| [ChangeDetection](stacks/monitoring/changedetection/) | Website change monitoring | 5000 |

### 🌐 Network (2 servizi)
| Servizio | Descrizione | Porta |
|----------|-------------|-------|
| [Pi-hole](stacks/network/pihole/) | DNS filtering e ad-blocking | 80, 53 |
| [Cloudflared](stacks/network/cloudflared/) | Cloudflare Tunnel | - |

### ⚙️ Management (3 servizi)
| Servizio | Descrizione | Porta |
|----------|-------------|-------|
| [Portainer](stacks/management/portainer/) | Docker management UI | 9443 |
| [Homepage](stacks/management/homepage/) | Dashboard centralizzata | 3000 |
| [Backrest](stacks/management/backrest/) | Backup management (Restic) | 9898 |

### 🔧 Utilities (1 servizio)
| Servizio | Descrizione | Porta |
|----------|-------------|-------|
| [Warracker](stacks/utilities/warracker/) | Warranty tracker | 8005 |

**Totale: 17 servizi containerizzati**

## 📁 Struttura Repository

```
homelab-pi5/
├── README.md
├── .gitignore
├── stacks/
│   ├── media/
│   │   ├── immich/
│   │   ├── jellyfin/
│   │   ├── paperless/
│   │   └── filebrowser/
│   ├── automation/
│   │   ├── homeassistant/
│   │   └── n8n/
│   ├── monitoring/
│   │   ├── beszel/
│   │   ├── uptime-kuma/
│   │   ├── netalertx/
│   │   ├── speedtest-tracker/
│   │   └── changedetection/
│   ├── network/
│   │   ├── pihole/
│   │   └── cloudflared/
│   ├── management/
│   │   ├── portainer/
│   │   ├── homepage/
│   │   └── backrest/
│   └── utilities/
│       └── warracker/
├── docs/
│   ├── setup/
│   ├── architecture/
│   └── troubleshooting/
├── scripts/
└── templates/
```

## 🚀 Quick Start

### Prerequisiti

```bash
# Aggiorna sistema
sudo apt update && sudo apt upgrade -y

# Installa Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Riavvia per applicare i permessi
sudo reboot
```

### Deploy di un servizio

```bash
# Clone repository
git clone https://github.com/YOUR_USERNAME/homelab-pi5.git
cd homelab-pi5

# Scegli un servizio (es. Jellyfin)
cd stacks/media/jellyfin

# Copia e configura environment
cp .env.example .env
nano .env  # modifica con i tuoi valori

# Deploy
docker compose up -d

# Verifica
docker compose ps
docker compose logs -f
```

## 🏗️ Architettura

### Networking
- **Accesso esterno**: Cloudflare Tunnel (zero port forwarding)
- **DNS locale**: Pi-hole per ad-blocking e DNS filtering
- **Autenticazione**: Cloudflare Access con Google OAuth
- **Geo-restriction**: Attiva per tutti i servizi esposti

### Storage Strategy
```
/home/user/stacks/          # Compose files e config
/mnt/external-drive/        # Media e dati persistenti
├── immich/                 # Foto e video
├── paperless/              # Documenti
├── jellyfin/               # Film e serie
└── backups/                # Backup locali
```

### Container Management
- **Dockge**: UI per gestione stack Docker
- **Portainer**: Management avanzato container
- **Watchtower**: Auto-update container (opzionale)

## 🔒 Sicurezza

### Gestione Secrets
- ⚠️ **Mai committare file `.env` reali**
- Usare sempre i template `.env.example`
- Secrets gestiti via variabili d'ambiente

### Accesso Remoto
- Cloudflare Tunnel (nessuna porta esposta)
- Cloudflare Access con OAuth
- Rate limiting configurato
- Geo-restriction attiva

### Best Practices implementate
- [x] No password di default
- [x] HTTPS ovunque (via Cloudflare)
- [x] Aggiornamenti regolari
- [x] Monitoring 24/7
- [x] Backup automatici

## 💾 Backup Strategy

Strategia **3-2-1**:
- **3** copie dei dati
- **2** media diversi (SSD locale + Cloud)
- **1** copia off-site (Backblaze B2)

| Dato | Frequenza | Destinazione |
|------|-----------|--------------|
| Config Docker | Giornaliero | Backblaze B2 |
| Database | Giornaliero | Locale + B2 |
| Media (Immich) | Settimanale | Backblaze B2 |
| Documenti (Paperless) | Giornaliero | Backblaze B2 |

Gestito tramite **Backrest** con Restic backend.

## 🔧 Manutenzione

### Aggiornamento Container
```bash
cd stacks/SERVICE_NAME
docker compose pull
docker compose up -d
docker image prune -f
```

### Health Check
```bash
# Status tutti i container
docker ps -a

# Risorse sistema
docker stats

# Log specifico servizio
docker compose logs -f SERVICE_NAME
```

### Pulizia periodica
```bash
# Pulizia Docker (ATTENZIONE: rimuove tutto lo inutilizzato)
docker system prune -a

# Solo immagini dangling
docker image prune

# Log di sistema
sudo journalctl --vacuum-size=500M
```

## 📚 Documentazione Aggiuntiva

- [Setup Iniziale](docs/setup/initial-setup.md)
- [Configurazione Cloudflare](docs/setup/cloudflare-tunnel.md)
- [Configurazione Storage](docs/setup/storage-configuration.md)
- [Troubleshooting](docs/troubleshooting/)
- [Decisioni Architetturali](docs/architecture/decisions.md)

## 🤝 Contributing

Questo è principalmente un progetto personale, ma suggerimenti e issue sono benvenuti!

## 📝 License

MIT License - Sentiti libero di usare e modificare per il tuo homelab.

---

⚠️ **Disclaimer**: Questa documentazione riflette il mio setup personale. Adatta le configurazioni alle tue esigenze e al tuo ambiente di rete. I valori sensibili sono stati sostituiti con placeholder.
