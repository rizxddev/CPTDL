# 🛡️ SHIELD DDOS - VPS Protection Tool

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Bash-5.0+-green)](https://www.gnu.org/software/bash/)
[![Author](https://img.shields.io/badge/Author-rizxofficial-blue)](https://github.com/rizxddev)

Automatic DDoS protection installer untuk VPS Linux Anda. Menggunakan **Fail2Ban** + **Nginx Rate Limiter** untuk melindungi server dari serangan denial-of-service.

## ✨ Fitur Utama

- ✅ **Instalasi Otomatis** - Setup Fail2Ban dalam sekali klik
- 🔒 **Rate Limiting** - Batasi koneksi per IP address
- 📊 **Monitoring Real-time** - Cek status proteksi kapan saja
- 🗑️ **Uninstall Mudah** - Hapus konfigurasi dengan aman
- 🎯 **Custom Configuration** - Sesuaikan maxretry, findtime, bantime
- 📝 **Log Tracking** - Monitor semua percobaan ban

## 📋 Requirements

- **OS**: Linux (Ubuntu, Debian, CentOS, Rocky)
- **Root Access**: Harus menjalankan sebagai root/sudo
- **Nginx**: Optional (untuk rate limiting yang lebih baik)
- **Disk Space**: Minimal 100MB

## 🚀 Quick Start

### 1️⃣ Instalasi

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/rizxddev/CPTDL/main/shielddos.sh)
```

Atau jika ingin download dulu:

```bash
curl -O https://raw.githubusercontent.com/rizxddev/CPTDL/main/shielddos.sh
chmod +x shielddos.sh
sudo ./shielddos.sh
```

### 2️⃣ Menu Utama

Setelah menjalankan script, pilih opsi:

```
[1] Pasang Shield DDoS      ← Install proteksi
[2] Lepas Shield DDoS       ← Uninstall proteksi
[3] Cek Status              ← Lihat status sekarang
[0] Keluar                  ← Exit
```

## 📖 Cara Penggunaan

### ✅ Memasang Proteksi

```bash
sudo bash <(curl -fsSL https://raw.githubusercontent.com/rizxddev/CPTDL/main/shielddos.sh)
```

Pilih opsi `[1]` dan tunggu proses instalasi selesai.

**Output yang akan Anda lihat:**
```
[1/4] Menginstall Fail2Ban...
[2/4] Membuat filter nginx-limit...
[3/4] Mengaktifkan jail...
[4/4] Restart & aktifkan Fail2Ban...

✅ SHIELD DDOS TERPASANG!
```

### 📊 Cek Status Proteksi

```bash
sudo bash <(curl -fsSL https://raw.githubusercontent.com/rizxddev/CPTDL/main/shielddos.sh)
```

Pilih opsi `[3]` untuk melihat:
- Status Fail2Ban service
- Daftar jail yang aktif
- IP yang ter-ban terakhir
- Total percobaan login gagal

### 🗑️ Menghapus Proteksi

```bash
sudo bash <(curl -fsSL https://raw.githubusercontent.com/rizxddev/CPTDL/main/shielddos.sh)
```

Pilih opsi `[2]` untuk menghapus semua konfigurasi dengan aman.

## ⚙️ Konfigurasi Default

```
Max Retry   : 5 kali percobaan
Find Time   : 60 detik
Ban Time    : 3600 detik (1 jam)
```

### Mengubah Konfigurasi (Manual)

Edit file `/etc/fail2ban/jail.local`:

```bash
sudo nano /etc/fail2ban/jail.local
```

Cari section `[nginx-limit]` dan ubah parameter:

```ini
[nginx-limit]
enabled  = true
port     = http,https
filter   = nginx-limit
logpath  = /var/log/nginx/error.log
maxretry = 5          # Ubah jumlah retry maksimal
findtime = 60         # Ubah window waktu (detik)
bantime  = 3600       # Ubah durasi ban (detik)
```

Restart Fail2Ban:

```bash
sudo systemctl restart fail2ban
```

## 🔍 Monitoring & Debugging

### Status Service

```bash
sudo systemctl status fail2ban
```

### Lihat Jail Aktif

```bash
sudo fail2ban-client status
```

### Status Jail Spesifik

```bash
sudo fail2ban-client status nginx-limit
```

### Lihat Log Ban Terbaru

```bash
sudo tail -20 /var/log/fail2ban.log
```

### Lihat IP yang di-Ban

```bash
sudo fail2ban-client set nginx-limit banip
```

### Un-Ban IP Tertentu

```bash
sudo fail2ban-client set nginx-limit unbanip [IP_ADDRESS]
```

**Contoh:**
```bash
sudo fail2ban-client set nginx-limit unbanip 192.168.1.100
```

## 📁 File Konfigurasi

```
/etc/fail2ban/
├── filter.d/
│   └── nginx-limit.conf      ← Filter rules
├── jail.local                 ← Jail configuration
└── jail.d/                    ← Additional configs
```

## 🐛 Troubleshooting

### ❌ Error: "Fail2Ban gagal diinstall"

```bash
# Update package manager
sudo apt update
sudo apt upgrade -y

# Install manual
sudo apt install fail2ban -y

# Jalankan script lagi
bash <(curl -fsSL https://raw.githubusercontent.com/rizxddev/CPTDL/main/shielddos.sh)
```

### ❌ Service Fail2Ban tidak running

```bash
# Start manual
sudo systemctl start fail2ban
sudo systemctl enable fail2ban

# Check status
sudo systemctl status fail2ban
```

### ❌ Jail tidak terdeteksi

```bash
# Tunggu 30 detik setelah instalasi
# Fail2Ban perlu waktu untuk inisialisasi

# Restart service
sudo systemctl restart fail2ban

# Cek lagi
sudo fail2ban-client status nginx-limit
```

### ❌ Terlalu banyak false positive (IP legit ter-ban)

Ubah konfigurasi untuk lebih relaks:

```bash
sudo nano /etc/fail2ban/jail.local
```

Ubah parameter:
```ini
maxretry = 10        # Naikkan threshold
findtime = 120       # Naikkan window
bantime  = 1800      # Turunkan durasi ban
```

Restart:
```bash
sudo systemctl restart fail2ban
```

## 🔐 Security Best Practices

1. **Monitor Log Secara Berkala**
   ```bash
   sudo tail -f /var/log/fail2ban.log
   ```

2. **Whitelist IP Trusted**
   Edit `/etc/fail2ban/jail.local` dan tambahkan:
   ```ini
   ignoreip = 127.0.0.1/8 ::1 [YOUR_IP]
   ```

3. **Backup Konfigurasi**
   ```bash
   sudo cp /etc/fail2ban/jail.local ~/jail.local.backup
   ```

4. **Disable SSH Brute Force (Bonus)**
   Tambahkan ke `/etc/fail2ban/jail.local`:
   ```ini
   [sshd]
   enabled = true
   port = ssh
   filter = sshd
   logpath = /var/log/auth.log
   maxretry = 5
   ```

## 📊 Contoh Output

### Status Check
```
======================================
   📊 STATUS SHIELD DDOS
======================================

⚙️  Service Fail2Ban : active

📋 Status Umum:
Status for the jail: sshd
|- Filter file list:	sshd
|- Currently failed:	0
|- Currently banned:	2
`- Total banned:		15

🔒 Jail nginx-limit:
Status for the jail: nginx-limit
|- Filter file list:	nginx-limit
|- Currently failed:	0
|- Currently banned:	3
`- Total banned:		42

🚫 20 Ban Terakhir:
2024-06-25 10:15:32 Ban 203.0.113.45
2024-06-25 10:14:15 Ban 198.51.100.23
...
```

## 📝 Log File Locations

```
/var/log/fail2ban.log           ← Main Fail2Ban log
/var/log/nginx/error.log        ← Nginx error log
/var/log/auth.log               ← Authentication log
```

## 🔄 Update Script

Untuk mendapatkan versi terbaru:

```bash
# Download ulang
curl -O https://raw.githubusercontent.com/rizxddev/CPTDL/main/shielddos.sh
chmod +x shielddos.sh
sudo ./shielddos.sh
```

Atau gunakan one-liner:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/rizxddev/CPTDL/main/shielddos.sh)
```

## 📚 References

- [Fail2Ban Documentation](https://www.fail2ban.org/)
- [Nginx Rate Limiting](https://nginx.org/en/docs/http/ngx_http_limit_req_module.html)
- [Linux Security Best Practices](https://ubuntu.com/security)

## 📄 License

MIT License - Bebas digunakan untuk keperluan apapun

## 👨‍💻 Author

**rizxofficial**
- GitHub: [@rizxddev](https://github.com/rizxddev)
- Purpose: VPS Protection & Security

## ⚠️ Disclaimer

- Script ini dirancang untuk **melindungi**, bukan untuk menyerang
- Gunakan hanya pada server yang Anda miliki/kelola
- Author tidak bertanggung jawab atas penggunaan yang menyalahgunakan
- Test di development environment terlebih dahulu sebelum production

## 💬 Support & Feedback

Jika ada masalah atau saran:
- Issues: [GitHub Issues](https://github.com/rizxddev/CPTDL/issues)
- Discussion: [GitHub Discussions](https://github.com/rizxddev/CPTDL/discussions)

---

**Made with ❤️ for Linux Server Security**
