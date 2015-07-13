#!/bin/bash
s=$(($RANDOM%100))
sleep $s
cd /root/bin/iop
date=`date`;
echo "process check starts at $date" >>/var/log/process_check.log 
/root/bin/iop/process_check.pl 2>&1 >>/var/log/process_check.log &

