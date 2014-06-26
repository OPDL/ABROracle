
-- binary column test

drop table bincol_test;

create table bincol_test (
	clear_text varchar2(10),
	binary_data varchar2(10)
	--binary_data long
);

insert into bincol_test(clear_text) values('Post-Dated');
insert into bincol_test(clear_text) values('Check');
insert into bincol_test(clear_text) values('Loan');
commit;


var xorstr varchar2(10)

begin
	:xorstr := rpad(chr(127),10,chr(127));
end;
/

update bincol_test
set binary_data = 
	utl_raw.cast_to_varchar2(
		utl_raw.bit_xor(
			utl_raw.cast_to_raw(clear_text),
			utl_raw.cast_to_raw(substr(:xorstr,1,length(clear_text)))
		)
	)
/

commit;
set term off
spool bincol_test.log
select * from bincol_test;
spool off
set term on

ed bincol_test.log

select 
	utl_raw.cast_to_varchar2(
		utl_raw.bit_xor(
			utl_raw.cast_to_raw(binary_data),
			utl_raw.cast_to_raw(:xorstr)
		)
	)
from bincol_test;


