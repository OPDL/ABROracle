
package PDBA::Daemon;

our $VERSION = '0.01';

use PDBA;
use strict;
use Carp;
use POSIX;

sub daemon {
	my($tries, $pid, $sess_id);
	{
		if ($pid = fork) { exit 0 }	# exit parent
		if (defined($pid )) {
			close STDOUT;
			close STDIN;
			chdir('/');
			croak  "Cannot detach from controlling terminal" unless $sess_id = POSIX::setsid();
			return $pid;
		}
		if (++$tries>5 ) {
			die "fork failed after $tries attempts: $!\n"
		} else {
			sleep 3;
			redo;
		}
	}
}

sub daemonize { return daemon }

1;

