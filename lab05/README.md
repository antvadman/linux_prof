# Lab 5 Навыки работы с ZFS

Задачи:
1. определить алгоритм с наилучшим сжатием;
2. определить настройки pool’a;
3. найти сообщение от преподавателей.

## 1. определить алгоритм с наилучшим сжатием
Создадим пулы zfs
```
zpool create pool2 /dev/sdd /dev/sde
zpool create pool3 /dev/sdf /dev/sdg
zpool create pool3 /dev/sdh /dev/sdi
zpool create pool4 /dev/sdh /dev/sdi
```
и посмотрим их свойства
```
#zpool list
#NAME    SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
#pool1   960M  91.5K   960M        -         -     0%     0%  1.00x    ONLINE  -
#pool2   960M  91.5K   960M        -         -     0%     0%  1.00x    ONLINE  -
#pool3   960M   100K   960M        -         -     0%     0%  1.00x    ONLINE  -
#pool4   960M  91.5K   960M        -         -     0%     0%  1.00x    ONLINE  -
```
Установим для каждого пула свой алгоритм сжатия и проверим свойства
```
zfs set compression=lzjb pool1
zfs set compression=lz4 pool2
zfs set compression=gzip-9 pool3
zfs set compression=zle pool4

zfs get all | grep compression
pool1  compression           lzjb                   local
pool2  compression           lz4                    local
pool3  compression           gzip-9                 local
pool4  compression           zle                    local
```
Создадим файл со случайным набором символов
```
base64 < /dev/urandom | head -c 100M > testfile
```
и скопируем его в каждый пул
```
cp ./testfile /pool1
cp ./testfile /pool2
cp ./testfile /pool3
cp ./testfile /pool4
```
Теперь оценим степень сжатия
```
zfs list
NAME    USED  AVAIL     REFER  MOUNTPOINT
pool1   100M   732M      100M  /pool1
pool2   100M   732M      100M  /pool2
pool3  76.3M   756M     76.3M  /pool3
pool4   100M   732M      100M  /pool4
```
Максимальной степенью сжатия обладает алгоритм gzip-9 (pool3)

## 2. определить настройки pool’a;
Скачиваем архив с пулом
```
curl -o archive.tar.gz https://drive.usercontent.google.com/download?id=1MvrcEp-WgAQe57aDEzxSRalPAwbNN1Bb
```
и распаковываем его
```
tar -xzvf archive.tar.gz

zpoolexport/
zpoolexport/filea
zpoolexport/fileb
```
импортируем пул
```
zpool import -d zpoolexport/ otus
```
Смотрим все параметры пула:
```
zfs get all otus
NAME  PROPERTY              VALUE                  SOURCE
otus  type                  filesystem             -
otus  creation              Fri May 15  4:00 2020  -
otus  used                  2.04M                  -
otus  available             350M                   -
otus  referenced            24K                    -
otus  compressratio         1.00x                  -
otus  mounted               yes                    -
otus  quota                 none                   default
otus  reservation           none                   default
otus  recordsize            128K                   local
otus  mountpoint            /otus                  default
otus  sharenfs              off                    default
otus  checksum              sha256                 local
otus  compression           zle                    local
otus  atime                 on                     default
otus  devices               on                     default
otus  exec                  on                     default
otus  setuid                on                     default
otus  readonly              off                    default
otus  zoned                 off                    default
otus  snapdir               hidden                 default
otus  aclinherit            restricted             default
otus  createtxg             1                      -
otus  canmount              on                     default
otus  xattr                 on                     default
otus  copies                1                      default
otus  version               5                      -
otus  utf8only              off                    -
otus  normalization         none                   -
otus  casesensitivity       sensitive              -
otus  vscan                 off                    default
otus  nbmand                off                    default
otus  sharesmb              off                    default
otus  refquota              none                   default
otus  refreservation        none                   default
otus  guid                  14592242904030363272   -
otus  primarycache          all                    default
otus  secondarycache        all                    default
otus  usedbysnapshots       0B                     -
otus  usedbydataset         24K                    -
otus  usedbychildren        2.01M                  -
otus  usedbyrefreservation  0B                     -
otus  logbias               latency                default
otus  objsetid              54                     -
otus  dedup                 off                    default
otus  mlslabel              none                   default
otus  sync                  standard               default
otus  dnodesize             legacy                 default
otus  refcompressratio      1.00x                  -
otus  written               24K                    -
otus  logicalused           1020K                  -
otus  logicalreferenced     12K                    -
otus  volmode               default                default
otus  filesystem_limit      none                   default
otus  snapshot_limit        none                   default
otus  filesystem_count      none                   default
otus  snapshot_count        none                   default
otus  snapdev               hidden                 default
otus  acltype               off                    default
otus  context               none                   default
otus  fscontext             none                   default
otus  defcontext            none                   default
otus  rootcontext           none                   default
otus  relatime              off                    default
otus  redundant_metadata    all                    default
otus  overlay               off                    default
otus  encryption            off                    default
otus  keylocation           none                   default
otus  keyformat             none                   default
otus  pbkdf2iters           0                      default
otus  special_small_blocks  0 
```
Теперь фильтруем следующие параметры: размер записи, свободное место, алгоритм сжатия, алгоритм хеширования и тип пула
```
zfs get recordsize otus
NAME  PROPERTY    VALUE    SOURCE
otus  recordsize  128K     local

zfs get available otus
NAME  PROPERTY   VALUE  SOURCE
otus  available  350M   -

zfs get all otus | grep compression
otus  compression           zle                    local

zfs get all otus | grep sum
otus  checksum              sha256                 local

[root@zfs vagrant]# zfs get all otus | grep type
otus  type                  filesystem 
```

## 3. найти сообщение от преподавателей.
Скачиваем снапшот
```
sudo wget -O otus_task2.file --no-check-certificate https://drive.usercontent.google.com/download?id=1wgxjih8YZ-cqLqaZVa0lA3h3Y029c3oI&export=download
```
восстанавливаем пул из снапшота и посмотрим его содержимое
```
zfs receive otus/test@today < otus_task2.file

[root@zfs vagrant]# ll /otus/test
total 2590
-rw-r--r--. 1 root    root          0 May 15  2020 10M.file
-rw-r--r--. 1 root    root     727040 May 15  2020 cinderella.tar
-rw-r--r--. 1 root    root         65 May 15  2020 for_examaple.txt
-rw-r--r--. 1 root    root          0 May 15  2020 homework4.txt
-rw-r--r--. 1 root    root     309987 May 15  2020 Limbo.txt
-rw-r--r--. 1 root    root     509836 May 15  2020 Moby_Dick.txt
drwxr-xr-x. 3 vagrant vagrant       4 Dec 18  2017 task1
-rw-r--r--. 1 root    root    1209374 May  6  2016 War_and_Peace.txt
-rw-r--r--. 1 root    root     398635 May 15  2020 world.sql
```
Найдем сообщение от преподавателей
```
find /otus/test -name "secret_message"
/otus/test/task1/file_mess/secret_message
```
Смотрим содержимое файла и получаем ссылку на урок
```
cat /otus/test/task1/file_mess/secret_message
https://otus.ru/lessons/linux-hl/
```

Приложения:
[Vagrantfile](./Vagrantfile)
[provisioning script](./prov-script.sh)



