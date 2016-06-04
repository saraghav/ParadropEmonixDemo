#!/usr/bin/perl

use IO::Socket;
use Getopt::Long ;

my $port = 2000 ;
my ($socket,$received_data);
my ($peeraddress,$peerport);

open(PIDFILE, ">", "/var/run/listener.pid") or die $!;
print PIDFILE $$;
close(PIDFILE);

my $result = GetOptions("port=i" =>\$port) ;

$masterdir = "/home/ubuntu/smartvent/";
mkdir($masterdir) or die ($! . "; unable to create directory $masterdir");

open(LOG, ">$masterdir/listener.log") or die $!;
select(LOG);
$| = 1;

print "trying to create socket\n";
my $socket = new IO::Socket::INET (
#                                 LocalHost => 'snail.wings.cs.wisc.edu',
                                 LocalPort => $port,
                                 Proto => 'udp',
#                                 Listen => 1,
#                                 Reuse => 1,
                                );
die "Could not create socket: $!\n" unless $socket;
print "successfully created socket\n";

print "Port = $port\n" ;
while(1)
{
	print "Calling recv\n" ;
	# read operation on the socket
	$socket->recv($received_data,1024);

	#get the peerhost and peerport at which the recent data received.
	$peer_address = $socket->peerhost();
	$peer_port = $socket->peerport();
	print "($peer_address:$peer_port) $received_data\n";

  if ($received_data =~ m/^\s*insert/i) {
    if ($received_data =~ m/vpn_ip/i) {
      &process_sql_user_details($received_data, $masterdir);
    } elsif ($received_data =~ m/temperature/i) {
      &process_sql_insert($received_data, "$masterdir/raw.csv", "$masterdir/data.csv");
    }
  } elsif ($received_data =~ m/^update.*vpn_ip/i) {
    &process_sql_sensor_ip($received_data, $masterdir);
  }

  print $socket "0";

	eval{
		$socket->send("0") or die "Server send: $!\n";
	};
}

close(LOG);

$socket->close() ;

sub process_sql_user_details {
  $sql = shift;
  $dir = shift;

  $sql =~ s/^\s*insert\s+into\s+(\S+)\s+//i;

  # separate the (label,value) pairs
  @separated = split(m/\s+values\s+/i, $sql);
  for $str (@separated) {
    $str =~ s/^\(//;
    $str =~ s/\);*$//;
  }
  @labels = split(m/,/, $separated[0]);
  @values = split(m/,/, $separated[1]);

  for ($i=0 ; $i<=$#labels ; $i++) {
    $label = $labels[$i];
    $value = $values[$i];
    `echo '$value' > $dir/$label`;
  }
}

sub process_sql_sensor_ip {
  $sql = shift;
  $dir = shift;

  $sql =~ m/^\s*update.*(vpn_ip)=\S+'(\d+\.\d+\.\d+\.\d+)'/;
  $label = $1;
  $value = $2;
  `echo '$value' > $dir/$label`;
}

sub process_sql_insert {
  $sql = shift;
  $rawfile = shift;
  $datafile = shift;

  $sql_orig = $sql;

  # get the table name
  $sql =~ s/^\s*insert\s+into\s+(\S+)\s+//i;
  $table = $1;

  # separate the (label,value) pairs
  @separated = split(m/\s+values\s+/i, $sql);
  for $str (@separated) {
    $str =~ s/^\(//;
    $str =~ s/\);*$//;
  }
  @labels = split(m/,/, $separated[0]);
  @values = split(m/,/, $separated[1]);

  @datalabels = ();
  @datavalues = ();

  # display it to the user
  for ($i=0; $i<=$#labels; $i++) {
    if ($values[$i] =~ m/from_unixtime\((\d+)\)/i) {
      $values[$i] = $1;
    }

    $label = $labels[$i];
    $rawval = $values[$i];
    $dataval = eval($rawval);

    push(@datalabels, $label);
    push(@datavalues, $dataval);
  }

  push(@labels, "sql");
  push(@values, $sql_orig);

  push(@datalabels, "table");
  push(@datavalues, $table);

  $write_header = 0;
  $header_csv = join(',', @labels);
  $values_csv = join(',', @values);
  $write_header = 1 if (! -e $rawfile);
  open(RAW, ">>", $rawfile) or die($! . "; unable to open $rawfile");
  flock(DATA, 2); # exclusive lock
  print RAW $header_csv . "\n" if ($write_header == 1);
  print RAW $values_csv . "\n";
  close(RAW);

  $write_header = 0;
  $header_csv = join(',', @datalabels);
  $values_csv = join(',', @datavalues);
  $write_header = 1 if (! -e $datafile);
  open(DATA, ">>", $datafile) or die($! , "; unable to open $datafile");
  flock(DATA, 2); # exclusive lock
  print DATA $header_csv . "\n" if ($write_header == 1);
  print DATA $values_csv . "\n";
  close(DATA);
}
