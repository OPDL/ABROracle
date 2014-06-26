#!/usr/bin/perl -w

use warnings;
use strict;
use PDBA::CM;
use PDBA::GQ;
use PDBA::OPT;
use PDBA::DBA;
use Getopt::Long;

my %optctl=();

# passthrough allows additional command line options
# to be passed to PDBA::OPT if needed
Getopt::Long::Configure(qw{pass_through});

GetOptions( \%optctl,
	"help!",
	"machine=s",
	"database=s",
	"username=s",
	"password=s",
	"source_username=s",
	"new_username=s",
	"roles!",
	"systemprivs!",
	"objectprivs!"
);

if ( $optctl{help} ) { usage(1) }

usage(1) unless $optctl{source_username};
usage(1) unless $optctl{new_username};

# lookup the password if not on the command line
my $password = '';
if ( defined( $optctl{password} ) ) {
	$password = $optctl{password};
} else {

	if (
		! defined($optctl{machine})
		|| ! defined($optctl{database})
		|| ! defined($optctl{username})
	) { usage(1) }

	$password = PDBA::OPT->pwcOptions (
		INSTANCE => $optctl{database},
		MACHINE => $optctl{machine},
		USERNAME => $optctl{username}
	);
}

my $dbh = new PDBA::CM(
	DATABASE => $optctl{database},
	USERNAME => $optctl{username},
	PASSWORD => $password,
);

my $dupUser = new PDBA::DBA( 
	DBH => $dbh,
	OBJECT_TYPE => 'duplicate_user',
	OBJECT => $optctl{source_username},
	NEW_USERNAME => $optctl{new_username},
	MACHINE => $optctl{machine},
	DATABASE => $optctl{database},
	SYSTEM_PRIVS => $optctl{systemprivs} ? $optctl{systemprivs} : 'Y',
	TABLE_PRIVS => $optctl{objectprivs} ? $optctl{objectprivs} : 'Y',
	ROLES => $optctl{roles} ? $optctl{roles} : 'Y',
);

$dupUser->create;

print "Password: $dupUser->{PASSWORD}\n";

$dbh->disconnect;

sub usage {
	my $exitVal = shift;
	use File::Basename;
	my $basename = basename($0);
	print qq/
$basename

usage: $basename 

-machine          database_server 
-database         database to create user in
-username         dba account
-password         dba password ( optional if using pwd server )
-new_username     target username to create
-source_username  account to duplicate

These 3 options default to true
-systemprivs      assign source users system privs to new user
-nosystemprivs    do not assign source users system privs to new user
-objectprivs      assign source users object privs to new user
-noobjectprivs    do not assign source users object privs to new user
-roles            assign source users roles privs to new user
-noroles          do not assign source users roles privs to new user

/;
	exit $exitVal;
};

