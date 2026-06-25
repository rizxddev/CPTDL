# 🛡️ SHIELD DDOS - VPS Protection Tool

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Bash-5.0+-green)](https://www.gnu.org/software/bash/)
[![Author](https://img.shields.io/badge/Author-rizxofficial-blue)](https://github.com/rizxddev)

Automatic DDoS protection installer untuk VPS Linux Anda. Menggunakan **Fail2Ban** + **Nginx Rate Limiter** untuk melindungi server dari serangan denial-of-service.

---

## 📦 Tools dalam Repo Ini

| Tool | Deskripsi |
|------|-----------|
| [shielddos.sh](#-shield-ddos) | Auto DDoS protection dengan Fail2Ban + Nginx |
| [ptero-monitor.sh](#-pterodactyl-monitor) | Monitoring + auto fix VPS & Pterodactyl panel |
| [delallsrvforce.js](#-delallsrvforce) | Hapus semua server Pterodactyl via Telegram bot |

---

## 🛡️ SHIELD DDOS

[![Bash](https://img.shields.io/badge/Bash-5.0+-green)](https://www.gnu.org/software/bash/)

Automatic DDoS protection installer untuk VPS Linux Anda. Menggunakan **Fail2Ban** + **Nginx Rate Limiter** untuk melindungi server dari serangan denial-of-service.

### ✨ Fitur Utama

- ✅ **Instalasi Otomatis** - Setup Fail2Ban dalam sekali klik
- 🔒 **Rate Limiting** - Batasi koneksi per IP address
- 📊 **Monitoring Real-time** - Cek status proteksi kapan saja
- 🗑️ **Uninstall Mudah** - Hapus konfigurasi dengan aman
- 🎯 **Custom Configuration** - Sesuaikan maxretry, findtime, bantime
- 📝 **Log Tracking** - Monitor semua percobaan ban

### 📋 Requirements

- **OS**: Linux (Ubuntu, Debian, CentOS, Rocky)
- **Root Access**: Harus menjalankan sebagai root/sudo
- **Nginx**: Optional (untuk rate limiting yang lebih baik)
- **Disk Space**: Minimal 100MB

### 🚀 Quick Start

#### 1️⃣ Instalasi

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/rizxddev/CPTDL/main/shielddos.sh)
```

Atau jika ingin download dulu:

```bash
curl -O https://raw.githubusercontent.com/rizxddev/CPTDL/main/shielddos.sh
chmod +x shielddos.sh
sudo ./shielddos.sh
```

#### 2️⃣ Menu Utama

```
[1] Pasang Shield DDoS      ← Install proteksi
[2] Lepas Shield DDoS       ← Uninstall proteksi
[3] Cek Status              ← Lihat status sekarang
[0] Keluar                  ← Exit
```

### ⚙️ Konfigurasi Default

```
Max Retry   : 5 kali percobaan
Find Time   : 60 detik
Ban Time    : 3600 detik (1 jam)
```

### 🔍 Monitoring & Debugging

```bash
# Status service
sudo systemctl status fail2ban

# Lihat jail aktif
sudo fail2ban-client status

# Lihat IP yang di-ban
sudo fail2ban-client status nginx-limit

# Un-ban IP tertentu
sudo fail2ban-client set nginx-limit unbanip [IP_ADDRESS]
```

### 📁 File Konfigurasi

```
/etc/fail2ban/
├── filter.d/
│   └── nginx-limit.conf
├── jail.local
└── jail.d/
```

### 🔐 Security Best Practices

1. Monitor log secara berkala: `sudo tail -f /var/log/fail2ban.log`
2. Whitelist IP trusted di `/etc/fail2ban/jail.local`: `ignoreip = 127.0.0.1/8 ::1 [YOUR_IP]`
3. Backup konfigurasi: `sudo cp /etc/fail2ban/jail.local ~/jail.local.backup`

---

## 🖥️ PTERODACTYL MONITOR

[![Bash](https://img.shields.io/badge/Bash-5.0+-green)](https://www.gnu.org/software/bash/)
[![Telegram](https://img.shields.io/badge/Telegram-Bot-blue)](https://core.telegram.org/bots)

Auto monitoring + auto fix untuk VPS Pterodactyl panel dengan tampilan **neofetch style** dan notifikasi **Telegram Bot** lengkap dengan inline button.

### ✨ Fitur

- 🖥️ **Neofetch Style Display** - Tampilan terminal yang clean dan informatif
- 📊 **Resource Monitoring** - RAM, Swap, Disk dengan progress bar + warna
- 🔄 **Service Monitoring** - Nginx, PHP-FPM, Redis, Wings
- 🤖 **Telegram Notifikasi** - Alert otomatis ke owner saat ada masalah
- 🔧 **Inline Button Fix** - Fix manual langsung dari Telegram
- ⚡ **Auto Fix** - Otomatis perbaiki masalah tanpa intervensi
- 🔁 **Toggle Auto Fix** - ON/OFF auto fix via Telegram bot

### 📋 Requirements

- **OS**: Ubuntu 20.04+ / Debian 11+
- **Root Access**: Wajib
- **Pterodactyl Panel**: Sudah terinstall
- **Telegram Bot**: Token dari [@BotFather](https://t.me/BotFather)
- **Dependencies**: `curl`, `docker`, `redis-cli`

### 🚀 Quick Start

#### 1️⃣ Download & Install

```bash
curl -O https://raw.githubusercontent.com/rizxddev/CPTDL/main/ptero-monitor.sh
chmod +x ptero-monitor.sh
cp ptero-monitor.sh /usr/local/bin/ptero-monitor
```

#### 2️⃣ Jalankan Pertama Kali

```bash
ptero-monitor
```

Akan muncul setup wizard:

```
  Pterodactyl Monitor - First Setup
  ─────────────────────────────────────────

  Masukkan Telegram Bot Token : 123456789:ABC...
  Masukkan Telegram Chat ID Owner : 987654321
```

> **Cara dapat Chat ID**: Kirim pesan ke bot kamu, lalu buka
> `https://api.telegram.org/bot<TOKEN>/getUpdates` dan salin nilai `id` dari object `chat`.

#### 3️⃣ Aktifkan Cron (Auto Run tiap 5 menit)

```bash
crontab -e
```

Tambahkan:

```
*/5 * * * * /usr/local/bin/ptero-monitor
```

### 📱 Tampilan Terminal

```
  pterodactyl@hostname
  Fri, 25 Jun 2026  20:15:00
  ─────────────────────────────────────────
  os        ·  Ubuntu 24.04.4 LTS
  kernel    ·  6.8.0-124-generic
  uptime    ·  6 days, 7 hours
  cpu       ·  Intel Xeon E5-2690 v4 (8 cores)
  load      ·  1.03 0.87 0.89
  docker    ·  44 running / 44 total
  auto fix  ·  ● on

  ── resources ────────────────────────────
  ram       ·  ████████████░░░░░░░░  78%  11Gi / 15Gi
  swap      ·  ██░░░░░░░░░░░░░░░░░░  12%  46Mi / 4Gi
  disk      ·  ███████████████░░░░░  78%  45G / 62G  (free 14G)

  ── services ─────────────────────────────
  nginx     ·  ● running
  php-fpm   ·  ● running
  redis     ·  ● running  pong
  wings     ·  ● running
  ─────────────────────────────────────────
  ✓  semua sistem normal
  log → /var/log/ptero-monitor.log
```

### 📱 Notifikasi Telegram

Saat ada masalah, bot akan kirim alert dengan inline button:

```
🚨 ALERT - Pterodactyl Monitor
━━━━━━━━━━━━━━━━━━━━
⚠️ Wings MATI
Service wings tidak berjalan!
━━━━━━━━━━━━━━━━━━━━
🖥️ Host : hostname
🕐 Time : 25/06/2026 20:15:00
🔴 Auto Fix: OFF

[ 🔧 Fix Sekarang ]  [ ❌ Ignore ]
[ 🟢 Aktifkan Auto Fix ]
```

### ⚙️ Auto Fix Yang Didukung

| Masalah | Auto Fix |
|---------|----------|
| Redis error / mati | Restart + disable bgsave error |
| Nginx mati | Restart otomatis |
| PHP-FPM mati | Restart otomatis |
| Wings mati | Restart otomatis |
| Swap > 90% | Refresh swap |
| Disk > 90% | Prune Docker, hapus log lama, apt clean |

### 📁 File & Direktori

```
/usr/local/bin/ptero-monitor      ← Script utama
/etc/ptero-monitor/config.conf    ← Config (token, chat_id)
/etc/ptero-monitor/autofix.flag   ← Status auto fix (on/off)
/var/log/ptero-monitor.log        ← Log monitoring
```

### 🔧 Lihat Log

```bash
tail -f /var/log/ptero-monitor.log
```

---

## 🤖 DELALLSRVFORCE

[![Node.js](https://img.shields.io/badge/Node.js-18+-green)](https://nodejs.org/)
[![Pterodactyl](https://img.shields.io/badge/Pterodactyl-Panel-blue)](https://pterodactyl.io/)

Modul Telegram bot untuk menghapus **semua server** di Pterodactyl panel tanpa perlu whitelist ID. Cukup ketik konfirmasi `HAPUS SEMUA`.

### ✨ Fitur

- 🗑️ Hapus semua server sekaligus tanpa whitelist
- ✅ Konfirmasi wajib sebelum eksekusi (`HAPUS SEMUA`)
- 📊 Laporan per chunk (45 server per batch)
- 🔐 Hanya bisa digunakan oleh Owner / Partner / Seller
- 🚫 Hanya bisa dijalankan di grup (bukan private chat)
- ❌ User pemilik server **tidak** ikut dihapus

### 📋 Requirements

- Node.js 18+
- Pterodactyl Panel dengan Application API Key
- Bot Telegram yang sudah dikonfigurasi

### 🚀 Cara Pakai

#### 1️⃣ Tambahkan ke bot kamu

```javascript
const { handleDeleteAllServersForce } = require('./delallsrvforce.js');

// Daftarkan command
module.exports = {
  'delallsrvforce':    handleDeleteAllServersForce,
  'delallsrvforcev2':  handleDeleteAllServersForce,
  'delallsrvforcev3':  handleDeleteAllServersForce,
  'delallsrvforcev4':  handleDeleteAllServersForce,
};
```

#### 2️⃣ Gunakan di Telegram

```
/delallsrvforce HAPUS SEMUA
/delallsrvforcev2 HAPUS SEMUA
```

### 📊 Contoh Output Bot

```
⏳ Mulai menghapus 44 server di V1...

🗑️ Hapus Semua Server (V1) [1/1]
━━━━━━━━━━━━━━━━━━━━━━━
✅ priv's Server (ID: 101)
✅ calvermc's Server (ID: 102)
✅ botpinn's Server (ID: 103)
❌ rizx's Server (ID: 104)
───────────────────────
Dihapus: 43 | Gagal: 1

✅ Selesai! Semua Server V1 Telah Diproses

📊 Total Server: 44
✅ Berhasil Dihapus: 43
❌ Gagal Dihapus: 1
```

### ⚠️ Peringatan

> Aksi ini **tidak bisa di-undo**. Semua data server akan hilang permanen.
> User pemilik server tidak ikut dihapus.

---

## 📝 Log File Locations

```
/var/log/ptero-monitor.log      ← Pterodactyl Monitor log
/var/log/fail2ban.log           ← Fail2Ban log
/var/log/nginx/error.log        ← Nginx error log
/var/log/auth.log               ← Authentication log
```

## 📚 References

- [Fail2Ban Documentation](https://www.fail2ban.org/)
- [Nginx Rate Limiting](https://nginx.org/en/docs/http/ngx_http_limit_req_module.html)
- [Pterodactyl API](https://dashflo.net/docs/api/pterodactyl/v1/)
- [Telegram Bot API](https://core.telegram.org/bots/api)

## 📄 License

MIT License - Bebas digunakan untuk keperluan apapun

## 👨‍💻 Author

**rizxofficial**
- GitHub: [@rizxddev](https://github.com/rizxddev)
- Purpose: VPS Protection, Security & Pterodactyl Tools

## ⚠️ Disclaimer

- Script ini dirancang untuk **melindungi & mengelola**, bukan untuk menyerang
- Gunakan hanya pada server yang Anda miliki/kelola
- Author tidak bertanggung jawab atas penggunaan yang menyalahgunakan
- Test di development environment terlebih dahulu sebelum production

## 💬 Support & Feedback

Jika ada masalah atau saran:
- Issues: [GitHub Issues](https://github.com/rizxddev/CPTDL/issues)
- Discussion: [GitHub Discussions](https://github.com/rizxddev/CPTDL/discussions)

---

**Made with ❤️ for Linux Server Security & Pterodactyl Management**
