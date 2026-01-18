#!/usr/bin/env python3

import os
import sys
import urllib.request as request
import socket
import string
import secrets
import subprocess
import shutil

caddyCfg = '''
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
'''

def must_run_cmd(cmd):
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Command failed: {cmd}")
        print(f"Error: {result.stderr}")
        sys.exit(1)
    return result.stdout

def install(domain, user, password):
    if not shutil.which("wget"):
        print("wget is not installed")
        sys.exit(1)
    
    os.chdir("/tmp")
    print("Downloading Caddy with forward proxy...")
    must_run_cmd("wget -q https://github.com/klzgrad/forwardproxy/releases/latest/download/caddy-forwardproxy-naive.tar.xz")
    must_run_cmd("tar -xf caddy-forwardproxy-naive.tar.xz")
    must_run_cmd("mv caddy-forwardproxy-naive/caddy /usr/local/bin/caddy")
    must_run_cmd("chmod +x /usr/local/bin/caddy")
    
    # Cleanup
    must_run_cmd("rm -rf caddy-forwardproxy-naive caddy-forwardproxy-naive.tar.xz")
    
    os.makedirs("/usr/local/etc", exist_ok=True)
    os.makedirs("/var/www/html", exist_ok=True)
    
    try:
        with open("/usr/local/etc/Caddyfile", "w") as f:
            f.write(caddyCfg % (domain, user, password))
    except IOError as e:
        print(f"Failed to write Caddyfile: {e}")
        sys.exit(1)

serviceConfig = '''
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
'''

def run():
    # Check if caddy user exists
    result = subprocess.run("id -u caddy", shell=True, capture_output=True)
    if result.returncode != 0:
        must_run_cmd("groupadd --system caddy")
        must_run_cmd("""useradd --system \
            --gid caddy \
            --create-home \
            --home-dir /var/lib/caddy \
            --shell /usr/sbin/nologin \
            --comment "Caddy web server" \
            caddy
        """)
    
    try:
        with open("/etc/systemd/system/caddy.service", "w") as f:
            f.write(serviceConfig)
    except IOError as e:
        print(f"Failed to write systemd service: {e}")
        sys.exit(1)
    
    must_run_cmd("systemctl daemon-reload")
    must_run_cmd("systemctl enable caddy")
    must_run_cmd("systemctl start caddy")

def enable_bbr():
    print("Enabling BBR...")
    must_run_cmd("sysctl -w net.core.default_qdisc=fq")
    must_run_cmd("sysctl -w net.ipv4.tcp_congestion_control=bbr")
    
    # Persist BBR settings
    bbr_config = "\n# BBR configuration\nnet.core.default_qdisc=fq\nnet.ipv4.tcp_congestion_control=bbr\n"
    try:
        with open("/etc/sysctl.conf", "a") as f:
            if "net.ipv4.tcp_congestion_control=bbr" not in open("/etc/sysctl.conf").read():
                f.write(bbr_config)
    except IOError as e:
        print(f"Warning: Failed to persist BBR settings: {e}")

if __name__ == "__main__":
    if os.geteuid() != 0:
        print("Please run as root")
        sys.exit(1)

    if not shutil.which("systemctl"):
        print("systemctl is not available. This script requires systemd.")
        sys.exit(1)

    domain = input("Please input domain name: ").strip()
    if domain == "":
        print("Domain name cannot be empty")
        sys.exit(1)
    
    try:
        host = socket.gethostbyname(domain)
    except socket.gaierror as e:
        print(f"Failed to resolve domain: {e}")
        sys.exit(1)
    
    try:
        resp = request.urlopen("https://ipinfo.io/ip", timeout=10)
        if resp.getcode() != 200:
            print("Failed to get public IP:", resp.getcode())
            sys.exit(1)
        ip = resp.read().decode('utf-8').strip()
    except Exception as e:
        print(f"Failed to get public IP: {e}")
        sys.exit(1)
    
    if host != ip:
        print(f"Domain name does not point to this server (domain: {host}, server: {ip})")
        sys.exit(1)

    alphabet = string.ascii_letters + string.digits
    user = ''.join(secrets.choice(alphabet) for _ in range(8))
    password = ''.join(secrets.choice(alphabet) for _ in range(16))

    print("Starting installation...")
    install(domain, user, password)
    run()
    enable_bbr()
    print(f"\nInstallation completed!")
    print(f"Proxy URL: https://{user}:{password}@{domain}")
