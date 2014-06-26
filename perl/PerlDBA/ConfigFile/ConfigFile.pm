
package PDBA::ConfigFile;

unless ( defined $PDBA::VERSION ) {
	eval "use PDBA";
}

use strict;
no strict qw(vars);
use warnings;

our $VERSION = '0.01';

our @ISA=qw(IO::File);
require IO::File;

use Carp;

sub new {

	my ($class, %args) = @_;

	my $internalPath =  $args{PATH} ? $args{PATH} : $ENV{PATH};
	$args{PATHSEP}||= PDBA->pathsep();  # set for Win32 or unix
	$args{DIRSEP} ||= '/'; # assume unix
	$args{FILE}   || croak "configuration file name required in $class\n";
	
	my @paths = split(/$args{PATHSEP}/, $internalPath);
	# add home and current dir to top of list
	# only if PATH attribute not set by caller
	unless ( $args{PATH} ) {
		unshift(@paths,PDBA->pdbaHome()) if ( PDBA->pdbaHome() );
		unshift(@paths,$ENV{HOME});
		unshift(@paths,'.');
	}

	if ( $args{DEBUG} ) { print join(' - ', @paths ), "\n" }

	my ($file,$fh) = (undef,undef);

	for my $dir ( @paths ) {
		my $testFile = $dir . $args{DIRSEP} . $args{FILE};
		if ( -r $testFile ) { 
			$fh = new IO::File;
			$fh->open($testFile) 
				|| croak "Unable to open config file $testFile in $class - $!\n";
			last;
		}
	}

	$fh;
}

package PDBA::ConfigLoad;


require 5.003;
use strict;
no strict qw(vars);
use warnings;

our $VERSION = '0.01';

use Carp;

sub new {
	my ($class, %args) = @_;
	my $fh = new PDBA::ConfigFile(%args);
	return undef unless $fh;
	my @code = ();
	if ( $fh ) {
		@code = <$fh>;
		$fh->close;
	}
	eval join('',@code);
	$@ ? undef : 1; 
}

1;

__END__


=head1 PDBA::ConfigFile

PDBA::ConfigFile - Perl extension for locating and opening your
configuration files.

=head1 DESCRIPTION

Use ConfigFile to locate your configuration files
If found, it returns an open file handle

=head1 AUTHOR

Jared Still
jkstill@cybcon.com

=head1 Usage

  use PDBA::ConfigFile;
  
  PDBA::ConfigFile is used to locate a configuration file and return
  an open file handle for it.

  The one required argument is the file name to look for.

  my $configFh = new PDBA::ConfigFile( FILE => 'myconfig.conf' );
  
  this will return an open filehandle that may be read by standard means

  e.g.  while(<$configFh>) { print }

  The default locations for searching for the file are:
  PDBA_HOME if defined
  HOME
  current directory

  You may optionally specify the PATH to search
  my $configFh = new PDBA::ConfigFile( 
    FILE => 'myconfig.conf' ,
    PATH => '/var/opt/config;/etc/config'
  );

  Two other arguments may be specified as well, the PATH separator and
  the directory separator.

  The default for PATH separator is ':'.
  The default for directory separator is '/'

  You will need to specify them if you wish to change them from their
  default values.

  e.g.
  my $configFh = new PDBA::ConfigFile( 
    FILE => 'myconfig.conf' ,
    PATH => 'C:\config;D:\config',
    PATHSEP => '\\', 
    DIRSEP => ';'
  );


=head1 SEE ALSO

PDBA

=cut

=head1 PDBA::ConfigLoad

ConfigLoad - Finds your config file and loads it vi 'eval'.

=head1 DESCRIPTION

Call ConfigLoad as you would ConfigFile. The difference
is that the file is read in and then executed via 'eval'


=head1 AUTHOR

Jared Still
jkstill@cybcon.com

=head1 Usage

  use PDBA::ConfigLoad;
  
  PDBA::ConfigFile is used to locate a configuration file, open
  it and execute the contents as a block of Perl code.

  It is called by the same method as ConfigFile.
  
  The one required argument is the file name to look for.
  
  ConfigLoad returns undef on failure.

  unless ( new PDBA::ConfigLoad( FILE => 'myconfig.conf' ) ) {
     die "unable to load myconfig.conf\n";
  };
  
  You may optionally specify the PATH to search

  All arguments to ConfigLoad are passed to ConfigFile.

  For further information, please see the documentation for ConfigFile

=head1 SEE ALSO

PDBA

=cut


