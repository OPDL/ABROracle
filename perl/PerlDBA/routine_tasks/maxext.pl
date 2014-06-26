#!/usr/bin/perl 

# maxext.pl
# locate objects in the database that that are near
# maxextents or will not be able to extend
#

use FileHandle;
use DBI;
use PDBA;
use PDBA::CM;
use PDBA::GQ;
use PDBA::OPT;
use PDBA::ConfigFile;
use strict;
use warnings;
use File::Temp qw{:POSIX};

use Carp;
#require Addresses;
use Getopt::Long;

my %optctl = ();

Getopt::Long::GetOptions(
	\%optctl, 
	"machine=s",
	"database=s",
	"username=s",
	"password=s",
	"email!",
	"silent!",
	"help"
);

usage(1) if $optctl{help};

my  $conf = new PDBA::ConfigLoad( FILE => 'maxext.conf');

my($db, $username, $password);

if ( ! defined($optctl{database}) ) {
	warn "database required\n";
	usage(1);
}
$db=$optctl{database};

if ( ! defined($optctl{username}) ) {
	warn "username required\n";
	usage(1);
}

$username=$optctl{username};

# lookup the password if not on the command line
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

my $systemDate = PDBA->sysdate($dbh, NLS_DATE_FORMAT => 'yyyy/mm/dd hh24:mi');
my $globalName = PDBA->globalName($dbh);

my $maxExtSql= qq{select
	s.owner segment_owner
	, s.segment_name
	, s.segment_type
	, s.tablespace_name
	, s.extents extent_count
	, decode( sign( 100000 - s.max_extents),
		-1, lpad('UNLIMITED',14),
		0, lpad('UNLIMITED',14),
		1, to_char(s.max_extents,'9,999,999,999')
	) max_extents
	, decode( sign( 100000 - ( s.max_extents - s.extents ) ),
		-1, lpad('UNLIMITED',14),
		0, lpad('UNLIMITED',14),
		1, to_char(s.max_extents - s.extents, '9,999,999,999')
	) num_extents_available
	, s.next_extent
	, f.max_bytes_free
	, s.partition_name
from dba_segments s, 
(
	select t.tablespace_name,  max(nvl(f.bytes,0)) max_bytes_free
	from dba_free_space f, dba_tablespaces t
	where t.tablespace_name = f.tablespace_name(+)
	group by t.tablespace_name
) f
where s.tablespace_name = f.tablespace_name
	and 
	(
		(s.max_extents - s.extents) < ?
		or 
		s.next_extent > f.max_bytes_free
	)
	and segment_type not in ('CACHE','TEMPORARY', 'SPACE HEADER')
order by 1,2,3

};

my $sth = $dbh->prepare($maxExtSql);

use vars qw($rv);
my $rv = $sth->execute($maxext::config{minExtentsCanExtend}) 
	|| die "error with statement $maxExtSql \n";

my  $tmpfile = tmpnam();
#print "TMPFILE: $tmpfile\n";

open(FILE,"> $tmpfile") || die "cannot create $tmpfile\n";

format_name FILE "FILE";
format_top_name FILE "FILE_TOP";

my $ary = {};
*OLD_STDOUT= *STDOUT;
*STDOUT = *FILE;
while(  $ary = $sth->fetchrow_hashref ) { 

	my($totalBlocks, $totalBytes, $unusedBlocks, $unusedBytes ) = (0,0,0,0);
	my($lastUsedExtentFileId, $lastUsedExtentBlockId, $lastUsedBlock ) = (0,0,0);
	my $maxVarSize = 40;

	my $spaceCsr = $dbh->prepare(q{
		BEGIN
			DBMS_SPACE.UNUSED_SPACE(
				:segment_owner 
				, :segment_name
				, :segment_type
				, :total_blocks
				, :total_bytes
				, :unused_blocks
				, :unused_bytes 
				, :last_used_extent_file_id
				, :last_used_extent_block_id
				, :last_used_block
				, :partition_name
			);
		END;
	});

	# in parms
	$spaceCsr->bind_param(":segment_owner", $ary->{SEGMENT_OWNER});
	$spaceCsr->bind_param(":segment_name", $ary->{SEGMENT_NAME});
	$spaceCsr->bind_param(":segment_type", $ary->{SEGMENT_TYPE});
	$spaceCsr->bind_param(":partition_name", $ary->{PARTITION_NAME});

	# in-out parms
	$spaceCsr->bind_param_inout(":total_blocks", \$totalBlocks, $maxVarSize);
	$spaceCsr->bind_param_inout(":total_bytes", \$totalBytes, $maxVarSize);
	$spaceCsr->bind_param_inout(":unused_blocks", \$unusedBlocks, $maxVarSize);
	$spaceCsr->bind_param_inout(":unused_bytes", \$unusedBytes, $maxVarSize);
	$spaceCsr->bind_param_inout(":last_used_extent_file_id", \$lastUsedExtentFileId, $maxVarSize);
	$spaceCsr->bind_param_inout(":last_used_extent_block_id", \$lastUsedExtentBlockId, $maxVarSize);
	$spaceCsr->bind_param_inout(":last_used_block", \$lastUsedBlock, $maxVarSize);

	$spaceCsr->execute;

	my $pctBlocksFree = $unusedBlocks / $totalBlocks * 100;
	#warn "\nPCT BLOCKS FREE: $pctBlocksFree \n\n";

	if ( $pctBlocksFree < $maxext::config{minPctBlocksUnused} ) {
		write;
	}
}

open(FILE,"$tmpfile") || die "cannot open $tmpfile\n";
my @rpt = <FILE>;
close FILE;
unlink $tmpfile;

*STDOUT = *OLD_STDOUT;
print 'RPT:', join('',@rpt) unless $optctl{silent};

if ( @rpt && $optctl{email} ) {
	my $subject = "Low Space Report for $optctl{database} at " . $systemDate;
	no warnings;
	PDBA->email(\@maxext::emailAddresses, join('',@rpt), $subject);
}

$sth->finish;
$dbh->disconnect;

#### 

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
-email         send email to DBA if report is generated
-silent        do not print report to screen

/;
	exit $exitVal;
};


## formats

format FILE_TOP =

Database Objects That Cannot Extend                                Page:   @####
$%
Database: @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<                Date: @<<<<<<<<<<<<<<<<<<<<
$globalName, $systemDate

@<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<< @<<<<<<<<<  
'','','','NUMBER'
@<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<< @<<<<<<<<< @<<<<<<<<<<
'','','','EXTENTS','NEXT'
@<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<< @<<<<<<<<< @<<<<<<<<<< @<<<<<<<<<<<<<<
'OWNER','NAME','TYPE','AVAILABLE','EXTENT SIZE','MAX BYTES FREE'
============== ============================== ========== ========== =========== ===============

.


format FILE =
@<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<< @<<<<<<<<< @########## @#############
$ary->{SEGMENT_OWNER} , $ary->{SEGMENT_NAME} , $ary->{SEGMENT_TYPE} , $ary->{NUM_EXTENTS_AVAILABLE} , $ary->{NEXT_EXTENT} , $ary->{MAX_BYTES_FREE}
.


