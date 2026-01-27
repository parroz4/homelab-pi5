# Initial Setup Guide

This guide covers the initial setup of a Raspberry Pi 5 for running a containerized homelab infrastructure.

## Prerequisites

- Raspberry Pi 5 (8GB RAM recommended)
- 64GB+ SD Card (for OS)
- External SSD (for data storage)
- Ethernet connection (recommended over WiFi)
- Another computer to flash the SD card

## 1. Flash Raspberry Pi OS

### Using Raspberry Pi Imager

1. Download [Raspberry Pi Imager](https://www.raspberrypi.com/software/)
2. Select **Raspberry Pi OS (64-bit)** - Debian Bookworm
3. Click the gear icon for advanced options:
   - Set hostname
   - Enable SSH
   - Set username and password
   - Configure WiFi (optional)
   - Set locale and timezone

```bash
# Alternative: Using dd (Linux/macOS)
sudo dd if=raspios.img of=/dev/sdX bs=4M status=progress
```

## 2. First Boot Configuration

### Connect and Update

```bash
# SSH into the Pi
ssh user@raspberry-pi.local

# Update system
sudo apt update && sudo apt upgrade -y

# Install essential tools
sudo apt install -y \
    vim \
    htop \
    git \
    curl \
    wget \
    net-tools \
    dnsutils
```

### Configure Static IP (Optional)

Edit `/etc/dhcpcd.conf`:

```bash
interface eth0
static ip_address=192.168.1.45/24
static routers=192.168.1.1
static domain_name_servers=192.168.1.1
```

## 3. Install Docker

```bash
# Official Docker install script
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER

# Enable Docker to start on boot
sudo systemctl enable docker

# Reboot to apply group changes
sudo reboot
```

### Verify Installation

```bash
docker --version
docker compose version
docker run hello-world
```

## 4. Mount External SSD

### Identify the Drive

```bash
lsblk
# Look for your SSD (usually /dev/sda)
```

### Format (if new drive)

```bash
# Create partition
sudo fdisk /dev/sda
# n (new), p (primary), 1, Enter, Enter, w (write)

# Format as ext4
sudo mkfs.ext4 /dev/sda1
```

### Create Mount Point and Mount

```bash
# Create mount point
sudo mkdir -p /mnt/external-drive

# Get UUID
sudo blkid /dev/sda1

# Add to /etc/fstab for auto-mount
echo "UUID=your-uuid-here /mnt/external-drive ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab

# Mount now
sudo mount -a

# Set permissions
sudo chown -R $USER:$USER /mnt/external-drive
```

## 5. Create Directory Structure

```bash
# Docker stacks directory
mkdir -p ~/stacks

# Data directories on external drive
mkdir -p /mnt/external-drive/{immich,jellyfin,paperless,backups,filebrowser}

# Set permissions
chmod 755 /mnt/external-drive/*
```

## 6. Configure Swap (Optional but Recommended)

The Pi 5 with 8GB RAM benefits from swap for memory-intensive containers:

```bash
# Create 4GB swap file
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Make permanent
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Adjust swappiness (lower = less aggressive swapping)
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

## 7. Security Hardening

### SSH Key Authentication

```bash
# On your local machine
ssh-keygen -t ed25519 -C "homelab"
ssh-copy-id user@raspberry-pi

# On the Pi - disable password auth
sudo vim /etc/ssh/sshd_config
# Set: PasswordAuthentication no
sudo systemctl restart sshd
```

### Firewall (UFW)

```bash
sudo apt install ufw

# Allow SSH
sudo ufw allow ssh

# Enable firewall
sudo ufw enable
```

### Automatic Security Updates

```bash
sudo apt install unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

## 8. Next Steps

1. [Configure Storage](storage-configuration.md) - Set up data directories
2. [Setup Cloudflare Tunnel](cloudflare-tunnel.md) - Secure external access
3. Start deploying services from the `stacks/` directory

## Verification Checklist

- [ ] Pi boots and is accessible via SSH
- [ ] Docker installed and running
- [ ] External SSD mounted at `/mnt/external-drive`
- [ ] Swap configured
- [ ] SSH key authentication working
- [ ] Static IP configured (if needed)
