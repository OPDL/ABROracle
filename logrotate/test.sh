#!/bin/bash
/usr/sbin/logrotate -v -d -f ~/user/logrotate/conf/ora_rdbms.conf
/usr/sbin/logrotate -v -d -f ~/user/logrotate/conf/ora_grid.conf
/usr/sbin/logrotate -v -d -f ~/user/logrotate/conf/ora_asm.conf
