#!/bin/bash
myip=10.0.0.3
host=10.0.0.4
port=5201

t_min=3
t_max=15
sleep_min=1
sleep_max=20

iperf -s -p 5201 &
tcpdump "tcp[tcpflags] & (tcp-syn|tcp-fin|tcp-rst) != 0" -w  $myip.pcap &
sleep 10

while true; do
    wait=$(($RANDOM%($sleep_max-$sleep_min+1)+$sleep_min))
    t=$(($RANDOM%($t_max-$t_min+1)+$t_min))
    sleep $wait
    echo "$(date +"%T")" inizio >> "$myip->$host.txt"
    iperf -c $host -p $port -t $t &>> "$myip->$host.txt"
    echo "$(date +"%T") fine " >> "$myip->$host.txt"
    echo "elapsed_time: $(($wait+$t))" >> "$myip->$host.txt"
done