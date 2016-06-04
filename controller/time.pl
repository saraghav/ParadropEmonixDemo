#!/usr/bin/perl

use IO::Socket;
use Getopt::Long ;

my $port = 2001 ;
my ($socket,$received_data);
my ($peeraddress,$peerport);


open(PIDFILE, ">/var/run/ntp_lite.pid") ;
print PIDFILE $PID;
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


while(1)
{
#	print "Calling recv\n";
	# read operation on the socket
	$socket->recv($received_data,1024);

	#get the peerhost and peerport at which the recent data received.
	$peer_address = $socket->peerhost();
	$peer_port = $socket->peerport();
	print "($peer_address:$peer_port) $received_data\n";

	#send the data to the client at which the read/write operations done recently.
	$t = time;
	print "time = $t\n";
#	print $socket "$data";
	$socket->send("$t", $peer_address) or die "Client send: $!\n"; 
}

$socket->close() ;


