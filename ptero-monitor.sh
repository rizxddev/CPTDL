#!/bin/bash
# ============================================================
# Pterodactyl Monitor - Neofetch Style + Telegram Bot
# Install : cp ptero-monitor.sh /usr/local/bin/ptero-monitor
#           chmod +x /usr/local/bin/ptero-monitor
# First   : ptero-monitor         (akan minta token & chat_id)
# Cron    : */5 * * * * /usr/local/bin/ptero-monitor
# ============================================================

# ── WARNA ───────────────────────────────────────────────────
RESET='\033[0m'; BOLD='\033[1m'; DIM='\033[2m'
BRED='\033[1;31m'; BGREEN='\033[1;32m'; BYELLOW='\033[1;33m'
BMAGENTA='\033[1;35m'; BCYAN='\033[1;36m'; BWHITE='\033[1;37m'
WHITE='\033[0;37m'

# ── CONFIG FILE ─────────────────────────────────────────────
CONFIG_DIR="/etc/ptero-monitor"
CONFIG_FILE="$CONFIG_DIR/config.conf"
LOG_FILE="/var/log/ptero-monitor.log"
AUTOFIX_FLAG="$CONFIG_DIR/autofix.flag"
DISK_WARN=80; DISK_CRIT=90
PTERO_DIR="/var/www/pterodactyl"
MAX_LOG_MB=10

mkdir -p "$CONFIG_DIR"

# ── LOAD / SETUP CONFIG ─────────────────────────────────────
setup_config() {
    echo
    echo -e "  ${BMAGENTA}${BOLD}Pterodactyl Monitor - First Setup${RESET}"
    echo -e "  ${DIM}─────────────────────────────────────────${RESET}"
    echo

    read -rp "  Masukkan Telegram Bot Token : " BOT_TOKEN
    echo

    echo -e "  ${DIM}Cara dapat CHAT ID:${RESET}"
    echo -e "  ${DIM}1. Kirim pesan ke bot kamu${RESET}"
    echo -e "  ${DIM}2. Buka: https://api.telegram.org/bot${BOT_TOKEN}/getUpdates${RESET}"
    echo -e "  ${DIM}3. Salin 'id' dari 'chat' object${RESET}"
    echo
    read -rp "  Masukkan Telegram Chat ID Owner : " CHAT_ID
    echo

    # Test kirim pesan
    echo -e "  ${BYELLOW}Mengirim pesan test...${RESET}"
    local res
    res=$(curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d "chat_id=${CHAT_ID}" \
        -d "text=✅ Pterodactyl Monitor berhasil terhubung ke bot!" \
        -d "parse_mode=HTML" 2>/dev/null)

    if echo "$res" | grep -q '"ok":true'; then
        echo -e "  ${BGREEN}✓ Bot berhasil terhubung!${RESET}"
    else
        echo -e "  ${BRED}✗ Gagal terhubung. Cek token & chat_id.${RESET}"
        echo -e "  ${DIM}Response: $res${RESET}"
        echo
        read -rp "  Tetap simpan dan lanjut? (y/n): " yn
        [[ "$yn" != "y" ]] && exit 1
    fi

    # Simpan config
    cat > "$CONFIG_FILE" << EOF
BOT_TOKEN=${BOT_TOKEN}
CHAT_ID=${CHAT_ID}
EOF
    echo "on" > "$AUTOFIX_FLAG"
    echo
    echo -e "  ${BGREEN}Config disimpan di ${CONFIG_FILE}${RESET}"
    echo
}

load_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        setup_config
    fi
    source "$CONFIG_FILE"
    AUTOFIX=$(cat "$AUTOFIX_FLAG" 2>/dev/null || echo "on")
}

# ── LOGGING ─────────────────────────────────────────────────
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"; }

rotate_log() {
    [ -f "$LOG_FILE" ] && [ "$(du -m "$LOG_FILE" | cut -f1)" -gt "$MAX_LOG_MB" ] && \
        mv "$LOG_FILE" "${LOG_FILE}.old"
}

# ── TELEGRAM ─────────────────────────────────────────────────
tg_send() {
    # $1 = text, $2 = inline keyboard json (optional)
    local text="$1"
    local keyboard="$2"
    local data="chat_id=${CHAT_ID}&text=${text}&parse_mode=HTML"
    [ -n "$keyboard" ] && data+="&reply_markup=${keyboard}"
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        --data-urlencode "chat_id=${CHAT_ID}" \
        --data-urlencode "text=${text}" \
        -d "parse_mode=HTML" \
        ${keyboard:+-d "reply_markup=${keyboard}"} &>/dev/null &
}

tg_alert() {
    # $1 = judul masalah, $2 = detail, $3 = service (untuk callback)
    local title="$1" detail="$2" service="$3"
    local autofix_label
    [ "$AUTOFIX" = "on" ] && autofix_label="🟢 Auto Fix: ON" || autofix_label="🔴 Auto Fix: OFF"

    local text="🚨 <b>ALERT - Pterodactyl Monitor</b>
━━━━━━━━━━━━━━━━━━━━
⚠️ <b>${title}</b>
${detail}
━━━━━━━━━━━━━━━━━━━━
🖥️ Host : <code>$(hostname)</code>
🕐 Time : $(date '+%d/%m/%Y %H:%M:%S')
${autofix_label}"

    local keyboard
    if [ "$AUTOFIX" = "off" ]; then
        keyboard="{\"inline_keyboard\":[[{\"text\":\"🔧 Fix Sekarang\",\"callback_data\":\"fix_${service}\"},{\"text\":\"❌ Ignore\",\"callback_data\":\"ignore_${service}\"}],[{\"text\":\"🟢 Aktifkan Auto Fix\",\"callback_data\":\"autofix_on\"}]]}"
    else
        keyboard="{\"inline_keyboard\":[[{\"text\":\"✅ Auto Fix Aktif\",\"callback_data\":\"info\"},{\"text\":\"🔴 Matikan Auto Fix\",\"callback_data\":\"autofix_off\"}]]}"
    fi

    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d "chat_id=${CHAT_ID}" \
        --data-urlencode "text=${text}" \
        -d "parse_mode=HTML" \
        -d "reply_markup=${keyboard}" &>/dev/null &
}

tg_ok() {
    # $1 = pesan resolved
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d "chat_id=${CHAT_ID}" \
        --data-urlencode "text=✅ <b>RESOLVED</b>
$1
🕐 $(date '+%d/%m/%Y %H:%M:%S')" \
        -d "parse_mode=HTML" &>/dev/null &
}

# ── HANDLE CALLBACK (baca tombol yang ditekan) ───────────────
handle_callbacks() {
    local updates offset
    # Ambil update terbaru
    updates=$(curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getUpdates?timeout=1&limit=10" 2>/dev/null)
    
    # Proses setiap callback
    echo "$updates" | grep -o '"callback_query":{[^}]*}' | while read -r cb; do
        local cb_id data update_id
        cb_id=$(echo "$cb" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
        data=$(echo "$updates" | grep -o '"data":"[^"]*"' | head -1 | cut -d'"' -f4)
        update_id=$(echo "$updates" | grep -o '"update_id":[0-9]*' | head -1 | grep -o '[0-9]*')

        case "$data" in
            autofix_on)
                echo "on" > "$AUTOFIX_FLAG"
                curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/answerCallbackQuery" \
                    -d "callback_query_id=${cb_id}" \
                    -d "text=✅ Auto Fix diaktifkan!" &>/dev/null
                tg_send "✅ <b>Auto Fix diaktifkan!</b>
Monitor akan otomatis memperbaiki masalah." ;;
            autofix_off)
                echo "off" > "$AUTOFIX_FLAG"
                curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/answerCallbackQuery" \
                    -d "callback_query_id=${cb_id}" \
                    -d "text=🔴 Auto Fix dimatikan!" &>/dev/null
                tg_send "🔴 <b>Auto Fix dimatikan!</b>
Monitor akan mengirim alert tapi tidak auto fix." ;;
            menu_autofix)
                local status_label
                [ "$AUTOFIX" = "on" ] && status_label="🟢 ON" || status_label="🔴 OFF"
                curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/answerCallbackQuery" \
                    -d "callback_query_id=${cb_id}" &>/dev/null
                local kb="{\"inline_keyboard\":[[{\"text\":\"🟢 ON\",\"callback_data\":\"set_autofix_on\"},{\"text\":\"🔴 OFF\",\"callback_data\":\"set_autofix_off\"}]]}"
                tg_send "⚙️ <b>Status Auto Fix saat ini:</b> ${status_label}

Pilih mode di bawah ini:" "$kb" ;;
            set_autofix_on)
                echo "on" > "$AUTOFIX_FLAG"
                curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/answerCallbackQuery" \
                    -d "callback_query_id=${cb_id}" \
                    -d "text=✅ Auto Fix: ON" &>/dev/null
                tg_send "🟢 <b>Auto Fix sekarang: ON</b>
Monitor akan otomatis memperbaiki masalah yang terdeteksi." ;;
            set_autofix_off)
                echo "off" > "$AUTOFIX_FLAG"
                curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/answerCallbackQuery" \
                    -d "callback_query_id=${cb_id}" \
                    -d "text=🔴 Auto Fix: OFF" &>/dev/null
                tg_send "🔴 <b>Auto Fix sekarang: OFF</b>
Monitor hanya akan mengirim alert tanpa auto fix." ;;
            menu_speedtest)
                curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/answerCallbackQuery" \
                    -d "callback_query_id=${cb_id}" \
                    -d "text=⚡ Menjalankan speed test, tunggu sebentar..." &>/dev/null
                run_speedtest ;;
            fix_redis)
                systemctl restart redis &>/dev/null
                redis-cli config set stop-writes-on-bgsave-error no &>/dev/null
                curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/answerCallbackQuery" \
                    -d "callback_query_id=${cb_id}" \
                    -d "text=🔧 Redis sedang di-fix..." &>/dev/null
                tg_ok "Redis berhasil di-restart secara manual." ;;
            fix_nginx)
                systemctl restart nginx &>/dev/null
                curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/answerCallbackQuery" \
                    -d "callback_query_id=${cb_id}" \
                    -d "text=🔧 Nginx sedang di-fix..." &>/dev/null
                tg_ok "Nginx berhasil di-restart secara manual." ;;
            fix_phpfpm)
                systemctl restart php8.3-fpm &>/dev/null
                curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/answerCallbackQuery" \
                    -d "callback_query_id=${cb_id}" \
                    -d "text=🔧 PHP-FPM sedang di-fix..." &>/dev/null
                tg_ok "PHP-FPM berhasil di-restart secara manual." ;;
            fix_wings)
                systemctl restart wings &>/dev/null
                curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/answerCallbackQuery" \
                    -d "callback_query_id=${cb_id}" \
                    -d "text=🔧 Wings sedang di-fix..." &>/dev/null
                tg_ok "Wings berhasil di-restart secara manual." ;;
            fix_disk)
                find "$PTERO_DIR/storage/logs" -name "*.log" -mtime +1 -delete &>/dev/null
                docker system prune -f --volumes &>/dev/null
                journalctl --vacuum-size=50M &>/dev/null
                apt clean -y &>/dev/null
                curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/answerCallbackQuery" \
                    -d "callback_query_id=${cb_id}" \
                    -d "text=🔧 Disk sedang dibersihkan..." &>/dev/null
                local new_avail; new_avail=$(df -h / | awk 'NR==2 {print $4}')
                tg_ok "Disk berhasil dibersihkan. Sisa: <b>${new_avail}</b>" ;;
            ignore_*)
                curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/answerCallbackQuery" \
                    -d "callback_query_id=${cb_id}" \
                    -d "text=❌ Alert diabaikan." &>/dev/null ;;
        esac

        # Update offset supaya tidak baca ulang
        [ -n "$update_id" ] && \
            curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getUpdates?offset=$(( update_id + 1 ))" &>/dev/null
    done

    # ── HANDLE COMMAND /start (buka menu utama) ──────────────
    if echo "$updates" | grep -q '"text":"/start"'; then
        local msg_chat_id msg_update_id
        msg_chat_id=$(echo "$updates" | grep -oE '"chat":\{"id":[0-9]+' | head -1 | grep -oE '[0-9]+$')
        if [ "$msg_chat_id" = "$CHAT_ID" ]; then
            send_main_menu
        fi
        msg_update_id=$(echo "$updates" | grep -o '"update_id":[0-9]*' | tail -1 | grep -o '[0-9]*')
        [ -n "$msg_update_id" ] && \
            curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getUpdates?offset=$(( msg_update_id + 1 ))" &>/dev/null
    fi
}

# ── MENU UTAMA (/start) ──────────────────────────────────────
send_main_menu() {
    local os kernel arch cpu_model cpu_cores cpu_cache aesni vmx \
          ram_used ram_total swap_used swap_total disk_used disk_total \
          uptime_h load_avg ipv4_status virt

    os=$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
    kernel=$(uname -r)
    arch=$(uname -m)
    cpu_model=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs)
    cpu_cores=$(nproc)
    cpu_cache=$(grep -m1 'cache size' /proc/cpuinfo | cut -d: -f2 | xargs)
    grep -q ' aes ' /proc/cpuinfo && aesni="✓ Enabled" || aesni="✗ Disabled"
    grep -Eq ' (vmx|svm) ' /proc/cpuinfo && vmx="✓ Enabled" || vmx="✗ Disabled"

    ram_total=$(free -h | awk '/Mem/ {print $2}')
    ram_used=$(free -h  | awk '/Mem/ {print $3}')
    swap_total=$(free -h | awk '/Swap/ {print $2}')
    swap_used=$(free -h  | awk '/Swap/ {print $3}')
    disk_total=$(df -h / | awk 'NR==2 {print $2}')
    disk_used=$(df -h / | awk 'NR==2 {print $3}')
    uptime_h=$(uptime -p | sed 's/up //')
    load_avg=$(cut -d' ' -f1-3 /proc/loadavg)

    curl -s -4 --max-time 2 ifconfig.me &>/dev/null \
        && ipv4_status="✓ Online" || ipv4_status="✗ Offline"

    virt=$(systemd-detect-virt 2>/dev/null)
    [ -z "$virt" ] && virt="none"

    # escape karakter HTML biar gak merusak parse_mode Telegram
    local esc='s/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'
    os=$(sed "$esc" <<< "$os")
    cpu_model=$(sed "$esc" <<< "$cpu_model")

    local sep="--------------------------------------------------------------"

    local info
    info=$(cat << INFO_EOF
${sep}
 Host           : $(hostname)
 OS             : ${os}
 Kernel         : ${kernel}
 Arch           : ${arch}
${sep}
 CPU Model      : ${cpu_model}
 CPU Cores      : ${cpu_cores}
 CPU Cache      : ${cpu_cache}
 AES-NI         : ${aesni}
 VM-x/AMD-V     : ${vmx}
${sep}
 Total RAM      : ${ram_total} (${ram_used} Used)
 Total Swap     : ${swap_total} (${swap_used} Used)
 Total Disk     : ${disk_total} (${disk_used} Used)
${sep}
 System Uptime  : ${uptime_h}
 Load Average   : ${load_avg}
 Virtualization : ${virt}
 IPv4           : ${ipv4_status}
${sep}
INFO_EOF
)

    local text="👋 <b>Pterodactyl Monitor</b>

<blockquote><pre>${info}</pre></blockquote>

Pilih menu di bawah:"

    local kb="{\"inline_keyboard\":[[{\"text\":\"⚙️ AUTO FIX\",\"callback_data\":\"menu_autofix\"},{\"text\":\"⚡ SPEED TEST\",\"callback_data\":\"menu_speedtest\"}]]}"
    tg_send "$text" "$kb"
}

# ── SPEED TEST ────────────────────────────────────────────────
run_speedtest() {
    command -v speedtest-cli &>/dev/null || \
        pip3 install --quiet --break-system-packages speedtest-cli &>/dev/null

    local raw ping_res dl_res ul_res
    raw=$(speedtest-cli --simple 2>/dev/null)

    if [ -z "$raw" ]; then
        tg_send "❌ <b>Speed test gagal dijalankan.</b>
Pastikan <code>speedtest-cli</code> bisa terinstall di server ini."
        return
    fi

    ping_res=$(echo "$raw" | awk -F': ' '/Ping/ {print $2}')
    dl_res=$(echo "$raw"   | awk -F': ' '/Download/ {print $2}')
    ul_res=$(echo "$raw"   | awk -F': ' '/Upload/ {print $2}')

    local info
    info=$(cat << INFO_EOF
Host     : $(hostname)
Ping     : ${ping_res}
Download : ${dl_res}
Upload   : ${ul_res}
Waktu    : $(date '+%d/%m/%Y %H:%M:%S')
INFO_EOF
)

    local text="⚡ <b>SPEED TEST RESULT</b>

<blockquote><pre>${info}</pre></blockquote>"

    tg_send "$text"
    log "SPEEDTEST: ping=${ping_res} dl=${dl_res} ul=${ul_res}"
}

# ── AUTO FIX ────────────────────────────────────────────────
fix_redis()  {
    redis-cli config set stop-writes-on-bgsave-error no &>/dev/null
    systemctl restart redis &>/dev/null
    log "AUTO FIX: Redis restart"
}
fix_nginx()  { systemctl restart nginx &>/dev/null;       log "AUTO FIX: Nginx restart"; }
fix_phpfpm() { systemctl restart php8.3-fpm &>/dev/null;  log "AUTO FIX: PHP-FPM restart"; }
fix_wings()  { systemctl restart wings &>/dev/null;       log "AUTO FIX: Wings restart"; }
fix_swap()   { swapoff -a && swapon -a &>/dev/null;       log "AUTO FIX: Swap refresh"; }
fix_disk()   {
    find "$PTERO_DIR/storage/logs" -name "*.log" -mtime +1 -delete &>/dev/null
    docker system prune -f --volumes &>/dev/null
    journalctl --vacuum-size=50M &>/dev/null
    apt clean -y &>/dev/null
    find /var/lib/docker/containers -name "*-json.log" -exec truncate -s 0 {} \; &>/dev/null
    log "AUTO FIX: Disk clean"
}

# ── STATUS HELPERS ───────────────────────────────────────────
status_icon() {
    systemctl is-active --quiet "$1" \
        && echo -e "${BGREEN}● running${RESET}" \
        || echo -e "${BRED}● dead${RESET}"
}

bar() {
    local pct=$1 width=${2:-20} filled empty color
    filled=$(( pct * width / 100 ))
    empty=$(( width - filled ))
    if   [ "$pct" -ge 90 ]; then color=$BRED
    elif [ "$pct" -ge 75 ]; then color=$BYELLOW
    else color=$BGREEN; fi
    local s="${color}"
    for ((i=0;i<filled;i++)); do s+="█"; done
    s+="${DIM}"
    for ((i=0;i<empty;i++));  do s+="░"; done
    s+="${RESET}"
    echo -ne "$s"
}

pct_color() {
    local p=$1
    if   [ "$p" -ge 90 ]; then echo -ne "${BRED}${p}%${RESET}"
    elif [ "$p" -ge 75 ]; then echo -ne "${BYELLOW}${p}%${RESET}"
    else echo -ne "${BGREEN}${p}%${RESET}"; fi
}

# ── COLLECT & CHECK ──────────────────────────────────────────
collect() {
    HOSTNAME=$(hostname)
    OS=$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
    KERNEL=$(uname -r)
    UPTIME=$(uptime -p | sed 's/up //')
    CPU_MODEL=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs)
    CPU_CORES=$(nproc)
    LOAD=$(cut -d' ' -f1-3 /proc/loadavg)

    RAM_TOTAL=$(free -m | awk '/Mem/ {print $2}')
    RAM_USED=$(free -m  | awk '/Mem/ {print $3}')
    RAM_PCT=$(( RAM_USED * 100 / RAM_TOTAL ))
    RAM_TOTAL_H=$(free -h | awk '/Mem/ {print $2}')
    RAM_USED_H=$(free -h  | awk '/Mem/ {print $3}')

    SWAP_TOTAL=$(free -m | awk '/Swap/ {print $2}')
    SWAP_USED=$(free -m  | awk '/Swap/ {print $3}')
    [ "$SWAP_TOTAL" -gt 0 ] && SWAP_PCT=$(( SWAP_USED * 100 / SWAP_TOTAL )) || SWAP_PCT=0
    SWAP_TOTAL_H=$(free -h | awk '/Swap/ {print $2}')
    SWAP_USED_H=$(free -h  | awk '/Swap/ {print $3}')

    DISK_PCT=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
    DISK_USED=$(df -h / | awk 'NR==2 {print $3}')
    DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
    DISK_AVAIL=$(df -h / | awk 'NR==2 {print $4}')

    DOCKER_RUN=$(docker ps -q 2>/dev/null | wc -l)
    DOCKER_ALL=$(docker ps -aq 2>/dev/null | wc -l)

    ALERTS=0

    # ── Redis ──
    local redis_bgsave
    redis_bgsave=$(redis-cli config get stop-writes-on-bgsave-error 2>/dev/null | tail -1)
    if ! systemctl is-active --quiet redis || [ "$redis_bgsave" = "yes" ]; then
        ALERTS=1
        if [ "$AUTOFIX" = "on" ]; then
            fix_redis; sleep 1
            tg_ok "Redis otomatis di-fix (restart + bgsave error dinonaktifkan)"
        else
            tg_alert "Redis Bermasalah" "• Service: $(systemctl is-active redis)\n• bgsave error: ${redis_bgsave}" "redis"
        fi
    fi
    REDIS_STATUS=$(status_icon redis)
    REDIS_PING=$(redis-cli ping 2>/dev/null)
    [ "$REDIS_PING" = "PONG" ] && REDIS_EXTRA="${DIM}pong${RESET}" || REDIS_EXTRA="${BRED}no pong${RESET}"

    # ── Nginx ──
    if ! systemctl is-active --quiet nginx; then
        ALERTS=1
        if [ "$AUTOFIX" = "on" ]; then fix_nginx; sleep 1
            tg_ok "Nginx otomatis di-restart"
        else tg_alert "Nginx MATI" "Service nginx tidak berjalan!" "nginx"; fi
    fi
    NGINX_STATUS=$(status_icon nginx)

    # ── PHP-FPM ──
    if ! systemctl is-active --quiet php8.3-fpm; then
        ALERTS=1
        if [ "$AUTOFIX" = "on" ]; then fix_phpfpm; sleep 1
            tg_ok "PHP-FPM otomatis di-restart"
        else tg_alert "PHP-FPM MATI" "Service php8.3-fpm tidak berjalan!" "phpfpm"; fi
    fi
    PHP_STATUS=$(status_icon php8.3-fpm)

    # ── Wings ──
    if ! systemctl is-active --quiet wings; then
        ALERTS=1
        if [ "$AUTOFIX" = "on" ]; then fix_wings; sleep 2
            tg_ok "Wings otomatis di-restart"
        else tg_alert "Wings MATI" "Service wings tidak berjalan!" "wings"; fi
    fi
    WINGS_STATUS=$(status_icon wings)

    # ── Swap ──
    if [ "$SWAP_PCT" -ge 90 ]; then
        ALERTS=1
        if [ "$AUTOFIX" = "on" ]; then fix_swap
            tg_ok "Swap otomatis di-refresh (usage was ${SWAP_PCT}%)"
        else tg_alert "Swap Hampir Penuh" "Swap usage: <b>${SWAP_PCT}%</b>" "swap"; fi
    fi

    # ── Disk ──
    if [ "$DISK_PCT" -ge "$DISK_CRIT" ]; then
        ALERTS=1
        if [ "$AUTOFIX" = "on" ]; then fix_disk; sleep 2
            local new_avail; new_avail=$(df -h / | awk 'NR==2 {print $4}')
            tg_ok "Disk otomatis dibersihkan. Sisa: <b>${new_avail}</b>"
            DISK_PCT=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
            DISK_AVAIL="$new_avail"
        else tg_alert "Disk KRITIS" "Disk usage: <b>${DISK_PCT}%</b>\nSisa: <b>${DISK_AVAIL}</b>" "disk"; fi
    elif [ "$DISK_PCT" -ge "$DISK_WARN" ]; then
        tg_alert "Disk Warning" "Disk usage: <b>${DISK_PCT}%</b>\nSisa: <b>${DISK_AVAIL}</b>" "disk"
    fi
}

# ── DISPLAY ─────────────────────────────────────────────────
display() {
    clear
    local NOW SEP AF_LABEL
    NOW=$(date '+%a, %d %b %Y  %H:%M:%S')
    SEP="${DIM}─────────────────────────────────────────${RESET}"
    [ "$AUTOFIX" = "on" ] \
        && AF_LABEL="${BGREEN}● on${RESET}" \
        || AF_LABEL="${BRED}● off${RESET}"

    echo
    echo -e "  ${BMAGENTA}${BOLD}pterodactyl${RESET}${WHITE}@${RESET}${BCYAN}${BOLD}${HOSTNAME}${RESET}"
    echo -e "  ${DIM}${NOW}${RESET}"
    echo -e "  $SEP"
    echo -e "  ${BWHITE}os        ${RESET}${DIM}·${RESET}  ${OS}"
    echo -e "  ${BWHITE}kernel    ${RESET}${DIM}·${RESET}  ${KERNEL}"
    echo -e "  ${BWHITE}uptime    ${RESET}${DIM}·${RESET}  ${UPTIME}"
    echo -e "  ${BWHITE}cpu       ${RESET}${DIM}·${RESET}  ${CPU_MODEL} ${DIM}(${CPU_CORES} cores)${RESET}"
    echo -e "  ${BWHITE}load      ${RESET}${DIM}·${RESET}  ${LOAD}"
    echo -e "  ${BWHITE}docker    ${RESET}${DIM}·${RESET}  ${BGREEN}${DOCKER_RUN}${RESET} running / ${DOCKER_ALL} total"
    echo -e "  ${BWHITE}auto fix  ${RESET}${DIM}·${RESET}  ${AF_LABEL}"
    echo
    echo -e "  ${BYELLOW}── resources ────────────────────────────${RESET}"
    printf  "  ${BWHITE}ram       ${RESET}${DIM}·${RESET}  "
    bar $RAM_PCT 20; printf "  "; pct_color $RAM_PCT
    echo -e "  ${DIM}${RAM_USED_H} / ${RAM_TOTAL_H}${RESET}"

    printf  "  ${BWHITE}swap      ${RESET}${DIM}·${RESET}  "
    bar $SWAP_PCT 20; printf "  "; pct_color $SWAP_PCT
    echo -e "  ${DIM}${SWAP_USED_H} / ${SWAP_TOTAL_H}${RESET}"

    printf  "  ${BWHITE}disk      ${RESET}${DIM}·${RESET}  "
    bar $DISK_PCT 20; printf "  "; pct_color $DISK_PCT
    echo -e "  ${DIM}${DISK_USED} / ${DISK_TOTAL}  (free ${DISK_AVAIL})${RESET}"

    echo
    echo -e "  ${BYELLOW}── services ─────────────────────────────${RESET}"
    echo -e "  ${BWHITE}nginx     ${RESET}${DIM}·${RESET}  ${NGINX_STATUS}"
    echo -e "  ${BWHITE}php-fpm   ${RESET}${DIM}·${RESET}  ${PHP_STATUS}"
    echo -e "  ${BWHITE}redis     ${RESET}${DIM}·${RESET}  ${REDIS_STATUS}  ${REDIS_EXTRA}"
    echo -e "  ${BWHITE}wings     ${RESET}${DIM}·${RESET}  ${WINGS_STATUS}"
    echo
    echo -e "  $SEP"
    [ "$ALERTS" -eq 0 ] \
        && echo -e "  ${BGREEN}✓  semua sistem normal${RESET}" \
        || echo -e "  ${BYELLOW}⚠  ada masalah terdeteksi - cek Telegram${RESET}"
    echo -e "  ${DIM}log → ${LOG_FILE}${RESET}"
    echo
}

# ── MAIN ─────────────────────────────────────────────────────
rotate_log
load_config
handle_callbacks
log "════ Monitor Run | autofix=${AUTOFIX} ════"
collect
display
log "════ Monitor Done ════"
