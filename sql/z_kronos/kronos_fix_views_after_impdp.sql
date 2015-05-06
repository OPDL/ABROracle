
set echo on

select sysdate from dual;

-- drop both links, most likely only one exists
drop database link jdeprod.epc.com;
drop database link jdetest.epc.com;

create database link jdetest.epc.com connect
        to kronos_test identified by kr0n0s_ta_201E using 'JDETEST';


Create or Replace View F0002    as 
	Select * From CRPCTL.F0002@JDETEST.EPC.COM;
Create or Replace View F06116Z1 as 
	Select * From CRPDTA.F06116Z1@JDETEST.EPC.COM;

Create or Replace View F0005   as 
	Select *  From CRPCTL.F0005@JDETEST.EPC.COM    WITH READ ONLY;

Create or Replace View F0006   as 
	Select *  From CRPDTA.F0006@JDETEST.EPC.COM    WITH READ ONLY;
Create or Replace View F0010   as 
	Select *  From CRPDTA.F0010@JDETEST.EPC.COM    WITH READ ONLY;
Create or Replace View F0111   as 
	Select *  From CRPDTA.F0111@JDETEST.EPC.COM    WITH READ ONLY;
Create or Replace View F060116 as 
	Select *  From CRPDTA.F060116@JDETEST.EPC.COM  WITH READ ONLY;
Create or Replace View F060117 as 
	Select *  From CRPDTA.F060117@JDETEST.EPC.COM  WITH READ ONLY;
Create or Replace View F06146  as 
	Select *  From CRPDTA.F06146@JDETEST.EPC.COM   WITH READ ONLY;
Create or Replace View F08042  as 
	Select *  From CRPDTA.F08042@JDETEST.EPC.COM   WITH READ ONLY;
Create or Replace View F01151  as 
	Select *  From CRPDTA.F01151@JDETEST.EPC.COM   WITH READ ONLY;

set echo off


