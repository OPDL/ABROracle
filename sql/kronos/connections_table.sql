set pagesize 99
set linesize 132
col schema format A10
col knxconnectionnm format A10
col knxconnectionsdsc format A10
col connectionservernm format A10
col connectionusernm format A10
select 'TRAIN' as Schema, KNXCONNECTIONNM, KNXCONNECTIONDSC, CONNECTIONSERVERNM, CONNECTIONUSERNM,CONNECTIONJDBCURL from train_tkcsowner.knxconnection where knxconnectionnm = 'CONNECTION_TO_DEFAULT_DB'
union all
select 'TRAIN' as Schema, KNXCONNECTIONNM, KNXCONNECTIONDSC, CONNECTIONSERVERNM, CONNECTIONUSERNM,CONNECTIONJDBCURL from train_tkcsowner.knxconnection where knxconnectionnm = 'CONNECTION_TO_XML_API';

select 'TEST' as Schema, KNXCONNECTIONNM, KNXCONNECTIONDSC, CONNECTIONSERVERNM, CONNECTIONUSERNM,CONNECTIONJDBCURL from test_tkcsowner.knxconnection where knxconnectionnm = 'CONNECTION_TO_DEFAULT_DB'
union all
select 'TEST' as Schema, KNXCONNECTIONNM, KNXCONNECTIONDSC, CONNECTIONSERVERNM, CONNECTIONUSERNM,CONNECTIONJDBCURL from test_tkcsowner.knxconnection where knxconnectionnm = 'CONNECTION_TO_XML_API';

select 'STAGE' as Schema, KNXCONNECTIONNM, KNXCONNECTIONDSC, CONNECTIONSERVERNM, CONNECTIONUSERNM,CONNECTIONJDBCURL from stage_tkcsowner.knxconnection where knxconnectionnm = 'CONNECTION_TO_DEFAULT_DB'
union all
select 'STAGE' as Schema, KNXCONNECTIONNM, KNXCONNECTIONDSC, CONNECTIONSERVERNM, CONNECTIONUSERNM,CONNECTIONJDBCURL from stage_tkcsowner.knxconnection where knxconnectionnm = 'CONNECTION_TO_XML_API';

