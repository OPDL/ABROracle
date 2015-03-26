-- grant execute on dbms_crypto to user;
CREATE OR REPLACE
PACKAGE abrcrypt
AS
  FUNCTION encrypt( p_key VARCHAR2, p_data IN VARCHAR2 ) RETURN RAW;
  FUNCTION decrypt( p_key VARCHAR2, p_data IN RAW ) RETURN VARCHAR2;
  FUNCTION test RETURN VARCHAR2;
END abrcrypt;
/
show errors
