#!/bin/bash
# Sync script for homelab documentation
# Copies compose files from stacksDocker to docs repo with sanitization

SOURCE_DIR="/home/francesco/stacksDocker"
DEST_DIR="/home/francesco/homelab-docs/homelab-pi5/stacks"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Homelab Docs Sync Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Mapping: source folder -> destination category/folder
declare -A FOLDER_MAP=(
    ["immich_server"]="media/immich"
    ["jellyfin"]="media/jellyfin"
    ["broker"]="media/paperless"
    ["filebrowser"]="media/filebrowser"
    ["homeassistant"]="automation/homeassistant"
    ["n8n"]="automation/n8n"
    ["beszel"]="monitoring/beszel"
    ["uptime-kuma"]="monitoring/uptime-kuma"
    ["netalertx"]="monitoring/netalertx"
    ["speedtest-tracker"]="monitoring/speedtest-tracker"
    ["changedetection"]="monitoring/changedetection"
    ["pihole"]="network/pihole"
    ["cloudflared"]="network/cloudflared"
    ["portainer"]="management/portainer"
    ["homepage"]="management/homepage"
    ["backrest"]="management/backrest"
    ["warracker"]="utilities/warracker"
)

# Sanitization function
sanitize_file() {
    local file="$1"

    # IP addresses
    sed -i 's/192\.168\.1\.[0-9]\+/${HOST_IP}/g' "$file"

    # Domains
    sed -i 's/parroz44\.xyz/example.com/g' "$file"
    sed -i 's/parroz44\.ddns\.net/example.ddns.net/g' "$file"

    # Paths
    sed -i 's|/home/francesco/stacksDocker|/home/user/stacks|g' "$file"
    sed -i 's|/media/francesco/BEA8-2D89|/mnt/external-drive|g' "$file"

    # Cloudflare tokens (long alphanumeric strings after TUNNEL_TOKEN=)
    sed -i 's/TUNNEL_TOKEN=.*/TUNNEL_TOKEN=${TUNNEL_TOKEN}/g' "$file"

    # App keys (Laravel style)
    sed -i 's/APP_KEY=base64:[A-Za-z0-9+/=]\+/APP_KEY=${APP_KEY}/g' "$file"

    # Generic passwords in environment
    sed -i "s/WEBPASSWORD: '[^']*'/WEBPASSWORD: '\${PIHOLE_PASSWORD}'/g" "$file"

    # Placeholder paths
    sed -i 's|/path/to/data|/path/to/data|g' "$file"
    sed -i 's|/path/to-custom-ssl-keys|/path/to-custom-ssl-keys|g' "$file"
}

# Count synced files
synced=0
skipped=0

echo -e "${YELLOW}Syncing compose files...${NC}"
echo ""

for source_folder in "${!FOLDER_MAP[@]}"; do
    dest_folder="${FOLDER_MAP[$source_folder]}"
    source_file="$SOURCE_DIR/$source_folder/compose.yaml"
    dest_path="$DEST_DIR/$dest_folder"
    dest_file="$dest_path/compose.yaml"

    if [[ -f "$source_file" ]]; then
        # Create destination directory if needed
        mkdir -p "$dest_path"

        # Copy file
        cp "$source_file" "$dest_file"

        # Sanitize
        sanitize_file "$dest_file"

        echo -e "  ${GREEN}✓${NC} $source_folder -> $dest_folder"
        synced=$((synced + 1))
    else
        echo -e "  ${RED}✗${NC} $source_folder (not found)"
        skipped=$((skipped + 1))
    fi
done

echo ""
echo -e "${BLUE}----------------------------------------${NC}"
echo -e "Synced: ${GREEN}$synced${NC} | Skipped: ${RED}$skipped${NC}"
echo -e "${BLUE}----------------------------------------${NC}"
echo ""

# Show git status
cd "$DEST_DIR/.."
echo -e "${YELLOW}Git status:${NC}"
git status --short

echo ""
echo -e "${YELLOW}Changes preview (git diff):${NC}"
git diff --stat

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Done!${NC} Review changes above."
echo -e "To commit: ${YELLOW}cd ~/homelab-docs/homelab-pi5 && git add -A && git commit -m 'Update configs'${NC}"
echo -e "${BLUE}========================================${NC}"
