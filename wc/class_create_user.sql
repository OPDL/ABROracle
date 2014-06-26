create user dev_wc_classifieds identified by "WCClass14!" default tablespace users temporary tablespace temp account unlock;
alter user dev_wc_classifieds  profile "APP_NO_EXPIRE_PW";
grant resource to dev_wc_classifieds;
grant connect to dev_wc_classifieds;
grant unlimited tablespace to dev_wc_classifieds;
grant create view to dev_wc_classifieds;
grant select_catalog_role to dev_wc_classifieds;
grant create database link to dev_wc_classifieds;

