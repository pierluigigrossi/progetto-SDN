#!/bin/bash
sudo tcpdump "tcp[tcpflags] & (tcp-syn|tcp-fin|tcp-rst) != 0" -i eth0  -w  h1_malicious.pcap &
sleep 3
sudo hping3 -c 5 -d 120 --syn -w 64 -p 5241   --spoof 8.8.8.8 10.10.6.41
sleep 1
sudo killall tcpdump