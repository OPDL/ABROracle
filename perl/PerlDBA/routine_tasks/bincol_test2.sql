

-- binary column test 2

var xorstr varchar2(10)

begin
	:xorstr := rpad(chr(127),10,chr(127));
end;
/

commit;
set term off
spool bincol_test2.log
select * from bincol_test;
spool off
set term on

ed bincol_test2.log

select 
	utl_raw.cast_to_varchar2(
		utl_raw.bit_xor(
			utl_raw.cast_to_raw(binary_data),
			utl_raw.cast_to_raw(:xorstr)
		)
	)
from bincol_test;

