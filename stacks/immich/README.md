# Immich - Photo & Video Management

Gestione completa di foto e video con supporto per machine learning, riconoscimento facciale e backup automatico.

## 📋 Setup

### 1. Configurazione

Copia il file di esempio:
```bash
cp .env.example .env
```

### 2. Modifica i path

Edita `.env` e sostituisci i placeholder:
```bash
nano .env
```

**Path da configurare:**
- `UPLOAD_LOCATION`: Dove Immich salverà le foto caricate
- `MEDIA_LOCATION`: Dove sono le tue foto esistenti (montato read-only)
- `ML_CACHE_LOCATION`: Cache per il machine learning
- `DB_DATA_LOCATION`: Dati del database PostgreSQL

**Esempio configurazione:**
```bash
UPLOAD_LOCATION=/home/user/docker-data/immich/upload
MEDIA_LOCATION=/mnt/ssd-external/photos
ML_CACHE_LOCATION=/home/user/docker-data/immich/ml-cache
DB_DATA_LOCATION=/home/user/docker-data/immich/postgres
```

### 3. Crea le directory necessarie
```bash
mkdir -p /path/to/docker-data/immich/{upload,ml-cache,postgres}
```

### 4. Imposta password sicura

Nel file `.env`, sostituisci:
```bash
DB_PASSWORD=YOUR_SECURE_DATABASE_PASSWORD_HERE
```

Con una password forte (usa un password manager).

### 5. Deploy
```bash
docker compose up -d
```

### 6. Verifica
```bash
docker compose ps
docker compose logs -f
```

## 🌐 Accesso

- **Locale**: `http://ip-raspberry-pi:2283`
- **Remoto**: Tramite Cloudflare Tunnel (vedi configurazione tunnel)

## 📊 Storage Info

- **Database**: PostgreSQL con estensione pgvecto-rs per ricerca vettoriale
- **Cache ML**: Modelli di machine learning per riconoscimento facciale
- **Upload**: Foto/video caricate tramite app mobile o web
- **Media**: Foto esistenti montate read-only (non vengono modificate)

## 🔄 Manutenzione

### Backup

Il backup dei dati Immich include:
- Database PostgreSQL (`DB_DATA_LOCATION`)
- Upload directory (`UPLOAD_LOCATION`)
- (Opzionale) ML cache (`ML_CACHE_LOCATION` - può essere ricreato)

### Aggiornamento
```bash
docker compose pull
docker compose up -d
```

### Pulizia
```bash
# Rimuovi immagini vecchie
docker image prune -f

# Verifica spazio
docker system df
```

## ⚠️ Note Importanti

- Le foto in `MEDIA_LOCATION` sono montate **read-only** per sicurezza
- Il machine learning richiede tempo al primo avvio (download modelli)
- PostgreSQL richiede il database extension `pgvecto-rs` (già incluso nell'immagine)

## 🐛 Troubleshooting

### Container non si avvia
```bash
docker compose logs immich_server
```

### Database connection error
Verifica che il container PostgreSQL sia healthy:
```bash
docker compose ps
```

### ML non funziona
Controlla i log:
```bash
docker compose logs immich_machine_learning
```

## 🔗 Link Utili

- [Documentazione Immich](https://immich.app/docs/overview/introduction)
- [GitHub Immich](https://github.com/immich-app/immich)
