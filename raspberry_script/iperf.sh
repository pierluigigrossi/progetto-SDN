#!/bin/bash
#parametri
t_min=3
t_max=15
sleep_min=1
sleep_max=20
n_hosts=3
hosts_IP=("10.10.6.40" "10.10.6.41" "10.10.6.42")
#elimino l'host su cui sono dalla lista dei target
myip=$(ip -f inet addr show  | sed -En -e 's/.*inet ([0-9.]+).*/\1/p' | grep -F  10.10.6.)
#myip=10.0.0.2

#partenza server 

iperf -s -p 5240 &
iperf -s -p 5241 &
iperf -s -p 5242 &
#iperf -s -p 5244 &

tcpdump "tcp[tcpflags] & (tcp-syn|tcp-fin|tcp-rst) != 0" -w  $myip.pcap &

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
out_file=$h_part.output.txt
port=$((5200+$h_part))
echo "port target $port"
#loop per generare traffico simultaneamente
for host in "${hosts_IP[@]}"; do
    #per ciascun host tranne quello su cui sono,
    #fai loop  iperf ad intervalli causali (wait),
    # di deurata casuale (t)
    echo "port target $port" >> "$myip->$host.txt"
    while true; do
        wait=$(($RANDOM%($sleep_max-$sleep_min+1)+$sleep_min))
        t=$(($RANDOM%($t_max-$t_min+1)+$t_min))
        sleep $wait
        echo "$(date +"%T")" inizio >> "$myip->$host.txt"
        iperf -c $host -p $port -t $t &>> "$myip->$host.txt"
        echo "$(date +"%T") fine " >> "$myip->$host.txt"
        echo "elapsed_time: $(($wait+$t))" >> "$myip->$host.txt"
    done &
    #mostra i 3 processi creati per i 3 loop in contemporanea
    echo "PID creati: $!" >> $out_file.proc.txt
done 