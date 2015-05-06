#!/bin/bash
df -Ph | perl -ne 'chomp; printf "%-50s|%8s|%8s|%8s|%8s|%-20s\n", split / +/, $_, 6 ; '|sed -e "s/^/`hostname` |/"

