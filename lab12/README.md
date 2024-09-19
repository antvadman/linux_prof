# Lab 12 SELinux

Задачи:
1. Запустить nginx на нестандартном порту 3-мя разными способами.  
2. Обеспечить работоспособность приложения при включенном selinux.  

## 1. 
Убеждаемся, что nginx работает на 80 порту:  
```
[root@localhost ant]# ss -tulpn | grep nginx
tcp   LISTEN 0      511           0.0.0.0:80         0.0.0.0:*    users:(("nginx",pid=25278,fd=6),("nginx",pid=25277,fd=6),("nginx",pid=25275,fd=6),("nginx",pid=25274,fd=6),("nginx",pid=25271,fd=6))
tcp   LISTEN 0      511              [::]:80            [::]:*    users:(("nginx",pid=25278,fd=7),("nginx",pid=25277,fd=7),("nginx",pid=25275,fd=7),("nginx",pid=25274,fd=7),("nginx",pid=25271,fd=7))
```
и что включен selinux:  
```
[root@localhost ant]# sestatus
SELinux status:                 enabled
SELinuxfs mount:                /sys/fs/selinux
SELinux root directory:         /etc/selinux
Loaded policy name:             targeted
Current mode:                   enforcing
Mode from config file:          enforcing
Policy MLS status:              enabled
Policy deny_unknown status:     allowed
Memory protection checking:     actual (secure)
Max kernel policy version:      33
```
Меняем порт в конфиге nginx и перезапускаем службу. Получаем ошибку.  
```
> /var/log/audit/audit.log 
systemctl restart nginx.service 
Job for nginx.service failed because the control process exited with error code.
See "systemctl status nginx.service" and "journalctl -xe" for details.
```
Скармливаем лог анализатору  
```
[root@localhost ant]# sealert -a /var/log/audit/audit.log 
100% done
found 1 alerts in /var/log/audit/audit.log
```
И разрешаем nginx работать на 99 порту:  
```
semanage port -a -t http_port_t -p tcp 99
```
Перезапускаем службу и проверяем порт nginx  
```
systemctl restart nginx.service

ss -tulpn | grep nginx
tcp   LISTEN 0      511           0.0.0.0:99         0.0.0.0:*    users:(("nginx",pid=39863,fd=6),("nginx",pid=39862,fd=6),("nginx",pid=39861,fd=6),("nginx",pid=39860,fd=6),("nginx",pid=39859,fd=6))
```
Удаляем разрешающее правило и обновляем лог:  
```
semanage port -d -t http_port_t -p tcp 99
> /var/log/audit/audit.log 
```
Также перезапускаем nginx и скармливаем ему лог:  
```
systemctl restart nginx.service 
Job for nginx.service failed because the control process exited with error code.
See "systemctl status nginx.service" and "journalctl -xe" for details.
[root@localhost ant]# sealert -a /var/log/audit/audit.log 
```
На основании лога создаем политику и применяем ее:  
```
ausearch -c 'nginx' --raw | audit2allow -M my-nginx
semodule -i my-nginx.pp
```
Проверяем результат: 
```
systemctl restart nginx.service
ss -tulpn | grep nginx
tcp   LISTEN 0      511           0.0.0.0:99         0.0.0.0:*    users:(("nginx",pid=39863,fd=6),("nginx",pid=39862,fd=6),("nginx",pid=39861,fd=6),("nginx",pid=39860,fd=6),("nginx",pid=39859,fd=6))
```
В последнем способе нужно было использовать setsebool. Везде в документации натыкался на параметр named_tcp_bind_http_port, но у меня не заработало. В итоге выкрутился так:  
```
semanage permissive -a httpd_t
```

## 2. 
Чтобы определить имя службы, смотрим, какой процесс слушает 53 порт:  
```
ss -tulpn | grep 53
udp    UNCONN     0      0      192.168.50.10:53                    *:*                   users:(("named",pid=5439,fd=512))

[root@ns01 vagrant]# ps afxZ | grep named
unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 25837 pts/0 S+   0:00                          \_ grep --color=auto named
system_u:system_r:named_t:s0     5439 ?        Ssl    0:00 /usr/sbin/named -u named -c /etc/named.conf
```
Смотрим, какую запись нам отдает DNS сервер:  
```
[root@client vagrant]# dig www.ddns.lab
; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.16 <<>> www.ddns.lab
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 44245
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;www.ddns.lab.			IN	A
```
Для зоны www.ddns.lab DNS сервер не отдает адрес.  
Пытаемся добавить А запись через nsupdate:  
```
[root@client vagrant]# nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
> SERVFAIL
```
Ошибка.  
Устанавливаем в SELinux разрешение для службы named (контекст безопасности мы берем из вывода процесса с ключем Z):    
```
semanage permissive -a named_t
```
Пытаемся повторно добавить запись:  
```
[root@client vagrant]# nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
> ^C[root@client vagrant]# 
```
Запись добавлена без ошибок.  
Теперь посмотрим, что вернет DNS:  
```
[root@client vagrant]# dig www.ddns.lab
; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.16 <<>> www.ddns.lab
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 62973
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 2

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;www.ddns.lab.			IN	A

;; ANSWER SECTION:
www.ddns.lab.		60	IN	A	192.168.50.15
```
Как мы видим, DNS вернул ту запись, которую мы добавили.  




