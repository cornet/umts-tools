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
use warnings;

BEGIN { push @INC, '/usr/share/umts-tools'; }

use UMTS::App;
use UMTS::DataLog::P2k;
use UMTS::DataLog::Packet;
use Getopt::Std;

use constant P2K_RRMM_DATA_IND        => 0x00013842;
use constant P2K_RRMM_DATA_REQ        => 0x00013801;
use constant P2K_RRMM_PACKET_DATA_IND => 0x00013853;
use constant P2K_RRMM_PACKET_DATA_REQ => 0x00013812;
use constant P2K_RRMM_EST_REQ         => 0x00013803;
use constant P2K_RRMM_PACKET_EST_REQ  => 0x00013811;
use constant P2K_GMMSM_UNITDATA_IND   => 0x0001E143;
use constant P2K_GMMSM_UNITDATA_REQ   => 0x0001E104;

my $script = "umts-p2klog.pl";

=head1 NAME

umts-p2klog.pl - A data log parser for Motorola P2k handsets

=head1 SYNOPSIS

B<umts-p2klog.pl> [options]

=head1 DESCRIPTION

The B<umts-p2klog.pl> script allows you parse binary logs captured on
Motorola P2k handsets with a tool such as B<datalog-tool> provided by
B<flash-tools>.

B<flash-tools> can be downloaded from L<http://flash-tools.jerryweb.org/>.

=head1 OPTIONS

 Options:
  -h          display a help message
  -i<input>   read input from <input> instead of standard input

=cut

# Display program usage
sub usage
{
  print "[ This is $script $UMTS::App::VERSION, a Motorola P2K data log parser ]\n\n",
        "Syntax:\n",
        "  $script [options]\n\n",
        " Options:\n",
        "  -i<input>   read input from <input> instead of standard input\n",
        "\n";
  exit 1;
}

# a process primitive
sub process_primitive
{
  my ($parser, $prim) = @_;

  if ($prim->{Body})
  {
    # extract layer 3 information
    my ($l3, $dir);
    if ($prim->{MsgID} == P2K_RRMM_DATA_IND) {
      my $tmp = $prim->{Body};
      my $len = unpack("C", $tmp);
      $l3 = substr($tmp, 1, $len);
      $dir = N_TO_MS;
    } elsif ($prim->{MsgID} == P2K_RRMM_DATA_REQ) {
      my $tmp = substr($prim->{Body}, 6);
      my $len = unpack("C", $tmp);
      $l3 = substr($tmp, 1, $len);
      $dir = MS_TO_N;
    } elsif ($prim->{MsgID} == P2K_RRMM_PACKET_EST_REQ) {
      my $tmp = substr($prim->{Body}, 10);
      my $len = unpack("n", $tmp);
      $l3 = substr($tmp, 2, $len);
      $dir = MS_TO_N;
    } elsif ($prim->{MsgID} == P2K_RRMM_PACKET_DATA_REQ) {
      my $tmp = substr($prim->{Body}, 4);
      my $len = unpack("n", $tmp);
      $l3 = substr($tmp, 2, $len);
      $dir = MS_TO_N;
    } elsif ($prim->{MsgID} == P2K_RRMM_EST_REQ) {
      my $tmp = substr($prim->{Body}, 8);
      my $len = unpack("n", $tmp);
      $l3 = substr($tmp, 2, $len);
      $dir = MS_TO_N;
    } elsif ( ($prim->{MsgID} == P2K_GMMSM_UNITDATA_IND) 
           || ($prim->{MsgID} == P2K_RRMM_PACKET_DATA_IND) ) {
      my $tmp = $prim->{Body};
      my $len = unpack("n", $tmp);
      $l3 = substr($tmp, 2, $len);
      $dir = N_TO_MS;
    } elsif ($prim->{MsgID} == P2K_GMMSM_UNITDATA_REQ) {
      my $tmp = $prim->{Body};
      my $len = unpack("n", $tmp);
      $l3 = substr($tmp, 2, $len);
      $dir = MS_TO_N;
    }
    return if (!$l3);

    my $p = UMTS::DataLog::Packet->new(
      'dir' => $dir,
      'level' => 0,
      'stamp' => $prim->{TimeStamp},
      'data' => $l3
    );
    $p->process_L3;
    print "\n";
  }
}

# the main routine
sub main
{
  my %opts;
  if ( not getopts('hi:', \%opts) or $opts{'h'}) {
    &usage();
  }
  
  my $file = $opts{i} ? $opts{i} : "-";
  
  my $parser = UMTS::DataLog::P2k->new;
  $parser->{callback} = \&process_primitive;
  my $nprim = $parser->parse($file);
}

&main;
