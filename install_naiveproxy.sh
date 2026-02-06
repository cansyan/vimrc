#!/bin/bash

set -e

CADDY_CFG='
{
    order forward_proxy before file_server
}
:443, %s {
    forward_proxy {
        basic_auth %s %s
        hide_ip
        hide_via
        probe_resistance
    }
    file_server {
        root /var/www/html
    }
}
'

SERVICE_CONFIG='
[Unit]
Description=Caddy
Documentation=https://caddyserver.com/docs/
After=network.target network-online.target
Requires=network-online.target

[Service]
User=caddy
Group=caddy
ExecStart=/usr/local/bin/caddy run --environ --config /usr/local/etc/Caddyfile
ExecReload=/usr/local/bin/caddy reload --config /usr/local/etc/Caddyfile
TimeoutStopSec=5s
LimitNOFILE=1048576
LimitNPROC=512
PrivateTmp=true
ProtectSystem=full
AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
'

INDEX_HTML='<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome</title>
</head>
<body>
    <h1>Welcome</h1>
    <p>Server is running.</p>
</body>
</html>
'

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "Please run as root"
   exit 1
fi

# Check if systemctl is available
if ! command -v systemctl &> /dev/null; then
    echo "systemctl is not available. This script requires systemd."
    exit 1
fi

# Get domain name
read -p "Please input domain name: " DOMAIN
DOMAIN=$(echo "$DOMAIN" | xargs)

if [[ -z "$DOMAIN" ]]; then
    echo "Domain name cannot be empty"
    exit 1
fi

# Get public IP
IP=$(curl -s --connect-timeout 10 https://ipinfo.io/ip)
if [[ -z "$IP" ]]; then
    echo "Failed to get public IP"
    exit 1
fi

# Resolve domain to IPv4
if command -v dig &> /dev/null; then
    HOST=$(dig +short "$DOMAIN" A | head -n1)
elif command -v host &> /dev/null; then
    HOST=$(host "$DOMAIN" | awk '/has address/ { print $4 }' | head -n1)
else
    echo "Neither 'dig' nor 'host' command found. Cannot resolve domain."
    exit 1
fi

if [[ -z "$HOST" ]]; then
    echo "Failed to resolve domain: $DOMAIN"
    exit 1
fi

# Verify domain points to this server
if [[ "$HOST" != "$IP" ]]; then
    echo "Error: Domain $DOMAIN resolves to $HOST, but your server IP is $IP"
    echo "Please update your DNS record to point to $IP"
    exit 1
fi

# Generate random credentials
USER=$(openssl rand -hex 8)
PASSWORD=$(openssl rand -hex 16)

echo "Starting installation..."

# Download and install Caddy
cd /tmp
echo "Downloading Caddy with forward proxy..."
curl -sL https://github.com/klzgrad/forwardproxy/releases/latest/download/caddy-forwardproxy-naive.tar.xz -o caddy-forwardproxy-naive.tar.xz
tar -xf caddy-forwardproxy-naive.tar.xz
mv caddy-forwardproxy-naive/caddy /usr/local/bin/caddy
chmod +x /usr/local/bin/caddy

# Cleanup
rm -rf caddy-forwardproxy-naive caddy-forwardproxy-naive.tar.xz

# Create directories
mkdir -p /usr/local/etc
mkdir -p /var/www/html

# Create index.html
echo "$INDEX_HTML" > /var/www/html/index.html

# Create Caddyfile
printf "$CADDY_CFG" "$DOMAIN" "$USER" "$PASSWORD" > /usr/local/etc/Caddyfile

# Create caddy user if not exists
if ! id -u caddy &> /dev/null; then
    groupadd --system caddy
    useradd --system \
        --gid caddy \
        --create-home \
        --home-dir /var/lib/caddy \
        --shell /usr/sbin/nologin \
        --comment "Caddy web server" \
        caddy
fi

# Create systemd service
echo "$SERVICE_CONFIG" > /etc/systemd/system/caddy.service

# Enable and start service
systemctl daemon-reload
systemctl enable caddy
systemctl start caddy

# Enable BBR
echo "Enabling BBR..."
sysctl -w net.core.default_qdisc=fq
sysctl -w net.ipv4.tcp_congestion_control=bbr

# Persist BBR settings
if ! grep -q "net.ipv4.tcp_congestion_control=bbr" /etc/sysctl.conf; then
    cat >> /etc/sysctl.conf << EOF

# BBR configuration
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF
fi

echo ""
echo "Installation completed!"
echo "user: ${USER}"
echo "password: ${PASSWORD}"
echo "domain: ${DOMAIN}"
echo "port: 443"
