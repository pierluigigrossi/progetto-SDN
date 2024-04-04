#!/bin/bash
ip_server=localhost
port=5201
t_min=10
t_max=30
parallel_min=1
parallel_max=1
sleep_min=0.5
sleep_max=5 
while true; do
    parallel=$(($RANDOM%(parallel_max-$parallel_min+1)+$parallel_min))
    wait=$(($RANDOM%($sleep_max-$sleep_min+1)+$sleep_min))
    t=$(($RANDOM%($t_max-$t_min+1)+$t_min))
    iperf -c $ip_server -port $port -t  $t -p $parallel
    sleep $wait
done