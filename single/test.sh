#!/bin/bash
#parametri
t_min=3
t_max=15
sleep_min=1
sleep_max=5 
n_hosts=3
hosts_IP=("10.0.0.1" "10.0.0.2" "10.0.0.3" "10.0.0.4")
#elimino l'host su cui sono dalla lista dei target



port=5201
#loop per generare traffico verso 1
for i in "${!hosts_IP[@]}"; do
    while true; do
        wait=$(($RANDOM%($sleep_max-$sleep_min+1)+$sleep_min))
        t=$(($RANDOM%($t_max-$t_min+1)+$t_min))
        echo "connessione ${hosts_IP[$i]}:$port di durata $t s " 
        sleep $t
        echo "attesa $wait s ${hosts_IP[$i]} " 
        sleep $wait
    done &
    echo "processi: $!"
done 