# В данном репозитории публикую скрипты которыми пользуюсь или разработал

1. [Организация бэкапов на примере доп хранилища хостера, с помощью rsync/ssh](script_backup_rsunc_ssh.md)
2. [update-blocked-ips.sh](update-blocked-ips.sh) - формируем список для блокировки Nginx'ом   
для подключения:
```bash
location / {
    # Включаем пользовательский и автоматически обновляемый список блокировок
    include /etc/nginx/conf.d/blocked_ips.conf;

    # Все, кто не попал под deny — проходят
    allow all;
}
```
или
```bash
server {
    listen 80;
    server_name example.com;

    include /etc/nginx/conf.d/blocked_ips.conf;

    location / {
        allow all;
        proxy_pass http://backend;
    }
}
```
