#!/bin/bash

set -e

echo "Stopping services..."
systemctl stop wings 2>/dev/null || true
systemctl stop nginx 2>/dev/null || true
systemctl stop mysql 2>/dev/null || true
systemctl stop redis-server 2>/dev/null || true
systemctl disable wings 2>/dev/null || true

echo "Removing Wings..."
rm -rf /etc/pterodactyl
rm -rf /var/lib/pterodactyl
rm -f /usr/local/bin/wings
rm -f /etc/systemd/system/wings.service
systemctl daemon-reload

echo "Removing Panel..."
rm -rf /var/www/pterodactyl

echo "Removing database..."
mysql -u root -e "DROP DATABASE IF EXISTS panel; DROP USER IF EXISTS 'pterodactyl'@'127.0.0.1';" 2>/dev/null || true

echo "Removing Nginx config..."
rm -f /etc/nginx/sites-enabled/pterodactyl.conf
rm -f /etc/nginx/sites-available/pterodactyl.conf
systemctl restart nginx 2>/dev/null || true

echo "Removing SSL certificates..."
for cert in $(certbot certificates 2>/dev/null | grep "Certificate Name" | awk '{print $3}'); do
    certbot delete --cert-name "$cert" --non-interactive 2>/dev/null || true
done
rm -rf /etc/letsencrypt

echo "Cleaning Docker..."
docker stop $(docker ps -aq) 2>/dev/null || true
docker rm $(docker ps -aq) 2>/dev/null || true
docker rmi $(docker images -q) 2>/dev/null || true
docker network prune -f 2>/dev/null || true

echo "Removing Supervisor config..."
rm -f /etc/supervisor/conf.d/pterodactyl.conf
supervisorctl reread 2>/dev/null || true
supervisorctl update 2>/dev/null || true

echo "Removing Certbot & PHP & Redis..."
apt remove --purge certbot python3-certbot-nginx python3-certbot-dns-cloudflare -y 2>/dev/null || true
apt remove --purge php* -y 2>/dev/null || true
apt remove --purge redis-server -y 2>/dev/null || true
rm -f /usr/local/bin/composer

echo "Cleanup..."
apt autoremove -y 2>/dev/null || true
apt autoclean -y 2>/dev/null || true

echo "Done. VPS clean."
