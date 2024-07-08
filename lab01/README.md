# Lab 1 Обновление ядра Линукс


Задачи лабораторной работы:  

1. Получить навыки работы с Git, Vagrant;
2. Обновлять ядро в ОС Linux

### Разворачиваем виртуальную машину

При помощи Vagrant создаем виртуальную машину (2 Гб ОЗУ и 4 ядра CPU) 

```
vagrant init

# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/trusty64"
  config.vm.synced_folder "./host_data", "/guest_data"
  config.vm.hostname = "updk"
  config.vm.provider "virtualbox" do |updk|
     updk.cpus = 4
     updk.memory = "2048"
  end
```
и проверяем версию ядра
```
vagrant@updk:~$ uname -r
3.13.0-170-generic
```

### Добавляем provisioning в файл Vagrant 

Создаем каталог, куда будем скачивать образ и модули ядра.
Для скачивания используем утилиту wget с ключами -Pq
```
mkdir ./kernel
wget -P ./kernel https://kernel.ubuntu.com/mainline/v3.14.73-trusty/linux-headers-3.14.73-031473_3.14.73-031473.201606241434_all.deb
wget -P ./kernel https://kernel.ubuntu.com/mainline/v3.14.73-trusty/linux-headers-3.14.73-031473-generic_3.14.73-031473.201606241434_amd64.deb
wget -P ./kernel https://kernel.ubuntu.com/mainline/v3.14.73-trusty/linux-image-3.14.73-031473-generic_3.14.73-031473.201606241434_amd64.deb
```
Потом переходим в в созданый нами каталог и от имени суперпользователя запускаем установку
```
cd /home/vagrant/kernel
dpkg -i linux-headers* linux-image*
```
Обновляем загрузчик, перезагружаем ВМ и смотрим версию ядра
```
update-grub
reboot
vagrant@updk:~$ uname -r
3.14.73-031473-generic
```
Ядро обновилось с версии 3.13.0-170 до 3.14.73-031473.
[Vagrantfile](./Vagrantfile)



