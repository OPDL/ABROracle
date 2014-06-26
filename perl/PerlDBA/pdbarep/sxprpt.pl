#!/usr/bin/perl

# sxprpt.pl
# sql explain plan report from repository

use warnings;
use FileHandle;
use DBI;
use strict;
use PDBA;
use PDBA::CM;
use PDBA::OPT;

use Getopt::Long;

our %optctl = ();

# passthrough allows additional command line options
# to be passed to PDBA::OPT if needed
Getopt::Long::Configure(qw{pass_through});

Getopt::Long::GetOptions( \%optctl,
	"help!",
	"machine=s",
	"database=s",
	"username=s",
	"password=s",
	"verbose!",
	"rpt_database=s",
	"rpt_end_date=s",
	"rpt_start_date=s",
);

if ( $optctl{help} ) { usage(1) }

# show available reports and exit

my $password = '';
if ( defined $optctl{password} ) {
	$password = $optctl{password};
} else {

	if (
		! defined($optctl{machine})
		|| ! defined($optctl{database})
		|| ! defined($optctl{username})
	) { usage(2) }

	$password = PDBA::OPT->pwcOptions (
		INSTANCE => $optctl{database},
		MACHINE => $optctl{machine},
		USERNAME => $optctl{username}
	);
}

# get the start/end dates if needed
if ( ! defined($optctl{rpt_start_date}) ) {
	$optctl{rpt_start_date} = '01/01/1700';
}

if ( ! defined($optctl{rpt_end_date}) ) {
	$optctl{rpt_end_date} = '12/31/4000';
}

our $dbh = new PDBA::CM(
	DATABASE => $optctl{database},
	USERNAME => $optctl{username},
	PASSWORD => $password,
);


my $rptDateHash = PDBA->rptDatePk (
	$dbh,
	TABLE => 'PDBA_SXP_DATES',
	START_DATE => $optctl{rpt_start_date},
	END_DATE => $optctl{rpt_end_date},

);

if ( $optctl{verbose} ) {
	print "start date pk: $rptDateHash->{startDatePk}\n";
	print "start date   : $rptDateHash->{startDate}\n";
	print "end   date pk: $rptDateHash->{endDatePk}\n";
	print "end   date   : $rptDateHash->{endDate}\n";
}

$dbh->{LongReadLen} = 128 * 2**10;
$dbh->{LongTruncOk} = 0;

my $nlsDateFormat = 'mm/dd/yyyy hh24:mi:ss';
$dbh->do(qq{alter session set nls_date_format = '$nlsDateFormat' } );

my $sql = qq{ 
	select
		d.global_name cinstance
		, s.username
		, s.chksum sql_chksum
		, d.snap_date
		, s.sqltext
		, e.chksum exp_chksum
		, e.explain_error
		, e.exptext
	from pdba_sxp_dates d, pdba_sxp_sql s, pdba_sxp_exp e
	where d.pk = s.snap_date_pk
	and s.pk = e. pdba_sxp_sql_pk
	and d.pk between ? and ?
	and d.global_name like ?
	order by d.global_name, s.username, s.chksum
};

print "\nSQL: $sql\n\n" if $optctl{verbose};

our $sth = $dbh->prepare($sql);

$optctl{rpt_database} = defined $optctl{rpt_database} ? uc( $optctl{rpt_database}) : '%';

$sth->execute(
	$rptDateHash->{startDatePk}, 
	$rptDateHash->{endDatePk} , 
	$optctl{rpt_database}
);

my (
	$instanceName, $sqlUsername, $sqlChkSum, $sqlSnapDate, $sqlText, 
	$expChkSum, $explainError, $explainText
);

$sth->bind_columns(
	\$instanceName, \$sqlUsername,  \$sqlChkSum, \$sqlSnapDate, \$sqlText, 
	\$expChkSum, \$explainError, \$explainText
);

while ( my $ary = $sth->fetchrow_arrayref ) {
	#print "chksum : $ary->[0]\n";
	#print "explain: \n$ary->[1]\n";
	#print '#' x 80, "\n\n";
	PDBA->formatSql(\$sqlText);
	write;
}


$sth->finish;
$dbh->disconnect;

sub usage {
	my ($exitVal) = @_;

   use File::Basename;
	my $basename = basename($0);

	print qq/

usage $basename:

-machine              server where repository database resides
-database             database repository is in
-username             repository schema
-password             repository schema password (optional)
-verbose              print SQL
-rpt_database         which database ( global_name ) to report on ( default all )
-rpt_end_date         end date for report ( default all )
-rpt_start_date       start date for report ( default all )

/;

	exit $exitVal;
}

format STDOUT = 
=============================================================================
Instance: @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	$instanceName 
sqlUsername: @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	$sqlUsername 

SQL Check Sum: @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	$sqlChkSum 
SnapShot Date: @<<<<<<<<<<<<<<<<<<<<<
	$sqlSnapDate
SQL Text: @*
	$sqlText

Explain Check Sum: @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	defined($expChkSum ) ? $expChkSum : ''
Explain Plan: 
@*
	defined($explainText) ? $explainText : ''

Explain Error: @*
	defined($explainError ) ? $explainError : ''


.


