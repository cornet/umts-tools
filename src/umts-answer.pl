#!/usr/bin/perl

use strict;

BEGIN { push @INC, '/usr/share/umts-tools'; }

use UMTS::App;
use UMTS::Core;
use Getopt::Std;

my $script = "umts-answer.pl";

=head1 NAME

umts-answer.pl - A GSM/UMTS call answering tool

=head1 SYNOPSIS

B<umts-answer.pl> [options]

=head1 DESCRIPTION

The B<umts-answer.pl> script allows you to automatically answer
mobile-terminated phone calls.

=head1 OPTIONS

 Common options:
  -d          debugging mode
  -l<log>     write log to <log>
  -h          display this help message
  -p<port>    terminal is connected to serial port <port>
              e.g. '\\.\COM12', '/dev/usb/acm/0'
  -z          use dummy terminal

=head1 TODO

Fix compatibility with UMTS::Dummy.

=cut 


# Get command-line arguments
sub init
{
  my %opts;
  if ( not getopts('dhl:p:z', \%opts) or $opts{'h'}) {
    &usage();
  }
   
  my $config = UMTS::App->parse_opts(%opts);  
  return $config;
}


# Display program usage
sub usage
{
  print "[ This is $script $UMTS::App::VERSION, a GSM/UMTS call answering tool ]\n\n",
        "Syntax:\n",
        "  $script [options]\n\n",
        UMTS::App->usage;
  exit 1;
}


# The main routine
sub main
{
  my $config = &init;

  my %results = (
    rings => 0,
    anwsers => 0
  );
  
  # this is called if the program is interrupted
  $SIG{INT} = \&cleanup;
  
  my $log = UMTS::App->make_log($config);  
  my $term = UMTS::App->make_term($config, $log) or
    die("Could not open terminal");
  
  # this function takes care of cleaning up
  sub cleanup
  {
    my $msg = shift;
    
    ($msg eq "INT") and
    $msg = "caught interrupt";
    
    $log->write("cleanup : $msg");
    
    # hangup the modem and close the port
    if (ref ($term)) {
      $term->hangupVoice;
      $term->close;
    }
    
    # output the results
    &showResults;
    exit 1;
  };
  
  sub showResults
  {
    $log->write("rings    : $results{rings}");
    $log->write("answered : $results{answers}");
  };
  
 
  while (1) {
    $log->write("waiting for incoming call..");
    # attendre 'RING'
    my $got = $term->waitfor;
  
    if ($got eq 'RING') {
      $results{rings}++;
      
      # repondre
      $log->write("call received, answering..");    
      $term->send("ATA" . CR);
      
      if (($term->waitfor eq 'OK') and ($term->checkCallEstablished eq RET_OK))
      {
        $log->write("OK, answered call, waiting for call termination..");
        $results{answers}++;
        
        # wait for call termination, polling every 5 seconds
        $term->monitorCall(0, 5);
        
      } else {
        $log->write("ERROR, failed to answer call");
      }
      
    }  
  }
  
  &cleanup;
  exit 0;
}


&main;
