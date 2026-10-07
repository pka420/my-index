#!/usr/bin/env bash
# Installs the from-delhi.net apex site into host nginx.
#
#   sudo ./infra/install-nginx.sh
#
# Copies this repo's public files to /var/www/from-delhi.net and enables
# infra/nginx.conf as sites-available/from-delhi.net.

set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Run this as root (sudo)." >&2
  exit 1
fi

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
SRC="$HERE/nginx.conf"
DEST_AVAILABLE="/etc/nginx/sites-available/from-delhi.net"
DEST_ENABLED="/etc/nginx/sites-enabled/from-delhi.net"
WEBROOT="/var/www/from-delhi.net"
NGINX_CONF="/etc/nginx/nginx.conf"

if ! grep -q "include /etc/nginx/sites-enabled" "$NGINX_CONF" 2>/dev/null; then
  echo "Adding 'include /etc/nginx/sites-enabled/*;' to $NGINX_CONF"
  if grep -q "include /etc/nginx/conf.d" "$NGINX_CONF"; then
    sed -i '/include \/etc\/nginx\/conf.d/a \    include /etc/nginx/sites-enabled/*;' "$NGINX_CONF"
  else
    sed -i '/http {/a \    include /etc/nginx/sites-enabled/*;' "$NGINX_CONF"
  fi
fi

mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled "$WEBROOT"

install -m 644 "$SRC" "$DEST_AVAILABLE"
ln -sf "$DEST_AVAILABLE" "$DEST_ENABLED"

rsync -a --delete \
  --exclude '.git/' \
  --exclude 'infra/' \
  --exclude '.gitignore' \
  "$REPO/" "$WEBROOT/"

nginx -t
systemctl reload nginx

echo "from-delhi.net installed to $WEBROOT (nginx $DEST_ENABLED)"
