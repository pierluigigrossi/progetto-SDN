#!/bin/bash
#hping3 -c 10 -d 120 -S -w 64 -p 5201   --rand-source 10.0.0.3
sleep 5
tcpdump "tcp[tcpflags] & (tcp-syn|tcp-fin|tcp-rst) != 0" -w  h1_malicious.pcap &
hping3 -c 5 -d 120 --syn -w 64 -p 80   --spoof 8.8.8.8 10.10.6.41
sleep 1
killall tcpdump