#!/usr/bin/perl -w

use warnings;
use strict;
use PDBA::CM;
use PDBA::GQ;
use PDBA::OPT;
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
);

if ( $optctl{help} ) { usage(1) }

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

print "Password: $password\n";

my $dbh = new PDBA::CM(
	DATABASE => $optctl{database},
	USERNAME => $optctl{username},
	PASSWORD => $password,
);

#my $gq = new PDBA::GQ ( $dbh, 'dual');
my $gq = new PDBA::GQ ( $dbh, 'user_tables', { WHERE => 'rownum < 2' } );

my $colHash = $gq->getColumns;
my @colNames = sort { $colHash->{$a} cmp $colHash->{$b} } keys %{$colHash};

print "HASH: ", join(':',keys %$colHash), "\n";
#print "COL: ", join(':',@colNames), "\n";

while ( my $row = $gq->next ) {
	print "$colNames[0]: $row->{$colNames[0]}\n";
}

$dbh->disconnect;

sub usage {
	my $exitVal = shift;
	use File::Basename;
	my $basename = basename($0);
	print qq/
$basename

usage: $basename -machine database_server -database instance -username account 

/;
	exit $exitVal;
};

