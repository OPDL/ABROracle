#!/bin/bash
/usr/sbin/logrotate -v -s ~/user/logrotate/state/ora_rdbms.state ~/user/logrotate/conf/ora_rdbms.conf
/usr/sbin/logrotate -v -s ~/user/logrotate/state/ora_grid.state ~/user/logrotate/conf/ora_grid.conf
/usr/sbin/logrotate -v -s ~/user/logrotate/state/ora_asm.state ~/user/logrotate/conf/ora_asm.conf
