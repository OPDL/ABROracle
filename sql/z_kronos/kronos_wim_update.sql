/* Base sql to update from Chris Flanders of Axsium Group */


UNDEF MY_DATE
UNDEF MY_ENV

pause Preparing to make backup of table, please enter a numeric date like 20140219 for my_date when prompted. (hit return to continue):

set echo on

create table EPC_KNXCONNECTION_&&MY_DATE as select * from KNXCONNECTION;

set echo off

pause When prompted, enter environment (Test, Stage, Train)  to update Kronos WIM connection settings.  Case matters. (hit return to continue):

set echo on

/* WIM Update Query #1 */

update knxconnection 
set connectionjdbcurl = 
	(select connectionjdbcurl from knxconnection where knxconnectionnm = '&&MY_ENV')
/*PUT Test or Stage or Train inside quotes*/
where knxconnectionnm = 'CONNECTION_TO_DEFAULT_DB';

commit;

/* WIM Update Query #2 */

update knxconnection 
set connectionservernm = 
   (select connectionservernm from knxconnection where knxconnectionnm = '&&MY_ENV XML API Connection')
/* PUT Test or Stage or Train inside quotes at the beginning of the stringi */
where knxconnectionnm = 'CONNECTION_TO_XML_API' ;

commit;

UNDEF MY_DATE
UNDEF MY_ENV

set echo off
