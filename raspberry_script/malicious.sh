#!/bin/bash
#hping3 -c 10 -d 120 -S -w 64 -p 5201   --rand-source 10.0.0.3
hping3 -c 5 -d 120 --syn -w 64 -p 80   --spoof 8.8.8.8 10.10.6.42