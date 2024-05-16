#!/bin/bash
echo "TCPDUMP su SYN RST FIN"
tcpdump "tcp[tcpflags] & (tcp-syn|tcp-fin|tcp-rst) != 0" -w  h1_thumb.pcap &
echo "iperf verso h2"
sleep 3
iperf -c 10.10.6.41 -p 5241 -t 1
iperf -c 10.10.6.41 -p 5241 -t 1
iperf -c 10.10.6.41 -p 5241 -t 1
iperf -c 10.10.6.41 -p 5241 -t 1
iperf -c 10.10.6.41 -p 5241 -t 1
sleep 5
killall tcpdump
