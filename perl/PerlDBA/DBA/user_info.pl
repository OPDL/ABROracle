#!/usr/bin/perl

use PDBA::CM;
use PDBA::DBA;
use PDBA::OPT;
use Getopt::Long;

my %optctl = ();

Getopt::Long::GetOptions( \%optctl,
	"machine=s",
	"database=s",
	"username=s",
	"password=s",
	"infouser=s"
);

Usage(1) unless $optctl{machine};
Usage(2) unless $optctl{database};
Usage(3) unless $optctl{username};
Usage(4) unless $optctl{infouser};

my $password='';

if ( $optctl{password} ) { $password = $optctl{password} }
else {
	$password = PDBA::OPT->pwcOptions (
		MACHINE => $optctl{machine},
		INSTANCE => $optctl{database},
		USERNAME => $optctl{username}
	);
}

my $dbh = new PDBA::CM (
	USERNAME => $optctl{username},
	PASSWORD => $password,
	DATABASE => $optctl{database}
);

my $userObj = new PDBA::DBA(
	DBH => $dbh,
	OBJECT => $optctl{infouser},
	OBJECT_TYPE => 'user'
);

my $userInfo = $userObj->info;

foreach my $attribute ( keys %{$userInfo} ) {
	printf("ATTRIBUTE:  %-30s  VALUE: %-30s\n",
	$attribute, $userInfo->{$attribute});
}

$dbh->disconnect;

sub Usage {

	my $exitVal = shift;
	use File::Basename;
	my $basename = basename($0);
	print qq{
$basename
usage: $basename - User Info

-machine         database server
-database        database name
-username        user to login as
-password        password for login user
-infouser        user to get info for

};

	exit $exitVal;

}





