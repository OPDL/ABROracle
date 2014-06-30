-- Generated by Oracle SQL Developer Data Modeler 4.0.2.840
--   at:        2014-06-11 16:29:22 MDT
--   site:      Oracle Database 11g
--   type:      Oracle Database 11g




CREATE TABLE "APPLICATION"
  (
    "ID"          NUMBER NOT NULL ,
    "NAME"        VARCHAR2 (100 BYTE) NOT NULL ,
    "ABBR"        VARCHAR2 (5 BYTE) NULL ,
    "STATUS_ID"   NUMBER NOT NULL ,
    "UPDATED_BY"  VARCHAR2 (200 BYTE) NULL ,
    "UDATED_DATE" DATE NULL
  )
  ORGANIZATION HEAP NOCOMPRESS NOCACHE NOPARALLEL NOROWDEPENDENCIES DISABLE ROW MOVEMENT ;
ALTER TABLE "APPLICATION" ADD CONSTRAINT "APPLICATION_PK" PRIMARY KEY ( "ID" ) NOT DEFERRABLE ENABLE VALIDATE ;
ALTER TABLE "APPLICATION" ADD CONSTRAINT "APPLICATION__UN" UNIQUE ( "ABBR" ) NOT DEFERRABLE ENABLE VALIDATE ;

CREATE TABLE "CATEGORY"
  (
    "ID"   NUMBER DEFAULT NULL NOT NULL ,
    "NAME" VARCHAR2 (50 BYTE) NOT NULL
  )
  ORGANIZATION HEAP NOCOMPRESS NOCACHE NOPARALLEL NOROWDEPENDENCIES DISABLE ROW MOVEMENT ;
ALTER TABLE "CATEGORY" ADD CONSTRAINT "CATEGORY_PK" PRIMARY KEY ( "ID" ) NOT DEFERRABLE ENABLE VALIDATE ;
ALTER TABLE "CATEGORY" ADD CONSTRAINT "CATEGORY__UN" UNIQUE ( "NAME" ) NOT DEFERRABLE ENABLE VALIDATE ;

CREATE TABLE "CLASSIFIED"
  (
    "ID"               NUMBER NOT NULL ,
    "CATEGORY_ID"      NUMBER NOT NULL ,
    "POSTED_DATE"      DATE DEFAULT sysdate NOT NULL ,
    "TITLE"            VARCHAR2 (200 BYTE) NOT NULL ,
    "PRICE"            NUMBER (10,2) NOT NULL ,
    "OBO"              CHAR (1 BYTE) DEFAULT 'N' NULL ,
    "CONTACT_PERSON"   VARCHAR2 (200 BYTE) NULL ,
    "TELEPHONE_NUMBER" VARCHAR2 (15 BYTE) NOT NULL ,
    "EMAIL"            VARCHAR2 (200 BYTE) NOT NULL ,
    "DESCRIPTION"      VARCHAR2 (2000 BYTE) NOT NULL ,
    "EXPIRED_DATE"     DATE NULL ,
    "EXPIRED"          CHAR (1 BYTE) DEFAULT 'N' NULL ,
    "CREATED_BY"       VARCHAR2 (200 BYTE) NULL ,
    "CREATED_DATE"     DATE NULL ,
    "UPDATED_BY"       VARCHAR2 (200 BYTE) NULL ,
    "UPDATED_DATE"     DATE NULL
  )
  ORGANIZATION HEAP NOCOMPRESS NOCACHE NOPARALLEL NOROWDEPENDENCIES DISABLE ROW MOVEMENT ;
ALTER TABLE "CLASSIFIED" ADD CHECK ( "OBO"     IN ('N', 'Y')) NOT DEFERRABLE ENABLE VALIDATE ;
ALTER TABLE "CLASSIFIED" ADD CHECK ( "EXPIRED" IN ('N', 'Y')) NOT DEFERRABLE ENABLE VALIDATE ;
ALTER TABLE "CLASSIFIED" ADD CONSTRAINT "CLASSIFIED_PK" PRIMARY KEY ( "ID" ) NOT DEFERRABLE ENABLE VALIDATE ;

CREATE TABLE "PICTURE"
  (
    "ID"            NUMBER NOT NULL ,
    "CLASSIFIED_ID" NUMBER NOT NULL ,
    "PICTURE" BLOB NULL ,
    "ORDER_OF_PIC" NUMBER (2) NULL ,
    "NAME"         VARCHAR2 (100 BYTE) NOT NULL
  )
  ORGANIZATION HEAP NOCOMPRESS NOCACHE NOPARALLEL NOROWDEPENDENCIES DISABLE ROW MOVEMENT ;
ALTER TABLE "PICTURE" ADD CONSTRAINT "PICTURE_PK" PRIMARY KEY ( "ID" ) NOT DEFERRABLE ENABLE VALIDATE ;

CREATE TABLE "STATUS"
  (
    "ID"          NUMBER NOT NULL ,
    "COLOR"       VARCHAR2 (15 BYTE) NOT NULL ,
    "STATUS"      CHAR (1 BYTE) NOT NULL ,
    "DESCRIPTION" VARCHAR2 (100 BYTE) NULL
  )
  ORGANIZATION HEAP NOCOMPRESS NOCACHE NOPARALLEL NOROWDEPENDENCIES DISABLE ROW MOVEMENT ;
ALTER TABLE "STATUS" ADD CONSTRAINT "STATUS_PK" PRIMARY KEY ( "ID" ) NOT DEFERRABLE ENABLE VALIDATE ;
ALTER TABLE "STATUS" ADD CONSTRAINT "STATUS__UN" UNIQUE ( "STATUS" ) NOT DEFERRABLE ENABLE VALIDATE ;

ALTER TABLE "APPLICATION" ADD CONSTRAINT "APPLICATION_STATUS_FK" FOREIGN KEY ( "STATUS_ID" ) REFERENCES "STATUS" ( "ID" ) ;

ALTER TABLE "CLASSIFIED" ADD CONSTRAINT "CLASSIFIED_CATEGORY_FK" FOREIGN KEY ( "CATEGORY_ID" ) REFERENCES "CATEGORY" ( "ID" ) ;

ALTER TABLE "PICTURE" ADD CONSTRAINT "TABLE_3_CLASSIFIED_FK" FOREIGN KEY ( "CLASSIFIED_ID" ) REFERENCES "CLASSIFIED" ( "ID" ) ;

CREATE SEQUENCE "APPLICATION_ID_SEQ" START WITH 1 INCREMENT BY 1 NOMINVALUE NOMAXVALUE NOCYCLE NOCACHE ORDER ;
CREATE OR REPLACE TRIGGER "APPLICATION_ID_SEQ_TRIG" BEFORE
  INSERT ON "APPLICATION" FOR EACH ROW WHEN (NEW."ID" IS NULL) BEGIN :NEW."ID" := "APPLICATION_ID_SEQ".NEXTVAL;
END;
/

CREATE SEQUENCE "CATEGORY_ID_SEQ" START WITH 1 INCREMENT BY 1 NOMINVALUE NOMAXVALUE NOCYCLE NOCACHE ORDER ;
CREATE OR REPLACE TRIGGER "CATEGORY_ID_SEQ_TRIG" BEFORE
  INSERT ON "CATEGORY" FOR EACH ROW WHEN (NEW."ID" IS NULL) BEGIN :NEW."ID" := "CATEGORY_ID_SEQ".NEXTVAL;
END;
/

CREATE SEQUENCE "CLASSIFIED_ID_SEQ" START WITH 1 INCREMENT BY 1 NOMINVALUE NOMAXVALUE NOCYCLE NOCACHE ORDER ;
CREATE OR REPLACE TRIGGER "CLASSIFIED_ID_SEQ_TRIG" BEFORE
  INSERT ON "CLASSIFIED" FOR EACH ROW WHEN (NEW."ID" IS NULL) BEGIN :NEW."ID" := "CLASSIFIED_ID_SEQ".NEXTVAL;
END;
/

CREATE SEQUENCE "PICTURE_ID_SEQ" START WITH 1 INCREMENT BY 1 NOMINVALUE NOMAXVALUE NOCYCLE NOCACHE ORDER ;
CREATE OR REPLACE TRIGGER "PICTURE_ID_SEQ_TRIG" BEFORE
  INSERT ON "PICTURE" FOR EACH ROW WHEN (NEW."ID" IS NULL) BEGIN :NEW."ID" := "PICTURE_ID_SEQ".NEXTVAL;
END;
/

CREATE SEQUENCE "STATUS_ID_SEQ" START WITH 1 INCREMENT BY 1 NOMINVALUE NOMAXVALUE NOCYCLE NOCACHE ORDER ;
CREATE OR REPLACE TRIGGER "STATUS_ID_SEQ_TRIG" BEFORE
  INSERT ON "STATUS" FOR EACH ROW WHEN (NEW."ID" IS NULL) BEGIN :NEW."ID" := "STATUS_ID_SEQ".NEXTVAL;
END;
/


-- Oracle SQL Developer Data Modeler Summary Report: 
-- 
-- CREATE TABLE                             5
-- CREATE INDEX                             0
-- ALTER TABLE                             13
-- CREATE VIEW                              0
-- CREATE PACKAGE                           0
-- CREATE PACKAGE BODY                      0
-- CREATE PROCEDURE                         0
-- CREATE FUNCTION                          0
-- CREATE TRIGGER                           5
-- ALTER TRIGGER                            0
-- CREATE COLLECTION TYPE                   0
-- CREATE STRUCTURED TYPE                   0
-- CREATE STRUCTURED TYPE BODY              0
-- CREATE CLUSTER                           0
-- CREATE CONTEXT                           0
-- CREATE DATABASE                          0
-- CREATE DIMENSION                         0
-- CREATE DIRECTORY                         0
-- CREATE DISK GROUP                        0
-- CREATE ROLE                              0
-- CREATE ROLLBACK SEGMENT                  0
-- CREATE SEQUENCE                          5
-- CREATE MATERIALIZED VIEW                 0
-- CREATE SYNONYM                           0
-- CREATE TABLESPACE                        0
-- CREATE USER                              0
-- 
-- DROP TABLESPACE                          0
-- DROP DATABASE                            0
-- 
-- REDACTION POLICY                         0
-- 
-- ERRORS                                   0
-- WARNINGS                                 0