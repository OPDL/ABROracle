ALTER SESSION SET CURRENT_SCHEMA="DEV_APEX";
/

DROP TABLE "ACCT_CRIB";
/
DROP TABLE "ACCT_CONTACT";
/
DROP TABLE "ACCT_TYPE";
/
DROP TABLE "ACCT_GROUP";
/
DROP TABLE "ACCT_CLASS";
/
DROP TABLE "ACCT_PLATFORM";
/


-- ACCT_PLATFORM
DROP SEQUENCE ACCT_PLATFORM_SEQ ;
/
CREATE SEQUENCE ACCT_PLATFORM_SEQ INCREMENT BY 1 MAXVALUE 9999999999999999999999999999 MINVALUE 1 NOCACHE;
/
CREATE TABLE "ACCT_PLATFORM" 
   (	"ID" NUMBER, 
	 "ABBRV" VARCHAR2(100 CHAR),  -- abreviation
	 "VALUE" VARCHAR2(100 CHAR),  -- type sqlserver, oracle, ldap, linux, windows, ftp
	 CONSTRAINT "ACCT_PLATFORM_PK" PRIMARY KEY ("ID")
   ) 
  TABLESPACE "USERS" ;
/
CREATE OR REPLACE TRIGGER "BI_ACCT_PLATFORM" 
  before insert on "ACCT_PLATFORM"              
  for each row 
begin  
  if :new."ID" is null then
    select "ACCT_PLATFORM_SEQ".nextval into :new."ID" from sys.dual;
  end if;
end;
/
ALTER TRIGGER "BI_ACCT_PLATFORM" ENABLE;
/

-- ACCT_CLASS INFORMATION
DROP SEQUENCE ACCT_CLASS_SEQ ;
/
CREATE SEQUENCE ACCT_CLASS_SEQ INCREMENT BY 1 MAXVALUE 9999999999999999999999999999 MINVALUE 1 NOCACHE;
/
CREATE TABLE "ACCT_CLASS" 
   (	"ID" NUMBER, 
	 "ABBRV" VARCHAR2(100 CHAR),  -- abreviation
	 "VALUE" VARCHAR2(100 CHAR),  -- type sqlserver, oracle, ldap, linux, windows, ftp
	 CONSTRAINT "ACCT_CLASS_PK" PRIMARY KEY ("ID")
   ) 
  TABLESPACE "USERS" ;
/
CREATE OR REPLACE TRIGGER "BI_ACCT_CLASS" 
  before insert on "ACCT_CLASS"              
  for each row 
begin  
  if :new."ID" is null then
    select "ACCT_CLASS_SEQ".nextval into :new."ID" from sys.dual;
  end if;
end;
/
ALTER TRIGGER "BI_ACCT_CLASS" ENABLE;
/

-- ACCT_GROUP INFORMATION
DROP SEQUENCE ACCT_GROUP_SEQ ;
/
CREATE SEQUENCE ACCT_GROUP_SEQ INCREMENT BY 1 MAXVALUE 9999999999999999999999999999 MINVALUE 1 NOCACHE;
/
CREATE TABLE "ACCT_GROUP" 
   (	"ID" NUMBER, 
	 "ABBRV" VARCHAR2(100 CHAR),  -- abreviation
	 "VALUE" VARCHAR2(100 CHAR),  -- type sqlserver, oracle, ldap, linux, windows, ftp
	 CONSTRAINT "ACCT_GROUP_PK" PRIMARY KEY ("ID")
   ) 
  TABLESPACE "USERS" ;
/
CREATE OR REPLACE TRIGGER "BI_ACCT_GROUP" 
  before insert on "ACCT_GROUP"              
  for each row 
begin  
  if :new."ID" is null then
    select "ACCT_GROUP_SEQ".nextval into :new."ID" from sys.dual;
  end if;
end;
/
ALTER TRIGGER "BI_ACCT_GROUP" ENABLE;
/


-- ACCT_TYPE INFORMATION
DROP SEQUENCE ACCT_TYPE_SEQ ;
/
CREATE SEQUENCE ACCT_TYPE_SEQ INCREMENT BY 1 MAXVALUE 9999999999999999999999999999 MINVALUE 1 NOCACHE;
/
CREATE TABLE "ACCT_TYPE" 
   (	"ID" NUMBER, 
	 "ABBRV" VARCHAR2(100 CHAR),  -- abreviation
	 "VALUE" VARCHAR2(100 CHAR),  -- type sqlserver, oracle, ldap, linux, windows, ftp
	 CONSTRAINT "ACCT_TYPE_PK" PRIMARY KEY ("ID")
   ) 
  TABLESPACE "USERS" ;
/
CREATE OR REPLACE TRIGGER "BI_ACCT_TYPE" 
  before insert on "ACCT_TYPE"              
  for each row 
begin  
  if :new."ID" is null then
    select "ACCT_TYPE_SEQ".nextval into :new."ID" from sys.dual;
  end if;
end;
/
ALTER TRIGGER "BI_ACCT_TYPE" ENABLE;
/

-- CONTACT INFORMATION
DROP SEQUENCE ACCT_CONTACT_SEQ ;
/
CREATE SEQUENCE ACCT_CONTACT_SEQ INCREMENT BY 1 MAXVALUE 9999999999999999999999999999 MINVALUE 1 NOCACHE;
/
CREATE TABLE "ACCT_CONTACT" 
   (	"ID" NUMBER, 
	 "POC_USER" VARCHAR2(100 CHAR),  -- primary user poc
  	 "POC_GROUP" VARCHAR2(100 CHAR), -- group for customer
	 "CUSTOMER_USER" VARCHAR2(100 CHAR),  -- primary user poc
	 "CUSTOMER_GROUP" VARCHAR2(100 CHAR), -- group for customer
	 "POC_SUPPORT" VARCHAR2(100 CHAR), -- support contact
	 "COMMENTS" VARCHAR2(2000 CHAR), -- additional comments
	 CONSTRAINT "ACCT_CONTACT_PK" PRIMARY KEY ("ID")
   ) 
  TABLESPACE "USERS" ;
/
CREATE OR REPLACE TRIGGER "BI_ACCT_CONTACT" 
  before insert on "ACCT_CONTACT"              
  for each row 
begin  
  if :new."ID" is null then
    select "ACCT_CONTACT_SEQ".nextval into :new."ID" from sys.dual;
  end if;
end;
/
ALTER TRIGGER "BI_ACCT_CONTACT" ENABLE;
/

-- CRIB TABLE FOR PASSWORD MANAGEMENT
DROP SEQUENCE ACCT_CRIB_SEQ ;
/
CREATE SEQUENCE ACCT_CRIB_SEQ INCREMENT BY 1 MAXVALUE 9999999999999999999999999999 MINVALUE 1 NOCACHE;
/

CREATE TABLE "ACCT_CRIB" 
   (	"ID" NUMBER, 
	"CONTACT_ID" NUMBER, 
	"PLATFORM_ID" NUMBER,
	"TYPE_ID" NUMBER, 
        "GROUP_ID" NUMBER,
	"CLASS_ID" NUMBER,
	"HOST" VARCHAR2(100 CHAR), 
	"IDENTIFIER" VARCHAR2(500 CHAR),
	"USERNAME" VARCHAR2(100 CHAR), 
	"PASSWORD" VARCHAR2(100 CHAR), 
	"COMMENTS" VARCHAR2(2000 CHAR), 
	 CONSTRAINT "ACCT_CRIB_PK" PRIMARY KEY ("ID")
   ) 
  TABLESPACE "USERS" ;

  COMMENT ON COLUMN  "ACCT_CRIB"."PLATFORM_ID" IS 'Hardware Platform REF';
  COMMENT ON COLUMN  "ACCT_CRIB"."CONTACT_ID" IS 'Contact Informatino REF';

  CREATE OR REPLACE TRIGGER "BI_ACCT_CRIB" 
  before insert on "ACCT_CRIB"              
  for each row 
begin  
  if :new."ID" is null then
    select "ACCT_CRIB_SEQ".nextval into :new."ID" from sys.dual;
  end if;
end;
/
ALTER TRIGGER "BI_ACCT_CRIB" ENABLE;
/

-- Link foriegn Keys
ALTER TABLE ACCT_CRIB ADD CONSTRAINT "FK_CONTACT_ID" FOREIGN KEY ("CONTACT_ID") 
REFERENCES ACCT_CONTACT ("ID") ENABLE;
/

ALTER TABLE "ACCT_CRIB" ADD CONSTRAINT "FK_TYPE_ID" FOREIGN KEY ("TYPE_ID") 
REFERENCES "ACCT_TYPE" ("ID") ENABLE;
/

ALTER TABLE "ACCT_CRIB" ADD CONSTRAINT "FK_GROUP_ID" FOREIGN KEY ("GROUP_ID") 
REFERENCES "ACCT_GROUP" ("ID") ENABLE;
/

ALTER TABLE "ACCT_CRIB" ADD CONSTRAINT "FK_CLASS_ID" FOREIGN KEY ("CLASS_ID") 
REFERENCES "ACCT_CLASS" ("ID") ENABLE;
/

ALTER TABLE "ACCT_CRIB" ADD CONSTRAINT "FK_PLATFORM_ID" FOREIGN KEY ("PLATFORM_ID") 
REFERENCES "ACCT_PLATFORM" ("ID") ENABLE;
/


-- VIEWs

CREATE OR REPLACE VIEW "V_ACCT_CRIB"
AS
  SELECT 
    P."VALUE" AS "PLATFORM",
    A."HOST",
    A."IDENTIFIER",
    A."USERNAME",
    A."PASSWORD",
    A."COMMENTS" ,
    T."VALUE" AS "TYPE",
    G."VALUE" AS "GROUP" ,
    L."VALUE" AS "CLASS",
    C."POC_USER",
    C."POC_GROUP",
    C."CUSTOMER_USER",
    C."CUSTOMER_GROUP",
    C."POC_SUPPORT",
    C."COMMENTS" AS "CONTACT_COMMENTS"
  FROM ACCT_CRIB A
  LEFT JOIN ACCT_CONTACT C
  ON A.CONTACT_ID = C.ID
  LEFT JOIN ACCT_TYPE T
  ON A.TYPE_ID = T.ID
  LEFT JOIN ACCT_GROUP G
  ON A.GROUP_ID = G.ID
  LEFT JOIN ACCT_CLASS L
  ON A.CLASS_ID = L.ID
  LEFT JOIN ACCT_PLATFORM P
  ON A.PLATFORM_ID = P.ID;

  / 




