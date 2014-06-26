

package PDBA::GQ;

our $VERSION = '0.01';

require DBI;

@ISA=qw(DBI DBI::db DBI::st);

#use DBI;
use PDBA;
use Carp;
use strict;
no strict 'refs';
use warnings;
use diagnostics;

=head2 GQ module - V dollar tables interface

$Author: jkstill $
$Date: 2002/02/16 21:46:15 $
$Id: GQ.pm,v 1.11 2002/02/16 21:46:15 jkstill Exp $

This module is used as a generic query interface to the tables.

It began life as an interface to the V$ tables, but then I
realized it would be useful for any table.

The V$ names are actually synonyms in the database for objects
that actually have the name of V_$.

GQ subclasses DBI to keep this as simple and easy 
to use as possible.

The 'new' method creates the V$ object, the 'next' method
is used to iterate through the returned rows.

The 'all' method may be optionally used to return all
rows to a array ref.  This method is probably more
useful with the V$ tables than the 'next' method, as
all rows in these are commonly examined.

The getColumns method uses the DBI method sth->{NAME_uc}
to gather the column names for the object, and return
them in a hash reference.  

A beneficial side effect of originally developing this for the
v$ tables is that the dollar sign '$' will be escaped if
found in the table name.

Several third party apps use $ in table names, so this
will eliminate that particular headache.


=cut

=head1 new

create a new statement handle in preparation
for retrieving data

example:

   my $vobj = new GQ($dbh, $synonym_name);
   die "GQ object creation failed \n" unless $vobj;
	
	instantiate a new V$ table object.  

	an optional WHERE clause and ORDER BY clause
	may be specified as well

	example: 
		my $vobj = new GQ(
			$dbh, 'v$parameter',
			{
				WHERE => "name like 'log%'",
				ORDER_BY => "name desc"
			}
		);

   The WHERE clause may also use bind parameters.  This will prevent
   Oracle from reparsing the same SQL many times when the same
   query is is used with differing values in the WHERE clause.

  e.g.
  my @bindparams=(qw{SYS TABLE});
  $vobj = new PDBA::GQ(
	  $dbh,'all_objects', 
	  { 
		  WHERE => 'owner = ? and object_type = ?',
		  BINDPARMS => \@bindparams
	  }
  );

  If you only want to retrieve certain columns, you can use
  the COLUMNS attribute:

  e.g.
  my @bindparams=(qw{SYS TABLE});
  $vobj = new PDBA::GQ(
	  $dbh,'all_objects', 
	  { 
        COLUMNS => [qw{object_name object_type}',
        WHERE => 'owner = ? and object_type = ?',
        BINDPARMS => \@bindparams
	  }
  );



=cut

sub new {

	my ($pkg) = shift;
	my $class = ref($pkg) || $pkg;

	my ($dbh, $gqSynonym, $optionHash ) = @_;
	my $gqTable = $gqSynonym;

	# escape the dollar sign
	$gqTable = uc($gqTable);
	$gqTable =~ s/^V\$/V_\$/g;

	my $sql = 'select * ' ;

	if ( exists $optionHash->{COLUMNS} ) {
		$sql = "select " . join(',', @{$optionHash->{COLUMNS}});
	} else { $sql = 'select * ' }
	$sql .= qq/ from $gqSynonym/;

	$sql .= ' where ' . $optionHash->{WHERE} if defined $optionHash->{WHERE};
	$sql .= ' group by ' . $optionHash->{GROUP_BY} if defined $optionHash->{GROUP_BY};
	$sql .= ' order by ' . $optionHash->{ORDER_BY} if defined $optionHash->{ORDER_BY};

	my $sth = $dbh->prepare($sql);
	croak "Failed to prepare $sql - $dbh->errstr\n" unless $sth;
	if ( exists $optionHash->{BINDPARMS} ) {
		my $rv = $sth->execute(@{$optionHash->{BINDPARMS}}) || die "Failed to execute $sql - $sth->errstr\n";
	} else {
		my $rv = $sth->execute || die "Failed to execute $sql - $sth->errstr\n";
	}
	my $handle = bless $sth, $class;
	return $handle;
	
}

=head1 next

retrieve the next row of data and return
in a hash via reference

can return either a hashref or an arrayref

default is hashref

example:

   while( my $row = $vobj->next ) {
	   print "SID: $row->{sid}\n";
   }

   while( my $row = $vobj->next([]) ) {
	   print "SID: $row->[0]\n";
   }


=cut

sub next {
	my $self = shift;
	my ( $ref ) = @_;
	$ref ||= {};

	my $refType = ref $ref;

	my $data;
	if ( 'ARRAY' eq $refType ) {
		$data = $self->fetchrow_arrayref;
	} elsif ( 'HASH' eq $refType ) {
		$data = $self->fetchrow_hashref;
	} else { croak "invalid ref type of $refType used to call PDBA::GQ->next\n" }

	if ( ! defined($data) ) { 
		return undef;
	}
	return $data;
}

=head1 all

return all rows into a hashref

See the getColumns entry for an example

see DBI::fetchall_arrayref for info on this

=cut

sub all {
	my $self = shift;

	my ( $ref ) = @_;
	$ref ||= {};
 
	my $refType = ref $ref;
 
	my $array;
	if ( 'ARRAY' eq $refType ) {
		$array = $self->fetchall_arrayref([]);
	} elsif ( 'HASH' eq $refType ) {
		$array = $self->fetchall_arrayref({});
	} else { croak "invalid ref type of $refType used to call PDBA::GQ->all\n" }

	if ( ! defined($array) ) { 
		return undef;
	}
	return $array;
}

=head1 getColumns

getColumns($sth);

returns a hash of column names, with the
column names as the key, and the position
of the column as the value

example:

	my $vobj = new GQ($dbh,'v$parameter');
	die "GQ object creation failed \n" unless $vobj;
  
	my $arrayRowRef = $vobj->all;
	my $colNames = $vobj->getColumns;
 
	for $row ( @$arrayRowRef ) {
		print "PARM: $row->[$colNames->{NAME}]  VALUE: $row->[$colNames->{VALUE}]\n";
	}


=cut

sub getColumns {
	my $self = shift;
	my @columns = @{ $self->{NAME_uc} };
	if ( ! @columns ) { 
		return undef;
	}

	my $colOrder = {};
	for my $el ( 0 .. $#columns ) {
		#print "col num:  $el  col name: $columns[$el] \n";
		$colOrder->{$columns[$el]} = $el;
	}

	return $colOrder;
}

1;

