#!/bin/bash
echo "TCPDUMP su SYN RST FIN"
iperf -s -p 5241 &
sudo tcpdump "tcp[tcpflags] & (tcp-syn|tcp-fin|tcp-rst) != 0" -i eth0 -w  h2_malicious.pcap &

