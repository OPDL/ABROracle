
package PDBA;

require 5.005;
 $VERSION = '1.0';

use Carp;

=head1 Perl DBA Toolkit

$Author: jkstill $
$Date: 2002/04/25 06:19:53 $
$Id: PDBA.pm,v 1.27 2002/04/25 06:19:53 jkstill Exp $

Simple global admin tasks for PDBA toolkit

=head1 Functions

=head2 pathsep

determines the correct path separator.

returns ';' for Windows/NT/Win2k

returns ':' for unix

=cut

sub pathsep {
	my ($self) = @_;
	use Config;
	return PDBA->osname() eq 'MSWin32' ? ';' : ':';
}

=head2 osname

determines the os - returns 'MSWin32' or 'unix'

  if ( 'unix' eq PDBA->osname() ) {
     #do some unix stuff...
  } else {
     #do some windows stuff...
  }

=cut

# returns MSWin32 or unix
sub osname {
	my ($self) = @_;
	use Config;
	return $Config{osname} eq 'MSWin32' ? 'MSWin32' : 'unix';
}

=head2 pdbaHome

returns the directory for PDBA_HOME.

e.g. $myHome = PDBA->pdbahome();

On unix systems, it will return the environment variable 
PDBA_HOME. If PDBA_HOME is not set, it returns $HOME.

On Win32 systems, it checks for the PDBA_HOME value in the
PDBA registry key.  If it isn't set, it dies.  Sorry, but
it's not always a good idea to assume a location on Win32.

PDBA_HOME can be set in the Win32 registry with the script
reg_pdba_home_create.pl

=cut

sub pdbaHome {
	my ($self) = @_;

	if ( 'unix' eq PDBA->osname() ) {

		require File::Spec;

		my $pdbaHome = $ENV{PDBA_HOME} ? $ENV{PDBA_HOME} : $ENV{HOME} . q{/pdba};
		$pdbaHome = File::Spec->canonpath($pdbaHome);
		# must be a directory, must have execute perms
		# dir exists, but no execute perms
		# croak so it can be fixed

		if ( -d $pdbaHome && !-x $pdbaHome ) {
			croak "incorrect permissions for $pdbaHome\n";
		}

		# if it's a file, croak and complain
		if ( -f $pdbaHome ) {
			croak "cannot create $pdbaHome - it's a regular file\n";
		}

		# directory exists and has execute bit
		if ( -d $pdbaHome && -x $pdbaHome ) {
			$ENV{PDBA_HOME} = $pdbaHome;
			return $pdbaHome;
		}

		if ( !-d $pdbaHome ){
			require File::Path;
			File::Path::mkpath([$pdbaHome]);
			if ( -d $pdbaHome ){
				$ENV{PDBA_HOME} = $pdbaHome;
				return $pdbaHome;
			} else { croak "failed to create $pdbaHome\n" }
		}

		# should never get to this line
		croak "Failure setting PDBA_HOME\n";

	} else {
		eval q{use Win32::TieRegistry ( Delimiter=>q{/}, ArrayValues => 0 )};
		if ($@) {
			croak "could not load Win32::TieRegistry in PDBA\n";
		} else {
			no warnings;
			$pdbaKey= $Registry->{"LMachine/Software/PDBA/"};
			use warnings;
			$ENV{PDBA_HOME}  = $pdbaKey->{'/PDBA_HOME'};
			unless ( $ENV{PDBA_HOME} ) { croak "PDBA_HOME not set in registry\n" }

			if ( !-d $ENV{PDBA_HOME} ){
				require File::Path;
				File::Path::mkpath([$ENV{PDBA_HOME}]);
				if ( -d $ENV{PDBA_HOME} ){
					return $ENV{PDBA_HOME};
				} else { croak "failed to create $ENV{PDBA_HOME}\n" }
			}

			return $ENV{PDBA_HOME};
		}
	}
}

=head2 oracleHome

use oracleHome to retrieve the value for ORACLE_HOME.

On unix the value of $ENV{ORACLE_HOME} is returned.

On Win32 the value of ORACLE_HOME is retrieved from the registry.

The returned value is undef if ORACLE_HOME is not set.

=cut 

sub oracleHome {
	my ($self) = @_;

	if ( 'unix' eq PDBA->osname() ) {

		# just return ORACLE_HOME
		return defined $ENV{ORACLE_HOME} ? $ENV{ORACLE_HOME} : undef;

	} else {
		eval q{use Win32::TieRegistry ( Delimiter=>q{/}, ArrayValues => 0 )};
		if ($@) {
			croak "could not load Win32::TieRegistry in PDBA::oracleHome\n";
		} else {
			no warnings;
			$oraKey= $Registry->{"LMachine/Software/ORACLE/"};
			use warnings;
			$ENV{ORACLE_HOME}  = $oraKey->{'/ORACLE_HOME'};
			return defined $ENV{ORACLE_HOME} ? $ENV{ORACLE_HOME} : undef;
		}
	}
}

=head2 email

Used to send email from your scripts. 

Takes 3 arguments, the first 2 are required.

The first argument should be a reference to a list
of addresses. The second argument is the message.

The third argument is the subject and is not required.
It will default to "PDBA Message" if not set.

  my @addresses = ('lell@oracle.com','scott@tiger.com');
  my $message = "this is a test email";
  my $subject = "testing";

  if ( PDBA->email(\@addresses,$message,$subject) ) {
     print "Email Sent\n";
  } else {
     print "Error Sending Email\n";
  }

The pdba.conf file must be configured for this to work.

=cut

sub email {


	my ($self, $addressRef, $msg, $subject) = @_;
	$subject = "PDBA Message" unless $subject;

	use Mail::Sendmail;

	unless ( exists $pdbaparms::emailParms{mailServer} ) {
		PDBA->initialize();
	}

	#print "server: $pdbaparms::emailParms{mailServer}\n";
	#print "from  : $pdbaparms::emailParms{fromAddress}\n";

	my %mail = (
		To => join(',', @$addressRef),
		From => $pdbaparms::emailParms{fromAddress},
		Subject => $subject,
		Message =>  $msg,
		smtp => $pdbaparms::emailParms{mailServer}
	);

	if ( sendmail(%mail) ) { return 1 } 
	else { 
		carp "$Mail::Sendmail::error\n";
		return 0;
	}

}

# should not need to call this explicitly
# as it is called internally
sub initialize {
	
	my ($self) = @_;
	require PDBA::ConfigFile;
	my $p = new PDBA::ConfigLoad(FILE => "pdba.conf");
	unless ( $p ) { croak "pdba.conf not setup for PDBA\n" }
	unless ( exists $pdbaparms::emailParms{fromAddress}){
		$pdbaparms::emailParms{fromAddress} = 'pdba@somewhere.com';
	}
	# if we still don't have a server, then die
	unless ( exists $pdbaparms::emailParms{mailServer} ) {
		croak "email server not set in pdba.conf\n";
	}
}

=head2 timestamp

return a timestamp suitable for logging
i.e. will sort properly

  my $timestamp = PDBA::timestmp();

=cut

sub timestamp {
	my ($self) = @_;
	# from the TimeDate CPAN distribution
	use Date::Format;
	my @lt=localtime(time);
	return strftime(q{%Y%m%d%H%M%S},@lt);
}


=head2 formatSql

format a scalar containing sql

It may not be pretty, but it will execute
used in sxp for running explain plan

=cut


sub formatSql {
	my ($self, $sqlRef) = @_;

	no warnings;

	$$sqlRef =~ s#,#\n\t\,#gmo;

	$$sqlRef =~ s/([-]{2}?)/\n$1/gomix;

	$$sqlRef =~ s/
		(--\s*(([\w]+)\s+))?
		(?=
			and\s+[\w+\.+]+\s*(\=|between|\<\>|\!\=)
			|or\s+[\w+\.+]+\s*(\=|between|\<\>|\!\=)
			|where\s+[\w+\.+]+\s*(\=|between|\<\>|\!\=)
			|select
			|union
			|minus
			|intersection
			|from
			|where
			|order\s+by
			|group\s+by
		)
	/\n$5/gomix;
	
	$$sqlRef =~ s/(\s+
		--\s*where
		|--\s*from
		|--\s*group\s+by
		|--\s*order\s+by
		|--\s*select
		|--\s*union
		|--\s*minus
		|--\s*intersection
		#|select
		#|union
		#|minus
		#|intersection
		#|from
		#|where
		#|order\s+by
		#|group\s+by\s+
	)/\n$1/gomix;

}


=head2 getXP


retrieve 'explain plan' output from plan_table, format into a 
single string and return a scalar ref object


=cut

sub getXP {

	my ($self, $dbh, %args ) = @_;

	my $planSql = qq{
		SELECT
			nvl(position,0) position,
			lpad('  ',2*(level-1))||operation || ' ' || options operation,
			object_name,
			nvl(cost,0) cost,
			lpad(
				decode(cardinality,null,'  ',
					decode( sign(cardinality-1000),
						-1, cardinality||' ',
						decode(sign(cardinality-1000000),
							-1, trunc(cardinality/1000)||'K',
							decode( sign(cardinality-1000000000),
								-1, trunc(cardinality/1000000)||'M',
								trunc(cardinality/1000000000)||'G'
							)
						)
					)
				), 10, ' ' 
			) total_rows,
		nvl(bytes,0) bytes,
		optimizer
		FROM plan_table
		START WITH id = 0 and statement_id = '$args{STATEMENT_ID}'
		CONNECT BY PRIOR id = parent_id AND statement_id = '$args{STATEMENT_ID}'
		ORDER BY id, position
	};
	# get the output
	my $sth = $dbh->prepare($planSql);
	$sth->execute;

	my @xp=();

	my @hdr = qw{POS OPERATION OBJECT_NAME COST TOTAL_ROWS BYTES OPTIMIZER};
	push @xp, sprintf("%3s %-45s %-30s %6s %10s %8s %10s",@hdr);
	push @xp, '-' x 128;

	while ( my $ary = $sth->fetchrow_arrayref ) {
		my @row = map( defined($_) ? $_ : '', @{$ary});
		push @xp, sprintf("%3d %-45s %-30s %6d %10s %8d %10s",@row);
	}

	my $output = join("\n",@xp);

	return bless \$output, $self;

}


=head2 createPlanTable


creates the PLAN_TABLE table needed for explain plan


=cut

sub createPlanTable {

	my ($dbh) = @_;
# create a plan table in users schema

	my $sql = q {
		create table PLAN_TABLE (
			statement_id 	varchar2(30),
			timestamp    	date,
			remarks      	varchar2(80),
			operation    	varchar2(30),
			options       	varchar2(30),
			object_node  	varchar2(128),
			object_owner 	varchar2(30),
			object_name  	varchar2(30),
			object_instance numeric,
			object_type     varchar2(30),
			optimizer       varchar2(255),
			search_columns  number,
			id		numeric,
			parent_id	numeric,
			position	numeric,
			cost		numeric,
			cardinality	numeric,
			bytes		numeric,
			other_tag       varchar2(255),
			partition_start varchar2(255),
			partition_stop  varchar2(255),
			partition_id    numeric,
			other		long,
			distribution    varchar2(30))
	};

	$dbh->do($sql);

}

=head2 chkForPlanTable

check for the existance of the PLAN_TABLE table.

if not exists, call createPlanTable

=cut

sub chkForPlanTable {

	my ($self, $dbh) = @_;

	{
		local $dbh->{PrintError} = 0;
		eval {
			my $planChk = new PDBA::GQ(
				$dbh, 'plan_table'
			);
		};

		if ($@) {
			my $err = $dbh->err;
			my $errstr = $dbh->errstr;
			# 942 is 'table not found'
			if ( 942 == $err ) {
				PDBA::createPlanTable($dbh);
			} else {
				# dunno what happened
				die $errstr;
			}
		}
	}

}

=head2 rptDatePk

used in repository reports to retrieve start/end dates
and the PK values for each from PDBA_SNAP_DATES or PDBA_SXP_DATES

e.g.:

  my $rptDateHash = PDBA->rptDatePk (
     $dbh,
     TABLE => 'PDBA_SNAP_DATES',
     START_DATE => $optctl{rep_start_date},
     END_DATE => $optctl{rep_end_date},
  );


  print "start date pk: $rptDateHash->{startDatePk}\n";
  print "start date   : $rptDateHash->{startDate}\n";
  print "end   date pk: $rptDateHash->{endDatePk}\n";
  print "end   date   : $rptDateHash->{endDate}\n";


=cut


sub rptDatePk {

	my ($self, $dbh, %args) = @_;

	my $nlsDateFormat = 'mm/dd/yyyy';

	use PDBA::GQ;

	$dbh->do(qq{alter session set nls_date_format = '$nlsDateFormat' } );

	# get the start date
	# find the latest snapshot date LE the start date
	my $sd = new PDBA::GQ(
		$dbh, $args{TABLE},
		{
			WHERE => qq{ snap_date < trunc(to_date('$args{START_DATE}','$nlsDateFormat')+1) },
			ORDER_BY => "snap_date"
		}
	);

	my ($sdHash, $startDatePk, $startDate);
	my $dc = 0;
	while ( $sdHash = $sd->next ){
		$dc++;
		$startDatePk = $sdHash->{PK};
		$startDate = $sdHash->{SNAP_DATE};
	}

	# old start date, no rows retrieved
	unless ( $dc ) {
		$sd = new PDBA::GQ(
			$dbh,$args{TABLE},
			{
				ORDER_BY => "snap_date"
			}
		);
		$sdHash = $sd->next;
		$startDatePk = $sdHash->{PK};
		$startDate = $sdHash->{SNAP_DATE};
		$sd->finish;
	}

	# get the end date
	# find the latest snapshot date LE the end date
	my $ed = new PDBA::GQ(
		$dbh,$args{TABLE},
		{
			WHERE => qq{ snap_date <= trunc(to_date('$args{END_DATE}','$nlsDateFormat')+1) },
			ORDER_BY => "snap_date"
		}
	);

	my ($edHash, $endDatePk, $endDate);
	while ( $edHash = $ed->next ){
		$endDatePk = $edHash->{PK};
		$endDate = $edHash->{SNAP_DATE};
	}

	my %rptDatePk = (
		startDatePk => $startDatePk,
		startDate => $startDate,
		endDatePk => $endDatePk,
		endDate => $endDate,
	);

	return bless \%rptDatePk, $self;
}

=head1 globalName

return the global_name from an Oracle database

  my $globalName = PDBA->globalName($dbh);

=cut

sub globalName {
	my ($self, $dbh) = @_;

	use PDBA::GQ;

	my $gn = new PDBA::GQ($dbh,'global_name');
	my $gnHash = $gn->next;
	my $globalName = $gnHash->{GLOBAL_NAME};
	undef $gn;
	undef $gnHash;
	return $globalName;

}

=head1 sysdate

return the value of the Oracle SYSDATE function

  my $sysdate = PDBA->sysdate($dbh);

  my $sysdate = PDBA->sysdate($dbh, NLS_DATE_FORMAT => 'MON-DD-YYYY');

=cut


sub sysdate {
	my ($self, $dbh, %args) = @_;

	use PDBA::GQ;

	$args{NLS_DATE_FORMAT} ||= 'mm/dd/yyyy';

	my $sd = new PDBA::GQ($dbh,'dual', 
		{ 
			COLUMNS => [qq{to_char(sysdate,'$args{NLS_DATE_FORMAT}') my_sysdate}] 
		} 
	);
	my $sdHash = $sd->next;
	my $sysdate = $sdHash->{MY_SYSDATE};
	undef $sd;
	undef $sdHash;
	return $sysdate;

}

=head1 oracleVersion

return the oracle version as a string of digits

  my $version = PDBA->oracleVersion($dbh);

=cut


sub oracleVersion {
	my ($self, $dbh) = @_;

	use PDBA::GQ;

	my $ov = new PDBA::GQ($dbh,'product_component_version', 
		{ 
			COLUMNS => ['version'],
			WHERE => q{product like 'Oracle%'}
		} 
	);
	my $ovHash = $ov->next;
	my $oracleVersion = $ovHash->{VERSION};

	$oracleVersion =~ s/\.//g;
	return $oracleVersion;

}


1;


