#!/usr/bin/perl 

use lib '../blib/lib';
use PDBA::OPT;

use PDBA::CM;
use PDBA::GQ;
use PDBA;

# this works with Getopt::Long 2.24+
# which comes std with Perl 5.6.1
# earlier versions of Perl come with
# older version of Getopt::Long. If this
# is the case, upgrade Perl and/or Getopt::Long
# use Getopt::Long(:config pass_through);

# old version of Getopt::Long
use Getopt::Long;

# get local options first
my %optctl=();

die "options not specified\n" unless ( 
		GetOptions ( \%optctl,
		"database=s",
		"username=s",
		"machine=s"
	)
);

if ( 
	! defined($optctl{database})
	|| ! defined($optctl{username})
	|| ! defined($optctl{machine})
){
	usage(1);
}

my $password = PDBA::OPT->pwcOptions(
	MACHINE => $optctl{machine},
	INSTANCE => $optctl{database},
	USERNAME => $optctl{username}
);

my $dbh = new PDBA::CM( 
	DATABASE => $optctl{database},
	USERNAME => $optctl{username},
	PASSWORD => $password
);

my $gq = new PDBA::GQ ($dbh, 'global_name');
my $row = $gq->next;
print "GLOBAL NAME: $row->{GLOBAL_NAME}\n";

$gq->finish;
$dbh->disconnect;

sub usage {
	my $exitVal = shift;

	print q/

  my_script.pl

  usage:  my_script.pl -username username -machine database_server -database database

/;

	exit $exitVal;

}

