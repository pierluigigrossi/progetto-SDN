#!/bin/bash
# 4 server iperf in parallelo 
iperf -s -p 5201 &
iperf -s -p 5202 &
iperf -s -p 5203 &
iperf -s -p 5204 &
pgrep iperf