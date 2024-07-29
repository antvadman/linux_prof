# Lab 4 Дисковая подсистема

Задачи:
1. уменьшить том под / до 8G
2. выделить том под /home
3. прописать монтирование в fstab (попробовать с разными опциями и разными файловыми системами на выбор)
4. для /home - сделать том для снэпшотов
5.Работа со снапшотами:
сгенерировать файлы в /home/
снять снэпшот
удалить часть файлов
восстановиться со снэпшота
6. выделить том под /var (/var - сделать в mirror)

## 1. уменьшить том под / до 8G
Проведем массовое обновление репозиториев:
```
sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/*.repo
sed -i s/^#.*baseurl=http/baseurl=http/g /etc/yum.repos.d/*.repo
sed -i s/^mirrorlist=http/#mirrorlist=http/g /etc/yum.repos.d/*.repo
```
И скачаем утилиту xfsdump.

Теперь приступим непосредственно к работе с LVM:
создадим физический том и группу томов
```
pvcreate /dev/sdb
vgcreate vg_root /dev/sdb
```
Теперь создадим логический том, заняв все свободное пространство.
```
lvcreate -n lv_root -l +100%FREE /dev/vg_root
```
В файле /etc/fstab смотрим тип файловой системы корневого каталога (xfs)
```
cat /etc/fstab
dev/mapper/VolGroup00-LogVol00 /                       xfs     defaults        0 0
```
Создаем ФС xfs и монтируем логический том в точку /mnt
```
mkfs.xfs /dev/vg_root/lv_root
mount /dev/vg_root/lv_root /mnt
```
Проводим резервное копирование утилитой xfsdump:
```
xfsdump -J - /dev/VolGroup00/LogVol00 | xfsrestore -J - /mnt
xfsrestore: Restore Status: SUCCESS
```
Монтируем локальные папки и меняем корневой каталог пользователя root
```
mount --bind /proc/ /mnt/proc/
mount --bind /sys/ /mnt/sys/
mount --bind /dev/ /mnt/dev/
mount --bind /run/ /mnt/run/
mount --bind /boot/ /mnt/boot/
chroot /mnt/
```
Пишем новый загрузчик
```
grub2-mkconfig -o /boot/grub2/grub.cfg
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-3.10.0-862.2.3.el7.x86_64
Found initrd image: /boot/initramfs-3.10.0-862.2.3.el7.x86_64.img
done
```
Создаем загрузочный образ initramfs
```
dracut -v initramfs-3.10.0-862.2.3.el7.x86_64.img 'echo initramfs-3.10.0-862.2.3.el7.x86_64.img | sed "s/initramfs-//g>s/.img//g"' --force
*** Creating initramfs image file '/boot/initramfs-3.10.0-862.2.3.el7.x86_64.img' done ***
```
Посмотрим блочные устройства:
```
lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk 
├─sda1                    8:1    0    1M  0 part 
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part 
  ├─VolGroup00-LogVol00 253:0    0 37.5G  0 lvm  
  └─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
sdb                       8:16   0   10G  0 disk 
└─vg_root-lv_root       253:2    0   10G  0 lvm  /
sdc                       8:32   0    2G  0 disk 
sdd                       8:48   0    1G  0 disk 
sde                       8:64   0    1G  0 disk 
```
Выходим из изолированной среды и перезагружаем ВМ.
Теперь в корень монтируется содержимое раздела lv_root
Удаляем том, который монтировался в корень изначально
```
lvremove  /dev/VolGroup00/LogVol00
Do you really want to remove active logical volume VolGroup00/LogVol00? [y/n]: y
Logical volume "LogVol00" successfully removed
```
Создаем новый раздел размером 8Гб, создаем на нем ФС и проводим те же самые операции в обратном порядке:
```
lvcreate -n VolGroup00/LogVol00 -L 8G /dev/VolGroup00
WARNING: xfs signature detected on /dev/VolGroup00/LogVol00 at offset 0. Wipe it? [y/n]: y
  Wiping xfs signature on /dev/VolGroup00/LogVol00.
  Logical volume "LogVol00" created.
  
mkfs.xfs /dev/VolGroup00/LogVol00
  
mount /dev/VolGroup00/LogVol00 /mnt

xfsdump -J - /dev/vg_root/lv_root | xfsrestore -J - /mnt
xfsrestore: Restore Status: SUCCESS

mount --bind /proc/ /mnt/proc/
mount --bind /sys/ /mnt/sys/
mount --bind /dev/ /mnt/dev/
mount --bind /run/ /mnt/run/
mount --bind /boot/ /mnt/boot/
chroot /mnt/

grub2-mkconfig -o /boot/grub2/grub.cfg
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-3.10.0-862.2.3.el7.x86_64
Found initrd image: /boot/initramfs-3.10.0-862.2.3.el7.x86_64.img
done

dracut -v initramfs-3.10.0-862.2.3.el7.x86_64.img 'echo initramfs-3.10.0-862.2.3.el7.x86_64.img | sed "s/initramfs-//g>s/.img//g"' --force

exit

shutdown -r now
```
Смотрим блочные устройства.
```
lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk 
├─sda1                    8:1    0    1M  0 part 
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part 
  ├─VolGroup00-LogVol00 253:0    0    8G  0 lvm  /
  └─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
sdb                       8:16   0   10G  0 disk 
└─vg_root-lv_root       253:2    0   10G  0 lvm  
```
Как видим, теперь корневой раздел занимает 8 Гб.

## 2. выделить том под /home 
## 3. прописать монтирование

Создаем физический том и добавляем его в группу томов:
```
pvcreate /dev/sdc
vgextend VolGroup00 /dev/sdc
```
Теперь создаем логический том, файловую систему на нем и копируем туда мусор
Копирование проводим с сохранением исходных аттрибутов файлов.
```
lvcreate -n lv_home -L 100M VolGroup00 
mkfs.xfs /dev/VolGroup00/lv_home
mount /dev/VolGroup00/lv_home /mnt
cp -arp /home/vagrant /mnt
```
jтмонтируем том и примонтируем его в точку /home
```
mount /dev/VolGroup00/lv_home /home
```
Теперь нужно, чтобы том монтировался в эту точку при загрузке ОС.
Для этого добавим запись в файл /etc/fstab
Выясним UUID логического тома
```
blkid 
/dev/mapper/VolGroup00-lv_home: UUID="b510749-392f-4a74-b682-9b4d3c887840" TYPE="xfs"
```
Добавим следующую запись в fstab
```
UUID=d13275b2-0463-49a0-aa93-2825d27b0359 /home                   xfs     defaults,nofail,noauto        0 0
```
Проверим количество файлов в /home
```
ll /home
total 0
drwx------. 3 vagrant vagrant 136 Jul 27 19:57 vagrant
```
Теперь перезагрузим ВМ и посмотрим перечень блочных устройств:
```
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk 
├─sda1                    8:1    0    1M  0 part 
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part 
  ├─VolGroup00-LogVol00 253:0    0 37.5G  0 lvm  /
  └─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
sdb                       8:16   0   10G  0 disk 
sdc                       8:32   0    2G  0 disk 
└─VolGroup00-lv_home    253:2    0  128M  0 lvm  /home

du -sh /home
20K	/home
```
Логический том успешно примонтировался.

## 4. для /home - сделать том для снэпшотов
## 5. работа со снапшотами

Создадим каталог для снапшота
```
mkdir /mnt/snap
```
Теперь создадим снапшот и смонтируем его во вновь созданный каталог:
```
lvcreate -L 100M -s -n lv_snap /dev/mapper/VolGroup00/lv_home
mount -o nouuid /dev/VolGroup00/lv_snap /mnt/snap
```
Посчитаем количество файлов ф каталоге /home
```
ll /mnt/snap/vagrant/
total 24
```
Теперь удалим все файлы из /home
```
rm -r /home
```
И восстановим их.
Для этого отмонтируем оба тома
```
umount /mnt/snap
umount /home
```
И восстановим данные со снапшота
```
lvconvert --merge /dev/VolGroup00/lv_snap
  Merging of volume VolGroup00/lv_snap started.
  VolGroup00/lv_home: Merged: 100.00%
```
Смонтируем логический том в /home  и посчитаем файлы
```
mount /dev/VolGroup00/lv_home /home
ll  /home/vagrant/
total 24
```
Как видим, файлы восстановлены

## 6. выделить том под /var (/var - сделать в mirror)
Создадим 2 физических тома и добавим их в группу томов
```
pvcreate /dev/sdd /dev/sde
vgcreate vg_raid /dev/sdd /dev/sde
```
Теперь посмотрим, какие ФС используются в системе
```
cat /proc/filesystems
```
Как мы видим, только xfs
Найдем объем /var
```
du -sh /var
51M	/var
```
Создадим зеркало, установим на файловую систему и смонтируем в /mnt
```
lvcreate -L 900M -m1 -n lv_raid vg_raid
mkfs.xfs /dev/vg_raid/lv_raid 
mount /dev/vg_raid/lv_raid /mnt
```
Скопируем содержимое каталога /var в /mnt (те на зеркало)
```
cd /var
cp -arp ./ /mnt
```
Отмонтируем зеркало и смонтируем его в /var
```
umount /mnt
mount /dev/vg_raid/lv_raid /var
```
Теперь для автозагрузки изменим файл /etc/fstab
Сначала узнаем uuid зеркала
```
blkid | grep raid
/dev/mapper/vg_raid-lv_raid_rimage_0: UUID="9fe4fccc-f419-4d60-bff0-36aded34a0c5" TYPE="xfs" 
/dev/mapper/vg_raid-lv_raid_rimage_1: UUID="9fe4fccc-f419-4d60-bff0-36aded34a0c5" TYPE="xfs" 
/dev/mapper/vg_raid-lv_raid: UUID="9fe4fccc-f419-4d60-bff0-36aded34a0c5" TYPE="xfs" 
```
Теперь добавим строку в /etc/fstab
```
UUID=9fe4fccc-f419-4d60-bff0-36aded34a0c5 /var                   xfs     defaults,nofail 0 0
```
и перезагрузим систему
После загрузки проверим блочные устройства
```
lsblk
NAME                       MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
├─vg_raid-lv_raid_rmeta_0  253:2    0    4M  0 lvm  
│ └─vg_raid-lv_raid        253:6    0  900M  0 lvm  /var
└─vg_raid-lv_raid_rimage_0 253:3    0  900M  0 lvm  
  └─vg_raid-lv_raid        253:6    0  900M  0 lvm  /var
sde                          8:64   0    1G  0 disk 
├─vg_raid-lv_raid_rmeta_1  253:4    0    4M  0 lvm  
│ └─vg_raid-lv_raid        253:6    0  900M  0 lvm  /var
└─vg_raid-lv_raid_rimage_1 253:5    0  900M  0 lvm  
  └─vg_raid-lv_raid        253:6    0  900M  0 lvm  /var
```
Как видно из вывода, в точку /var смонтировалось зеркало










