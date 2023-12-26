# Организация бэкапов на примере доп хранилища хостера

Допустим у нас имеется доп хранилище которое поддерживает подключение по ssh/sftp на нестандартном порту:

    Сервер: u1111.storagebox.com
    Пользователь: u11111
    Пароль: 111111111111111

---

Первым делом для удобства дальнейшей работы нам необходимо настроить подключение к серверу по ssh без пароля, для чего необходимо зайти на удаленный сторадж через ssh/sftp создать там каталог **.ssh** после чего загрузить в него **authorized_keys** файл содержащий наш публичный ключ.

Так-же создаем в корне 2 каталога **copy** и **backup**    
- в **copy** мы будем хранить полную актуальную версию данных   
- в **backup** мы будем создавать резервные копии соответсвенно   

---

## Используем скрипты 
    Скрипты в примере расположены в /opt/scripts_backup/, а логи работы в /opt/scripts_backup/logs/.

---

### Скрипт который будет поддерживать актуальную копию каталога/каталогов на удаленном сервере (включая лог изменений):
```bash
#!/bin/sh

DATE=$(date +%Y-%m-%d-t-%H-%M-%S)

rsync --progress --delete  -e 'ssh -p 2899' --recursive /mydata/ u11111@u1111.storagebox.com:/home/copy/ > /opt/scripts_backup/logs/sync-actual_$DATE.log

find /opt/scripts_backup/logs/sync-actual_*.log -type f -mtime +3 -exec rm {} \;

```
Остается добавить его в крон с нужным интервалом работы, данный скрипт будет поддживать полную копию заданного каталога или каталогов на удаленном сервере с помощью **rsync**

---

### Скрипт который будет создавать полные копии данных за определенный день (например можно делать недельные полные бэкапы):

```bash
#!/bin/sh

DATE_log=$(date +%Y-%m-%d-t-%H-%M-%S)
DATE_dir=$(date +%Y-%m-%d)

echo "start log" > /opt/scripts_backup/logs/sync_week_$DATE_dir.log

echo "$DATE_log - create dir" >> /opt/scripts_backup/logs/sync_week_$DATE_dir.log

ssh -p2899 u11111@u1111.storagebox.com mkdir backup/$DATE_dir/

sleep 3s

echo "$DATE_log - copy files" >> /opt/scripts_backup/logs/sync_week_$DATE_dir.log

ssh -p2899 u11111@u1111.storagebox.com cp -R copy/* backup/$DATE_dir/

echo "$DATE_log - finish copy" >> /opt/scripts_backup/logs/sync_week_$DATE_dir.log

echo "$DATE_log - delete old logs" >> /opt/scripts_backup/logs/sync_week_$DATE_dir.log

find /opt/scripts_backup/logs/sync_week_*.log -type f -mtime +21 -exec rm {} \; >> /opt/scripts_backup/logs/sync_week_$DATE_dir.log

echo "$DATE_log - finish" >> /opt/scripts_backup/logs/sync_week_$DATE_dir.log

```

Данный скрипт по средствам ssh подключается на уделенное хранилище создает там каталог с датой, после чего копирует все данные из каталога **copy** в каталог **backup/текущая дата**, используя ресурсы самого хранилища.

Лог достаточно примитивный, добавлен как ориентир именно на время выполнения.

Не забываем про добавление задачи в крон.