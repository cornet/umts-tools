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
use vars qw(@ISA @EXPORT);

use Exporter;
use Data::Dumper;

@ISA = qw(Exporter);
@EXPORT = qw(checkSMS_UD checkNBS checkProps);

sub checkProps
{
  my ($pkt_a, $pkt_b, $title, @props) = @_;

  #print "\n--- SOURCE $title ---\n". Dumper($pkt_a);
  #print "\n--- DECODED $title ---\n" . Dumper($pkt_b);

  foreach my $prop(@props)
  {
    my $a_val = defined($pkt_a->{$prop}) ? "`$pkt_a->{$prop}`" : "undef";
    my $b_val = defined($pkt_b->{$prop}) ? "`$pkt_b->{$prop}`" : "undef";

    my $ok = ( (!defined($pkt_a->{$prop}) and !defined($pkt_b->{$prop})) or
               ( defined($pkt_a->{$prop}) and defined($pkt_b->{$prop}) and
                 ($pkt_a->{$prop} eq $pkt_b->{$prop}) ) );
    ok($ok, "$title property '$prop' matches ($a_val vs $b_val)");
  }
}

# check SMS UserData properties
sub checkSMS_UD
{
  my ($pkt_a, $pkt_b) = @_; 
  my @props = qw(dcs drn src_port fsn data dest_port fmax);
  checkProps($pkt_a, $pkt_b, "SMS::PDU::UserData", @props);
}

# check SMS Submit properties
sub checkSMS_Submit
{
  my ($pkt_a, $pkt_b) = @_;
  my @props = qw(TP-UDHI TP-RP TP-SRR TP-VPF TP-RD TP-MTI TP-PID TP-REF smsc TP-DA TP-DCS TP-VP);
  checkProps($pkt_a, $pkt_b, "SMS::PDU::Submit", @props);
  checkSMS_UD($pkt_a->{'TP-UD'}, $pkt_b->{'TP-UD'});
}

# check SMS Deliver properties
sub checkSMS_Deliver
{
  my ($pkt_a, $pkt_b) = @_;
  my @props = qw(TP-UDHI TP-RP TP-PID smsc TP-OA TP-DCS TP-MTI);
  checkProps($pkt_a, $pkt_b, "SMS::PDU::Deliver", @props);
  checkSMS_UD($pkt_a->{'TP-UD'}, $pkt_b->{'TP-UD'});
}

# check SMPP packet properties
sub checkSMPP
{
  my ($pkt_a, $pkt_b) = @_;

  my @props = qw(cmd class dcs delivery from msisdn predef priority proto registered replace status seq tos vp);
  checkProps($pkt_a, $pkt_b, "SMPP", @props);
  checkSMS_UD($pkt_a->{ud}, $pkt_b->{ud});
}
