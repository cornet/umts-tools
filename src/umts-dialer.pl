#!/usr/bin/perl
#
# umts-tools - tools for manipulating 3G terminals
# Copyright (C) 2004-2005 Jeremy Laine <jeremy.laine@m4x.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#

use strict;

BEGIN { push @INC, '/usr/share/umts-tools'; }

use UMTS::App;
use UMTS::Dialer;
use UMTS::Log;
use Getopt::Std;
use POSIX qw(strftime);

my $script = "umts-dialer.pl";

=head1 NAME

umts-dialer.pl - A GSM/UMTS mass dialing tool

=head1 SYNOPSIS

B<umts-dialer.pl> [options] <number>

=head1 DESCRIPTION

A recurrent task in terminal testing is to produce Key Performance
Indicators (KPI), that is to say measurements of how well the
terminal performs. This is usually achieved through drive tests,
which means making a large number of calls to an answering machine
from one or more terminals placed in vehicle and measuring the number
of call setup failures and call drops.

The B<umts-dialer.pl> script provides a means of performing such
drive tests in an automatic fashion as it is capable of mass call
dialing, detecting call setup success or failure, monitoring call
drops and producing the statistics of the run.

=head1 CALL MONITORING MECHANICS

A call can be broken down into the following steps:

=over 4

=item B<dial call>

Issue the ATDxxxx; to dial an number and examine the reply of the
ATD command, OK means success, anything else is a call setup failure.

=item B<check call setup>

The terminal is periodically polled by looking either at the list of
current calls (AT+CLCC) or the phone activity status (AT+CPAS) until
it finishes dialing and alerting. The possible outcomes are either we
have an active call, in which case we have a successful call setup,
or we have no active calls in which case we have a call setup
failure.

=item B<monitor call>

The terminal is periodically polled by looking either at the list of
current calls (AT+CLCC) or the phone activity status (AT+CPAS) for a
specified call duration and we check we still have an active call. If
this is not the case, we have a dropped call and we sleep until the
end of the expected call time.

=item B<hangup call>

Issue the ATH command to hangup the terminal.

=back

=head1 OPTIONS

 Common options:
  -d          debugging mode
  -h          display this help message
  -p<port>    terminal is connected to serial port <port>
              e.g. '\\.\COM12', '/dev/usb/acm/0'
  -z          use dummy terminal
 
 Options:
  -c<calls>   make <calls> calls (default : 1000)
  -l<prefix   write log to <prefix>_log.txt and
              write results to <prefix>_results.txt
  -t<time>    make <time> second calls (default: 120s)
  -v          make video calls
  -w<wait>    wait for <wait> seconds between calls (default: 60s)

=cut

# Get command-line arguments
sub init
{
  my %opts;
  if ( not getopts('dhl:p:zc:t:vw:', \%opts) or $opts{'h'}) {
    &usage();
  }
  my $config = UMTS::App->parse_opts(%opts);    
    
  if (@ARGV < 1) {
    print "Too few arguments!\n";
    &usage();
  }
  
  if (!$opts{l}) {
    $opts{l} = strftime("%d-%b-%Y_%H-%M-%S", localtime);
  }
  
  if (!$opts{c}) {
    $opts{c} = 1000;
  }

  if (!$opts{t}) {
    $opts{t} = 120;
  }
  
  if (!$opts{w}) {
    $opts{w} = 60;
  }  
  
  return ($config, %opts);
}


# Display program usage
sub usage
{
  print "[ This is $script $UMTS::App::VERSION, a GSM/UMTS mass dialing tool ]\n\n",
        "Syntax:\n",
        "  $script [options] <number>\n\n",
        UMTS::App->usage,
        " Options:\n",
        "  -c<calls>   make <calls> calls (default : 1000)\n",        
        "  -l<prefix   write log to <prefix>_log.txt and\n",
        "              write results to <prefix>_results.txt\n",
        "  -t<time>    make <time> second calls (default: 120s)\n",
        "  -v          make video calls\n",
        "  -w<wait>    wait for <wait> seconds between calls (default: 60s)\n",
        "\n";
  exit 1;
}


# The main routine
sub main
{
  my ($config, %opts) = &init;
  
  # extract parameters
  my $dest = shift @ARGV;
  my $call_max = $opts{c};
  my $call_duration = $opts{t};
  my $call_type = $opts{v} ? 'video' : 'voice';
  my $call_wait = $opts{w};
    
  # create logs
  my $log = UMTS::Log->new("$opts{l}_log.txt");
  my $reslog = UMTS::Log->new("$opts{l}_results.txt");

  
  # open terminal
  my $terminal = UMTS::App->make_term($config, $log);
  
  if (!ref($terminal))
  {
    $log->write("Can't open terminal, aborting.");
    exit 1;
  }
  
  # create and launch dialer
  my $dialer = UMTS::Dialer->new(
    term => $terminal,
    call_number => $dest,
    call_max => $call_max,
    call_duration => $call_duration,
    call_wait => $call_wait,
    call_type => $call_type,
    log => $log,
    reslog => $reslog
  );
  
  $dialer->run;
  $terminal->close;
    
  exit 0;
}

&main;
