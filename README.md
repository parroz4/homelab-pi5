# Homelab Raspberry Pi 5

Documentazione completa del mio homelab basato su Raspberry Pi 5, con focus su self-hosting, privacy e automazione.

## 📋 Indice

- [Hardware](#hardware)
- [Servizi attivi](#servizi-attivi)
- [Architettura](#architettura)
- [Quick Start](#quick-start)
- [Backup Strategy](#backup-strategy)
- [Sicurezza](#sicurezza)
- [Manutenzione](#manutenzione)

## 🖥️ Hardware

- **SBC**: Raspberry Pi 5 (8GB RAM)
- **Storage**: SSD esterno USB 3.0
  - Sistema: ext4 (per container Docker)
  - Media/Backup: exFAT (per compatibilità multi-piattaforma)
- **Rete**: Ethernet Gigabit
- **OS**: Raspberry Pi OS (64-bit)

## 🚀 Servizi attivi

### Gestione Media
- **Immich**: Gestione foto e video (~75.000 foto, 4.800 video, 218GB)
- **Paperless-ngx**: Gestione documentale con OCR

### Networking & Sicurezza
- **Pi-hole**: DNS filtering e ad-blocking
- **Cloudflare Tunnel**: Accesso remoto sicuro (no port forwarding)
- **Cloudflare Access**: Autenticazione con Google OAuth + geo-restriction

### Monitoring
- **Beszel**: Monitoring sistema
- **Uptime Kuma**: Monitoring servizi
- **NetAlertX**: Monitoring rete
- **changedetection.io**: Monitoring siti web
- **Homepage**: Dashboard centralizzata

### Automation
- **N8N**: Workflow automation (YouTube monitoring + Gemini AI + Telegram)

### Management
- **Dockge**: Gestione container Docker
- **Backrest**: Backup management (Backblaze B2)

## 🏗️ Architettura

### Struttura Directory
```
/home/francesco/stacks/
├── immich/
├── paperless-ngx/
├── monitoring/
├── network/
└── automation/
```

### Networking
- Accesso esterno: `parroz44.xyz` (placeholder: `example.com`)
- Tunnel Cloudflare per tutti i servizi
- Nessun port forwarding sul router
- Autenticazione centralizzata via Cloudflare Access

### Storage Strategy
- **Container data**: SSD ext4 montato su `/path/to/docker/data`
- **Media files**: SSD exFAT montato su `/path/to/media`
- **Backup**: Locale (SSD) + Cloud (Backblaze B2)

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

### Clone e Setup
```bash
# Clone repository
git clone https://github.com/TUO_USERNAME/homelab-pi5.git
cd homelab-pi5

# Copia template ambiente
cp stacks/immich/.env.example stacks/immich/.env
cp stacks/paperless-ngx/.env.example stacks/paperless-ngx/.env
# ... ripeti per ogni servizio

# Modifica i file .env con i tuoi valori
nano stacks/immich/.env
```

### Deploy Servizi
```bash
# Esempio: Deploy Immich
cd stacks/immich
docker compose up -d

# Verifica status
docker compose ps
docker compose logs -f
```

## 💾 Backup Strategy

Strategia 3-2-1:
- **3** copie dei dati
- **2** media diversi (SSD locale + Cloud)
- **1** copia off-site (Backblaze B2)

Backup gestito tramite **Backrest**:
- Backup automatici programmati
- Retention policy configurabile
- Restore testato e funzionante

Dettagli: [docs/architecture/backup-strategy.md](docs/architecture/backup-strategy.md)

## 🔒 Sicurezza

### Gestione Secrets
- **IMPORTANTE**: Mai committare file `.env` reali
- Usare sempre i template `.env.example`
- Sostituire valori sensibili con placeholder

### Accesso Remoto
- Cloudflare Tunnel (no esposizione diretta)
- Cloudflare Access con Google OAuth
- Geo-restriction attiva
- Rate limiting configurato

### Best Practices
- Aggiornamenti regolari dei container
- Monitoring attivo 24/7
- Log centralizati
- Backup testati regolarmente

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
# Verifica tutti i container
docker ps -a

# Log specifico servizio
docker compose -f stacks/SERVICE_NAME/docker-compose.yml logs -f
```

### Spazio Disco
```bash
# Verifica spazio
df -h

# Pulizia Docker
docker system prune -a --volumes
```

## 📚 Documentazione

- [Setup Iniziale](docs/setup/initial-setup.md)
- [Configurazione Cloudflare](docs/setup/cloudflare-tunnel.md)
- [Configurazione Storage](docs/setup/storage-configuration.md)
- [Troubleshooting Paperless](docs/troubleshooting/paperless-integrity.md)
- [Decisioni Architetturali](docs/architecture/decisions.md)

## 🤝 Contributing

Questo è principalmente un progetto personale, ma suggerimenti e issue sono benvenuti!

## 📝 License

MIT License - Sentiti libero di usare e modificare per il tuo homelab.

## ⚠️ Disclaimer

Questa documentazione riflette il mio setup personale. Adatta le configurazioni alle tue esigenze e al tuo ambiente di rete.
