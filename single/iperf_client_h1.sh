#!/bin/bash
host_IP=10.0.0.2
port=5201
t_min=10
t_max=30
sleep_min=1
sleep_max=7

iperf -s -p 5201 &
echo "connessioni verso $host_IP"
sleep 10

while true; do
    wait=$(($RANDOM%($sleep_max-$sleep_min+1)+$sleep_min))
    t=$(($RANDOM%($t_max-$t_min+1)+$t_min))
    echo "prossima connessione iperf tra $(($wait+$t)) s "
    iperf -c $host_IP -p $port -t  $t  
    sleep $wait
done