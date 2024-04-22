#!/bin/bash
echo "SYN prima di timeoute"
cat /proc/sys/net/ipv4/tcp_synack_retries 
echo "Partenza  automatica sui 4 host degli script"
cd /root/sdn-labs/progetto8
/root/mininet/util/m h1 ./iperf.sh &
/root/mininet/util/m h2 ./iperf.sh &
/root/mininet/util/m h3 ./iperf.sh &
/root/mininet/util/m h4 ./iperf.sh &