#!/usr/bin/env bash
# Add a new VMess client to existing v2ray config and print a vmess link.

set -Eeuo pipefail
trap 'echo "[ERR] Failed at line $LINENO"; exit 1' ERR

must_root() { [[ $EUID -eq 0 ]] || { echo "[!] Run as root (sudo)"; exit 1; }; }
must_root

CONFIG_PATH="/usr/local/etc/v2ray/config.json"
REMOTE_HOST_DEFAULT="moradicloud.ir"   # your domain or IP

if [[ ! -f "${CONFIG_PATH}" ]]; then
  echo "[!] ${CONFIG_PATH} not found. Run v2ray_install.sh first."
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "==> Installing jq…"
  apt-get update -y >/dev/null
  apt-get install -y jq >/dev/null
fi

echo
read -rp "Enter client name/label (e.g. phone, laptop): " CLIENT_NAME
[[ -z "${CLIENT_NAME}" ]] && { echo "❌ Client name cannot be empty"; exit 1; }

UUID="$(uuidgen)"

# Extract port of first inbound
PORT=$(jq -r '.inbounds[0].port' "${CONFIG_PATH}")
PROTO=$(jq -r '.inbounds[0].protocol' "${CONFIG_PATH}")

if [[ "${PROTO}" != "vmess" ]]; then
  echo "[!] First inbound is not 'vmess'. This script assumes inbounds[0] is VMess."
  exit 1
fi

if [[ -z "${PORT}" || "${PORT}" == "null" ]]; then
  echo "[!] Could not detect inbound port from config."
  exit 1
fi

echo "==> Adding client to v2ray config…"
cp "${CONFIG_PATH}" "${CONFIG_PATH}.bak.$(date +%s)"

# Append new client to .inbounds[0].settings.clients
jq ".inbounds[0].settings.clients += [{\"id\":\"${UUID}\",\"alterId\":0,\"email\":\"${CLIENT_NAME}\"}]" \
  "${CONFIG_PATH}" > "${CONFIG_PATH}.tmp"

mv "${CONFIG_PATH}.tmp" "${CONFIG_PATH}"

echo "==> Restarting v2ray…"
systemctl restart v2ray
sleep 1
systemctl is-active --quiet v2ray || {
  echo "[!] v2ray failed to start after adding client. Restoring backup."
  cp "${CONFIG_PATH}.bak."* "${CONFIG_PATH}" 2>/dev/null || true
  systemctl restart v2ray || true
  exit 1
}

# Choose host for client config
REMOTE_HOST="${REMOTE_HOST_DEFAULT}"
if [[ -z "${REMOTE_HOST}" ]]; then
  REMOTE_HOST="$(curl -s --max-time 4 ifconfig.me || hostname -I | awk '{print $1}' || echo "YOUR_SERVER_IP")"
fi

echo
echo "==> New client added."
echo "    Name : ${CLIENT_NAME}"
echo "    UUID : ${UUID}"
echo "    Host : ${REMOTE_HOST}"
echo "    Port : ${PORT}"
echo "    Proto: ${PROTO}"

# Build vmess link
VMESS_JSON=$(cat <<JSON
{"v":"2","ps":"${CLIENT_NAME}","add":"${REMOTE_HOST}","port":"${PORT}","id":"${UUID}","aid":"0","net":"tcp","type":"none","host":"","path":"","tls":""}
JSON
)

VMESS_B64=$(echo -n "${VMESS_JSON}" | base64 -w0 2>/dev/null || echo -n "${VMESS_JSON}" | base64)
VMESS_LINK="vmess://${VMESS_B64}"

echo
echo "==> VMess link for this client:"
echo "${VMESS_LINK}"
echo
echo "Import this link into V2RayN / V2RayNG."
