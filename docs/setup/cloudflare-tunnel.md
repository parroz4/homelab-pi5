# Cloudflare Tunnel Setup

Cloudflare Tunnel provides secure access to your homelab services without exposing any ports on your router. This is the recommended approach for external access.

## Why Cloudflare Tunnel?

| Feature | Traditional Port Forwarding | Cloudflare Tunnel |
|---------|---------------------------|-------------------|
| Open ports | Required | None |
| SSL certificates | Manual (Let's Encrypt) | Automatic |
| DDoS protection | None | Included |
| WAF | Additional setup | Included |
| Geo-restriction | Complex | Built-in |

## Prerequisites

- Cloudflare account (free tier works)
- Domain managed by Cloudflare DNS
- Docker installed on your Pi

## 1. Create a Tunnel

### Via Cloudflare Dashboard

1. Go to [Cloudflare Zero Trust](https://one.dash.cloudflare.com/)
2. Navigate to **Networks** → **Tunnels**
3. Click **Create a tunnel**
4. Choose **Cloudflared** connector
5. Name your tunnel (e.g., "homelab-pi5")
6. Copy the tunnel token

### Via CLI (Alternative)

```bash
# Install cloudflared
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb -o cloudflared.deb
sudo dpkg -i cloudflared.deb

# Authenticate
cloudflared tunnel login

# Create tunnel
cloudflared tunnel create homelab-pi5

# Get tunnel token
cloudflared tunnel token homelab-pi5
```

## 2. Deploy Cloudflared Container

Create the compose file:

```yaml
# stacks/network/cloudflared/compose.yaml
services:
  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared
    restart: unless-stopped
    command: tunnel run
    environment:
      - TUNNEL_TOKEN=${TUNNEL_TOKEN}
    networks:
      - cloudflared

networks:
  cloudflared:
    driver: bridge
```

Create `.env` file:

```bash
TUNNEL_TOKEN=your-tunnel-token-here
```

Deploy:

```bash
docker compose up -d
```

## 3. Configure Public Hostnames

In Cloudflare Dashboard → Tunnels → Your Tunnel → Public Hostname:

### Add a Service

| Setting | Example Value |
|---------|---------------|
| Subdomain | `jellyfin` |
| Domain | `example.com` |
| Type | `HTTP` |
| URL | `192.168.1.45:8096` |

### Common Services Configuration

| Service | Type | URL |
|---------|------|-----|
| Jellyfin | HTTP | `${HOST_IP}:8096` |
| Immich | HTTP | `${HOST_IP}:2283` |
| Home Assistant | HTTP | `${HOST_IP}:8123` |
| Portainer | HTTPS | `${HOST_IP}:9443` |
| Pi-hole | HTTP | `${HOST_IP}:80` |

## 4. Configure Cloudflare Access (Authentication)

### Create Access Application

1. Go to **Access** → **Applications**
2. Click **Add an application**
3. Select **Self-hosted**

### Settings

```
Application name: Homelab Services
Session duration: 24 hours
Application domain: *.example.com
```

### Add Authentication Policy

```
Policy name: Homelab Users
Action: Allow
Include:
  - Emails: your-email@gmail.com
  - Login Methods: Google OAuth
```

### Configure Identity Providers

1. Go to **Settings** → **Authentication**
2. Add **Google** as identity provider
3. Follow OAuth setup instructions

## 5. Geo-Restriction (Optional)

### Via WAF Rules

1. Go to **Security** → **WAF**
2. Create custom rule:

```
Rule name: Block non-Italy traffic
Expression: (ip.geoip.country ne "IT")
Action: Block
```

### Per-Application Restriction

In Access Application settings:
- Add policy with `Country` selector
- Include only allowed countries

## 6. Additional Security Settings

### HTTP to HTTPS Redirect

In domain settings:
- Enable **Always Use HTTPS**

### Minimum TLS Version

- Set to **TLS 1.2** minimum

### Bot Protection

- Enable **Bot Fight Mode** (free)

## 7. Monitoring

### Check Tunnel Status

```bash
# Container logs
docker logs cloudflared

# Cloudflare dashboard
# Networks → Tunnels → Your tunnel → Connections
```

### Health Check

```bash
# From external network
curl -I https://service.example.com
```

## Troubleshooting

### Tunnel Not Connecting

```bash
# Check container status
docker ps | grep cloudflared

# Check logs for errors
docker logs cloudflared --tail 50

# Verify token
echo $TUNNEL_TOKEN | wc -c  # Should be > 100 chars
```

### 502 Bad Gateway

- Verify the internal service is running
- Check the URL in tunnel config (use container IP or host IP)
- Ensure the port is correct

### Access Denied

- Check Access policies
- Verify email is in allowed list
- Clear browser cookies and retry

## Architecture Diagram

```
Internet User
      │
      ▼
┌─────────────────┐
│   Cloudflare    │
│   Edge Network  │
│  (WAF, DDoS)    │
└────────┬────────┘
         │ Encrypted tunnel
         ▼
┌─────────────────┐
│  cloudflared    │
│   container     │
└────────┬────────┘
         │ Local network
         ▼
┌─────────────────┐
│  Your Services  │
│  (Docker)       │
└─────────────────┘
```

## Next Steps

- [Storage Configuration](storage-configuration.md)
- Deploy services from `stacks/` directory
