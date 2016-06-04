#!/bin/bash

echo $#

usage()
{
	echo "Usage: $0 <ip address> <state>";
	echo "Where <state> is open or close";
}

if [ $# -ne 2 ]
then
	usage;
	exit;
fi

if [ $2 == "open" ]
then
	echo "Opening vent";

	echo -n "setpwm 1 4000 200" | nc -u -q1 $1 48879
elif [ $2 == "close" ]
then
	echo "Closing vent";

	echo -n "setpwm 1 4000 550" | nc -u -q1 $1 48879
else
	usage;
	exit;
fi

sleep 3;

# Turn servo off.
echo -n "setpwm 1 4000 4500" | nc -u -q1 $1 48879

