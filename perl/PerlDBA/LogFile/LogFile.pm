

package PDBA::LogFile;
use PDBA;

our $VERSION=0.01;

=head2 LogFile.pm

create an opened and  locked file for logging 
printed lines are prefixed with a formatted date
e.g. YYYYMMDDHHMMSS:<text>


=item B<new>

  use PDBA::LogFile;

  my $logFile = './dbup.log';
  my $logFh = new LogFile($logFile);

  unless( $logFh ) { die "couldn't open log file for writing\n" }
  my $line=0;

  while(1) {
    $logFh->printflush("dbup log action, line #" . $line++, "\n");
    sleep 1;
  }

=item B<print|printflush>

  print and printflush prepend the data to print with a datestamp and
  call the superclass method of print or printflush in IO::File.

  See the IO::File documentation for further information

=item B<makepath>

  makepath is used to create a path to your logfile if needed.  This 
  needs to be a file name with a fully or relatively qualified path.

    my $logFile = PDBA->pdbaHome() . '/logs/test.log';
    PDBA::LogFile->makepath($logFile);

=item B<logFile>

  This is used internally to create and lock the logfile. There is
  no need to use this in your scripts.

=cut


use Fcntl qw(:flock);
use Carp;

require IO::File;
our @ISA = qw(IO::File);

use IO::File;

sub new {

	# class method
	# since it is called by package name, we have
	# to include that in the parameters
	my $pkg = shift;
	my $class = ref($pkg) || $pkg;

	my ($logFile ) = @_;

	croak "LOG filename is required in $pkg\n" unless $logFile;

	my $fh_logFile = new IO::File;

	my $handle = bless $fh_logFile, $class;

	if ( $handle->logFile( file => $logFile ) ) {
		return $handle;
	} else { return undef }

}


sub logFile {

	my $self=shift;

	my ( %options ) = @_;

	my $logFile = $options{file}; 
	croak "logFile requires a file name\n" unless $logFile;

	my $debug = 0;

	print "LogFile 1: $logFile\n" if $debug;

	if ( -r $logFile and -w $logFile ) {

		# this should never happen
		$self->open($logFile) || return undef;

		print "LogFile 2 : $logFile\n" if $debug;
		$self->close;

		# try to open existing log file
		# file must be opened with intent to write
		# required on Solaris, don't know about other platforms
		$self->open("+<$logFile" ) || return undef;
		print "LogFile 3 : $logFile\n" if $debug;

		# lock file, recreate and relock
		# print PID to file
		if ( flock $self, LOCK_EX|LOCK_NB ) {
			$self->open("+>>$logFile" ) || return undef;
			print "LogFile 4 : $logFile\n" if $debug;
			if ( flock $self, LOCK_EX|LOCK_NB ) {
				$self->autoflush;
				return 1;
			} else { return undef }
		} else { $self->close; return undef }

	} else { # lock file does not exist
		print "LogFile 5 : $logFile\n" if $debug;
		$self->open("+>>$logFile" ) || return undef;
		print "LogFile 6 : $logFile\n" if $debug;
		# get an exclusive lock on the file
		if ( flock $self, LOCK_EX|LOCK_NB ) { 
			print "LogFile 7 : $logFile\n" if $debug;
			return 1 
		}
		else { return undef }
	}

}

sub printflush {
	
	my $self=shift;
	my @args = @_;
	$self->SUPER::printflush(PDBA->timestamp(), ":", ,join(' ',@args));
}

sub print {
	
	my $self=shift;
	my @args = @_;
	$self->SUPER::print(PDBA->timestamp(), ":", ,join(' ',@args));
}

sub makepath {

	my $self = shift;
	my ($filePath, %args) = @_;

	$args{PERMS} ||= 0750;

	use PDBA;
	use File::Spec;
	use File::Path;

	my ($volume, $directories, $file) = File::Spec->splitpath($filePath);
	my $path = $volume . $directories;

	File::Path::mkpath($path, 0, $args{PERMS});
	# hmmm... 
	# this used to work, and now it doesn't
	# strange
	#-d  || -w  || -r  || -x  $path || die "dir $path not found or privs set wrong\n";
	-d $path || -w $path || -r $path || -x  $path || die "dir $path not found or privs set wrong\n";

}

1;

