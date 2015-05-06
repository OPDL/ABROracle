set pagesize 9999
set linesize 9999
column connectionservernm format A30
column knxconnectionnm format A30
column connectionusernm format A18
column connectionjdbcurl format A60
select connectionservernm,connectionusernm, knxconnectionnm, connectionjdbcurl from knxconnection;

