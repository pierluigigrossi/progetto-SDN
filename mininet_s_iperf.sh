#!/bin/bash
echo "tcp_syn_retries:"
cat /proc/sys/net/ipv4/tcp_syn_retries 
echo "Partenza  automatica sui 4 host degli script"
cd /root/sdn-labs/progetto8/single/
/root/mininet/util/m h1 ./iperf_h1.sh &
/root/mininet/util/m h2 ./iperf_h2.sh &
/root/mininet/util/m h3 ./iperf_h3.sh &
/root/mininet/util/m h4 ./iperf_h4.sh &