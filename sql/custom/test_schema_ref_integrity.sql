DROP TABLE "PERSON";
/
DROP TABLE "PERSON_TYPE";
/
DROP VIEW V_PERSON;
/

-- PERSON_TYPE INFORMATION
DROP SEQUENCE PERSON_TYPE_SEQ ;
/
CREATE SEQUENCE PERSON_TYPE_SEQ INCREMENT BY 1 MAXVALUE 9999999999999999999999999999 MINVALUE 1 NOCACHE;
/
CREATE TABLE "PERSON_TYPE" 
   (	"ID" NUMBER, 
	 "ABBRV" VARCHAR2(100 CHAR),  
	 "VALUE" VARCHAR2(100 CHAR),  
	 CONSTRAINT "PERSON_TYPE_PK" PRIMARY KEY ("ID")
   ) 
;
/
CREATE OR REPLACE TRIGGER "BI_PERSON_TYPE" 
  before insert on "PERSON_TYPE"              
  for each row 
begin  
  if :new."ID" is null then
    select "PERSON_TYPE_SEQ".nextval into :new."ID" from sys.dual;
  end if;
end;
/
ALTER TRIGGER "BI_PERSON_TYPE" ENABLE;
/

-- PERSON TABLE

DROP SEQUENCE PERSON_SEQ ;
/
CREATE SEQUENCE PERSON_SEQ INCREMENT BY 1 MAXVALUE 9999999999999999999999999999 MINVALUE 1 NOCACHE;
/

CREATE TABLE "PERSON" 
   (	"ID" NUMBER, 
	"TYPE_ID" NUMBER, 
	"NAME" VARCHAR2(100 CHAR), 
	 CONSTRAINT "PERSON_PK" PRIMARY KEY ("ID")
   ) 
 ;

  CREATE OR REPLACE TRIGGER "BI_PERSON" 
  before insert on "PERSON"              
  for each row 
begin  
  if :new."ID" is null then
    select "PERSON_SEQ".nextval into :new."ID" from sys.dual;
  end if;
end;
/
ALTER TRIGGER "BI_PERSON" ENABLE;
/


ALTER TABLE "PERSON" ADD CONSTRAINT "FK_TYPE_ID" FOREIGN KEY ("TYPE_ID") 
REFERENCES "PERSON_TYPE" ("ID") ENABLE;
/

insert into PERSON_TYPE ("ABBRV","VALUE") values ('Oracle','Directory');
insert into PERSON_TYPE ("ABBRV","VALUE") values ('MSSQL','Operating System');
insert into PERSON_TYPE ("ABBRV","VALUE") values ('FTP','FTP');
insert into PERSON_TYPE ("ABBRV","VALUE") values ('LDAP','LDAP');
insert into PERSON_TYPE ("ABBRV","VALUE") values ('OS','OS Login');
commit;
/

insert into PERSON ("TYPE_ID","NAME") values (1,'Adam');
insert into PERSON ("TYPE_ID","NAME") values (NULL,'Joe');

commit;
/
-- should fail ref integrity
insert into PERSON ("TYPE_ID","NAME") values (100,'Adam');
commit;
/

create view V_PERSON as 
select
a.*,b.abbrv from person a left outer join person_type b
on a.type_id = b.id;
commit;
/

select * from v_person;
/
