

#!/usr/bin/perl -w
#
Category:	Text Processing
Author/Contact Info	Paul Dyer 
pmdyer@hotmail.com
Description:	
I looked around for some alert log parsers, but none seemed to be out there for public consumption. If anyone knows of a better way for me to approach this, I will be grateful for any comments. Also, if anyone knows better techniques to code in Perl, I will be happy to hear about it. The code is my own, except for techniques lifted from a few O'Reilly books.


Script to monitor Oracle alert logs. Output is to stdout, or to a mail address, depending on the parms. 

Parameters: 
log days - defaults to look one day back. 
mail address - if not set, output is printed, otherwise mailed. 

Notes: 
exclude_list is a list of oracle error numbers to 
exclude from printing. But, this exclusion only takes 
effect if all oracle errors in the stanza are in the exclude list. 

The totals printed at the bottom include all oracle errors found.

#  /usr/local/bin/alertlog.pl [log days] [mail address]
#
use strict;
use Time::Local;
local (*ALERT, *MAIL);
my %errs = ();
my $errors = 0;
my $errtxt;
my $ast;
my $astx = 0;
my @exclude_list = (1109, 1142, 1145, 1511);
my $stanzatime;
my @stanza = ();
my %months = (Jan => 0, Feb => 1,  Mar => 2,
              Apr => 3, May => 4,  Jun => 5,
              Jul => 6, Aug => 7,  Sep => 8,
              Oct => 9, Nov => 10, Dec => 11);
my ($mon,$day,$time,$year);
my ($hr,$min,$sec);

die "No ORACLE_HOME available" unless $ENV{ORACLE_HOME};
die "No ORACLE_SID available"  unless $ENV{ORACLE_SID};
my $input_dir = "$ENV{ORACLE_HOME}/admin/$ENV{ORACLE_SID}/bdump";
my $input_file = "alert_$ENV{ORACLE_SID}.log";

chdir $input_dir or die "Unable to chdir to ". $input_dir .": $!";
die "Alert log not readable"  unless -r $input_file;

# set the number of log days to scan.  Default=1.
my $logdays = (shift @ARGV || 1);

# get the mail address if there is one.
my $hostname = "from ". (`hostname 2>/dev/null` ||"who");
if (my $mailaddr = shift @ARGV) {
  open MAIL, "|mail -s \"Nightly Database Alert Logs $hostname\" $mail
+addr";
  }
else {
  open MAIL, ">&STDOUT";
  }

# Set ltime to be today less the logdays parm, at this time of day.
# Used to capture only current errors
my $ltime = time() - (60*60*24*$logdays);
print MAIL "\nLogging from " . localtime($ltime) ."\n\n";

foreach my $file (reverse sort <$input_file*>) {
  open (ALERT, "$file") || die "Can't open $file";
  while (<ALERT>) {
    # Extract the most recent date-time stamp from the logfile.
    if (/^(?:Mon|Tue|Wed|Thu|Fri|Sat|Sun)/) {
      print_and_flush_stanza($stanzatime, $ltime, @stanza)
           if $stanzatime;
      @stanza = $_;
      ($mon,$day,$time,$year) = (split / +/, $_) [1,2,3,4];
      ($hr,$min,$sec) = (split /:/, $time);
      $stanzatime = timelocal($sec,$min,$hr,$day,$months{$mon},$year);
      }
    else {
      push @stanza, $_;
      }
    }
  close (ALERT);
  }

stat("$ENV{ORACLE_HOME}/bin/oerr"); # load the filestat info to _

print MAIL "\nOracle Error   Count Standard Message Text\n";
print MAIL   "------------   ----- ---------------------\n";
foreach my $key (sort keys %errs) {
  if (-x _ ) {
    ($errtxt) = ((`$ENV{ORACLE_HOME}/bin/oerr ora $key`)[0] ||".");
    $errtxt =~ s/(^\w+, \w+,) "(.+)"/$2/;
    chomp($errtxt);
    }
  $ast = "";
  foreach my $excluded (@exclude_list) {
    if ($key == $excluded) {
      $ast = "*";
      $astx++;
      }
    }
  printf MAIL "%-12s  %5d  %s\n", "ORA-$key$ast", $errs{$key}, $errtxt
+;
  $errors += $errs{$key};
  }
print  MAIL "------------   -----\n";
printf MAIL "Grand Total   %5d\n\n", $errors;
print  MAIL "* denotes errors on the exclude list.\n\n" if $astx > 0;
close MAIL;


sub print_and_flush_stanza {
    my ($dt, $lt, @r) = @_;
    my $ora_errno = 0;
    my $ora_err_flag = 0;

    return
      if ($dt < $lt);  # only look at errors from the last 24 hours

    foreach my $line (@r) {
      if (($ora_errno) = $line =~ m/^ORA-(\d+)/) {
        $ora_errno = sprintf "%05d", $ora_errno; # count errors, but o
+nly
        $errs{$ora_errno}++;                     # display those not e
+xcluded.
        $ora_err_flag++;                         # flag it now.
        foreach my $excluded (@exclude_list) {
          if ($ora_errno == $excluded) {
            $ora_err_flag--;                     # unflag it. >1 means
+ some
            last;                                # error is included.
            }
          }
        }
      }
    # now print the stanza if there was an error there.
    if ($ora_err_flag) {
      foreach my $line (@r) {
        print MAIL $line;
        }
      print MAIL "\n";
      }
}