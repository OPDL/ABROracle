#!/usr/bin/perl

=head1  sqlunldr.pl

unload data from an oracle database

use 'sqlunldr.pl -help' for help on usage

=cut

use warnings;
use FileHandle;
use strict;
use File::Path;
use IO::File;
use PDBA;
use PDBA::CM;
use PDBA::GQ;
use PDBA::OPT;
use PDBA::ConfigFile;
use PDBA::LogFile;
use Getopt::Long;
use Data::Dumper;

our %optctl = ();
our %bincol = ();
our %hexcols = ();

unless ( 
	Getopt::Long::GetOptions( \%optctl, 
		"machine=s",
		"database=s",
		"username=s",
		"password=s",
		"owner=s",
		"directory=s",
		"dateformat=s",
		"multibyte!",
		"header!",
		"debug!",
		"schemadump!",
		"longlen=i",
		"rowlimit=i",
		"table=s@",
		"bincol=s" => \%bincol,
		"fieldsep=s",
		"quotechar=s",
		"sysdba!",
		"sysoper!",
		"z","h","help"
	)
) { Usage(1); }

for my $table ( keys %bincol ) {
	my @bincols = split(/\,/,$bincol{$table});
	$hexcols{uc($table)} = \@bincols;
}

#print Dumper(\%optctl);
#print Dumper(\%hexcols);
#for my $hexdumpcol ( @{$hexcols{XML_DATA}} ) {
	#print "hexdumpcol: $hexdumpcol\n";
#}
#exit;

our($database, $username, $password, $connectionMode);

$connectionMode = '';
if ( $optctl{sysoper} ) { $connectionMode = 'SYSOPER' }
if ( $optctl{sysdba} ) { $connectionMode = 'SYSDBA' }

Usage(2) unless $optctl{machine};
Usage(3) unless $optctl{database};
Usage(4) unless $optctl{username};
Usage(5) unless $optctl{owner};
$optctl{longlen} = 65535 unless $optctl{longlen};

if ( $optctl{h} || $optctl{z} || $optctl{help} ) {
	Usage(0);
}

if ( $optctl{schemadump} ) {
	$optctl{table} = ['SCHEMADUMP']; 
} else {
	Usage(6) unless $optctl{table};
}

# default hdr to off
$optctl{header} ||= 0;

my $castFunction = '';
if ( $optctl{multibyte} ) {
	$castFunction = 'utl_raw.cast_to_nvarchar2';
} else {
	$castFunction = 'utl_raw.cast_to_varchar2';
}

my $quoteChar = $optctl{quotechar} ||= q{"};
# set quotechar empty if 'none'
$quoteChar =~ s/^none$//i;

my $fieldSep = $optctl{fieldsep} ||= q{,};
my $internalFieldSep = qq{${quoteChar}${fieldSep}${quoteChar}};

$username=$optctl{username};
$database = $optctl{database};

# lookup the password if not on the command line
if ( defined( $optctl{password} ) ) {
	$password = $optctl{password};
} else {

	if (
		! defined($optctl{machine})
		|| ! defined($optctl{database})
		|| ! defined($optctl{username})
	) { Usage(7) }

	$password = PDBA::OPT->pwcOptions (
		INSTANCE => $optctl{database},
		MACHINE => $optctl{machine},
		USERNAME => $optctl{username}
	);
}

# create the working directory
unless ( $optctl{directory} ) {
	$optctl{directory} = qq{$optctl{owner}.dump};
}

# create directory path if it doesn't exist
-d $optctl{directory} || File::Path::mkpath([$optctl{directory}]);

my $dbh = new PDBA::CM(
	DATABASE => $optctl{database},
	USERNAME => $optctl{username},
	PASSWORD => $password,
	MODE => $connectionMode,
);

$dbh->{LongReadLen} = $optctl{longlen};

# set Oracle NLS date format
if ( $optctl{dateformat} ) {
	$dbh->do(qq{alter session set nls_date_format = '$optctl{dateformat}'} );
}

my $tableHash = new Tables($dbh, \%optctl);

if ( $optctl{debug} ){
	print "tables: ", join(':', keys %{$tableHash}), "\n";
	for my $table (  keys %{$tableHash} ){
		print "TABLE: $table  FILE: $tableHash->{$table}\n";
	}
}

# print console info immediately
autoflush STDOUT 1;

my $sth;

# take a dump
for my $table ( keys %{$tableHash} ){

	print "Table: $table\n";

	my $tobj = new PDBA::GQ($dbh, qq{$optctl{owner}\.$table},
		{
			WHERE => $optctl{rowlimit} 
				? qq{rownum <= $optctl{rowlimit}}
				: "1=1",
		}
	);

	my $colOrder = $tobj->getColumns;

	# get a list of the columns in the correct order for printing a header
	# and for the control file
	my @columns = sort { $colOrder->{$a} <=> $colOrder->{$b} } keys %{$colOrder};

	my $dumpFile = $optctl{directory} . '/' . $tableHash->{$table};
	open(DUMP, "+> $dumpFile") || die "could not create file $dumpFile - $!\n";

	if ( $optctl{header} ) {
		print DUMP join($fieldSep,@columns),"\n";
	}

	# create the ctl and par files
	Tables->createCtl( 
		TABLE => $table, 
		COLUMNS => \@columns, 
		DUMPFILE => $tableHash->{$table},
		DIRECTORY => $optctl{directory},
		SCHEMA => $optctl{owner},
		HEXCOLS => \@{$hexcols{$table}},
		COLORDER => $colOrder,
		QUOTE_CHAR => $quoteChar,
		FIELD_SEP => $fieldSep,
	);

	# turn warnings off here so that warnings are not
	# reported for null columns when printed
	# comment it out to see what I mean
	no warnings;
	while ( my $ary = $tobj->next([]) ) {
		# change column to hex if specified as binary via -bincol arg
		if ( exists $hexcols{$table} ) {
			for my $hexdumpcol ( @{$hexcols{$table}} ) {
				$ary->[$colOrder->{uc($hexdumpcol)}] = uc(unpack("H*",$ary->[$colOrder->{uc($hexdumpcol)}]));
			}
		}
		print DUMP $quoteChar . join($internalFieldSep,@{$ary}) . qq{$quoteChar\n};
		if ( $optctl{debug} ) {
			print "ROW: " . q{'} . join(q{','},@{$ary}) . qq{'\n};
		}
	}
	use warnings;
	close DUMP;
}

$dbh->disconnect;

sub Usage {

	my $exitVal = shift;
	use File::Basename;
	my $basename = basename($0);
	print qq{
$basename

usage: $basename - SQL data unloader for Oracle 

   $basename -database <database> -username <userid> -password <password> \
     -directory <data unload directory> \
     -header|noheader \
     -owner <schema owner> \
     -table <table1,table2,table3,...)


-machine         database server
-database        database name
-username        user to login as
-password        password for login user
-owner           owner of tables to dump

-directory       directory to unload data into
                 will default to <owner>.dump 

-dateformat      Oracle NLS date format - optional
-header|noheader should first line include column names?

-table           table to dump.  may be repeated as many
                 times as necessary.

-schemadump      dump entire schema of <owner>
                 will ignore -table settings

-rowlimit        limit number of rows returned

-multibyte       use utl_raw.cast_to_nvarchar2 to multi byte 
                 character sets

-fieldsep        the character used to separate fields
                 in a record. defaults to a comma ,
                 you will likely need to escape this character 
                 if used.  eg.  -fieldsep \\|

-quotechar       the quote character used to enclose each field.
                 the default is to use double quotes "".
                 use 'none' to avoid quoting fields.

-longlen         if longs are in the table, set this
                 to the maximum length you want.
                 defaults to 65535

-bincol          use to specify columns that should be dumped
                 in hex format.  columns with binary data tend
                 to cause problems in text dumps.
                 e.g. -bincol <table_name>=<column_name,column_name,...>

   $basename -database orcl -username system -password manager \\
   -owner scott -directory scott.tables \\
   -quotechar none \\
   -header \\
   -table emp \\
   -table dept \\
   -table sales

   $basename -database orcl -username system -password manager \\
   -owner scott \\
   -fieldsep \\| \\
   -dateformat 'mm/dd/yyyy' \\
   -header \\
   -schemadump \\
   -bincol xml_data=payload,header,authorization \\
   -bincol app_notes=text


};

	exit $exitVal ? $exitVal : 0;
}


package Tables;

sub new {

	my $pkg = shift;
	my $class = ref($pkg) || $pkg;

	my ( $dbh, $optionHash ) = @_;

	my $tableHash;
	if ( grep(/^SCHEMADUMP$/, @{$optionHash->{table}} ) ) {
		# get all tables of owner

		my $tquery = new PDBA::GQ ( $dbh, 'all_tables',
			{
				COLUMNS => [qw{table_name}],
				WHERE => qq{owner = ?},
				BINDPARMS => [uc($optionHash->{owner})],
			}
		);

		my @tableArray; 
		while( my $ary = $tquery->next([]) ) {
			push(@tableArray, $ary->[0]);
		}
		$tableHash = setTables(\@tableArray);
	} else {
		$tableHash = setTables(\@{$optionHash->{table}});
	}

	bless $tableHash, $class;
	return $tableHash;

}


=head1 setTables

  make a neat hash of the form TABLE_NAME => 'table_name.dump'
  all table names upper case, all file names lower case
  for dump file names - Perl is awesome

=cut


sub setTables {
	my ($tableArray) = shift;

	my %tables = map(
		split(/:/, $_), 
		map( 
			$_.':'.lc($_).'.txt', 
			split(
				/:/,
				uc(join(':',@{$tableArray}))
			)
		)
	);

	if ( $optctl{debug} ) {	
		use Data::Dumper;
		print Dumper(\%tables);
	}

	my $hashRef = \%tables;
	return $hashRef;
}


sub createCtl {
	my($self,%args) = @_;

	my @columns = @{$args{COLUMNS}};
	my %colOrder = %{$args{COLORDER}};

	if ( $args{HEXCOLS} ) {
		for my $hexdumpcol ( @{$args{HEXCOLS}} ) {
			$columns[$colOrder{uc($hexdumpcol)}] = 
				$columns[$colOrder{uc($hexdumpcol)}] .
				qq{ "$castFunction(:$columns[$colOrder{uc($hexdumpcol)}])"};
		}
	}

	my $ctlFile = $args{DIRECTORY}. '/' . lc($args{TABLE}) . '.ctl';
	my $ctlFh = new IO::File();
	$ctlFh->open("> $ctlFile") || die "cannot create file $ctlFile - $!\n";
	$ctlFh->print("load data\n");
	$ctlFh->print("infile '$args{DUMPFILE}'\n");
	$ctlFh->print("into table $args{TABLE}\n");
	$ctlFh->print(qq{fields terminated by '$args{FIELD_SEP}' } );
	if ( $args{QUOTE_CHAR} ) {
		$ctlFh->print(qq{ optionally enclosed by '$args{QUOTE_CHAR}'}. "\n");
	} else {
		$ctlFh->print("\n");
	}
	$ctlFh->print("(\n");
	$ctlFh->print( "\t" . join(",\n\t",@columns) . "\n");
	$ctlFh->print(")\n");
	$ctlFh->close;
	

	my $parFile = $args{DIRECTORY}. '/' . lc($args{TABLE}) . '.par';
	my $parFh = new IO::File();
	$parFh->open("> $parFile") || die "cannot create file $parFile - $!\n";
	$parFh->print("userid = $args{SCHEMA}\n");
	$parFh->print("control = " . lc($args{TABLE}) . ".ctl\n");
	$parFh->print("log = " . lc($args{TABLE}) . ".log\n");
	$parFh->print("bad = " . lc($args{TABLE}) . ".bad\n");
	$parFh->close;
	
}


