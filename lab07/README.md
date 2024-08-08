# Lab 7 Дистрибьюция софта

Задачи:
1. создать свой пакет (можно взять свое приложение, либо собрать к примеру Apache с определенными опциями);
2. cоздать свой репозиторий и разместить там ранее собранный пакет;

## 1. Создадим deb* пакет
Подготовим рабочие каталоги
```
mkdir repo
cd repo
touch hello.c
chmod 777 hello.c
```
Напишем примитивную программу на Си, выводящую в консоль надпись "hello world" и сохраним в hello.c
```
#include <stdio.h>
void main(){
    printf("hello world\n");
}
```
Создадим исполняемый файл, узнаем его размер и зависимости
```
gcc hello.c -o hello

du -kh ./hello
12K	./hello

objdump -p ./hello | grep NEEDED
  NEEDED               libc.so.6
```
Создаем описательный файл для пакета
```
echo "Package: hello" >> package/DEBIAN/control
echo "Version: 1.0" >> package/DEBIAN/control
echo "Provides: hello" >> package/DEBIAN/control
echo "Section: misc" >> package/DEBIAN/control
echo "Priority: optional" >> package/DEBIAN/control
echo "Depends: libc6" >> package/DEBIAN/control
echo "Architecture: all" >> package/DEBIAN/control
echo "Essential: no" >> package/DEBIAN/control
echo "Installed-Size: 12" >> package/DEBIAN/control
echo "Maintainer: ant <ant@mail.ru>" >> package/DEBIAN/control
echo "Description: prints hello world" >> package/DEBIAN/control
```
Собираем пакет и переименовываем его
```
dpkg-deb --build ./package
dpkg-deb: building package `hello' in `./package.deb'.
mv ./package.deb ./hello_1.0_all.deb
```
Устанавливаем пакет
```
dpkg -i ./hello_1.0_all.deb 
(Reading database ... 63239 files and directories currently installed.)
Preparing to unpack ./hello_1.0_all.deb ...
Unpacking hello (1.0) over (1.0) ...
Setting up hello (1.0) ...
```
Запускаем его
```
root@repo:/home/vagrant/repo# hello
hello world
```
Как мы видим, пакет установился и работает

## 2. Создадим репозиторий
Установим вспомогательную инструкцию для gpg
```
sudo apt install gnupg -y
```
Теперь в интерактивном режиме сгенерируем RSA ключ 4096 бит,
которым будем подписывать репозиторий и программы
В качестве ID пользователя будем использовать адрес почты
Также в качестве хэш функций будем использовать SHA256 (SHA1 запрещены в последних релизах, ПО не пройдет верификацию)
```
nano /home/vagrant/.gnupg/gpg.conf
cert-digest-algo SHA256
digest-algo SHA256

gpg --gen-key
   (1) RSA and RSA (default)
   (2) DSA and Elgamal
   (3) DSA (sign only)
   (4) RSA (sign only)

Real name: antvad
Email address: antvad@mail.com
Comment: 
You selected this USER-ID:
    "antvad <antvad@mail.com>"
pg: /home/vagrant/.gnupg/trustdb.gpg: trustdb created
gpg: key 38DF2312 marked as ultimately trusted
public and secret key created and signed.

gpg: checking the trustdb
gpg: 3 marginal(s) needed, 1 complete(s) needed, PGP trust model
gpg: depth: 0  valid:   1  signed:   0  trust: 0-, 0q, 0n, 0m, 0f, 1u
pub   4096R/38DF2312 2024-08-07
      Key fingerprint = 896E 66E9 0076 5BCA 98AD  8FCC DF68 1132 38DF 2312
uid                  antvad <antvad@mail.com>
sub   4096R/9A205B2A 2024-08-07
```
Теперь подпишем наш пакет созданным ключем
```
dpkg-sig --sign builder /home/vagrant/repo/hello_1.0_all.deb
```
Далее посмотрим релиз Убунту, на которую мы будем устанавливать ПО
```
root@home:/home/vad# cat /etc/*release
DISTRIB_ID=Ubuntu
DISTRIB_RELEASE=24.04
DISTRIB_CODENAME=noble
DISTRIB_DESCRIPTION="Ubuntu 24.04 LTS"
PRETTY_NAME="Ubuntu 24.04 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04 LTS (Noble Numbat)"
VERSION_CODENAME=noble
ID=ubuntu
ID_LIKE=debian
```
Нас интересует параметр CODENAME=noble. Его будем указывать при описании репозитория
```
nano /var/www/repository/conf/distributions
Origin: repo.linuxbabe.com
Label: apt repository
Codename: noble
Architectures: amd64
Components: main
Description: LinuxBabe package repository for Debian/Ubuntu
SignWith: 38DF2312
Pull: noble
```
Создаем набор каталогов для репозитория
```
sudo mkdir -p /var/www/repository/
sudo chown vagrant:vagrant /var/www/repository/
mkdir -p /var/www/repository/conf/
nano /var/www/repository/conf/distributions
```
Добавляем наш пакет в репозиторий
```
reprepro -V --basedir /var/www/repository/ includedeb noble /home/vagrant/repo/hello_1.0_all.deb
Created directory "/var/www/repository//db"
/home/vagrant/repo/hello_1.0_all.deb: component guessed as 'main'
Created directory "/var/www/repository//pool"
Created directory "/var/www/repository//pool/main"
Created directory "/var/www/repository//pool/main/h"
Created directory "/var/www/repository//pool/main/h/hello"
Exporting indices...
Created directory "/var/www/repository//dists"
Created directory "/var/www/repository//dists/noble"
Created directory "/var/www/repository//dists/noble/main"
Created directory "/var/www/repository//dists/noble/main/binary-amd64"
Successfully created '/var/www/repository//dists/noble/Release.gpg.new'
Successfully created '/var/www/repository//dists/noble/InRelease.new
```
Добавляем ключ к репозиторию
```
gpg --armor --export antvad@mail.com | sudo tee /var/www/repository/gpg-pubkey.asc
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1
mQINBGazrGkBEADT7zIFsI9qwU+frkaS5o11B99Fib61WuSt6fiPk5ElhdvTkBCf
bzakmr0c/LQoLdGMwElONoblax40Sf0nNPC833VJP1N57jJha4GTjBrLtkh1pkQr
B3LCrIRLhnXjSsoNj3rLXhrxj42sLWioMbSuWp+no/20VTIXXKxkxKac8pfDVEJo
/GtXvDFyAJycKv2GGKICbMeQn3L03fvUNn60lKG1vTuZB+/h/Nw0jM7+Yz0vXkhu
.......
```
Устанавливаем nginx, и настраиваем конфиг
```
sudo apt install nginx -y
sudo nano /etc/nginx/sites-enabled/apt-repository.conf
server {
  listen 80;
  server_name 10.30.30.190;

  access_log /var/log/nginx/apt-repository.access;
  error_log /var/log/nginx/apt-repository.error;

  location / {
    root /var/www/repository/;
    autoindex on;
  }

  location ~ /(.*)/conf {
    deny all;
  }

  location ~ /(.*)/db {
    deny all;
  }
}
```
Добавим репозиторий на ПК, куда будем ставить пакет.
Сначала установим публичный ключ
```
wget --quiet -O - http://10.30.30.190/gpg-pubkey.asc | sudo tee /etc/apt/keyrings/gpg-pubkey.asc
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1
mQINBGazrGkBEADT7zIFsI9qwU+frkaS5o11B99Fib61WuSt6fiPk5ElhdvTkBCf
bzakmr0c/LQoLdGMwElONoblax40Sf0nNPC833VJP1N57jJha4GTjBrLtkh1pkQr
```
Добавим наш репозиторий в список, указав публичный ключ, которым подписываются пакеты
```
echo "deb [signed-by=/etc/apt/keyrings/gpg-pubkey.asc arch=$( dpkg --print-architecture )] http://10.30.30.190 $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hello.list
```
Обновим список репозиториев и уберем стандартные, переименовав файл с ними
```
apt update
mv /etc/apt/sources.list.d/ubuntu.sources /etc/apt/sources.list.d/ubuntu.sources_1
```
Установим наш пакет
```
apt install hello
The following NEW packages will be installed:
  hello
0 upgraded, 1 newly installed, 0 to remove and 2 not upgraded.
Need to get 3,920 B of archives.
After this operation, 12.3 kB of additional disk space will be used.
Get:1 http://10.30.30.190 noble/main amd64 hello amd64 1.0 [3,920 B]
Fetched 3,920 B in 0s (196 kB/s)  
N: Ignoring file 'ubuntu.sources_1' in directory '/etc/apt/sources.list.d/' as it has an invalid filename extension
Selecting previously unselected package hello.
(Reading database ... 222325 files and directories currently installed.)
Preparing to unpack .../archives/hello_1.0_amd64.deb ...
Unpacking hello (1.0) ...
Setting up hello (1.0) ...
```
Как видно из вывода, список стандартных репозиториев не удается прочитать, поэтому 
установка пакета будет производиться из нашего.
Запустим пакет
```
root@home:/home/vad# hello
hello world
```
Как видим, пакет, установленный по сети из нашего репозитория работает корректно

Приложения:
[Vagrantfile](./Vagrantfile)








