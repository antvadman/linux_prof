# Lab 3 Дисковая подсистема

Задачи:
1. добавить в Vagrantfile еще дисков;
2. сломать/починить raid;
3. собрать R0/R5/R10 на выбор;
4. прописать собранный рейд в конф, чтобы рейд собирался при загрузке;
5. создать GPT раздел и 5 партиций.

За основу возьмем ВМ, созданную в прошлой лабе.

Добавляем в Vgrantfile 2 дополнительных диска.
```
raid_disk1 = "/tmp/raid_disk1.vmdk"
     raid_disk2 = "/tmp/raid_disk2.vmdk"
     updk.customize ['createhd', '--filename', raid_disk1, '--size',2 * 1024]
     updk.customize ['createhd', '--filename', raid_disk2, '--size',2 * 1024]
     updk.customize ['storageattach', :id,  '--storagectl', 'SATAController', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', raid_disk1]
     updk.customize ['storageattach', :id,  '--storagectl', 'SATAController', '--port', 2, '--device', 0, '--type', 'hdd', '--medium', raid_disk2]
```

После развертывания ВМ установим утилиту mdadm:
```
apt install mdadm -y
```
Теперь создадим raid 10, из добавленных дисков
```
mdadm --create /dev/md01 -l 10 -n 2 /dev/sdb /dev/sdc
```
Просмотрим информацию о получившемся raid:
```
root@updk:/home/vagrant# mdadm -D /dev/md1
/dev/md1:
        Version : 1.2
  Creation Time : Fri Jul 19 18:07:43 2024
     Raid Level : raid0
     Array Size : 4193280 (4.00 GiB 4.29 GB)
   Raid Devices : 2
  Total Devices : 2
    Persistence : Superblock is persistent

    Update Time : Fri Jul 19 18:07:43 2024
          State : clean 
 Active Devices : 2
Working Devices : 2
 Failed Devices : 0
  Spare Devices : 0

     Chunk Size : 512K

           Name : updk:01  (local to host updk)
           UUID : 5e5f3d7f:29df1da6:3ffa7819:e014313b
         Events : 0

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
```
Развалим raid, указав статус одного из дисков fail. 
```
   mdadm  --manage /dev/md1 --fail /dev/sdb
```
Увидим, что статус raid сменился на degraded:
```
root@updk:/home/vagrant# mdadm -D /dev/md1
/dev/md1:
        Version : 1.2
  Creation Time : Fri Jul 19 18:35:54 2024
     Raid Level : raid10
     Array Size : 2095616 (2046.84 MiB 2145.91 MB)
  Used Dev Size : 2095616 (2046.84 MiB 2145.91 MB)
   Raid Devices : 2
  Total Devices : 2
    Persistence : Superblock is persistent

    Update Time : Fri Jul 19 18:36:35 2024
          State : clean, degraded 
 Active Devices : 1
Working Devices : 1
 Failed Devices : 1
  Spare Devices : 0
root@updk:/home/vagrant# mdadm  --manage /dev/md1 --remove /dev/sdb
mdadm: hot removed /dev/sdb from /dev/md1
```
Теперь удалим неисправный диск из массива
```
   mdadm  --manage /dev/md1 --remove /dev/sdb
```
На извлеченном диске удалим метаданные:
```
mdadm --zero-superblock /dev/sdb
```
Теперь добавим извлеченный диск обратно в raid:
```
 mdadm  --manage /dev/md1 --add /dev/sdb
```
Далее создадим таблицу разделов GPT (будем использовать утилиту sgdisk)
и 5 разделов. 4 раздела по 200 Мб и последний - все оставшееся пространство.
```
sgdisk --clear /dev/md1
sgdisk -o /dev/md1  
sgdisk -n 2::+200M /dev/md1
sgdisk -n 3::+200M /dev/md1
sgdisk -n 4::+200M /dev/md1
sgdisk -n 5::+200M /dev/md1
sgdisk -n 6::0 /dev/md1
```
Создадим на одном из разделов файловую систему. Пусть это будет ext4.
```
mkfs.ext4 /dev/md1p2
```
Смонтируем раздел в /mnt и создадим там тестовый файл.
```
   mount /dev/md1p2 /mnt
   touch /mnt/testfile
```
Чтобы монтирование происходило автоматически, добавим запись в /etc/fstab
```
echo "/dev/md1p2 /mnt ext4 defaults 0 0" >> /etc/fstab
```
И отправим ВМ в перезагрузку.
После загрузки проверим содержимое каталога /mnt
```
vagrant@updk:~$ ls -la /mnt
total 17
drwxr-xr-x  3 root root  1024 Jul 21 09:48 .
drwxr-xr-x 23 root root  4096 Jul 21 09:49 ..
drwx------  2 root root 12288 Jul 21 09:48 lost+found
-rw-r--r--  1 root root     0 Jul 21 09:48 testfile
```
Как мы видим, рейд при загрузке собрался, и раздел примонтировался в указанную точку.
   
Приложения:
[Vagrantfile](./Vagrantfile)




