#!/bin/bash
# export COLUMNS=6000
crontab -l | egrep -v '^#' |sed -e "s/^/`hostname` |/"
