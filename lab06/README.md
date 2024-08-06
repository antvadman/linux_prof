# Lab 6 Навыки работы с NFS

Задачи:
1. на сервере должна быть настроена директория для отдачи по NFS;
2. на клиенте она должна автоматически монтироваться при старте (fstab или autofs);
3. в сетевой директории должна быть папка upload с правами на запись;
требования для NFS: NFS версии 3.

## 1. Настроим сервер 
Создадим каталоги, которые будем отдавать по NFS и назначим права
```
cd /mnt
mkdir share
mkdir ./share/upload
chmod 755 ./share
chmod 777 ./share/upload
```
Также создадим несколько тестовых файлов
```
echo "ro1 file content" > ./share/ro1
echo "ro2 file content" > ./share/ro2
```
Установим подсистему NFS и загрузим в ядро ее модуль
```
apt install nfs-kernel-server -y
modprobe nfs
```
Откроем на МСЭ порты для работы с NFS
```
ufw allow 2049
ufw allow 111
```
Настроим отдачу каталога в файле /etc/exports и запустим службу NFS
```
echo "/mnt/share *(rw,root_squash,no_subtree_check)" >> /etc/exports
service  nfs-kernel-server start
```
Проверим, что порт 2049 открыт и прослушивается
```
ss -tulpn | grep 2049
tcp    UNCONN     0      0                      *:2049                  *:*     
tcp    UNCONN     0      0                     :::2049                 :::*     
tcp    LISTEN     0      64                     *:2049                  *:*     
tcp    LISTEN     0      64                    :::2049                 :::* 
```
## 2. Настроим клиент
Смонтируем каталог по 3 версии NFS
```
mount -t nfs -o vers=3 192.168.56.11:/mnt/share /mnt
```
и попробуем создать какой-нибудь файл в каталоге share
```
root@clnt:/home/vagrant# > /mnt/111
bash: /mnt/111: Permission denied
```
при этом в каталог upload запись разрешена
```
root@clnt:/home/vagrant# > /mnt/upload/111
```
Для автомвтического монтирования NFS добавим строку в /etc/fstab
```
echo "192.168.56.11:/mnt/share /mnt    nfs    defaults        0 0" >> /etc/fstab
```
Отправим клиета в перезагрузку командой reboot и проверим автоматическое монтирование
```
 ll /mnt
total 20
drwxr-xr-x  3 root root 4096 Aug  5 15:55 ./
drwxr-xr-x 23 root root 4096 Aug  5 17:47 ../
-rw-r--r--  1 root root   17 Aug  5 15:55 ro1
-rw-r--r--  1 root root   17 Aug  5 15:56 ro2
drwxrwxrwx  2 root root 4096 Aug  5 17:38 upload/
```
Как видим, удаленный каталог примонтировался автоматически

Приложения:
[Vagrantfile](./Vagrantfile)




