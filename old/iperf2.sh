#!/bin/bash
#parametri
t_min=3
t_max=15
sleep_min=1
sleep_max=5 
n_hosts=3
hosts_IP=("10.0.0.1" "10.0.0.2" "10.0.0.3" "10.0.0.4")
#elimino l'host su cui sono dalla lista dei target
myip=$(ip -f inet addr show  | sed -En -e 's/.*inet ([0-9.]+).*/\1/p' | grep -F  10.0.0.)
#myip=10.0.0.2

#partenza server 

iperf -s -p 5201 &
iperf -s -p 5202 &
iperf -s -p 5203 &
iperf -s -p 5204 &
pgrep iperf
#aspetta 10 secondi dopo aver fatto partire i server prima dei client
sleep 10

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
    echo "to ${hosts_IP[$i]}  "
    echo "prossima connessione tra $($t+$wait))  s " 
    iperf -c ${hosts_IP[$i]} -p $port -t  $t 
    sleep $wait
done