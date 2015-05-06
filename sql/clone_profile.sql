
/*http://www.memosoup.com/20110324/oracle-how-to-clone-profiles.html*/


SET serveroutput ON
 
DECLARE
  CURSOR c_profiles IS
   SELECT PROFILE, RESOURCE_NAME, LIMIT
   FROM dba_profiles 
  ORDER BY PROFILE, resource_name;
 
  s_PROFILE                     dba_profiles.PROFILE%TYPE ;
   s_prev_PROFILE        dba_profiles.PROFILE%TYPE ;
   s_RESOURCE_NAME       dba_profiles.RESOURCE_NAME%TYPE ;
   s_LIMIT                       dba_profiles.LIMIT%TYPE ;
 BEGIN
 
s_prev_PROFILE := 'no_such_profile' ;
 
dbms_output.enable(1000000);
 OPEN c_profiles;
 LOOP
   FETCH c_profiles INTO s_PROFILE,s_RESOURCE_NAME,s_LIMIT ;
   IF ( s_prev_profile <> s_profile ) THEN
     BEGIN
       dbms_output.put_line ( '--');
       dbms_output.put_line ( 'create profile "'||s_profile||'" limit ' ||s_RESOURCE_NAME|| ' ' || s_LIMIT||';' ) ;
       s_prev_profile := s_profile ;
     END;
   ELSE
        dbms_output.put_line ( 'alter profile "'||s_profile|| '" limit ' ||s_RESOURCE_NAME|| ' ' || s_LIMIT || ';' ) ;
   END IF;
   EXIT WHEN c_profiles%NOTFOUND ;
 END LOOP ;
 
CLOSE c_profiles ;
 
END;
 /

