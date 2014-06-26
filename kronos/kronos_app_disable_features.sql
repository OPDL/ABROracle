col WDMDEVICEDSC format a30

UNDEF MY_DATE

pause Preparing to make backups of tables, please enter a numeric date like 20140219 for my_date when prompted. (hit return to continue):

set echo on

create table EPC_WDMDEVICE_&&MY_DATE as select * from WDMDEVICE;

create table EPC_EVENTMGRTASK_&MY_DATE as select * from EVENTMGRTASK;

set echo off

pause Kronos Disable Clocks in table WDMDEVICE (hit return to continue):

set echo on

select WDMDEVICEID, ENABLEDSW, WDMDEVICENAME, WDMDEVICEDSC   from WDMDEVICE;

update WDMDEVICE set ENABLEDSW = 0;


select WDMDEVICEID, ENABLEDSW, WDMDEVICENAME, WDMDEVICEDSC   from WDMDEVICE;

set echo off

pause Kronos Disable Event Manager events in table WDMDEVICE (hit return to continue):

set echo on

select EVENTMGRTASKID,  STATUSTXT from eventmgrtask where STATUSTXT NOT LIKE 'Protected%';

update eventmgrtask
set STATUSTXT = 'Status changed,Scheduled' where STATUSTXT NOT LIKE 'Protected%';

select EVENTMGRTASKID,  STATUSTXT from eventmgrtask where STATUSTXT NOT LIKE 'Protected%';


commit;


UNDEF MY_DATE

set echo off
