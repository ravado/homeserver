#!/usr/bin/env bash
# Deduplicate vfio-pci ids= list in /etc/modprobe.d/vfio.conf

set -euo pipefail
CONF="/etc/modprobe.d/vfio.conf"
BACKUP="${CONF}.bak.$(date +%s)"

[[ -f "$CONF" ]] || { echo "❌ $CONF not found"; exit 1; }

cp -a "$CONF" "$BACKUP"
echo "📂 Backup saved to $BACKUP"

# Extract all ids, clean, dedupe
IDS=$(grep -oP '^options\s+vfio-?pci.*ids=\K\S+' "$CONF" \
  | tr ',' '\n' | tr '[:upper:]' '[:lower:]' \
  | grep -E '^[0-9a-f]{4}:[0-9a-f]{4}$' \
  | awk '!seen[$0]++' | paste -sd, -)

[[ -n "$IDS" ]] || { echo "❌ No valid IDs found"; exit 1; }

# Replace the line
sed -i -E "s|^options vfio-pci .*|options vfio-pci ids=${IDS} disable_vga=1|" "$CONF"

echo "✅ Cleaned line in $CONF:"
grep '^options vfio-pci' "$CONF"