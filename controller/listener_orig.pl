#!/usr/bin/perl

use IO::Socket;
use Getopt::Long ;
use DBI ;


my $port = 2000 ;
my ($socket,$received_data);
my ($peeraddress,$peerport);
my $data_db_name = 'test' ;
my $dbhost = 'localhost' ;
my $user = 'root';
my $password = '699.tmp' ;


open(PIDFILE, ">/var/run/listener.pid") ;
print PIDFILE, $PID;
close(PIDFILE);

my $result = GetOptions("port=i" =>\$port) ;

my $socket = new IO::Socket::INET (
#                                 LocalHost => 'snail.wings.cs.wisc.edu',
                                 LocalPort => $port,
                                 Proto => 'udp',
#                                 Listen => 1,
#                                 Reuse => 1,
                                );
die "Could not create socket: $!\n" unless $socket;

dbConnect() ;

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

	# Issue the SQL query to the DB.
	$sqlQuery = $data_dbh->prepare($received_data) or die "Can't prepare SQL query: $data_dbh->errstr\nsqlQuery = $sqlQuery" ;
	eval{$rv = $sqlQuery->execute or die "Your mom has aids.\n"};
	if($@)
	{
		#logmessage("SQL Query Failed to Execute. Error:$!. SQL:'$sql'");
		dbConnect() ;
		print "SQL Query Failed to execute. $!" ;
	}

	$rv = $sqlQuery->finish ;
	
	#send the data to the client at which the read/write operations done recently.
#	$data = "data from server\n";
#	print $socket "$data";
}

$socket->close() ;

sub dbConnect
{
	my $errstr = "[dbConnect] Attempting to connect to database\n";

	while($errstr)
	{
		print $errstr ;

		# Set up database connection.
		eval
		{
			$data_dbh = DBI->connect("DBI:mysql:$data_db_name:$dbhost", $user, $password) or die "Can't open data_dbh: $data_dbh->errstr";
		};

		$errstr = $@ ;
		if($errstr)
		{
			sleep 2;
		}
	}
}


