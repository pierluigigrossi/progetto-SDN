#!/bin/bash
echo "tcp_syn_retries:"
cat /proc/sys/net/ipv4/tcp_syn_retries 
/root/mininet/util/m h2 ./thumb_h2.sh &
/root/mininet/util/m h1 ./thumb_h1.sh &