# Author: Adam Richards
# read input file Line by line and process
# write results to output file
# designed to handle very large files
my $scriptName= $0;
my $argn = $#ARGV +1;

# check syntax
if ($argn < 1)
{
  print "Syntax $0 inputFile [outputFile]\n";
  exit 1;
}
my $inputFile = $ARGV[0];
# setup output handle STDOUT or file
my $outHandle  = \*STDOUT;
if ($argn == 2 && length(trim($ARGV[1])) > 0)
{
  my $outFile = $ARGV[1];
  open($outHandle, '>', $outFile) or do
  {
  warn "$0: failed to open outfile $outFile: $!";
  return 2;
  } 
} 
##################################################
# set line terninator
local $/ = "\n";
local $currentDateTime = &getCurrentDateTime();
local $fileChecksum = &fauxCheckSumFile($inputFile);
local $basename = &getBaseFileName($inputFile);
my $rc = &processFile($inputFile,$outHandle);

close $outHandle or do
  {
  warn "$0: close $outFile: $!";
  return 2;
  };

exit $rc;
##################################################
# Open the file for read access:
sub processFile
{
  my $fileName = @_[0];
  my $newline;

  open my $filehandle, '<', $fileName or do {
  warn "$0: open $fileName $!";
  return 1;
  };

  my $line_number = 0;

  # Loop through each line:
  while (defined($line = <$filehandle>))
  {
  # The text of the line, including the linebreak
  # is now in the variable $line.

  # Keep track of line numbers
  $line_number++;

  # Strip the linebreak character at the end.
  chomp $line;
  my $validLine = validateLine($line);
  if ($validLine == 1 )
	  {
	  # Do something with the line.
	  my $newline = processLine($line,$line_number);
	  if ($line_number == 1)
	  {
		print $outHandle $newline;
	  }
	  else
	  {
		print $outHandle "\n".$newline;
	  }
  }
}


close $filehandle or do
  {
  warn "$0: close $fileName: $!";
  return 2;
  }
}

sub validateLine
{
 my $line = @_[0];
 $line =~ s/^\s+|\s+$//g;
 if (length(trim($line)) == 0)
	{
	warn "Empty line\n";
	return 0;
	}
 return 1;
}
sub processLine
{
  my $line = @_[0];
  #UTF8 Removal
  #Strip BOM if unicode file
  # $line =~ s/^\xEF\xBB\xBF//;
  #replace any non ascii char with _
  # $line =~s/[^[:print:]]/_/g;
  my $line_number = @_[1];
  my $lineChecksum = fauxCheckSum($line);
  #parse fixed width line
  my $formatString = 'A6A30A12A1A11A11A9A3A7A5A15A1A9A20A5A5A2A30A2A10A20A2A9A5A4A55A55A1A10A10A10A30A10';
  $formatString .= 'A10A1A1A30A4A4A4A4A1A4A25A*';
  my @parseArray = unpack($formatString,$line);
  my $rv = join('|',@parseArray);
  $rv = "$line_number|$basename|$fileChecksum|$lineChecksum|$currentDateTime|".$rv;
  return $rv;
}
############################################################################
# Utility Functions
############################################################################
sub trim {
  my $rv = $_[0] ;
  $rv =~ s/^\s+|\s+$//g;
   return $rv;
}

sub getBaseFileName
{
  my $str = @_[0];
  my $pathsep = quotemeta(&getFileSeparator());
  my @parts = split(/$pathsep/,$str);
  return $parts[$#parts];
}

sub getFileSeparator
{
  if ($^O =~ m/WIN/i )
    {
      return '\\';
    }
    return '/';
}

sub getCurrentDateTime
{
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
  my $now = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);
  return $now;
}

sub fauxCheckSumFile
{
  my $fileName = @_[0];
  
  my $chk=0;
  open my $filehandle, '<', $fileName or do {
  die "$0: open $fileName $!";
  };

  while (defined($line = <$filehandle>))
  {
  chomp $line;
  $chk += &fauxCheckSum($line);
  $chk = $chk % (2 ** 32);
  }
  close $filehandle or do
  {
  die "$0: close $fileName: $!";
  };
  return $chk;
}

sub fauxCheckSum
{
  my $line = @_[0];
  my $modValue=10;
  my $counter =0;
  my $rv=1;
  for (my $key = 0; $key < length($line); $key++) 
  {
    my $c= substr ($line, $key, 1);
    my $multiplyer = 10 ** ($counter % $modValue);
    $rv +=  $multiplyer * ord($c);
    $counter++;
  }
  
    #$rv += unpack('%64C*',$v) % 65535;
  return $rv;  
}