#!/bin/bash

rm ./tmp_ps_list 2> /dev/null

ls  /proc/ | grep -P '[0-9]{1,6}' | sort -u > ./tmp_ps_list

file="./tmp_ps_list"

while read -r pidd; do
	
	pth=/proc/$pidd/cmdline 
	
	if [ -e $pth ]	
	then
		pidl=$(tr -d '\0' <"$pth")
		
		ppd=$(cat /proc/$pidd/status | grep PPid)
		
		nm=$(cat /proc/$pidd/status | grep Name)
		
		st=$(cat /proc/$pidd/status | grep State)
		
		echo -e "Pid: $pidd    $ppd   $nm   $st   $pidl\n" 
	fi

done <$file

rm ./tmp_ps_list
