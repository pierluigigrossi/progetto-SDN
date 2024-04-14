#!/bin/bash
tcpdump "tcp[tcpflags] & (tcp-syn) != 0"