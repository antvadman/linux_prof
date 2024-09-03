## Lab 8 Systemd
1. Написать service, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова (файл лога и ключевое слово должны задаваться в /etc/default).  
2. Установить spawn-fcgi и создать unit-файл (spawn-fcgi.sevice) с помощью переделки init-скрипта (https://gist.github.com/cea2k/1318020).  
3. Доработать unit-файл Nginx (nginx.service) для запуска нескольких инстансов сервера с разными конфигурационными файлами одновременно.  

## 1
Создаем файл с переменными для запуска сервиса:  
```
> /etc/default/watch_vars
WORD="alarm"
LOG=/var/log/watchlog.log
```
Далее пишем скрипт, который выводит количество встречающихся подстрок alarm и пишет это количество в лог-файл, добавляя при этом слово alarm(те каждый раз при подсчете кол-во подстрок увеличивается на 1):  
```
nano /opt/watchlog.sh
#!/bin/bash
source /etc/default/watch_vars
if [ $(grep -c $WORD $LOG) -gt 0 ]
then
echo "We met word alarm " $(grep -c $WORD $LOG) "times"
else
exit 0
fi
```
Теперь создаем юнит для службы:  
```
nano /etc/systemd/system/watchlog.service
[Unit]
Description=test service
[Service]
Type=oneshot
EnvironmentFile=/etc/default/watch_vars
ExecStart=/opt/watchlog.sh $WORD $LOG
```
И юнит таймера, который будет запускать скрипт:  
```
nano /etc/systemd/system/watchlog.timer                                           
[Unit]
Description=test timer
[Timer]
OnUnitActiveSec=30
Unit=/etc/systemd/system/watchlog.service
[Install]
WantedBy=multi-user.target
```
Запускаем службу и смотрим статус:  
```
root@debian:/home/vad# systemctl status watchlog.timer
● watchlog.timer - test timer
     Loaded: loaded (/etc/systemd/system/watchlog.timer; disabled; preset: enabled)
     Active: active (elapsed) since Sat 2024-08-31 11:38:45 MSK; 43s ago
    Trigger: n/a
   Triggers: ● watchlog.service
```
Проверяем результат работы:  
```
root@debian:/home/vad# cat /var/log/watchlog.log
alarm
alarm
We met word alarm  2 times
root@debian:/home/vad# cat /var/log/watchlog.log
alarm
alarm
We met word alarm  2 times
We met word alarm  3 times
```
Последняя строка в выводе показывает количество подстрок alarm в файле /var/log/watchlog.log.  
## 2
Узнаем текущий runlevel:  
```
who -r
run-level 5  86383574-11-11 22:15
```
Копируем содержимое скрипта инициализации с гита в /etc/init.d/spawn-fcgi  
Создаем мягкую ссылку на скрипт инициализации в директории /etc/rc5.d (5 - runlevel, который мы узнали выше)  
```
root@debian:/home/vad# cd /etc/rc5.d
root@debian:/etc/rc5.d# ln -s /etc/init.d/spawn-fcgi S01spawn-fcgi
```
Создаем файл с переменными командной строки:  
```
nano /etc/spawn-fcgi/fcgi.conf
SOCKET=/run/php-fcgi.sock
OPTIONS="-u www-data -g www-data -s $SOCKET -S -M 0600 -C 32 -F 1 /usr/bin/php-cgi"
```
И файл юнита:  
```
nano /etc/systemd/system/spawn-fcgi.service
[Unit]
After=network.target
[Service]
Type=simple
PIDFile=/run/spawn-fcgi.pid
EnvironmentFile=/etc/spawn-fcgi/fcgi.conf
ExecStart=/usr/bin/spawn-fcgi -n $OPTIONS
KillMode=process
[Install]
WantedBy=multi-user.target
```
Перезапускаем конфигурацию systemd, запускаем службу и смотрим статус службы:  
```
systemctl daemon-reload
root@debian:/etc/rc5.d# systemctl start spawn-fcgi
root@debian:/etc/rc5.d# systemctl status spawn-fcgi
● spawn-fcgi.service
     Loaded: loaded (/etc/systemd/system/spawn-fcgi.service; disabled; preset: enabled)
     Active: active (running) since Mon 2024-09-02 21:19:46 MSK; 6s ago
   Main PID: 18461 (php-cgi)
      Tasks: 33 (limit: 4915)
     Memory: 12.6M
        CPU: 86ms
     CGroup: /system.slice/spawn-fcgi.service
             ├─18461 /usr/bin/php-cgi
             ├─18463 /usr/bin/php-cgi
             ├─18464 /usr/bin/php-cgi
             ├─18465 /usr/bin/php-cgi
             ├─18466 /usr/bin/php-cgi
             ├─18467 /usr/bin/php-cgi
             ├─18468 /usr/bin/php-cgi
             ├─18469 /usr/bin/php-cgi
             ├─18470 /usr/bin/php-cgi
             ├─18471 /usr/bin/php-cgi
             ├─18472 /usr/bin/php-cgi
             ├─18473 /usr/bin/php-cgi
             ├─18474 /usr/bin/php-cgi
             ├─18475 /usr/bin/php-cgi
             ├─18476 /usr/bin/php-cgi
             ├─18477 /usr/bin/php-cgi
             ├─18478 /usr/bin/php-cgi
             ├─18479 /usr/bin/php-cgi
             ├─18480 /usr/bin/php-cgi
             ├─18481 /usr/bin/php-cgi
             ├─18482 /usr/bin/php-cgi
```
## 3
Устанавливаем nginx:  
```
apt install nginx -y
```
Правим конфиги для каждого инстанса:  
```
nano /etc/nginx/nginx-1.conf                                                
user www-data;
worker_processes auto;
pid /run/nginx-1.pid;
error_log /var/log/nginx/error.log;
include /etc/nginx/modules-enabled/*.conf;
events {
        worker_connections 768;
        # multi_accept on;
}
http {

        ##
        # Basic Settings
        ##

        sendfile on;
        tcp_nopush on;
        types_hash_max_size 2048;
        # server_tokens off;
        server {
                listen 9001;
        }
}

nano /etc/nginx/nginx-2.conf                                                
user www-data;
worker_processes auto;
pid /run/nginx-2.pid;
error_log /var/log/nginx/error.log;
include /etc/nginx/modules-enabled/*.conf;
events {
        worker_connections 768;
        # multi_accept on;
}
http {

        ##
        # Basic Settings
        ##

        sendfile on;
        tcp_nopush on;
        types_hash_max_size 2048;
        # server_tokens off;
        server {
                listen 9002;
        }
}
```
Проверяем работу nginx по открытым портам:
```
root@debian:/home/vad# ss -tulp |grep 900
tcp   LISTEN 0      511          0.0.0.0:9002       0.0.0.0:*    users:(("nginx",pid=19891,fd=5),("nginx",pid=19890,fd=5),("nginx",pid=19889,fd=5),("nginx",pid=19888,fd=5),("nginx",pid=19887,fd=5))                                                                
tcp   LISTEN 0      511          0.0.0.0:9001       0.0.0.0:*    users:(("nginx",pid=19751,fd=5),("nginx",pid=19750,fd=5),("nginx",pid=19749,fd=5),("nginx",pid=19748,fd=5),("nginx",pid=19747,fd=5))
```
Как мы видим, кждый инстанс nginx слушает запросы на своем порту.


