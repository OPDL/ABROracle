use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'		=> 'PDBA',
	'VERSION_FROM'	=> 'PDBA.pm', # finds $VERSION
	'PREREQ_PM'		=> { 'DBI' => 1.13, 'DBD::Oracle' => 1.06 }, # e.g., Module::Name => 1.1
	'EXE_FILES' => [ qw(
			DBA/priv_info.pl
			DBA/user_info.pl
			PWD/pwd.pl PWD/pwc.pl sendmail_test.pl
			OPT/my_script.pl
			pdbarep/spdrvr.pl
			pdbarep/pdba_opt.pl
			pdbarep/baseline.pl
			pdbarep/sxp.pl
			pdbarep/sxprpt.pl
			pdbarep/sxpcmp.pl
			chkalert/chkalert.pl
			dbup2/dbup.pl
			dbup2/dbignore.pl
			routine_tasks/create_user.pl
			routine_tasks/dba_jobs.pl
			routine_tasks/dba_jobsm.pl
			routine_tasks/ddl_oracle.pl
			routine_tasks/drop_user.pl
			routine_tasks/dup_user.pl
			routine_tasks/idxr.pl
			routine_tasks/kss.pl
			routine_tasks/maxext.pl
			routine_tasks/mucr8.pl
			routine_tasks/odpc.pl
			routine_tasks/sqlunldr.pl
		) 
	]
);
