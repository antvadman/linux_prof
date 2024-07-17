# Lab 2 Ansible part 1

За основу возьмем ВМ, созданную в прошлой лабе.

Добавляем в Vgrantfile описание публичной сети, чтобы иметь возможность обращаться к вэб-серверу,
установленному на ВМ.

Также при развертывании ВМ обновим ключи keyring:
```
sudo apt-key update
sudo apt-get update
```

Создаем файл hosts.ini, где опишем хосты для оркестрации.
Здесь же опишем форвардинг портов, логин и пароль для доступа:
```
[NGINX_GR]
updk ansible_host=127.0.0.1 ansible_port=2222 ansible_user=vagrant ansible_ssh_pass=vagrant
```
Создадим конфигурационный файл ansible.cfg
Там укажем, из какого файла брать информацию о хостах:
```
[defaults]
inventory = hosts.ini
host_key_checking = False
```
Теперь проверим работу ansible при помощи ad-hoc комманд:
```
vad@home:~/labs/lab1$ ansible updk -m command -a "uname -r"
updk | CHANGED | rc=0 >>
3.14.73-031473-generic

vad@home:~/labs/lab1$ ansible -i hosts.ini -m ping all
updk | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "ping": "pong"
}
```
Создадим каталог group_vars для хранения переменных группы. 
```
mkdir group_vars
```
В нем разместим файл с описанием переменных.
Имя файла соответствует имени группы из файла hosts.ini
```
---
nginx_port: 8080
```
Далее проверим, что переменная привязалась к ВМ
```
vad@home:~/labs/lab1$ ansible-inventory --list
{
    "NGINX_GR": {
        "hosts": [
            "updk"
        ]
    },
    "_meta": {
        "hostvars": {
            "updk": {
                "ansible_host": "127.0.0.1",
                "ansible_port": 2222,
                "ansible_ssh_pass": "vagrant",
                "ansible_user": "vagrant",
                "nginx_port": 8080
            }
        }
    },
    "all": {
        "children": [
            "ungrouped",
            "NGINX_GR"
        ]
    }
}
```
Копируем файл конфига сайта с гостевой ВМ и добавляем расширение j2.
Вместо порта добавляем имя переменной в фигурных скобках:
```
server {
	listen {{ nginx_port }} default_server;
```
Обратно копируем конфиг на целевую машину и меняем права:
```
scp vagrant@10.30.30.117:/etc/nginx/sites-available/default ./default.j2
chmod 777 default.j2
```
Создаем плэйбук lab2.yml.
Устанавливаем nginx, используя модуль apt
```
tasks:
   - name: NGINX | Install nginx
     apt:
      name: nginx
```
Добавляем секцию для работы с шаблонами в плэйбук lab2.yml
```
- name: Change NGINX port
     template: src=./default.j2 dest=/etc/nginx/sites-available/default mode=0555
     notify:
      - Reload nginx
```
Добавляем в ansible файл обработчик notify.
```
  handlers:
   - name: Reload nginx
     service: name=nginx state=restarted
```
Запускаем плэйбук и проверяем стартовую страницу на стандартном порту:
```
vad@home:~/labs/lab1$ curl http://10.30.30.117
curl: (7) Failed to connect to 10.30.30.117 port 80 after 1 ms: Couldn't connect to server
```
А теперь на порту 8080:
```
vad@home:~/labs/lab1$ curl http://10.30.30.117:8080
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
```
Приложения:
[Vagrantfile](./Vagrantfile)
[lab2.yml](./lab2.yml)
[hosts.ini](./hosts.ini)
[ansible.cfg](./ansible.cfg)
[default.j2](./default.j2)
[NGINX_GR](./group_vars/NGINX_GR)



