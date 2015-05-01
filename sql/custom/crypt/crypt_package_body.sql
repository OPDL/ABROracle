alter session set current_schema=DEV_APEX;
/
create or replace PACKAGE BODY abrcrypt
AS
-- Author: Adam Richards
--DO NOT FORGET TO WRAP THIS BEFORE LOADING INTO DATABASE
--IF IT IS NOT WRAPPED, THE KEY WILL BE EXPOSED
--THE WRAP UTILITY IS LOCATED IN THE \BIN DIRECTORY (WRAP.EXE)
-- grant execute on dbms_crypto to user;
-- select ABRCRYPT.decrypt('key',ABRCRYPT.encrypt('key','test string')) from dual;
-- select ABRCRYPT.decrypt('key',ABRCRYPT.encrypt('key','This is a test string')) from dual;
-- select ABRCRYPT.encrypt('keykey','This is a test string') as "e" from dual;
  G_CHARACTER_SET VARCHAR2(10) := 'AL32UTF8';
  G_STRING VARCHAR2(32) := '2uWty09T2Bv5hjoJj09PvFfaLikCCVL9';
  G_KEY RAW(250) := utl_i18n.string_to_raw( data => G_STRING,dst_charset => G_CHARACTER_SET );
  G_ENCRYPTION_TYPE PLS_INTEGER := sys.dbms_crypto.encrypt_aes256 
                                    + dbms_crypto.chain_cbc 
                                    + dbms_crypto.pad_pkcs5;
  FUNCTION scrubkey(p_key IN VARCHAR2 ) RETURN VARCHAR2
  IS
  BEGIN
   if length(p_key) < 32 then
     return lpad(p_key,32,'0');
   end if;
   return substr(p_key,1,32);
  END scrubkey;
  
  FUNCTION encrypt( p_key IN VARCHAR2, p_data IN VARCHAR2 ) RETURN RAW
  IS

    l_key RAW(250);
    l_data RAW(4000) := UTL_I18N.STRING_TO_RAW( p_data, G_CHARACTER_SET );
    l_encrypted RAW(4000);
  BEGIN
    l_key:=utl_i18n.string_to_raw( data => scrubkey(p_key) ,dst_charset => G_CHARACTER_SET );
    l_encrypted := dbms_crypto.encrypt
                   ( src => l_data,
                     typ => G_ENCRYPTION_TYPE,
                     key => l_key );
                     
    RETURN l_encrypted;
  END encrypt;
  
  FUNCTION decrypt( p_key IN varchar2, p_data IN RAW ) RETURN VARCHAR2
  IS
    l_key RAW(250);
    l_decrypted RAW(4000);
    l_decrypted_string VARCHAR2(4000);
  BEGIN
  
    l_key := utl_i18n.string_to_raw( data => scrubkey(p_key) ,dst_charset => G_CHARACTER_SET );
    l_decrypted := dbms_crypto.decrypt
                    ( src => p_data,
                      typ => G_ENCRYPTION_TYPE,
                      key => l_key );

    l_decrypted_string := utl_i18n.raw_to_char
                            ( data => l_decrypted,
                              src_charset => G_CHARACTER_SET );
    RETURN l_decrypted_string;
  END decrypt;
  FUNCTION test RETURN VARCHAR2
  IS
  l_test_key varchar2(32) := '12345678901234567890123456789012';
  l_test varchar2(1000) := 'This is a testThis is a testThis is a testThis is a test';

  l_encrypted RAW(4000);
  l_rv2 varchar2(100);
  BEGIN
    l_encrypted := ABRCRYPT.ENCRYPT(l_test_key,l_test);
    l_rv2 := ABRCRYPT.DECRYPT(l_test_key,l_encrypted);
    if not (l_rv2 = l_test ) then
      return 'FAIL';
    end if;

    l_rv2 := ABRCRYPT.DECRYPT(l_test_key,ABRCRYPT.ENCRYPT(l_test_key,l_test));
    if not (l_rv2 = l_test ) then
      return 'FAIL';
    end if;
    return 'PASS';
  END test;
END abrcrypt;
/
show errors
commit;

