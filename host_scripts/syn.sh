#!/bin/bash
#parametri
n_syn=40
host=10.0.0.1
wait=1

#loop per generare SYN
while true; do
    echo "SYN"
    nc -G 0.5 $host 443 -w 1
    sleep $wait
done