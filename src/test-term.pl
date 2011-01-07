#!/usr/bin/perl

use Test::Harness;
use Getopt::Std;
use UMTS::Test;

$Test::Harness::Verbose = 1;

my $script = "test-term.pl";

my @alltests = qw(
  UMTS/Test/AT.t
);


=item B<init> - Get command-line arguments

=cut 
# 
sub init
{
  my %opts;
  if ( not getopts('dhl:p:z', \%opts) or $opts{'h'}) {
    &usage();
  }

  #if (@ARGV < 2) {
  #  print "Too few arguments!\n";
  #  usage();
  #}

  if ($opts{z}) {
    UMTS::Test->writeParams({
      Terminal => "UMTS::Dummy::$opts{z}"
    });
  } elsif ($opts{p}) {
    UMTS::Test->writeParams({
      Terminal => 'UMTS::Terminal',
      Port => $opts{p},
    });  
  } else {
    UMTS::Test->clearParams;
  }  

  return %opts;
}


=item B<usage> - Display program usage

=cut 

sub usage
{
  print "[ This is $script $UMTS::App::VERSION, a test tool for GSM/UMTS terminals ]\n\n",
        "Syntax:\n",
        "  $script [options]\n\n",
        " Options:\n",
        "  -d          debugging mode\n",
        "  -h          display this help message\n",        
        "  -l<log>     write log to <log>\n",
        "  -p<port>    terminal is connected to serial port <port>\n",
        "              e.g. '\\\\.\\COM12', '/dev/usb/acm/0'\n",
        "  -z<term>    use dummy terminal\n",                
        "\n";
  exit 1;
}


=item B<main> - Main routine

=cut 

sub main
{
  my %opts = &init;
  
  runtests(@alltests);
}

&main;
