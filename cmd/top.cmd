#!/bin/bash
export COLUMNS=6000
 top -b -n 1 -c |head -n 10 |sed -e "s/^/`hostname` /"
