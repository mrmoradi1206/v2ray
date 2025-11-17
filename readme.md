# V2Ray Installer & Client Manager (VMess / TCP)

Simple and safe V2Ray deployment scripts for Ubuntu servers.  
These scripts install V2Ray (v2fly core), create a secure VMess TCP server on a custom port, and allow you to easily add new clients with auto-generated `vmess://` links.

✔ Works on **Ubuntu 20.04 / 22.04 / 24.04**  
✔ Designed for servers already running Nginx / OpenVPN / MTProto  
✔ Auto-checks ports and prevents conflicts  
✔ Auto-generates UUIDs  
✔ Auto-generates **vmess://** links  
✔ Domain-friendly (`moradicloud.ir` by default)  
✔ Clean JSON config, restart-safe  
✔ No TLS required (pure TCP mode)  

---

# 📁 Files Included

### **1. `v2ray_install.sh`**
Installs V2Ray, writes a clean VMess config, opens a firewall port, and creates your **first VMess client**.

### **2. `v2ray_add_client.sh`**
Adds additional VMess clients and prints a fresh `vmess://` link.

---

# 🚀 Installation

```bash
chmod +x v2ray_install.sh
chmod +x v2ray_add_client.sh
```

### Install V2Ray + First Client  
```bash
sudo ./v2ray_install.sh
```

### Add Additional Clients  
```bash
sudo ./v2ray_add_client.sh
```

---

# 🔧 Custom Installation Example

```bash
sudo VMESS_PORT=11001 VMESS_USER=phone ./v2ray_install.sh
```

---

# 📖 VMess Example

A typical VMess link looks like:

```
vmess://xxxxxxxxxxxx==
```

Import into:
- V2RayNG (Android)
- V2RayN (Windows)
- Nekobox (iOS/macOS)

---

# 🛠 Debugging

```bash
sudo systemctl status v2ray --no-pager -l
sudo journalctl -u v2ray -n 50 --no-pager
sudo ss -tulpn | grep v2ray
```

---

# 📦 Directory Layout

```
/usr/local/etc/v2ray/config.json
/var/log/v2ray/access.log
/var/log/v2ray/error.log
v2ray_install.sh
v2ray_add_client.sh
README.md
```

---

If you need a **WebSocket + TLS version**, **Reality (VLESS)**, or full **Cloudflare proxy compatibility**, I can generate upgraded scripts as well.
