#!/usr/bin/perl
BEGIN {
  $| = 1;
}
use strict;
use Cwd qw/abs_path/;
use File::Basename;

my $masterdir = "/home/ubuntu/smartvent";
my $bindir = dirname(abs_path($0));

my $datafile = "$masterdir/data.csv";
my $vent_ctrl_script = "$bindir/setvent.sh";
my $vent_ip_addr_file = "$masterdir/vpn_ip";
  
my $vent_cmd_common = "sudo $vent_ctrl_script `cat $vent_ip_addr_file`";
my $vent_cmd_open = "$vent_cmd_common open";
my $vent_cmd_close = "$vent_cmd_common close";

my $last_position = 0; # last position read in data.csv file
my $temperature_value_index = 0; # index of the temperature value in the file
my $timestamp_value_index = 0; # index of the timestamp value in the file

my $last_action = 0; # last action taken on the vent
my @temperature_log = (); # log of the temperature values
my @timestamp_log = (); # log of the timestamp values
my $log_size = 2; # how many values to retain in memory for processing
my $temperature_threshold = 25; # temperature threshold in C for vent state transition

print "waiting for data file to be created\n";
while (!-e $datafile) {
  sleep(5);
}
print "...done\n";

while(1) {
  &control_vent();
  sleep(5);
}

sub control_vent {
  open(DATA, "<$datafile") or die($! . "; unable to open $datafile");
  flock(DATA, 1); # shared read lock
  seek DATA, $last_position, 0;
  while (my $line = <DATA>) {
    chomp $line;
    if ($line =~ m/sensor_id/) {
      # find temperature_value_index
      my @column_names = split(m/,/, $line);
      for (my $i=0; $i<=$#column_names; $i++) {
        if ($column_names[$i] =~ m/temperature/i) {
          $temperature_value_index = $i;
        }
        if ($column_names[$i] =~ m/timestamp/i) {
          $timestamp_value_index = $i;
        }
      }
    } else {
      # add temperature value to log
      my @values = split(m/,/, $line);
      my $temperature = $values[$temperature_value_index];
      my $timestamp = $values[$timestamp_value_index];
      &add_to_log($temperature, $timestamp);
    }
  }
  $last_position = tell(DATA);
  close(DATA);

  # determine action
  if ( ($#temperature_log+1) == $log_size ) {
    my $mean_temperature = 0;
    for (my $i=0; $i<=$#temperature_log; $i++) {
      $mean_temperature += $temperature_log[$i];
    }
    $mean_temperature /= $log_size;

    print "\tlast read timestamp = " . $timestamp_log[$#timestamp_log] . "\n";

    if ($mean_temperature <= $temperature_threshold && $last_action != 1) {
      print "mean_temperature = $mean_temperature, temperature_threshold = $temperature_threshold\n";
      print "$vent_cmd_close\n";
      `$vent_cmd_close`;
      $last_action = 1;
    } elsif ($mean_temperature > $temperature_threshold && $last_action != 2) {
      print "mean_temperature = $mean_temperature, temperature_threshold = $temperature_threshold\n";
      print "$vent_cmd_open\n";
      `$vent_cmd_open`;
      $last_action = 2;
    }
  }
}

sub add_to_log {
  my $temperature = shift;
  my $timestamp = shift;

  if ( ($#temperature_log+1) == $log_size ) {
    shift @temperature_log;
    shift @timestamp_log;
  }
  push(@temperature_log, $temperature);
  push(@timestamp_log, $timestamp);
}
