#!/bin/bash
echo "TCPDUMP su SYN RST FIN"
iperf -s -p 5241 &
tcpdump "tcp[tcpflags] & (tcp-syn|tcp-fin|tcp-rst) != 0" -w  h2_thumb.pcap &

