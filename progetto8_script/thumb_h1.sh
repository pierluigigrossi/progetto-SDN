#!/bin/bash
echo "TCPDUMP su SYN RST FIN"
sudo tcpdump "tcp[tcpflags] & (tcp-syn|tcp-fin|tcp-rst) != 0" -i eth0  -w  h1_thumb.pcap &
echo "5 iperf verso h2 durta 1 s"
sleep 3
iperf -c 10.10.6.41 -p 5241 -t 1
iperf -c 10.10.6.41 -p 5241 -t 1
iperf -c 10.10.6.41 -p 5241 -t 1
iperf -c 10.10.6.41 -p 5241 -t 1
iperf -c 10.10.6.41 -p 5241 -t 1
sleep 5
sudo killall tcpdump
