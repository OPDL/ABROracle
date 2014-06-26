
package PDBA::DBA;

=head2 PDBA::DBA

=head1 Common DBA tasks

use this module to create and drop users, drop objects
in the database, retrieve information on objects in
the database.

=cut


use PDBA;
use PDBA::GQ;
use PDBA::CM;
use Carp;
use strict;
use warnings;
use diagnostics;

require 5.005;
my $VERSION = '0.01';

my $dbh;
# line terminator
# defaults to a single line feed

=head1 The DBA dispatch tables


By means of the hash arrays %drop, %create and %info, the create(),
drop() and info() methods know which internal methods to call based
on the attributes they receive.

Here's an example of how it works.  If you are creating a new user,
you would set the OBJECT_TYPE attribute to 'user'.

my $newUser = new PDBA::DBA(
  DBH => $dbh,
  OBJECT_TYPE => 'user',
  OBJECT => 'alicia',
  PASSWORD => 'generate',
  DEFAULT_TABLESPACE => 'users',
  TEMPORARY_TABLESPACE => 'temp',
  PRIVS => ['create session', 'resource', 'connect', 'oem_monitor'],
  QUOTAS => { users => 'unlimited', tools => '10m', indx => 'unlimited'},
);

This information can now all be referenced by the object $newUser.

When you invoke the create method like this:

  $newUser->create;

The create() method first looks in the %create dispatch table to see
if there is an entry for 'user'.  If it exists, that entry will be a
reference to a method.  create() will call that method, passing all of
it's own parameters to it, which the called method will use to carry 
out it's operations.

Here's the entire create() method.

  sub create {
	  my $self = shift;
	  my $objectType = lc($self->{OBJECT_TYPE});
	  die "$objectType invalid for 'create'\n" unless $create{$objectType};
	  $create{$objectType}->($self);
  }

Deceptively simple, but actually does quite a lot.

=cut

my %create = (
	user => \&_createUser,
	duplicate_user => \&_dupUser,
	password => \&_newPassword,
	table => \&_createTable,
	index => \&_createIndex,
	view => \&_createView,
	sequence => \&_createSequence,
	role => \&_createRole,
);

my %drop = (
	user => \&_dropUser,
	table => \&_dropTable,
	index => \&_dropGeneric,
	package => \&_dropGeneric,
	procedure => \&_dropGeneric,
	function => \&_dropGeneric,
	role => \&_dropGeneric,
	view => \&_dropGeneric,
);

my %info = (
	user => \&_userInfo,
	privs => \&_privInfo,
	# this need implemented now!
	table => \&_tableInfo,
	tablespace => \&_tablespaceInfo,
	index => \&_indexInfo,
	#################################
	# from here ...
	freespace => \&_freespaceInfo,
	# to here.
	#################################
	tbsquota => \&_tbsQuota,
	role => \&_roleInfo,
	privsbygrantor => \&_grantorPrivsInfo,
);

my %ddl = (
	user => \&_userDdl,
	role => \&_roleDdl,
	privsbygrantor => \&_grantorPrivsDdl,
);

=head1 new

create a new DBA object.

e.g.

  my $dupUser = new PDBA::DBA(
    DBH => $dbh,
    OBJECT => 'testuser',
    OBJECT_TYPE => 'duplicate_user'
  );

=cut

sub new {
	my $pkg = shift;
	my $class = ref($pkg) || $pkg;

	my (%args) = @_;
	$dbh = $args{DBH};

	# configuration file not yet implemented in this module
	#my $conf = new PDBA::ConfigLoad( FILE => 'dba.conf' ); 

	croak "Attribute OBJECT_TYPE is required in $class::new\n" unless $args{OBJECT_TYPE};
	croak "Attribute OBJECT is required in $class::new\n" unless $args{OBJECT};

	return bless \%args, $class;
}

=head1 create

depending on the parameters, will create a new object.

e.g.

  my $dupUser = new PDBA::DBA(
    DBH => $dbh,
    OBJECT => 'testuser',
    OBJECT_TYPE => 'duplicate_user'
  );
 
  $dupUser->create;

=cut


sub create {
	my $self = shift;
	my $objectType = lc($self->{OBJECT_TYPE});

	croak "$objectType invalid for 'create'\n" unless $create{$objectType};

	$create{$objectType}->($self);
}

=head1 drop

drop an object.

used to drop tables, indexes, users and stored procedures

e.g. 

  my $dropObject = new PDBA::DBA (
    DBH => $dbh,
    OWNER => 'SCOTT',
    OBJECT => 'EMPT',
    OBJECT_TYPE => 'TABLE'
  );
  $dropObject->drop;
 
=cut

sub drop {
	my $self = shift;
	my $objectType = lc($self->{OBJECT_TYPE});

	croak "$objectType invalid for 'drop'\n" unless $drop{$objectType};

	$drop{$objectType}->($self);
	
}

=head1 info

retrieve information on a database object

e.g. retrieve all known information about the USERS tablespace

  my $tbsInfo = new PDBA::DBA (
    DBH => $dbh,
    OBJECT => 'USERS',
    OBJECT_TYPE => 'TABLESPACE'
  );
  $tbsInfo->info;

  
  the information can then be retrieved via the same names that are used
  to define it in the database.  if the data is multipart, it will be 
  stored in an array.

  print "PCT Increase for USERS is $tbsInfo{PCT_FREE}\n";

  for my $file ( @{$tbsInfo{FILE_NAME} ) {
    print "USERS datafile $file\n";
  } 


=cut

sub info {
	my $self = shift;
	my $objectType = lc($self->{OBJECT_TYPE});

	croak "$objectType invalid for 'info'\n" unless $info{$objectType};

	$info{$objectType}->($self);
	
}

sub ddl {
	my $self = shift;
	my $objectType = lc($self->{OBJECT_TYPE});

	croak "$objectType invalid for 'ddl'\n" unless $ddl{$objectType};

	$ddl{$objectType}->($self);
}

=head1 _dupUser

duplicate a user with same default
and temp tablespaces, privileges, etc.

e.g. 

  my $dupUser = new PDBA::DBA(
    DBH => $dbh,
    OBJECT => 'sourceuser',
    NEW_USERNAME => 'newuser',
    OBJECT_TYPE => 'duplicate_user',
	 SYSTEM_PRIVS => 'Y',
	 TABLE_PRIVS =>'N',
	 ROLES => 'Y',
  );
 
  $dupUser->create;


 The SYSTEM_PRIVS, TABLE_PRIVS and ROLES attributes will default
 to 'Y' unless explicitly set to 'N'.

 If set to 'N', that type of privilege will not be granted.


=cut

sub _dupUser {

	my $self = shift;

	my @privParms = qw{SYSTEM_PRIVS TABLE_PRIVS ROLES};

	# assign Y to values for PRIVS that are empty
	map ( 
		$self->{$_} = $self->{$_} 
			? $self->{$_} 
			: 'Y' , 
		@privParms
	);

	# uppercase some stuff
	map ( 
		$self->{$_} = uc($self->{$_}),
		@privParms
	);

	#print "SYSTEM_PRIVS: $self->{SYSTEM_PRIVS}\n";
	#print "TABLE_PRIVS: $self->{TABLE_PRIVS}\n";
	#print "ROLES: $self->{ROLES}\n";
	
	# get user info
	my $userObj = new PDBA::DBA( 
		DBH => $dbh,
		OBJECT => $self->{OBJECT},
		OBJECT_TYPE => 'user'
	);

	my $userInfo = $userObj->info;

	# get tablespace quotas
	my $tbsObj = new PDBA::DBA( 
		DBH => $dbh,
		OBJECT => $self->{OBJECT},
		OBJECT_TYPE => 'tbsquota'
	);

	my $tbsQuotas = $tbsObj->info;

	# get user privileges
	$userObj = new PDBA::DBA( 
		DBH => $dbh,
		OBJECT => $self->{OBJECT},
		OBJECT_TYPE => 'privs'
	);

	my $privInfo = $userObj->info;

	# now that we have all this info, create the new user

	my @privs = ();
	if ( 'Y' eq $self->{SYSTEM_PRIVS} ) {
		@privs = @{$privInfo->{systemPrivs}};
	}
	if ( 'Y' eq $self->{ROLES} ) {
		push @privs, @{$privInfo->{roles}};
	}

	my $newUser = new PDBA::DBA(
		DBH => $dbh,
		OBJECT_TYPE => 'user',
		OBJECT => $self->{NEW_USERNAME},
		PASSWORD => 'generate',
		DEFAULT_TABLESPACE => $userInfo->{DEFAULT_TABLESPACE},
		TEMPORARY_TABLESPACE => $userInfo->{TEMPORARY_TABLESPACE},
		PRIVS => [@privs],
		QUOTAS => $tbsQuotas,
		PROFILE => $userInfo->{PROFILE}
	);

	eval{ $newUser->create };
	if($@) {
		croak "user $self->{NEW_USERNAME} already exists - $@ \n"
	}

	$self->{PASSWORD} = $newUser->{PASSWORD};

	# assign default roles
	if ( 'Y' eq $self->{ROLES} ) {
		$dbh->do(qq{alter user $self->{NEW_USERNAME} default role none});
		my $defRoleSql = qq{alter user $self->{NEW_USERNAME} default role } 
			. join(',', @{$privInfo->{defaultRoles}});

		$dbh->do($defRoleSql);
	}

	# assign table privs
	# must login as the owner to do this
	# just give a warning if cannot login
	use PDBA::OPT;

	if ( 'Y' eq $self->{TABLE_PRIVS} ) {
		foreach my $objectOwner ( keys %{$privInfo->{tablePrivs}} ) {
			#print "OWNER: $objectOwner\n";

			# login as owner if possible
			my $ownerPassword =  PDBA::OPT->pwcOptions (
				INSTANCE => $self->{DATABASE},
				MACHINE => $self->{MACHINE},
				USERNAME => lc($objectOwner)
			);

			if ( $ownerPassword ) {
				my $ownerDbh = new PDBA::CM(
					DATABASE => $self->{DATABASE},
					USERNAME => $objectOwner,
					PASSWORD => $ownerPassword,
					MODE => 'SYS' eq $objectOwner ? 'SYSDBA' : 'USER'
				);

				foreach my $object ( keys %{$privInfo->{tablePrivs}{$objectOwner}} ) {
					#print "\tOBJ: $object - ";
					#print join(':', @{$privInfo->{tablePrivs}{$objectOwner}{$object}}) . "\n"; 
					foreach my $privilege ( @{$privInfo->{tablePrivs}{$objectOwner}{$object}} ){
						my $grantSql = qq(grant $privilege on $object to $self->{NEW_USERNAME} );
						$ownerDbh->do($grantSql);
					}
				}
				$ownerDbh->disconnect;
			} else {
				carp "\nno password - cannot login as $objectOwner\n";
				carp "cannot assign privileges to $self->{NEW_USERNAME}\n";
			}
		}
	}
}

=head1 Creating a user: attributes

DBH => $dbh # database handle
OBJECT_TYPE => 'user'
OBJECT => 'username'
DEFAULT_TABLESPACE  => 'tablespace_name'
TEMPORARY_TABLESPACE => 'tablespace_name'
PASSWORD => 'giddyup'
PRIVS => ['create session','resource']
REVOKES => ['unlimited tablespace']
QUOTAS => { users => 'unlimited', index => '20m' }
PROFILE => 'profile_name'

e.g.

  my $newUser = new PDBA::DBA(
    DBH => $dbh,
    OBJECT_TYPE => 'user',
    OBJECT => 'alicia',
    PASSWORD => 'generate',
    DEFAULT_TABLESPACE => 'users',
    TEMPORARY_TABLESPACE => 'temp',
    PRIVS => ['create session', 'resource', 'connect', 'oem_monitor'],
    REVOKES => ['unlimited tablespace'],
    QUOTAS => { users => 'unlimited', tools => '10m', indx => 'unlimited'},
	 PROFILE => 'idle_limit',
  );

  $newUser->create;


=cut

sub _createUser {

	my $self = shift;

	if ( $self->{PASSWORD} eq 'generate' ) {
		$self->{PASSWORD} = _genPassword();
	}
	
	my $profile = undef;
	if ( defined $self->{PROFILE} ) { $profile = $self->{PROFILE} }
	else { $profile = 'DEFAULT' }

	my $sql = qq{
		create user $self->{OBJECT} 
		identified by $self->{PASSWORD}
		default tablespace $self->{DEFAULT_TABLESPACE}
		temporary tablespace $self->{TEMPORARY_TABLESPACE}
		profile $profile
	};

	$dbh->do($sql);

	if ( defined @{$self->{PRIVS}} ) {
		$sql = 'grant ' . join(',', @{$self->{PRIVS}}) . 
			' to '.  $self->{OBJECT};

		$dbh->do($sql);
	};
	
	# failure to revoke made non-fatal
	if ( defined @{$self->{REVOKES}} ) {
		$sql = 'revoke ' . join(',', @{$self->{REVOKES}}) . 
			' from '.  $self->{OBJECT};

		eval { 
			local $dbh->{PrintError} = 0;
			local $dbh->{RaiseError} = 1;
			$dbh->do($sql);
		};

		if ($@) {
			if (  $@ =~ /ORA-01952/ ) {
				carp "error revoking non-existing privileges from $self->{OBJECT}\n";
			} else {
				croak "$@\n";
			}
		}
	};
	
	if ( defined %{$self->{QUOTAS}} ) {
		for my $tbs ( keys %{$self->{QUOTAS}} ) {
			$sql = "alter user $self->{OBJECT} quota $self->{QUOTAS}{$tbs} on $tbs";
			$dbh->do($sql);
		}
	}
}

=head1 Create a new password

this is to create a suggested password
it does not change anything in the database

  my $passwdObj = new PDBA::DBA(
    DBH => $dbh,
    OBJECT => 'new_password',
    OBJECT_TYPE => 'password'
    );
  $passwdObj->create;

  print "$passwdObj->{PASSWORD}\n";

=cut

sub _newPassword {

	my $self = shift;

	$self->{PASSWORD} = _genPassword();
}



=head1 Dropping a user: attributes

DBH => $dbh # database handle
OBJECT_TYPE => 'user'
OBJECT => 'username'

e.g. 

  my $dropUser = new PDBA::DBA(
    DBH => $dbh,
    OBJECT_TYPE => 'user',
    OBJECT => 'scott'
  );

  $dropUser->drop;


When dropping a user, all tables, indexes and stored procedures 
are dropped first, then the user is dropped with the 'cascade'
option.


=cut


sub _dropUser {

	my $self = shift;
	my $sql;

	# drop tables, packages, procedures and functions first
	$self->{OBJECT} = uc($self->{OBJECT});

	use PDBA::GQ;

	my $vobj = new PDBA::GQ($dbh,'dba_objects', 
		{ 
			WHERE => 'owner = ?',
			BINDPARMS => [$self->{OBJECT}]
		}
	);

	my $arrayRowRef = $vobj->all([]);
	my $colNames = $vobj->getColumns;

	for my $row ( @$arrayRowRef ) {
		#print "PARM: $row->[$colNames->{OBJECT_NAME}]  VALUE: $row->[$colNames->{OBJECT_TYPE}]\n";
		#print "dropping $row->[$colNames->{OBJECT_NAME}]\n";
		my $dropObject = new PDBA::DBA (
			DBH => $dbh,
			OWNER => $self->{OBJECT},
			OBJECT => $row->[$colNames->{OBJECT_NAME}],
			OBJECT_TYPE => $row->[$colNames->{OBJECT_TYPE}]
		);
		$dropObject->drop;
	}

	$sql = qq{ drop user $self->{OBJECT} cascade };
	$dbh->do($sql);
}

=head1 Dropping a table: Attributes

DBH => $dbh  # database handle
OWNER => 'scott'
OBJECT => 'emp'
OBJECT_TYPE => 'table'

my $dropObject = new PDBA::DBA (
DBH => $dbh,
OWNER => $self->{OBJECT},
OBJECT => $row->[$colNames->{OBJECT_NAME}],
OBJECT_TYPE => $row->[$colNames->{OBJECT_TYPE}]
);
$dropObject->drop;

=cut

sub _dropTable {
	my $self = shift;
	my $sql = qq{drop $self->{OBJECT_TYPE} $self->{OWNER}.$self->{OBJECT} cascade constraints};
	$dbh->do($sql);
}

=head1 Dropping  indexes and stored procedures

DBH => $dbh  # database handle
OWNER => 'scott'
OBJECT => 'emp'
OBJECT_TYPE => 'package'

  my $dropObject = new PDBA::DBA (
    DBH => $dbh,
    OWNER => 'scott',
    OBJECT => 'my_package',
    OBJECT_TYPE => 'package'
  );
  $dropObject->drop;

valid values for OBJECT_TYPE:
  index
  package
  function
  procedure

=cut

sub _dropGeneric {
	my $self = shift;
	my $sql = qq{drop $self->{OBJECT_TYPE} $self->{OWNER}.$self->{OBJECT}};
	$dbh->do($sql);
}

=head1 _genPassword 

SQL to generate passwords and the subroutine to run it

called automatically when the PASSWORD attribute is set
to 'generate' when creating a new user object

e.g.

  my $newUser = new PDBA::DBA(
    DBH => $dbh,
    OBJECT_TYPE => 'user',
    OBJECT => 'alicia',
    PASSWORD => 'generate',
    DEFAULT_TABLESPACE => 'users',
    TEMPORARY_TABLESPACE => 'temp',
    PRIVS => ['create session', 'resource', 'connect', 'oem_monitor'],
    QUOTAS => { users => 'unlimited', tools => '10m', indx => 'unlimited'},
  );
  $newUser->create;

  # print the generated password
  print "Password: $newUser{PASSWORD}\n";


=cut 

my $Alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWZYZ';
my $PasswordGenSql = qq {select 
	substr('$Alphabet',MOD(TO_CHAR(SYSDATE,'SS'),25)+1,1)||
	substr('$Alphabet',MOD(substr(mod(hsecs,99999999)+?,5,2),25)+1,1)||
	substr('$Alphabet',MOD(substr(mod(hsecs,99999999)+?,6,2),25)+1,1)||
	substr('$Alphabet',MOD(substr(mod(hsecs,99999999)+?,7,2),25)+1,1)||
	substr(to_char(floor(mod(hsecs*?,9999)))||'0000',1,4) as password
	from v\$timer 
};

sub _genPassword {

	my $newPassword;
	my $sthPasswordGen = $dbh->prepare( $PasswordGenSql );
	$sthPasswordGen->bind_columns( undef, \$newPassword );
	use DBI qw{:sql_types};	

	my $seed = rand ((localtime(time))[0]) * rand 1000;
	$sthPasswordGen->bind_param( 1, $seed, SQL_INTEGER );

	$seed = rand ((localtime(time))[0]) * rand 1000;
	$sthPasswordGen->bind_param( 2, $seed, SQL_INTEGER );

	$seed = rand ((localtime(time))[0]) * rand 1000;
	$sthPasswordGen->bind_param( 3, $seed, SQL_INTEGER );

	$seed = rand ((localtime(time))[0]) * rand 1000;
	$sthPasswordGen->bind_param( 4, $seed, SQL_INTEGER );

	$sthPasswordGen->execute();
	$sthPasswordGen->fetch();
	return $newPassword;
	
}


=head1 _tbsQuota

 get the quotas, if any, per tablespace

 my $tbsObj = new PDBA::DBA( 
    DBH => $dbh,
    OBJECT => 'scott',
    OBJECT_TYPE => 'tbsquota'
 );

 my $tbsQuotas = $tbsObj->info;

 foreach my $tbs ( keys %{$tbsQuotas} ) {
    print "TBS: $tbs  QUOTA: $tbsQuotas->{$tbs}\n";
 }

=cut

sub _tbsQuota {

	my $self = shift;

	$self->{OBJECT} = uc($self->{OBJECT});

	my $vobj = new PDBA::GQ($dbh,'dba_ts_quotas', 
		{ 
			WHERE => 'username = ?',
			COLUMNS => [ 
				q{tablespace_name}, 
				q{decode(max_bytes, -1, 'UNLIMITED', NULL,  'NO QUOTA', to_char(max_bytes)) max_bytes} 
			],
			BINDPARMS => [$self->{OBJECT}]
		}
	);

	my $tbsQuotasRef = {};
	while ( my $row = $vobj->next ) {
		$tbsQuotasRef->{$row->{TABLESPACE_NAME}} = $row->{MAX_BYTES};
	}

	$tbsQuotasRef;

}


=head1 _userInfo

 retrieve information from dba_users about a user

 data returned in a hashref

 e.g.

 my $userObj = new PDBA::DBA( 
    DBH => $dbh,
    OBJECT => 'scott',
    OBJECT_TYPE => 'user'
 );

 my $userInfo = $userObj->info;

 foreach my $attribute ( keys %{$userInfo} ) {
    printf("ATTRIBUTE:  %-30s  VALUE: %-30s\n", 
		 $attribute, $userInfo->{$attribute});
 }


=cut

 
sub _userInfo {
	my $self = shift;
	$self->{OBJECT} = uc($self->{OBJECT});

	my $vobj = new PDBA::GQ($dbh,'dba_users', 
		{ 
			WHERE => 'username = ?',
			BINDPARMS => [$self->{OBJECT}]
		}
	);

	my $userInfoRef = $vobj->all({});

	# the above returns a single row with ref hash
	# in an array ref.  want to just return a ref hash
	# here, so deref the array portion and return a 
	# ref to the resulting hash.
	my $userHashRef = \%{$userInfoRef->[0]};

	# assign an empty string '' to undef values
	map ( 
		$userHashRef->{$_} = $userHashRef->{$_} 
			? $userHashRef->{$_} 
			: '' , 
		keys %{$userHashRef}
	);

	return $userHashRef;

}

=head1 _roleInfo

 retrieve information from dba_roles about a role

 data returned in a hashref

 e.g.

 my $roleObj = new PDBA::DBA( 
    DBH => $dbh,
    OBJECT => 'DBA',
    OBJECT_TYPE => 'role'
 );

 my $roleInfo = $roleObj->info;

 foreach my $attribute ( keys %{$roleInfo} ) {
    printf("ATTRIBUTE:  %-30s  VALUE: %-30s\n", 
		 $attribute, $roleInfo->{$attribute});
 }


=cut

sub _roleInfo {
	my $self = shift;
	$self->{OBJECT} = uc($self->{OBJECT});

	my $vobj = new PDBA::GQ($dbh,'dba_roles', 
		{ 
			WHERE => 'role = ?',
			BINDPARMS => [$self->{OBJECT}]
		}
	);

	my $roleInfoRef = $vobj->all({});

	# the above returns a single row with ref hash
	# in an array ref.  want to just return a ref hash
	# here, so deref the array portion and return a 
	# ref to the resulting hash.
	my $roleHashRef = \%{$roleInfoRef->[0]};

	# assign an empty string '' to undef values
	map ( 
		$roleHashRef->{$_} = $roleHashRef->{$_} 
			? $roleHashRef->{$_} 
			: '' , 
		keys %{$roleHashRef}
	);

	return $roleHashRef;

}

=head1 _userDdl

  generate DDL for 'CREATE USER' statement

  my $userObj = new PDBA::DBA(
    DBH => $dbh,
    OBJECT => $row->{USERNAME},
    OBJECT_TYPE => 'user'
  );

  my $ddl = $userObj->ddl;
  print DDL "$ddl\n\n";

=cut

sub _userDdl {
	my $self = shift;
	$self->{OBJECT} = uc($self->{OBJECT});

	my $userObj = new PDBA::DBA(
		DBH => $dbh,
		OBJECT => $self->{OBJECT},
		OBJECT_TYPE => 'user'
	);

	my $userInfo = $userObj->info;

	my $ddl = "CREATE USER $userInfo->{USERNAME} IDENTIFIED ";

	$ddl .= 'EXTERNAL' eq $userInfo->{PASSWORD} 
		? 'EXTERNALLY'
		: qq{BY VALUES '$userInfo->{PASSWORD}'};

	$ddl .= qq{\n\tDEFAULT TABLESPACE $userInfo->{DEFAULT_TABLESPACE}\n};
	$ddl .= qq{\tTEMPORARY TABLESPACE $userInfo->{TEMPORARY_TABLESPACE}\n};

	my $tbsObj = new PDBA::DBA( 
		DBH => $dbh,
		OBJECT => $self->{OBJECT},
		OBJECT_TYPE => 'tbsquota'
	);

	my $tbsQuotas = $tbsObj->info;

	foreach my $tbs ( keys %{$tbsQuotas} ) {
		$ddl .= qq{\tQUOTA $tbsQuotas->{$tbs} on $tbs\n};
	}

	$ddl .= ";\n\n";

	$userObj = new PDBA::DBA(
		DBH => $dbh,
		OBJECT => $self->{OBJECT},
		OBJECT_TYPE => 'privs'
	);

	my $privInfo = $userObj->info;

	if ( $privInfo->{systemPrivs} ) {
		my @sysprivs = map { "grant $_ to $self->{OBJECT};" } @{$privInfo->{systemPrivs}};
		$ddl .= join("\n", @sysprivs );
		$ddl .= "\n";
	}

	if ( $privInfo->{adminSystemPrivs} ) {
		my @sysprivs = map { "grant $_ to $self->{OBJECT} with ADMIN OPTION;" } @{$privInfo->{adminSystemPrivs}};
		$ddl .= join("\n", @sysprivs );
		$ddl .= "\n";
	}

	if ( $privInfo->{roles} ) {
		my @roleprivs = map { "grant $_ to $self->{OBJECT};" } @{$privInfo->{roles}};
		$ddl .= join("\n", @roleprivs );
		$ddl .= "\n";
	}

	if ( $privInfo->{adminRoles} ) {
		my @roleprivs = map { "grant $_ to $self->{OBJECT} with ADMIN OPTION;" } @{$privInfo->{adminRoles}};
		$ddl .= join("\n", @roleprivs );
		$ddl .= "\n";
	}

	if ( $privInfo->{defaultRoles} ) {
		$ddl .= "ALTER USER $self->{OBJECT} DEFAULT ROLE " 
			. join(',', @{$privInfo->{defaultRoles}}) . ";";
	}

	return $ddl;
}

=head1 _roleDdl

 generate DDL to recreate a rold

  my $roleList = new PDBA::GQ( $dbh,'dba_roles',
    {
      WHERE => 'role not in ' . qw{DBA CONNECT RESOURCE}
      }
  );
  
  while ( my $row = $roleList->next({}) ) {

    my $roleObj = new PDBA::DBA(
      DBH => $dbh,
      OBJECT => $row->{ROLE},
      OBJECT_TYPE => 'role'
    );

    my $roleDdl = $roleObj->ddl;
    print "$roleDdl\n";

  }


=cut

sub _roleDdl {
	my $self = shift;
	$self->{OBJECT} = uc($self->{OBJECT});

	my $roleObj = new PDBA::DBA(
		DBH => $dbh,
		OBJECT => $self->{OBJECT},
		OBJECT_TYPE => 'role'
	);

	my $roleInfo = $roleObj->info;

	my $ddl = "CREATE ROLE $roleInfo->{ROLE}  ";

	if ( 'YES' eq $roleInfo->{PASSWORD_REQUIRED} ) {

		# get role password values
		# must have SELECT on sys.user$ for this to work
		my $roleQuery = new PDBA::GQ($dbh,'sys.user$', 
			{ 
				COLUMNS => [qw{ password }],
				WHERE => 'name = ?',
				BINDPARMS => [$self->{OBJECT}]
			}
		);

		my $row = $roleQuery->next({});

		$ddl .= qq{IDENTIFIED BY VALUES '$row->{PASSWORD}'};

	} elsif ( 'EXTERNAL' eq $roleInfo->{PASSWORD_REQUIRED} ) {
		$ddl .= 'IDENTIFIED EXTERNALLY';
	} else {
		$ddl .= 'NOT IDENTIFIED';
	}

	$ddl .= ";\n";

}

=head1 _grantorPrivsInfo

 return info for privs by a grantor


=cut

sub _grantorPrivsInfo {
	my $self = shift;
	$self->{OBJECT} = uc($self->{OBJECT});

	my $vobj = new PDBA::GQ($dbh,'dba_tab_privs', 
		{ 
			WHERE => 'grantor = ?',
			BINDPARMS => [$self->{OBJECT}]
		}
	);

	my $grantPrivsRef = {};

	while ( my $row = $vobj->next ) {
		$grantPrivsRef->{$row->{TABLE_NAME}}{$row->{GRANTEE}}{$row->{PRIVILEGE}}
			= $row->{GRANTABLE};
	}

	return $grantPrivsRef;
}

=head1 _grantorPrivsDdl

 generate DDL for grants by grantor

 ie. when called with user SCOTT, all privs granted by SCOTT
 will be generated

  my $infoObj = new PDBA::DBA(
    DBH => $dbh,
    OBJECT => $row->{USERNAME},
    OBJECT_TYPE => 'privsbygrantor'
  );

  my $privInfo = $infoObj->ddl;

=cut

sub _grantorPrivsDdl {
	my $self = shift;
	$self->{OBJECT} = uc($self->{OBJECT});

	my $infoObj = new PDBA::DBA(
		DBH => $dbh,
		OBJECT => $self->{OBJECT},
		OBJECT_TYPE => 'privsbygrantor'
	);

	my $privInfo = $infoObj->info;

	my $ddl = '';
	foreach my $table ( keys %{$privInfo} ) {
		foreach my $grantee ( keys %{$privInfo->{$table}} ) {
			foreach my $privilege ( keys %{$privInfo->{$table}{$grantee}} ) {
				my $grantOption = $privInfo->{$table}{$grantee}{$privilege};
				$ddl .= qq{GRANT $privilege on $table to $grantee };
				$ddl .= 'YES' eq $grantOption
					? "with GRANT OPTION;\n"
					: ";\n";
			}
		}
	}

	$ddl .= "\n";
	return $ddl;
}

=head1 _privInfo

 returns a hashref of arrays to privileges granted to 
 a role or user. 

 The keys to the hashref are

   systemPrivs  :  system privileges granted
   tablePrivs   :  table privileges granted
   roles        :  roles granted
   defaultRoles :  default roles for user

 The value for all keys is an array ref.  The arrayrefs
 for systemPrivs and roles contain a list of privs or
 roles granted.

 The array ref for tablePrivs is actually a list of hashrefs,
 each containing the table_name, privilege and owner of the
 object.

 Here's a test script to demonstrate dereferencing this:

 my $userObj = new PDBA::DBA( 
    DBH => $dbh,
    OBJECT => 'scott',
    OBJECT_TYPE => 'privs'
 );

 my $privInfo = $userObj->info;

 foreach my $privType ( sort keys %{$privInfo} ) {
    print "PRIVTYPE: $privType\n";

   if ( $privType =~ /systemPrivs|roles/ ) {
       foreach my $priv ( sort @{$privInfo->{$privType}} ) {
          print "\tPRIV: $priv\n";
       }
    } elsif ( 'tablePrivs' eq $privType ) {
       foreach my $objectOwner ( keys %{$privInfo->{$privType}} ) {
          print "\t\tOWNER: $objectOwner\n";
          foreach $object ( keys %{$privInfo->{$privType}{$objectOwner}} ) {
             print "\t\t\t\tOBJ: $object - ";
             print join(':', @{$privInfo->{$privType}{$objectOwner}{$object}}) . "\n"; 
          }
       }
    } else {
       croak "unknown privilege type of $privType\n";
    }
 }


=cut

sub _privInfo {
	my $self = shift;

	$self->{OBJECT} = uc($self->{OBJECT});

	my $vobj = new PDBA::GQ($dbh,'dba_role_privs', 
		{ 
			WHERE => 'grantee = ?',
			COLUMNS => [ 'granted_role','default_role','admin_option' ],
			BINDPARMS => [$self->{OBJECT}]
		}
	);

	my $userRolesRef = [];
	my $userDefaultRoles = [];
	my $userAdminRoles = [];
	while ( my $row = $vobj->next ) {
		push @{$userRolesRef}, $row->{GRANTED_ROLE};
		push @{$userDefaultRoles}, $row->{GRANTED_ROLE} 
			if 'YES' eq $row->{DEFAULT_ROLE} ;
		push @{$userAdminRoles}, $row->{GRANTED_ROLE} 
			if 'YES' eq $row->{ADMIN_OPTION} ;
	}

	$vobj = new PDBA::GQ($dbh,'dba_tab_privs', 
		{ 
			WHERE => 'grantee = ?',
			COLUMNS => [ qw{privilege owner table_name} ],
			BINDPARMS => [$self->{OBJECT}]
		}
	);
	my $userTabPrivsRef = {};
	while ( my $row = $vobj->next ) {
		push @{$userTabPrivsRef->{$row->{OWNER}}{$row->{TABLE_NAME}}}, $row->{PRIVILEGE};
	}

	$vobj = new PDBA::GQ($dbh,'dba_sys_privs', 
		{ 
			WHERE => 'grantee = ?',
			COLUMNS => [ 'privilege','admin_option' ],
			BINDPARMS => [$self->{OBJECT}]
		}
	);
	my $userSysPrivsRef = [];
	my $userAdminSysPrivsRef = [];
	while ( my $row = $vobj->next ) {
		push @{$userSysPrivsRef}, $row->{PRIVILEGE};
		push @{$userAdminSysPrivsRef}, $row->{PRIVILEGE} 
			if 'YES' eq $row->{ADMIN_OPTION} ;
	}

	my $privsRef = { 
		systemPrivs => $userSysPrivsRef,
		adminSystemPrivs => $userAdminSysPrivsRef,
		tablePrivs => $userTabPrivsRef,
		roles => $userRolesRef,
		defaultRoles => $userDefaultRoles,
		adminRoles => $userAdminRoles,
	};

	return $privsRef;

}

=head1 _tableInfo

returns a hashref to the corresponding row in DBA_TABLES

e.g. 

  my $userObj = new PDBA::DBA(
    DBH => $dbh,
    OBJECT_OWNER => 'scott',
    OBJECT => 'emp',
    OBJECT_TYPE => 'table'
  );

  my $userInfo = $userObj->info;

  foreach my $attribute ( keys %{$userInfo} ) {
    printf("ATTRIBUTE:  %-30s  VALUE: %-30s\n",
    $attribute, $userInfo->{$attribute});
  }


=cut

sub _tableInfo {
	my $self = shift;
	$self->{OBJECT} = uc($self->{OBJECT});
	$self->{OBJECT_OWNER} = uc($self->{OBJECT_OWNER});

	my $vobj = new PDBA::GQ($dbh,'dba_tables', 
		{ 
			WHERE => 'owner = ? and table_name = ?',
			BINDPARMS => [$self->{OBJECT_OWNER}, $self->{OBJECT}]
		}
	);

	my $tableInfoRef = {};

	# only one row returned
	while ( my $row = $vobj->next){ $tableInfoRef = $row }

	return $tableInfoRef;
}

=head1 _tablespaceInfo

returns a hashref to all tablespace information in DBA_TABLESPACES

use 'ALL' for the OBJECT_TYPE attribute if you want info for all
tablespaces returned, or use the name of a single tablespace.

If an invalid value is used, an empty hashref will be returned.

Oracle wildcards may also be used for the OBJECT attribute

e.g. 

  # all tablespaces
  my $userObj = new PDBA::DBA(
    DBH => $dbh,
    OBJECT => 'ALL',
    OBJECT_TYPE => 'tablespace'
  );

  my $tbsInfo = $userObj->info;

  foreach my $tbs ( sort keys %$tbsInfo ) {
    print "Tablespace: $tbs\n";
    foreach my $att ( sort keys %{$tbsInfo->{$tbs}} ) {
      print "\t$att: $tbsInfo->{$tbs}{$att}\n";
    }
  }

  # wildcard - all tablespaces like 'HASH%'
  my $userObj = new PDBA::DBA(
    DBH => $dbh,
    OBJECT => 'HASH%',
    OBJECT_TYPE => 'tablespace'
  );


=cut

sub _tablespaceInfo {
	my $self = shift;
	$self->{OBJECT} = uc($self->{OBJECT});

	my $vobj = new PDBA::GQ($dbh,'dba_tablespaces', 
		$self->{OBJECT} =~ /ALL/i || 
		{ 
			WHERE => 'tablespace_name like ?',
			BINDPARMS => [ $self->{OBJECT}]
		}
	);

	my $tbsInfoRef = {};

	while ( my $row = $vobj->next({})){ 
		my $tbs = $row->{TABLESPACE_NAME};
		delete $row->{TABLESPACE_NAME};
		$tbsInfoRef->{$tbs} = $row;
	}

	return $tbsInfoRef;
}

=head1 _indexInfo

returns a hashref with index information for all indexes on a table
as seen in DBA_INDEXES and DBA_TAB_COLUMNS

all values from DBA_INDEXES are returned, and the column names are 
returned in the proper order from DBA_IND_COLUMNS as the COLUMNS attribute

e.g. 

  my $userObj = new PDBA::DBA(
    DBH => $dbh,
    OBJECT_OWNER => 'scott',
    OBJECT => 'emp',
    OBJECT_TYPE => 'index'
  );

  my $idxInfo = $userObj->info;

Here's one way to iterate through the data. 

  foreach my $index ( sort keys %$idxInfo ) {
    print "Index: $index\n";
    foreach my $att ( sort keys %{$idxInfo->{$index}} ) {
      $idxInfo->{$index}{$att} = '' unless $idxInfo->{$index}{$att};
      # column info is in an array
      print "\t$att: ";
      if ( 'ARRAY' eq ref($idxInfo->{$index}{$att})) {
        print join(' - ', @{$idxInfo->{$index}{$att}}), "\n";
      } else {
        print "$idxInfo->{$index}{$att}\n";
      }
    }
  }

And here's another way.

  foreach my $index ( sort keys %$idxInfo ) {
    print "Index: $index\n";
    foreach my $att ( qw{OWNER TABLE_NAME INDEX_NAME TABLESPACE_NAME COLUMNS} ) {
      $idxInfo->{$index}{$att} = '' unless $idxInfo->{$index}{$att};
      # column info is in an array
      print "\t$att: ";
      if ( 'COLUMNS' eq $att ) {
        print join(' - ', @{$idxInfo->{$index}{$att}}), "\n";
      } else {
        print "$idxInfo->{$index}{$att}\n";
      }
    }
  }

=cut

sub _indexInfo {
	my $self = shift;
	$self->{OBJECT} = uc($self->{OBJECT});
	$self->{OBJECT_OWNER} = uc($self->{OBJECT_OWNER});

	my $vobj = new PDBA::GQ($dbh,'dba_indexes', 
		{ 
			WHERE => 'owner = ? and table_name = ?',
			BINDPARMS => [$self->{OBJECT_OWNER}, $self->{OBJECT}]
		}
	);

	my $idxInfoRef = {};

	# only one row returned
	while ( my $row = $vobj->next){ 
		my $idxName = $row->{INDEX_NAME};
		delete $row->{INDEX_NAME};
		$idxInfoRef->{$idxName} = $row;

		# get columns in index
		my $colObj = new PDBA::GQ($dbh, 'dba_ind_columns',
			{
				COLUMNS => ['column_name'], 
				WHERE => 'index_owner = ? and table_name = ? and index_name = ?',
				ORDER_BY => 'column_position',
				BINDPARMS => [$row->{OWNER}, $row->{TABLE_NAME}, $idxName],

			}
		);
		while ( my $colrow = $colObj->next([]) ) {
			push @{$idxInfoRef->{$idxName}{COLUMNS}}, $colrow->[0]; 
		}
	}

	return $idxInfoRef;
}

=head1 _freespaceInfo

returns a hashref to all freespace information in DBA_FREE_SPACE.
The filename that the freespace is in as found in DBA_DATA_FILES
is also included

The OBJECT_TYPE attribute should be the name of a tablespace, or
'ALL' if freespace for all tablespaces is to be returned.

If an invalid value is used, an empty hashref will be returned.

Oracle wildcards may also be used for the OBJECT attribute

e.g. 

  my $userObj = new PDBA::DBA(
    DBH => $dbh,
    OBJECT => 'USERS',
    OBJECT_TYPE => 'freespace'
    );

  my $freespaceInfo = $userObj->info;

  foreach my $tbs ( sort keys %{$freespaceInfo} ) {
    print "tbs: $tbs\n";
    foreach my $file ( sort keys %{$freespaceInfo->{$tbs}}){
      print "\tfile: $file\n";
      foreach my $att ( sort keys %{$freespaceInfo->{$tbs}{$file}} ) {
        print "\t\t$att: ";

        if ( 'ARRAY' eq ref($freespaceInfo->{$tbs}{$file}{$att}) ) {
          # space
          print "\n";
          foreach my $spaceHash( @{$freespaceInfo->{$tbs}{$file}{SPACE}} ) {
            print "\n\t\t\tBLOCK_ID: $spaceHash->{BLOCK_ID}\n";
            print "\t\t\tBLOCKS  : $spaceHash->{BLOCKS}\n";
            print "\t\t\tBYTES   : $spaceHash->{BYTES}\n";
          }
          print "\n";
        } else {
          print $freespaceInfo->{$tbs}{$file}{$att}, "\n";
        }
      }
    }
  }


The data is arranged of a hash of hashes, with an array of hashes
holding the space values, and standard hash keys holding the others.

The main keys are the tablespace name and the file name.

The keys for the rest of the freespace info are:

  SPACE:  an array of hashes with keys of:
    BYTES:  bytes of free space
    BLOCKS: blocks of free space
    BLOCK_ID: location of freespace in the file

  TOTAL_BLOCKS
  TOTAL_BYTES
  MAX_BLOCKS
  MAX_BYTES
  MIN_BLOCKS
  MIN_BYTES

The MIN and MAX attributes refer to the largest and smallest chunks
of freespace that are available.

Here's an example of what the data structure looks like:

  %freespace = (
    USERS => {
       /u02/oradata/ts01/ts01_users01.dbf => {
        SPACE => [
          {
            BYTES => 4456448,
            BLOCKS => 544,
            BLOCK_ID => 1698
          },
          {
            BYTES => 10878976,
            BLOCKS => 1328,
            BLOCK_ID => 2258
          },
          {
            BYTES => 7077888,
            BLOCKS => 864,
            BLOCK_ID => 3602
          },
          ...
        ],
        TOTAL_BLOCKS => 23504,
        MIN_BLOCKS => 16,
        MAX_BLOCKS => 14032,
        MAX_BYTES => 114950144,
        TOTAL_BYTES => 192544768,
        MIN_BYTES => 131072
      }
    }
  );


=cut

sub _freespaceInfo {
	my $self = shift;
	$self->{OBJECT} = uc($self->{OBJECT});

	my $dfobj = new PDBA::GQ($dbh,'dba_data_files', 
		COLUMNS => [qw{relative_fno file_name}]
	);

	my %df = ();

	while ( my $row = $dfobj->next({}) ) {
		$df{$row->{RELATIVE_FNO}} = $row->{FILE_NAME};
	}

	my $vobj = new PDBA::GQ($dbh,'dba_free_space', 
		$self->{OBJECT} =~ /ALL/i || 
		{ 
			WHERE => 'tablespace_name like ?',
			BINDPARMS => [ $self->{OBJECT}]
		}
	);

	my $freespaceInfoRef = {};

	while ( my $row = $vobj->next({})){ 
		my $tbs = $row->{TABLESPACE_NAME};
		my $filename = $df{$row->{RELATIVE_FNO}};
		delete $row->{TABLESPACE_NAME};
		delete $row->{RELATIVE_FNO};
		delete $row->{FILE_ID};
		push @{$freespaceInfoRef->{$tbs}{$filename}{SPACE}}, $row;

		# initialize the hash elements if needed
		$freespaceInfoRef->{$tbs}{$filename}{MAX_BLOCKS} = 0 
			unless $freespaceInfoRef->{$tbs}{$filename}{MAX_BLOCKS};
			
		$freespaceInfoRef->{$tbs}{$filename}{MAX_BYTES} = 0 
			unless $freespaceInfoRef->{$tbs}{$filename}{MAX_BYTES};
			
		$freespaceInfoRef->{$tbs}{$filename}{MIN_BLOCKS} = 2**100
			unless $freespaceInfoRef->{$tbs}{$filename}{MIN_BLOCKS};
			
		$freespaceInfoRef->{$tbs}{$filename}{MIN_BYTES} = 2**100
			unless $freespaceInfoRef->{$tbs}{$filename}{MIN_BYTES};
			
		if ( $row->{BLOCKS} > $freespaceInfoRef->{$tbs}{$filename}{MAX_BLOCKS} ){
			$freespaceInfoRef->{$tbs}{$filename}{MAX_BLOCKS} = $row->{BLOCKS};
		}
		if ( $row->{BYTES} > $freespaceInfoRef->{$tbs}{$filename}{MAX_BYTES} ){

			$freespaceInfoRef->{$tbs}{$filename}{MAX_BYTES} = $row->{BYTES};
		}

		if ( $row->{BLOCKS} < $freespaceInfoRef->{$tbs}{$filename}{MIN_BLOCKS} ){
			$freespaceInfoRef->{$tbs}{$filename}{MIN_BLOCKS} = $row->{BLOCKS};
		}

		if ( $row->{BYTES} < $freespaceInfoRef->{$tbs}{$filename}{MIN_BYTES} ){
			$freespaceInfoRef->{$tbs}{$filename}{MIN_BYTES} = $row->{BYTES};
		}

		$freespaceInfoRef->{$tbs}{$filename}{TOTAL_BLOCKS} += $row->{BLOCKS};
		$freespaceInfoRef->{$tbs}{$filename}{TOTAL_BYTES} += $row->{BYTES};
	}

	return $freespaceInfoRef;
}

sub stub {
	my ($stub) = @_;
	my $text = "$stub is a stub and not yet implemented";
	print "\n$text\n\n";
	return $text;
}

1;

