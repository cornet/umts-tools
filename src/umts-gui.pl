#!/usr/bin/perl -w

use strict;      # a good idea for all non-trivial Perl scripts
use warnings;

BEGIN { push @INC, '/usr/share/umts-tools'; }

use Gtk2 '-init';
use UMTS::App;
use UMTS::Phonebook;
use UMTS::GUI::Main;
use Getopt::Std;

# script name
my $script = "umts-gui.pl";

=head1 NAME

umts-gui.pl - A graphic user interface for GSM/UMTS terminals

=head1 SYNOPSIS

B<umts-gui.pl> [options]

=head1 DESCRIPTION

B<umts-gui.pl> is the graphic user interface of the umts-tools package. Most
of its functionalities work well, but it should still be considered as
experimental as it is relatively young compared to the other umts-tools
scripts.

B<umts-gui.pl> makes use of Gtk2::Perl, so you will need to make sure that
Gtk2::Perl is installed in order to run the script.

=head1 OPTIONS

Common options:
  -d          debugging mode
  -l<log>     write log to <log>
  -h          display this help message
  -p<port>    terminal is connected to serial port <port>
              e.g. '\\.\COM12', '/dev/usb/acm/0'
  -z          use dummy terminal

=cut 


# Get command-line arguments
sub init
{
  my %opts;
  if ( not getopts('dhl:p:z', \%opts) or $opts{'h'}) {
    &usage();
  }

  return UMTS::App->parse_opts(%opts);    
}


# Display program usage
sub usage
{
  print "[ This is $script $UMTS::App::VERSION, a graphic user interface for GSM/UMTS terminals ]\n\n",
        "Syntax:\n",
        "  $script [options]\n\n",
        UMTS::App->usage;
  exit 1;
}


# The main routine
sub main
{
  my $config = &init;
  
  my $log = UMTS::App->make_log($config);  
  my $term = UMTS::App->make_term($config, $log) or
    die("Could not open terminal");

  # widget creation
  my $window = new UMTS::GUI::Main(config => $config, log => $log, term => $term);  
  $window->show();
  
  # Gtk event loop
  Gtk2->main;
  
  # Should never get here
  exit( 0 );
}

&main;
      
