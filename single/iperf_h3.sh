#!/bin/bash
host_IP=10.0.0.4
port=5201
t_min=10
t_max=30
sleep_min=1
sleep_max=7
out_file=h3.txt

iperf -s -p 5201 &
tcpdump "tcp[tcpflags] & (tcp-syn|tcp-fin|tcp-rst) != 0" -w  $h_part.pcap &
echo "connessioni da 10.0.0.3 verso $host_IP"
sleep 10

while true; do
    wait=$(($RANDOM%($sleep_max-$sleep_min+1)+$sleep_min))
    t=$(($RANDOM%($t_max-$t_min+1)+$t_min))
    echo "prossima connessione iperf tra $(($wait+$t)) s "
    iperf -c $host_IP -p $port -t  $t  
    sleep $wait
done