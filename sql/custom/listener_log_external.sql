create directory LISTENERDIR
as '/u01/app/oracle/oracle/product/10.2.0/db_4/network/log'
/ 

create table listenerlog
(
   logtime1 timestamp,
   connect1 varchar2(300), 
   protocol1 varchar2(300),
   action1 varchar2(15),
   service1 varchar2(15),
   return1 number(10)
)
organization external (
   type oracle_loader
   default directory LISTENERDIR
   access parameters
   (
      records delimited by newline
      nobadfile 
      nologfile
      nodiscardfile
      fields terminated by "*" lrtrim
      missing field values are null
      (
          logtime1 char(30) date_format 
          date mask "DD-MON-YYYY HH24:MI:SS",
          connect1,
          protocol1,
          action1,
          service1,
          return1
      )
   )
   location ('listener.log')
)
reject limit unlimited
/
