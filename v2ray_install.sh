#!/usr/bin/env bash
# Install v2ray (v2fly) and configure a basic VMess TCP server on a safe port.

set -Eeuo pipefail
trap 'echo "[ERR] Failed at line $LINENO"; exit 1' ERR

must_root() { [[ $EUID -eq 0 ]] || { echo "[!] Run as root (sudo)"; exit 1; }; }
must_root

VMESS_PORT="${VMESS_PORT:-11000}"      # default port
VMESS_USER="${VMESS_USER:-client1}"    # label/email for first client
REMOTE_HOST_DEFAULT="moradicloud.ir"   # your domain (can be IP if you want)
CONFIG_PATH="/usr/local/etc/v2ray/config.json"

echo "==> Installing dependencies (curl, jq)…"
apt-get update -y >/dev/null
apt-get install -y curl jq >/dev/null

echo "==> Installing v2ray (v2fly)…"
bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)

echo "==> Generating UUID for first VMess client…"
UUID="$(uuidgen)"

# Simple check to avoid obvious conflicts on the port
if ss -ltnp | grep -q ":${VMESS_PORT}\b"; then
  echo "[WARN] Port ${VMESS_PORT} already in use. Choose another port by running:"
  echo "       VMESS_PORT=11001 bash v2ray_install.sh"
  exit 1
fi

echo "==> Writing v2ray config to ${CONFIG_PATH} …"
cat > "${CONFIG_PATH}" <<EOF
{
  "log": {
    "access": "/var/log/v2ray/access.log",
    "error": "/var/log/v2ray/error.log",
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": ${VMESS_PORT},
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "${UUID}",
            "alterId": 0,
            "email": "${VMESS_USER}"
          }
        ]
      },
      "streamSettings": {
        "network": "tcp"
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ]
}
EOF

echo "==> Enabling and restarting v2ray service…"
systemctl enable v2ray >/dev/null
systemctl restart v2ray
sleep 1

systemctl is-active --quiet v2ray || {
  echo "[!] v2ray service is not running. Check logs:"
  echo "    journalctl -u v2ray -n 50 --no-pager"
  exit 1
}

# Open firewall
echo "==> Allowing TCP port ${VMESS_PORT} in UFW…"
if command -v ufw >/dev/null 2>&1; then
  ufw allow "${VMESS_PORT}/tcp" >/dev/null || true
  ufw reload >/dev/null || true
fi

# Try to guess remote host; prefer your domain by default
REMOTE_HOST="${REMOTE_HOST_DEFAULT}"
if [[ -z "${REMOTE_HOST}" ]]; then
  REMOTE_HOST="$(curl -s --max-time 4 ifconfig.me || hostname -I | awk '{print $1}' || echo "YOUR_SERVER_IP")"
fi

echo
echo "==> v2ray installed and configured."
echo "    Port : ${VMESS_PORT}"
echo "    UUID : ${UUID}"
echo "    Host : ${REMOTE_HOST}"
echo "    User : ${VMESS_USER}"

# Build vmess link
VMESS_JSON=$(cat <<JSON
{"v":"2","ps":"${VMESS_USER}","add":"${REMOTE_HOST}","port":"${VMESS_PORT}","id":"${UUID}","aid":"0","net":"tcp","type":"none","host":"","path":"","tls":""}
JSON
)

VMESS_B64=$(echo -n "${VMESS_JSON}" | base64 -w0 2>/dev/null || echo -n "${VMESS_JSON}" | base64)
VMESS_LINK="vmess://${VMESS_B64}"

echo
echo "==> VMess link (import into V2RayN / V2RayNG):"
echo "${VMESS_LINK}"
echo
echo "You can rerun this script with custom values, e.g.:"
echo "  VMESS_PORT=11001 VMESS_USER=myphone bash v2ray_install.sh"
