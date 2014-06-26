
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..11\n"; }
END {print "not ok 1\n" unless $loaded;}
use PDBA::GQ;
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
	PASSWORD => $password , 
	PATH=>'../CM', 
	FILE=>'cm.conf'
);

#my $vobj = new PDBA::GQ($dbh, 'v$session');
# not a v$ object, but it works and only
# returns one row
my $vobj = new PDBA::GQ($dbh, 'dual');
die "GQ object creation failed \n" unless $vobj;
print "ok 2\n";

my ( $sid, $event, $total_waits);
my $i=3;

while( my $row = $vobj->next ) {
	#print "$row->{DUMMY}\n";
	print "ok ", $i++, "\n";
}

$vobj = new PDBA::GQ($dbh, 'dual');
print "ok ", $i++, "\n";

while( my $row = $vobj->next([]) ) {
	#print $vobj->{NAME_uc}[0],  ": $row->[0]\n";
	print "ok ", $i++, "\n";
}

$vobj = new PDBA::GQ(
	$dbh,'all_objects', 
	{ 
		COLUMNS => [qw{object_name object_type}],
		WHERE => q(rownum < 3 and object_type not like 'JAVA%') 
	}
);
  
# defaults to ref to array of hash refs
my $arrayRowRef = $vobj->all;
 
for my $row ( @$arrayRowRef ) {
	#print "ARRAY OBJECT: $row->{OBJECT_NAME}  TYPE: $row->{OBJECT_TYPE}\n";
	print "ok ", $i++, "\n";
}

# now get a ref to array of refs to array
$vobj->execute;
$arrayRowRef = $vobj->all([]);
my $colNames = $vobj->getColumns;
for my $row ( @$arrayRowRef ) {
	#print "HASH OBJECT: $row->[$colNames->{OBJECT_NAME}]  TYPE: $row->[$colNames->{OBJECT_TYPE}]\n";
	print "ok ", $i++, "\n";
}

my @bindparams=(qw{SYS TABLE});
$vobj = new PDBA::GQ(
	$dbh,'all_objects', 
	{ 
		WHERE => 'owner = ? and object_type = ? and rownum < 3' ,
		BINDPARMS => \@bindparams
	}
);

while( my $row = $vobj->next ) {
	print "ok ", $i++, "\n";
# here's how to see the data
# just reference the column names
	#print qq/
#Object: $row->{OBJECT_NAME} 
  #LAST DDL TIME: $row->{LAST_DDL_TIME}
  #OBJECT_TYPE: $row->{OBJECT_TYPE}
#/;
}

$vobj->finish;
$dbh->disconnect;

