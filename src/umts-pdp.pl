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
use UMTS::PDP;
use Getopt::Std;

my $script = "umts-pdp.pl";

=head1 NAME

umts-pdp.pl - A PDP context tool for GSM/UMTS terminals

=head1 SYNOPSIS

B<umts-pdp.pl> [options]

=head1 DESCRIPTION

The B<umts-pdp.pl> script allows to use a GSM/UMTS terminal as
a modem by establishing a PDP context.

WARNING: this script has not undergone much testing, it is intended
more as a proof of concept than as an actual working tool.

=head1 OPTIONS

 Common options:
  -d          debugging mode
  -l<log>     write log to <log>
  -h          display this help message
  -p<port>    terminal is connected to serial port <port>
              e.g. '\\.\COM12', '/dev/usb/acm/0'
  -z          use dummy terminal

 Options:
  -i<init>    send the <init> AT initialisation string to the terminal
              for example 'AT+CGDCONT=2,"ip","myapn"'
  -n<number>  dial <number> to connect, for example '*99***2#'

=cut

# Get command-line arguments
sub init
{
  my %opts;
  if ( not getopts('dhl:p:i:n:', \%opts) or $opts{'h'}) {
    &usage();
  }

  my $config = UMTS::App->parse_opts(%opts);
  
  if (!defined($opts{g}) and (@ARGV < 0)) {
    print "Too few arguments!\n";
    usage();
  }
  
  return ($config, %opts);
}


# Display program usage
sub usage
{
  print "[ This is $script $UMTS::App::VERSION, a PDP tool for GSM/UMTS terminals ]\n\n",
        "Syntax:\n",
        "  $script [options]\n\n",
        UMTS::App->usage,
	" Options:\n",
        "  -i<init>    send the <init> AT initialisation string to the terminal\n",
	"              for example 'AT+CGDCONT=2,\"ip\",\"myapn\"'\n",
        "  -n<number>  dial <number> to connect, for example '*99***2#'\n",
        "\n";
  exit 1;
}


# The main routine
sub main
{
  my ($config, %opts) = &init;    
  my %params; 

  $params{port} = $opts{p} ? $opts{p} : $config->{port};
  $params{number} = $opts{n} ? $opts{n} : '*99#';
  $params{initstring} = $opts{i} ? $opts{i} : '';
  
  my $pdp = UMTS::PDP->new(%params);
  $pdp->start;

  my $sleep = 60;
  print "Sleeping for $sleep seconds..\n";
  sleep($sleep);

  $pdp->stop; 
  exit 0;
}

&main;

