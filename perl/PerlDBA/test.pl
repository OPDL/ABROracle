# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..10\n"; }
END {print "not ok 1\n" unless $loaded;}
use PDBA;
use PDBA::CM;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

if (defined($PDBA::VERSION) ) { print "ok 2\n" }
else { print "not ok 2\n" }

use Config;

my $osname;

if ( defined $ENV{ORACLE_USERID} ) {
	$username=$ENV{ORACLE_USERID};
} else {
	$username='system/manager';
	$password = '';
}

$db = $ENV{ORACLE_SID};

my $dbh = new PDBA::CM(
	DATABASE => $db,
	USERNAME => $username,
	PASSWORD => $password,
	#PATH => '.',
	#MODE => 'SYSOPER'
);


if ( $Config{osname} eq 'MSWin32' ) { $osname = $Config{osname} }
else { $osname = 'unix' }

if ( $osname eq PDBA->osname() ) { print "ok 3\n"}
else { print "not ok 3\n" }

my $pathsep;

if ( $osname eq 'unix' ) { $pathsep = ':' }
else { $pathsep = ';' }

if ( $pathsep eq PDBA->pathsep() ) { print "ok 4\n" }
else { print "not ok 4\n" }

if ( PDBA->pdbaHome() ) { print "ok 5\n" } 
else { print "not ok 5\n" }

if ( PDBA->oracleHome() ) { print "ok 6\n" } 
else { print "not ok 6\n" }

if ( 14 == length(PDBA->timestamp()) ) { print "ok 7\n" } 
else { print "not ok 7\n" }

if ( PDBA->globalName($dbh) ) { print "ok 8\n" } 
else { print "not ok 8\n" }

#print PDBA->globalName($dbh), "\n";

if ( PDBA->sysdate($dbh) ) { print "ok 9\n" } 
else { print "not ok 9\n" }

if ( PDBA->oracleVersion($dbh) ) { print "ok 10\n" } 
else { print "not ok 10\n" }

#print PDBA->sysdate($dbh, NLS_DATE_FORMAT => 'MON-DD-YY'), "\n";

$dbh->disconnect;


