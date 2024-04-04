#!/bin/sh
ip_server = localhost
port = 5201
t_min=10
t_max=30
sleep_min= 0.5
sleep_max= 5 
while true; do
    rand2=$(($RANDOM%($sleep_max-$sleep_min+1)+$sleep_min))
    rand=$(($RANDOM%($t_max-$t_min+1)+$t_min))
    iperf3 -c $ip_server -port $port -t  $rand
    sleep $rand2
done