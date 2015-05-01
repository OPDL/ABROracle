alter session set current_schema=DEV_APEX;
/
-- grant execute on dbms_crypto to user;
-- select  DEV_APEX.ABRCRYPT.TEST from dual;
-- select DEV_APEX.ABRCRYPT.ENCRYPT('mysecretkey1','a very long password maybe') from dual;
-- select DEV_APEX.ABRCRYPT.DECRYPT('mysecretkey1',ABRCRYPT.ENCRYPT('mysecretkey1','test text')) from dual;
CREATE OR REPLACE
PACKAGE abrcrypt
AS
  FUNCTION encrypt( p_key VARCHAR2, p_data IN VARCHAR2 ) RETURN RAW;
  FUNCTION decrypt( p_key VARCHAR2, p_data IN RAW ) RETURN VARCHAR2;
  FUNCTION test RETURN VARCHAR2;
END abrcrypt;
/
show errors
commit;