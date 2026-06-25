#!/bin/bash
# ============================================
#   SHIELD DDOS INSTALLER
#   Fail2Ban + Nginx Rate Limiter
#   by rizxofficial
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

if (( EUID != 0 )); then
    echo -e "${RED}❌ Jalankan sebagai root!${NC}"
    exit 1
fi

clear
echo -e "${CYAN}======================================${NC}"
echo -e "   ${GREEN}🛡  SHIELD DDOS - rizxofficial${NC}"
echo -e "${CYAN}======================================${NC}"
echo ""
echo -e " ${YELLOW}[1]${NC} Pasang Shield DDoS"
echo -e " ${YELLOW}[2]${NC} Lepas Shield DDoS"
echo -e " ${YELLOW}[3]${NC} Cek Status"
echo -e " ${YELLOW}[0]${NC} Keluar"
echo ""
echo -ne "Pilih opsi: "
read -r PILIHAN

case "$PILIHAN" in
    1) do_install ;;
    2) do_uninstall ;;
    3) do_status ;;
    0) echo "Keluar."; exit 0 ;;
    *) echo -e "${RED}Pilihan tidak valid.${NC}"; exit 1 ;;
esac

do_install() {
    echo ""
    echo -e "${CYAN}[1/4] Menginstall Fail2Ban...${NC}"
    apt update -y > /dev/null 2>&1
    apt install -y fail2ban > /dev/null 2>&1

    if ! which fail2ban-server > /dev/null 2>&1; then
        echo -e "${RED}❌ Gagal install Fail2Ban! Coba manual:${NC}"
        echo "    apt install fail2ban -y"
        exit 1
    fi
    echo -e "${GREEN}✅ Fail2Ban terinstall${NC}"

    echo ""
    echo -e "${CYAN}[2/4] Membuat filter nginx-limit...${NC}"
    cat > /etc/fail2ban/filter.d/nginx-limit.conf << 'EOF'
[Definition]
failregex = limiting connections by zone.*client: <HOST>
ignoreregex =
EOF
    echo -e "${GREEN}✅ Filter dibuat${NC}"

    echo ""
    echo -e "${CYAN}[3/4] Mengaktifkan jail...${NC}"
    touch /etc/fail2ban/jail.local
    if grep -q '\[nginx-limit\]' /etc/fail2ban/jail.local 2>/dev/null; then
        echo -e "${YELLOW}⚠️  Jail nginx-limit sudah ada, skip.${NC}"
    else
        cat >> /etc/fail2ban/jail.local << 'EOF'

[nginx-limit]
enabled  = true
port     = http,https
filter   = nginx-limit
logpath  = /var/log/nginx/error.log
maxretry = 5
findtime = 60
bantime  = 3600
EOF
        echo -e "${GREEN}✅ Jail ditambahkan${NC}"
    fi

    echo ""
    echo -e "${CYAN}[4/4] Restart & aktifkan Fail2Ban...${NC}"
    systemctl restart fail2ban > /dev/null 2>&1
    systemctl enable fail2ban > /dev/null 2>&1

    echo ""
    echo -e "${GREEN}======================================${NC}"
    echo -e "   ${GREEN}✅ SHIELD DDOS TERPASANG!${NC}"
    echo -e "${GREEN}======================================${NC}"
    echo ""
    echo -e "📋 Konfigurasi:"
    echo -e "   • Max Retry : 5 kali"
    echo -e "   • Find Time : 60 detik"
    echo -e "   • Ban Time  : 3600 detik (1 jam)"
    echo ""
    echo -e "📊 Status Fail2Ban:"
    systemctl is-active fail2ban
    echo ""
    echo -e "📊 Status Jail:"
    fail2ban-client status nginx-limit 2>/dev/null || echo "Jail belum aktif, tunggu sebentar."
    echo ""
}

do_uninstall() {
    echo ""
    echo -e "${CYAN}[1/3] Menghapus filter nginx-limit...${NC}"
    rm -f /etc/fail2ban/filter.d/nginx-limit.conf
    echo -e "${GREEN}✅ Filter dihapus${NC}"

    echo ""
    echo -e "${CYAN}[2/3] Menghapus jail nginx-limit...${NC}"
    sed -i '/\[nginx-limit\]/,/^$/d' /etc/fail2ban/jail.local 2>/dev/null
    echo -e "${GREEN}✅ Jail dihapus${NC}"

    echo ""
    echo -e "${CYAN}[3/3] Restart Fail2Ban...${NC}"
    systemctl restart fail2ban > /dev/null 2>&1
    echo -e "${GREEN}✅ Fail2Ban di-restart${NC}"

    echo ""
    echo -e "${GREEN}======================================${NC}"
    echo -e "   ${GREEN}✅ SHIELD DDOS DILEPAS!${NC}"
    echo -e "${GREEN}======================================${NC}"
    echo ""
    echo -e "📊 Status Fail2Ban:"
    fail2ban-client status 2>/dev/null
    echo ""
}

do_status() {
    echo ""
    echo -e "${CYAN}======================================${NC}"
    echo -e "   ${CYAN}📊 STATUS SHIELD DDOS${NC}"
    echo -e "${CYAN}======================================${NC}"
    echo ""
    echo -e "⚙️  Service Fail2Ban : $(systemctl is-active fail2ban 2>/dev/null)"
    echo ""
    echo -e "📋 Status Umum:"
    fail2ban-client status 2>/dev/null
    echo ""
    echo -e "🔒 Jail nginx-limit:"
    fail2ban-client status nginx-limit 2>/dev/null || echo "Jail nginx-limit tidak aktif."
    echo ""
    echo -e "🚫 20 Ban Terakhir:"
    grep 'Ban ' /var/log/fail2ban.log 2>/dev/null | tail -20 || echo "(tidak ada log ban)"
    echo ""
}
