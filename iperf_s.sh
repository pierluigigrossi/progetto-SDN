#!/bin/bash
#parametri
t_min=3
t_max=15
sleep_min=1
sleep_max=5 
#elimino l'host su cui sono dalla lista dei target
myip=$(ip -f inet addr show  | sed -En -e 's/.*inet ([0-9.]+).*/\1/p' | grep -F  10.0.0.)
#myip=10.0.0.2
ports=("5201" "5202" "5203" "5204")
out_file=$myip.txt

nextip(){
    IP=$1
    IP_HEX=$(printf '%.2X%.2X%.2X%.2X\n' `echo $IP | sed -e 's/\./ /g'`)
    NEXT_IP_HEX=$(printf %.8X `echo $(( 0x$IP_HEX + 1 ))`)
    NEXT_IP=$(printf '%d.%d.%d.%d\n' `echo $NEXT_IP_HEX | sed -r 's/(..)/0x\1 /g'`)
    echo "$NEXT_IP"
}

nextip=$(nextip $myip)
#partenza server 
for port in "${ports[@]}"; do
    iperf -s -p $port &
    echo "starting server on $port" &>> $out_file
done
pgrep iperf
#aspetta 10 secondi dopo aver fatto partire i server prima dei client
sleep 10


tcpdump "tcp[tcpflags] & (tcp-syn|tcp-ack|tcp-fin|tcp-rst) != 0" -w  $myip.pcap &

#loop per generare traffico simultaneamente
for port in "${ports[@]}"; do
    #per ciascun host tranne quello su cui sono,
    #fai loop  iperf ad intervalli causali (wait),
    # di deurata casuale (t)
    while true; do
        wait=$(($RANDOM%($sleep_max-$sleep_min+1)+$sleep_min))
        t=$(($RANDOM%($t_max-$t_min+1)+$t_min))
        echo "$(date +"%T") $myip ->  $nextip:$port di durata $t s " &>> $out_file
        iperf -c $nextip -p $port -t $t  &>> $out_file 2>&1
        echo "$(date +"%T") fine $myip ->  $nextip:$port  di durata $t s" &>> $out_file
        echo "attesa $wait s $myip -> $nextip:$port " &>> $out_file
        sleep $wait
    done &
    wait=$(($RANDOM%($sleep_max-$sleep_min+1)+$sleep_min))
    sleep $wait
    #mostra i 3 processi creati per i 3 loop in contemporanea
    echo "PID creati: $!" &>> $out_file
done 