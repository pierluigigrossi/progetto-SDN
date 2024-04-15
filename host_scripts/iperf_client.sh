#!/bin/bash
#parametri
t_min=10
t_max=30
sleep_min=1
sleep_max=7 
n_hosts=3
hosts_IP=("10.0.0.1" "10.0.0.2" "10.0.0.3" "10.0.0.4")
#elimino l'host su cui sono dalla lista dei target
myip=$(ip -f inet addr show  | sed -En -e 's/.*inet ([0-9.]+).*/\1/p' | grep -F  10.0.0.)
#myip=10.0.0.2
for i in "${!hosts_IP[@]}"; do
    if [ ${hosts_IP[i]} != $myip ]
    then
        new_array+=( "${hosts_IP[i]}" )
    fi
done
hosts_IP=("${new_array[@]}")
unset new_array
#caclolo porta target come 5200 + ultimo ottetto IP host
h_part=$(echo $myip | cut -d . -f 4)
port=$((5200+$h_part))
echo "port target $port"
#loop per generare traffico
while true; do
    i=$(($RANDOM%$n_hosts))
    wait=$(($RANDOM%($sleep_max-$sleep_min+1)+$sleep_min))
    t=$(($RANDOM%($t_max-$t_min+1)+$t_min))
    echo "tentativo connessione ${hosts_IP[$i]} di durata $t s " 
    iperf -c ${hosts_IP[$i]} -port $port -t  $t 
    echo "prossima connessione iperf tra $wait s " 
    sleep $wait
done