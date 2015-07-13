#!/bin/bash
s=$(($RANDOM%100))
sleep $s
cd /root/bin/iopattern
/root/bin/iopattern/process_check.pl 

