#!/bin/bash
export COLUMNS=6000
ps  -a -x -f -o pid,pcpu,pmem,cputime,cmd
