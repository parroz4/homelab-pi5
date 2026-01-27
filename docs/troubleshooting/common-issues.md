# Troubleshooting Guide

Common issues and solutions for the homelab infrastructure.

## Table of Contents

- [Docker Issues](#docker-issues)
- [Storage Issues](#storage-issues)
- [Network Issues](#network-issues)
- [Service-Specific Issues](#service-specific-issues)
- [Performance Issues](#performance-issues)
- [Cloudflare Tunnel Issues](#cloudflare-tunnel-issues)

---

## Docker Issues

### Container Won't Start

**Symptoms**: Container exits immediately or keeps restarting

**Diagnosis**:
```bash
# Check container status
docker ps -a | grep container_name

# View logs
docker logs container_name --tail 100

# Check for port conflicts
docker ps --format "{{.Names}}: {{.Ports}}" | grep PORT_NUMBER
```

**Common Causes**:
1. **Port already in use**
   ```bash
   # Find what's using the port
   sudo lsof -i :PORT_NUMBER
   # or
   sudo netstat -tlnp | grep PORT_NUMBER
   ```

2. **Permission denied on volumes**
   ```bash
   # Check ownership
   ls -la /path/to/volume

   # Fix permissions
   sudo chown -R 1000:1000 /path/to/volume
   ```

3. **Missing environment variables**
   ```bash
   # Check .env file exists and is readable
   cat .env

   # Verify variables are loaded
   docker compose config
   ```

### Out of Disk Space

**Symptoms**: Containers fail with "no space left on device"

**Solution**:
```bash
# Check disk usage
df -h

# Clean Docker resources
docker system prune -a

# Remove unused volumes (CAUTION)
docker volume prune

# Check large containers/images
docker system df -v
```

### Docker Daemon Not Running

**Symptoms**: "Cannot connect to Docker daemon"

**Solution**:
```bash
# Check status
sudo systemctl status docker

# Start Docker
sudo systemctl start docker

# Enable on boot
sudo systemctl enable docker

# Check logs if still failing
sudo journalctl -u docker -n 50
```

---

## Storage Issues

### External Drive Not Mounting

**Symptoms**: `/mnt/external-drive` is empty or mount fails

**Diagnosis**:
```bash
# Check if drive is detected
lsblk
sudo fdisk -l

# Check dmesg for USB errors
dmesg | tail -30

# Try manual mount
sudo mount /dev/sda1 /mnt/external-drive
```

**Solutions**:

1. **Drive not detected**
   - Try different USB port (use USB 3.0 blue ports)
   - Try different cable
   - Check drive on another computer

2. **Wrong UUID in fstab**
   ```bash
   # Get correct UUID
   sudo blkid /dev/sda1

   # Update fstab
   sudo nano /etc/fstab
   ```

3. **Filesystem errors**
   ```bash
   # Unmount first
   sudo umount /mnt/external-drive

   # Check and repair
   sudo fsck -y /dev/sda1
   ```

### Permission Denied on Mounted Drive

**Solution**:
```bash
# Check current ownership
ls -la /mnt/external-drive

# Fix ownership
sudo chown -R $USER:$USER /mnt/external-drive

# For specific container user (e.g., UID 8888)
sudo chown -R 8888:8888 /mnt/external-drive/sync-in
```

---

## Network Issues

### Can't Access Services Locally

**Symptoms**: `Connection refused` on local IP

**Diagnosis**:
```bash
# Check if service is listening
sudo netstat -tlnp | grep PORT

# Check container is running
docker ps | grep service_name

# Test from Pi itself
curl http://localhost:PORT
```

**Solutions**:

1. **Service not bound to all interfaces**
   - Check compose file uses `0.0.0.0:PORT:PORT` not `127.0.0.1:PORT:PORT`

2. **Firewall blocking**
   ```bash
   # Check UFW status
   sudo ufw status

   # Allow port
   sudo ufw allow PORT
   ```

### DNS Not Working (Pi-hole)

**Symptoms**: Devices can't resolve domains

**Diagnosis**:
```bash
# Test Pi-hole directly
dig @192.168.1.45 google.com

# Check Pi-hole container
docker logs pihole --tail 50

# Check Pi-hole is listening
sudo netstat -ulnp | grep 53
```

**Solutions**:

1. **Pi-hole container not running**
   ```bash
   cd ~/stacks/network/pihole
   docker compose up -d
   ```

2. **Port 53 conflict**
   ```bash
   # Check what's using port 53
   sudo lsof -i :53

   # Often systemd-resolved - disable it
   sudo systemctl disable systemd-resolved
   sudo systemctl stop systemd-resolved
   ```

---

## Service-Specific Issues

### Immich: Machine Learning Unhealthy

**Symptoms**: Alerts about ML server being unhealthy

**Explanation**: This is normal! The ML container sleeps after 5 minutes of inactivity to save RAM.

**If actually broken**:
```bash
# Restart ML container
docker restart immich_machine_learning

# Check logs
docker logs immich_machine_learning --tail 50

# Check memory (ML needs ~2GB)
free -h
```

### Jellyfin: Transcoding Fails

**Symptoms**: Videos won't play or buffer constantly

**Solutions**:

1. **Check hardware acceleration**
   ```bash
   # Verify V4L2 device exists
   ls -la /dev/video*

   # Add to compose.yaml
   devices:
     - /dev/video10:/dev/video10
     - /dev/video11:/dev/video11
   ```

2. **Insufficient cache space**
   ```bash
   # Check cache directory
   du -sh /mnt/external-drive/jellyfin/cache

   # Clear if needed
   rm -rf /mnt/external-drive/jellyfin/cache/transcodes/*
   ```

### Home Assistant: Integration Not Working

**Diagnosis**:
```bash
# Check HA logs
docker logs homeassistant --tail 100 | grep -i error

# Restart HA
docker restart homeassistant
```

**Common fixes**:
- Check if integration requires specific network mode
- Verify API keys/tokens are correct
- Some integrations need `network_mode: host`

### Paperless: OCR Not Working

**Solutions**:
```bash
# Check if documents are being consumed
docker logs paperless --tail 50

# Verify consume directory permissions
ls -la /mnt/external-drive/paperless/consume

# Manually trigger consumption
docker exec paperless document_consumer
```

---

## Performance Issues

### High Memory Usage

**Diagnosis**:
```bash
# Check memory usage
free -h

# Find memory-hungry containers
docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}"

# Check swap usage
swapon --show
```

**Solutions**:

1. **Stop unnecessary services**
   ```bash
   docker compose -f ~/stacks/SERVICE/compose.yaml down
   ```

2. **Add swap**
   ```bash
   sudo fallocate -l 4G /swapfile
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile
   ```

3. **Limit container memory**
   ```yaml
   services:
     myservice:
       deploy:
         resources:
           limits:
             memory: 512M
   ```

### High CPU Usage

**Diagnosis**:
```bash
# Find CPU-hungry processes
htop

# Per-container CPU
docker stats --no-stream
```

**Common causes**:
- Immich ML processing photos
- Jellyfin transcoding
- Paperless OCR processing

These are normal during processing; they should settle down.

---

## Cloudflare Tunnel Issues

### Tunnel Not Connecting

**Symptoms**: Services not accessible externally, tunnel shows disconnected

**Diagnosis**:
```bash
# Check cloudflared container
docker logs cloudflared --tail 50

# Look for connection errors
docker logs cloudflared 2>&1 | grep -i error
```

**Solutions**:

1. **Invalid token**
   ```bash
   # Regenerate token in Cloudflare dashboard
   # Update .env file
   # Restart container
   docker compose up -d --force-recreate
   ```

2. **Network issues**
   ```bash
   # Test outbound connectivity
   curl -I https://cloudflare.com

   # Check DNS resolution
   dig cloudflare.com
   ```

### 502 Bad Gateway

**Symptoms**: External access returns 502 error

**Causes**:
1. Internal service not running
2. Wrong port in tunnel config
3. Service not accessible from cloudflared container

**Debug**:
```bash
# Test from inside cloudflared container
docker exec cloudflared wget -O- http://HOST_IP:PORT

# Check service is actually running
docker ps | grep service_name
```

### Access Denied (Cloudflare Access)

**Solutions**:
1. Check email is in allowed policy
2. Clear browser cookies
3. Try incognito window
4. Check Access policy hasn't expired

---

## Quick Reference Commands

```bash
# View all container logs
docker compose logs -f

# Restart all services in a stack
docker compose restart

# Full stack rebuild
docker compose down && docker compose up -d

# Check what's using a port
sudo lsof -i :PORT

# Monitor resources
htop
docker stats

# Check disk space
df -h
du -sh /mnt/external-drive/*

# Test local service
curl -I http://localhost:PORT

# View recent system logs
journalctl -n 100 --no-pager
```
