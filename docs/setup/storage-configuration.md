# Storage Configuration

This guide explains the storage architecture and configuration for the homelab, optimized for a Raspberry Pi 5 with external SSD.

## Storage Tiers

| Tier | Device | Purpose | Mount Point |
|------|--------|---------|-------------|
| **OS** | SD Card (64GB) | Operating system, Docker | `/` |
| **Data** | External SSD (1TB) | Media, databases, backups | `/mnt/external-drive` |

### Why This Separation?

1. **SD Card Longevity**: SD cards have limited write cycles; keeping heavy I/O on SSD extends SD card life
2. **Performance**: SSD provides much better I/O for databases and media transcoding
3. **Portability**: Data can be easily migrated by moving the SSD
4. **Backup Simplicity**: Data directory is a single backup target

## Directory Structure

### SD Card (`/home/user/`)

```
/home/user/
└── stacks/                    # Docker compose files only
    ├── media/
    │   ├── immich/
    │   │   └── compose.yaml
    │   ├── jellyfin/
    │   │   └── compose.yaml
    │   └── ...
    ├── monitoring/
    ├── network/
    ├── management/
    ├── automation/
    └── utilities/
```

### External SSD (`/mnt/external-drive/`)

```
/mnt/external-drive/
├── immich/
│   ├── library/              # Photos and videos
│   ├── upload/               # Incoming uploads
│   ├── profile/              # User profiles
│   └── postgres/             # Database
├── jellyfin/
│   ├── config/               # Server configuration
│   ├── cache/                # Transcoding cache
│   └── media/                # Movies, TV shows
├── paperless/
│   ├── data/                 # Document storage
│   ├── media/                # Original files
│   └── postgres/             # Database
├── filebrowser/
│   └── data/                 # Shared files
├── syncthing/
│   └── data/                 # Synced folders
├── sync-in/
│   └── data/                 # Sync-in storage
├── homeassistant/
│   └── config/               # HA configuration
└── backups/
    ├── daily/                # Daily backup snapshots
    └── restic/               # Restic repository
```

## Setting Up External Storage

### 1. Format and Mount SSD

```bash
# Identify drive
lsblk

# Format (WARNING: destroys all data)
sudo mkfs.ext4 -L homelab-data /dev/sda1

# Create mount point
sudo mkdir -p /mnt/external-drive

# Get UUID for fstab
sudo blkid /dev/sda1
# Note the UUID

# Add to fstab
sudo nano /etc/fstab
```

Add this line to `/etc/fstab`:

```
UUID=your-uuid-here /mnt/external-drive ext4 defaults,nofail,x-systemd.device-timeout=30 0 2
```

**Important flags:**
- `nofail`: System boots even if drive is missing
- `x-systemd.device-timeout=30`: Limits wait time for USB drives

```bash
# Mount
sudo mount -a

# Verify
df -h /mnt/external-drive
```

### 2. Create Directory Structure

```bash
#!/bin/bash
# create-directories.sh

BASE="/mnt/external-drive"

# Create all service directories
mkdir -p $BASE/{immich,jellyfin,paperless,filebrowser,syncthing,sync-in,homeassistant,backups}

# Immich subdirectories
mkdir -p $BASE/immich/{library,upload,profile,postgres}

# Jellyfin subdirectories
mkdir -p $BASE/jellyfin/{config,cache,media}

# Paperless subdirectories
mkdir -p $BASE/paperless/{data,media,postgres}

# Backup subdirectories
mkdir -p $BASE/backups/{daily,restic}

# Set ownership
sudo chown -R $USER:$USER $BASE

# Set permissions
chmod -R 755 $BASE
```

### 3. Docker Volume Configuration

In compose files, use bind mounts to external storage:

```yaml
# Example: Immich
services:
  immich-server:
    volumes:
      - /mnt/external-drive/immich/library:/usr/src/app/upload
      - /mnt/external-drive/immich/upload:/usr/src/app/upload/upload
```

```yaml
# Example: Jellyfin
services:
  jellyfin:
    volumes:
      - /mnt/external-drive/jellyfin/config:/config
      - /mnt/external-drive/jellyfin/cache:/cache
      - /mnt/external-drive/jellyfin/media:/media
```

## Permissions

### Standard Permissions

Most containers run as specific users. Common UIDs:

| Service | UID:GID | Notes |
|---------|---------|-------|
| Immich | 1000:1000 | Matches default user |
| Jellyfin | 1000:1000 | Matches default user |
| Paperless | 1000:1000 | Matches default user |
| Syncthing | 1000:1000 | Matches default user |
| Sync-in | 8888:8888 | Custom UID |

### Setting Permissions

```bash
# For most services (UID 1000)
sudo chown -R 1000:1000 /mnt/external-drive/immich
sudo chown -R 1000:1000 /mnt/external-drive/jellyfin

# For Sync-in (UID 8888)
sudo chown -R 8888:8888 /mnt/external-drive/sync-in
```

### Docker User Mapping

In compose files, specify user:

```yaml
services:
  myservice:
    user: "1000:1000"
    # or use environment variables
    environment:
      - PUID=1000
      - PGID=1000
```

## Performance Optimization

### USB 3.0 Verification

```bash
# Check USB speed
lsusb -t

# Look for "5000M" which indicates USB 3.0
```

### I/O Scheduler

For SSDs, use `none` or `mq-deadline`:

```bash
# Check current scheduler
cat /sys/block/sda/queue/scheduler

# Set to none (best for SSD)
echo none | sudo tee /sys/block/sda/queue/scheduler

# Make permanent via udev rule
echo 'ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/scheduler}="none"' | \
  sudo tee /etc/udev/rules.d/60-ssd-scheduler.rules
```

### Disable Access Time Updates

In `/etc/fstab`, add `noatime`:

```
UUID=xxx /mnt/external-drive ext4 defaults,nofail,noatime 0 2
```

## Monitoring Storage

### Check Disk Usage

```bash
# Overall usage
df -h /mnt/external-drive

# Per-directory usage
du -sh /mnt/external-drive/*

# Find large files
find /mnt/external-drive -type f -size +100M -exec ls -lh {} \;
```

### Set Up Alerts

Use Beszel or a cron job to monitor disk space:

```bash
# Add to crontab
0 * * * * df -h /mnt/external-drive | awk 'NR==2 {if ($5+0 > 80) print "Disk usage: " $5}' | mail -s "Disk Alert" user@email.com
```

## Backup Considerations

### What to Backup

| Priority | Data | Location |
|----------|------|----------|
| Critical | Photos (Immich) | `/mnt/external-drive/immich/library` |
| Critical | Documents (Paperless) | `/mnt/external-drive/paperless/data` |
| High | Databases | Various `postgres/` directories |
| High | Home Assistant | `/mnt/external-drive/homeassistant/config` |
| Medium | Jellyfin config | `/mnt/external-drive/jellyfin/config` |
| Low | Media files | Replaceable from source |

### Exclude from Backup

- Transcoding caches (`jellyfin/cache`)
- Temporary uploads
- Log files

See [Backup Strategy](../architecture/decisions.md#backup-strategy) for full backup configuration.

## Troubleshooting

### Drive Not Mounting

```bash
# Check if drive is detected
lsblk
dmesg | tail -20

# Try manual mount
sudo mount /dev/sda1 /mnt/external-drive

# Check fstab syntax
sudo mount -a
```

### Permission Denied

```bash
# Check current permissions
ls -la /mnt/external-drive

# Reset ownership
sudo chown -R $USER:$USER /mnt/external-drive

# Check container user
docker exec container_name id
```

### Slow Performance

```bash
# Check if USB 3.0
lsusb -t

# Test write speed
dd if=/dev/zero of=/mnt/external-drive/test bs=1M count=1024 oflag=direct

# Test read speed
dd if=/mnt/external-drive/test of=/dev/null bs=1M count=1024

# Clean up
rm /mnt/external-drive/test
```
