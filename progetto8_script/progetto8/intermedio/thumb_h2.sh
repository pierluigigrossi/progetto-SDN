#!/bin/bash
echo "TCPDUMP su SYN RST FIN"
tcpdump "tcp[tcpflags] & (tcp-syn|tcp-fin|tcp-rst) != 0" -w  h2_thumb.pcap &

