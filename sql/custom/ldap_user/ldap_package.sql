create or replace PACKAGE abrldap
  -- LDAP Access Package
  -- Author: Adam Richards
AS
TYPE dn_record
IS
  RECORD
  (
    id     NUMBER,
    server VARCHAR2(100),
    base   VARCHAR2(100),
    dn     VARCHAR2(500),
    name   VARCHAR2(100) );
TYPE dn_table
IS
  TABLE OF dn_record;
TYPE u_record
IS
  RECORD
  (
    id          NUMBER,
    server      VARCHAR2(100),
    base        VARCHAR2(100),
    dn          VARCHAR2(500),
    employee_id VARCHAR2(100),
    first_name  VARCHAR2(100),
    last_name   VARCHAR2(100),
    common_name VARCHAR2(1000),
    sam         VARCHAR2(100),
    email       VARCHAR2(200),
    phone       VARCHAR2(200),
    manager     VARCHAR2(500),
    company     VARCHAR2(200),
    department  VARCHAR2(200),
    location    VARCHAR2(200),
    last_active DATE,
    disabled    NUMBER(1) );
TYPE u_table
IS
  TABLE OF u_record;
TYPE m_record
IS
  RECORD
  (
    id       NUMBER,
    server   VARCHAR2(100),
    base     VARCHAR2(100),
    dn       VARCHAR2(500),
    sam      VARCHAR2(100),
    memberof VARCHAR2(4000) );
TYPE m_table
IS
  TABLE OF m_record;
  FUNCTION getUserGroups(
      sam VARCHAR2)
    RETURN INTEGER;
  FUNCTION checkUserIsMemberOf(
      sam       VARCHAR2,
      groupName VARCHAR2 )
    RETURN INTEGER;
  FUNCTION getOrgUnits
    RETURN dn_table PIPELINED;
  FUNCTION getGroupsByOU
    RETURN dn_table PIPELINED;
  FUNCTION getUsersByOU
    RETURN u_table PIPELINED;
  FUNCTION getUserMemberOfByOU
    RETURN m_table PIPELINED;
END abrldap;


