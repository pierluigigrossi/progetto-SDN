#!/bin/bash
n_hosts=3
hosts_IP=("10.0.0.1" "10.0.0.3" "10.0.0.4" )
port=5201
t_min=10
t_max=30
sleep_min=1
sleep_max=7 
while true; do
    i=$(($RANDOM%$n_hosts))
    wait=$(($RANDOM%($sleep_max-$sleep_min+1)+$sleep_min))
    t=$(($RANDOM%($t_max-$t_min+1)+$t_min))
    echo "tentativo connessione ${hosts_IP[$i]} di durata $t s " 
    iperf -c ${hosts_IP[$i]} -port $port -t  $t 
    echo "prossima connessione iperf tra $wait s " 
    sleep $wait
done