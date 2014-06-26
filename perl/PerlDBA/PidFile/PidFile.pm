

package PDBA::PidFile;

our $VERSION=0.01;

=head2 PidFile.pm


create a file that contains the pid of a running process, and lock
it via flock.

e.g.


  use PDBA::PidFile;

  my $lockfile = '/tmp/my_app_pid.lock';
  my $pid = $$;
  my $fh = new PidFile( $lockfile, $pid );

  if ( $fh ) {
    print "lockFile created for PID: $pid\n";
  } else {
    die "could not open lock file\n";
  }


=cut


use Fcntl qw(:flock);
use Carp;
use PDBA;

require IO::File;
our @ISA = qw(IO::File);

sub new {

	# class method
	# since it is called by package name, we have
	# to include that in the parameters
	my $pkg = shift;
	my $class = ref($pkg) || $pkg;

	my ($pidFile, $PID ) = @_;

	croak "PID filename is required in $pkg\n" unless $pidFile;
	croak "PID  required in $pkg\n" unless $PID;

	my $fh_lockFile = new IO::File;
	my $handle = bless $fh_lockFile, $class;
	my $ppid = $handle->lockFile( file => $pidFile, pid => $PID );

	#print "PID:  $PID   PPID: $ppid\n";

	if ( $ppid ) {
		
		if ( 'unix' eq PDBA::osname() ) {
			if ( $ppid == $PID ) {
				return $handle;
			} else {
				return undef;
			}
		} else {  # win32
			if ( $ppid eq $PID ) {
				return $handle;
			} else {
				return undef;
			}
		}
	} else {
		return undef;
	}
}


sub lockFile {

	my $self=shift;

	my ( %options ) = @_;

	my $lockFile = $options{file}; 
	croak "lockFile requires a file name\n" unless $lockFile;

	my $pid = $options{pid};
	croak "lockFile requires a PID\n" unless $pid;

	#print "passed: $lockFile\n";
	#print "passed: $pid\n";

	if ( -r $lockFile and -w $lockFile ) {

		$self->open($lockFile) || return undef;
		#print "Opened $lockFile\n";
		($lockPid) = <$self>;
		$self->close;

		#print "pidfile 1: $lockPid\n";

		# try to open existing lock file
		# file must be opened with intent to write
		# required on Solaris, don't know about other platforms
		$self->open("+<$lockFile" ) || return undef;

		# lock file, recreate and relock
		# print PID to file
		if ( flock $self, LOCK_EX|LOCK_NB ) {

			$self->open(">$lockFile" ) || return undef;

			#print "pidfile 2: opened for write\n";

			# printflush is in newer version of IO::Handle, and I don't have privileges
			#if ( flock $self, LOCK_EX|LOCK_NB ) { $self->autoflush($pid) }
			# return pid from file if you can't lock
			if ( flock $self, LOCK_EX|LOCK_NB ) { 
				#print "pidfile 3:\n";
				$self->printflush($pid) ;
				return $pid;
			}
			else { return undef }

		} else { return $lockPid }

	} else { # lock file does not exist
		#print "Creating new lock\n";
		$self->open(">$lockFile" ) || return undef;
		$self->printflush($pid);
		#$self->autoflush($pid);
		# get an exclusive lock on the file
		if ( flock $self, LOCK_EX|LOCK_NB ) { return $pid }
		else { return undef }
	}

}


1;

