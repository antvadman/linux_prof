## Lab 11 Процессы
Написать свою реализацию ps ax используя анализ /proc.  

Результат работы скрипта (фрагмент):   
```
Pid: 777    PPid:	1   Name:	snapd   State:	S (sleeping)   /usr/lib/snapd/snapd
Pid: 78    PPid:	2   Name:	irq/9-acpi   State:	S (sleeping)   
Pid: 784    PPid:	1   Name:	systemd-logind   State:	S (sleeping)   /usr/lib/systemd/systemd-logind
Pid: 786    PPid:	1   Name:	accounts-daemon   State:	S (sleeping)   /usr/libexec/accounts-daemon
Pid: 789    PPid:	1   Name:	cron   State:	S (sleeping)   /usr/sbin/cron-f-P
Pid: 791    PPid:	1   Name:	switcheroo-cont   State:	S (sleeping)   /usr/libexec/switcheroo-control
Pid: 796    PPid:	1   Name:	udisksd   State:	S (sleeping)   /usr/libexec/udisks2/udisksd
Pid: 804    PPid:	766   Name:	avahi-daemon   State:	S (sleeping)   avahi-daemon: chroot helper
Pid: 81    PPid:	2   Name:	kworker/R-tpm_d   State:	I (idle)   
Pid: 82    PPid:	2   Name:	kworker/R-ata_s   State:	I (idle)   
Pid: 83    PPid:	2   Name:	kworker/R-md   State:	I (idle)  
```
Приложение:  
[скрипт](./my_ps.sh)









