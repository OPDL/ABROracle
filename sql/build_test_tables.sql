conn / as sysdba
-- create user1
create user user1 identified by "password" default tablespace users temporary tablespace tempts1 account unlock;
alter user user1  profile "APP_NO_EXPIRE_PW";
grant resource to user1;
grant connect to user1;
grant unlimited tablespace to user1;
grant create view to user1;
grant select_catalog_role to user1;
grant create database link to user1;
grant QRY_ANALYSIS_ROLE to user1;

conn user1/password
-- add user1.table11 user1.table12 
CREATE TABLE TABLE11 
(
  ID NUMBER DEFAULT Null NOT NULL 
, VALUE VARCHAR2(20) 
, DT VARCHAR2(20) DEFAULT sysdate NOT NULL 
, CONSTRAINT TABLE11_PK PRIMARY KEY 
  (
    ID 
  )
  ENABLE 
);

CREATE SEQUENCE TABLE11_SEQ;

CREATE TRIGGER TABLE11_TRG 
BEFORE INSERT ON TABLE11 
FOR EACH ROW 
BEGIN
  <<COLUMN_SEQUENCES>>
  BEGIN
    IF INSERTING THEN
      SELECT TABLE11_SEQ.NEXTVAL INTO :NEW.ID FROM SYS.DUAL;
    END IF;
  END COLUMN_SEQUENCES;
END;
/



INSERT into table11(value)
SELECT  
dbms_random.string('U',trunc(dbms_random.value(1,20)))
FROM  dual
CONNECT BY level <= 10000;

select * from
(select * from table11 order by id asc) a where rownum < 10;


CREATE TABLE TABLE12 
(
  ID NUMBER DEFAULT Null NOT NULL 
, VALUE VARCHAR2(20) 
, DT VARCHAR2(20) DEFAULT sysdate NOT NULL 
, CONSTRAINT TABLE12_PK PRIMARY KEY 
  (
    ID 
  )
  ENABLE 
);

CREATE SEQUENCE TABLE12_SEQ;

CREATE TRIGGER TABLE12_TRG 
BEFORE INSERT ON TABLE12 
FOR EACH ROW 
BEGIN
  <<COLUMN_SEQUENCES>>
  BEGIN
    IF INSERTING THEN
      SELECT TABLE12_SEQ.NEXTVAL INTO :NEW.ID FROM SYS.DUAL;
    END IF;
  END COLUMN_SEQUENCES;
END;
/



INSERT into TABLE12(value)
SELECT  
dbms_random.string('U',trunc(dbms_random.value(1,20)))
FROM  dual
CONNECT BY level <= 10000;

select * from
(select * from TABLE12 order by id asc) a where rownum < 10;


conn / as sysdba
-- create user2
create user user2 identified by "password" default tablespace users temporary tablespace tempts1 account unlock;
alter user user2  profile "APP_NO_EXPIRE_PW";
grant resource to user2;
grant connect to user2;
grant unlimited tablespace to user2;
grant create view to user2;
grant select_catalog_role to user2;
grant create database link to user2;
grant QRY_ANALYSIS_ROLE to user2;

conn user2/password
-- add user2.table21 user2.table22 
CREATE TABLE TABLE21 
(
  ID NUMBER DEFAULT Null NOT NULL 
, VALUE VARCHAR2(20) 
, DT VARCHAR2(20) DEFAULT sysdate NOT NULL 
, CONSTRAINT TABLE21_PK PRIMARY KEY 
  (
    ID 
  )
  ENABLE 
);

CREATE SEQUENCE TABLE21_SEQ;

CREATE TRIGGER TABLE21_TRG 
BEFORE INSERT ON TABLE21 
FOR EACH ROW 
BEGIN
  <<COLUMN_SEQUENCES>>
  BEGIN
    IF INSERTING THEN
      SELECT TABLE21_SEQ.NEXTVAL INTO :NEW.ID FROM SYS.DUAL;
    END IF;
  END COLUMN_SEQUENCES;
END;
/



INSERT into table21(value)
SELECT  
dbms_random.string('U',trunc(dbms_random.value(1,20)))
FROM  dual
CONNECT BY level <= 10000;

select * from
(select * from table21 order by id asc) a where rownum < 10;


CREATE TABLE TABLE22 
(
  ID NUMBER DEFAULT Null NOT NULL 
, VALUE VARCHAR2(20) 
, DT VARCHAR2(20) DEFAULT sysdate NOT NULL 
, CONSTRAINT TABLE22_PK PRIMARY KEY 
  (
    ID 
  )
  ENABLE 
);

CREATE SEQUENCE TABLE22_SEQ;

CREATE TRIGGER TABLE22_TRG 
BEFORE INSERT ON TABLE22 
FOR EACH ROW 
BEGIN
  <<COLUMN_SEQUENCES>>
  BEGIN
    IF INSERTING THEN
      SELECT TABLE22_SEQ.NEXTVAL INTO :NEW.ID FROM SYS.DUAL;
    END IF;
  END COLUMN_SEQUENCES;
END;
/



INSERT into TABLE22(value)
SELECT  
dbms_random.string('U',trunc(dbms_random.value(1,20)))
FROM  dual
CONNECT BY level <= 10000;

select * from
(select * from TABLE22 order by id asc) a where rownum < 10;

conn / as sysdba
-- create user3
create user user3 identified by "password" default tablespace users temporary tablespace tempts1 account unlock;
alter user user3  profile "APP_NO_EXPIRE_PW";
grant resource to user3;
grant connect to user3;
grant unlimited tablespace to user3;
grant create view to user3;
grant select_catalog_role to user3;
grant create database link to user3;
grant QRY_ANALYSIS_ROLE to user3;

conn user3/password
-- add user3.table31 user3.table32 
CREATE TABLE TABLE31 
(
  ID NUMBER DEFAULT Null NOT NULL 
, VALUE VARCHAR2(20) 
, DT VARCHAR2(20) DEFAULT sysdate NOT NULL 
, CONSTRAINT TABLE31_PK PRIMARY KEY 
  (
    ID 
  )
  ENABLE 
);

CREATE SEQUENCE TABLE31_SEQ;

CREATE TRIGGER TABLE31_TRG 
BEFORE INSERT ON TABLE31 
FOR EACH ROW 
BEGIN
  <<COLUMN_SEQUENCES>>
  BEGIN
    IF INSERTING THEN
      SELECT TABLE31_SEQ.NEXTVAL INTO :NEW.ID FROM SYS.DUAL;
    END IF;
  END COLUMN_SEQUENCES;
END;
/



INSERT into table31(value)
SELECT  
dbms_random.string('U',trunc(dbms_random.value(1,20)))
FROM  dual
CONNECT BY level <= 10000;

select * from
(select * from table31 order by id asc) a where rownum < 10;


CREATE TABLE TABLE32 
(
  ID NUMBER DEFAULT Null NOT NULL 
, VALUE VARCHAR2(20) 
, DT VARCHAR2(20) DEFAULT sysdate NOT NULL 
, CONSTRAINT TABLE32_PK PRIMARY KEY 
  (
    ID 
  )
  ENABLE 
);

CREATE SEQUENCE TABLE32_SEQ;

CREATE TRIGGER TABLE32_TRG 
BEFORE INSERT ON TABLE32 
FOR EACH ROW 
BEGIN
  <<COLUMN_SEQUENCES>>
  BEGIN
    IF INSERTING THEN
      SELECT TABLE32_SEQ.NEXTVAL INTO :NEW.ID FROM SYS.DUAL;
    END IF;
  END COLUMN_SEQUENCES;
END;
/



INSERT into TABLE32(value)
SELECT  
dbms_random.string('U',trunc(dbms_random.value(1,20)))
FROM  dual
CONNECT BY level <= 10000;

select * from
(select * from TABLE32 order by id asc) a where rownum < 10;
-- verify
conn / as sysdba
select count(1) "user1.table11" from user1.table11;
select count(1) "user1.table12" from user1.table12;
select count(1) "user2.table21" from user2.table21;
select count(1) "user2.table22" from user2.table22;
select count(1) "user3.table31" from user3.table31;
select count(1) "user3.table32" from user3.table32;
-- drop tables
conn / as sysdba
drop table user1.table11;
drop table user1.table12;

drop table user2.table21;
drop table user2.table22;

drop table user3.table31;
drop table user3.table32;

-- drop users
conn / as sysdba
drop user user1 cascade;
drop user user2 cascade;
drop user user3 cascade;
