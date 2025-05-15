#!/bin/bash

BLOCKED_FILE="/etc/nginx/conf.d/blocked_ips.conf"
TMP_DIR=$(mktemp -d)
TMP_RAW="$TMP_DIR/raw.txt"
TMP_CLEAN="$TMP_DIR/clean.txt"

# Очищаем целевой файл
> "$BLOCKED_FILE"
echo "# Blocked IPs - Auto Generated" >> "$BLOCKED_FILE"

# Регулярное выражение для проверки IP/CIDR
IP_CIDR_REGEX='^([0-9]{1,3}\.){3}[0-9]{1,3}(/\s*[0-9]{1,2})?$'

# Функция проверки формата
is_valid_ip_or_cidr() {
    [[ $1 =~ $IP_CIDR_REGEX ]]
}

echo "[+] Загружаем и обрабатываем списки..."

# === Скачиваем списки и сохраняем во временный файл ===
curl -s https://www.spamhaus.org/drop/drop.txt  | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]+' >> "$TMP_RAW"
curl -s https://cinsscore.com/list/cidr-all.txt  | grep -v '^#' >> "$TMP_RAW"
curl -s https://malc0de.com/bl/blocklists/main_malwaredomains_com.txt  | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]+' >> "$TMP_RAW"
curl -s https://lists.blocklist.de/lists/all.txt  >> "$TMP_RAW"
curl -s https://blocklist.greensnow.co/greensnow.txt  >> "$TMP_RAW"

# === Чистим список: удаляем комментарии, лишние пробелы и проверяем формат ===
grep -v '^#' "$TMP_RAW" | sed 's/[[:space:]]//g' | sort -u > "$TMP_CLEAN"

# === Добавляем только валидные строки в финальный файл ===
while read line; do
    if is_valid_ip_or_cidr "$line"; then
        echo "deny $line;" >> "$BLOCKED_FILE"
    else
        echo "[!] Пропущена некорректная строка: $line"
    fi
done < "$TMP_CLEAN"

# === Завершающий deny all не добавляем, если вы хотите пропускать всё остальное
# echo "deny all;" >> "$BLOCKED_FILE"

# === Проверяем синтаксис и перезапускаем Nginx ===
echo "[+] Перезагрузка Nginx..."
nginx -t && systemctl reload nginx

# === Чистка временных файлов ===
rm -rf "$TMP_DIR"
