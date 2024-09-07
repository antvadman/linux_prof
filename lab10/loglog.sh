#!/bin/bash

echo $$ > /run/loglog.pid

if [[ "$(ps -aux | grep loglog | wc -l)" -gt 3 ]] 
then
 echo "Script is already running with pid " $(cat /run/loglog.pid)
 exit
fi

rm ./report
touch ./report
file="/tmp/access.log"
touch ./iptmp
touch ./urltmp
touch ./codetmp

sleep 40

while read -r line; do
 #echo -e  "$line\n"
 IFS=' '
 read -ra ARR <<< "$line"
 
 echo "${ARR[0]}" >> ./iptmp
 
 if [[ ${ARR[8]} -gt 0 ]]
 then 
  echo "${ARR[8]}" >> ./codetmp
 fi
 
 if [[ ${ARR[10]} == *http*  ]]
 then
  echo "${ARR[10]}" >> ./urltmp
 fi

done <$file

echo "     count  IP" >> ./report
sort ./iptmp | uniq -c | sort -bgr >> ./report 

echo "-----------------------------------------------" >> ./report

echo "     count  Response code" >> ./report
sort ./codetmp | uniq -c | sort -bgr >> ./report

echo "-----------------------------------------------" >> ./report

echo "     count  URL" >> ./report
sort ./urltmp | uniq -c | sort -bgr >> ./report

echo "------------------------ERRORS-----------------" >> ./report

while read -r line; do
 read -ra ARR <<< "$line"
 if [[ "$line" == *error*  ]]
 then
  echo "$line" >> ./report
 fi
done <$file



rm ./iptmp
rm ./urltmp
rm ./codetmp
rm /run/loglog.pid
