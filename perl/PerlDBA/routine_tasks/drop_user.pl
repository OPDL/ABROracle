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
	"force!",
	"drop_username=s",
);

if ( $optctl{help} ) { usage(1) }

usage(1) unless $optctl{drop_username};

print "\ndropping user '$optctl{drop_username}'\n";

unless ( $optctl{force} ) {
	print "\nReally drop user $optctl{drop_username}?: Y/N: ";
	my $answer=<>;
	exit unless $answer =~ /^Y/i;
}

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

my $dropUser = new PDBA::DBA(
	DBH => $dbh,
	OBJECT_TYPE => 'user',
	OBJECT => $optctl{drop_username}
);

eval {
	local $dbh->{PrintError} = 0;
	local $dbh->{RaiseError} = 1;
	$dropUser->drop;
};

if ($@) {
	if (  $@ =~ /ORA-01918/ ) {
		warn "error dropping user - user '$optctl{drop_username}' does not exist\n";
	} else {
		warn "$@\n";
	}
} else {
	print "user $optctl{drop_username} successfully dropped\n\n";
}

$dbh->disconnect;

sub usage {
	my $exitVal = shift;
	use File::Basename;
	my $basename = basename($0);
	print qq/
$basename

usage: $basename 

-machine       database_server 
-database      database to create user in
-username      dba account
-password      dba password ( optional if using pwd server )
-drop_username username to drop
-force         drop user without asking for confirmation

/;
	exit $exitVal;
};

