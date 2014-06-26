
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use PDBA::CM;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

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
	PATH => '.',
	#MODE => 'SYSOPER'
);


if ( $dbh ) { print "ok 2\n" }
else { print "not ok 2\n" }

$dbh->disconnect;

