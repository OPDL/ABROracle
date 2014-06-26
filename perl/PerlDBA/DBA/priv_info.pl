#!/usr/bin/perl

use lib '../blib/lib';

use PDBA::CM;
use PDBA::DBA;
use PDBA::OPT;
use Data::Dumper;
use strict;
use Getopt::Long;

my %optctl = ();

Getopt::Long::GetOptions( \%optctl,
	"machine=s",
	"database=s",
	"username=s",
	"password=s",
	"privuser=s"
);

Usage(1) unless $optctl{machine};
Usage(2) unless $optctl{database};
Usage(3) unless $optctl{username};
Usage(4) unless $optctl{privuser};

my $password='';

if ( $optctl{password} ) { $password = $optctl{password} }
else {
	$password = PDBA::OPT->pwcOptions (
		MACHINE => $optctl{machine},
		INSTANCE => $optctl{database},
		USERNAME => $optctl{username}
	);
}

my $dbh = new PDBA::CM(
	DATABASE => $optctl{database},
	USERNAME =>  $optctl{username},
	PASSWORD => $password
);

my $userObj = new PDBA::DBA( 
	DBH => $dbh,
	OBJECT => $optctl{privuser},
	OBJECT_TYPE => 'privs'
);

my $privInfo = $userObj->info;

print "USERNAME: $optctl{privuser}\n";

foreach my $privType ( sort keys %{$privInfo} ) {

	next unless $privType;
	print "PRIVTYPE: $privType\n";

	if ( $privType =~ /systemPrivs|roles/ ) {
		foreach my $priv ( sort @{$privInfo->{$privType}} ) {
			print "\tPRIV: $priv\n";
		}
	} elsif ( 'tablePrivs' eq $privType ) {
		foreach my $ownerObjects ( keys %{$privInfo->{$privType}} ) {
			#print 'OWNER: ' . Dumper($privInfo->{$privType}{$ownerObjects});
			print "\t\tOWNER: $ownerObjects\n";
			foreach my $object ( keys %{$privInfo->{$privType}{$ownerObjects}} ) {
				print "\t\t\t\tOBJ: $object - ";
				print join(':', @{$privInfo->{$privType}{$ownerObjects}{$object}}) . "\n"; 
			}
		}
	} elsif ( 'defaultRoles' eq $privType ) {
		#print Dumper($privInfo->{$privType});
		print "\tDEFAULT ROLES: ", join(',',@{$privInfo->{$privType}}), "\n";
	} elsif ( 'adminRoles' eq $privType ) {
		print "\tADMIN ROLES: ", join(',',@{$privInfo->{$privType}}), "\n";
	} elsif ( 'adminSystemPrivs' eq $privType ) {
		print "\tADMIN SYS PRIVS: ", join(',',@{$privInfo->{$privType}}), "\n";
	} else {
		die "unknown privilege type of $privType\n";
	}
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
-privuser        user to get privilege info for

};

	exit $exitVal;

}

