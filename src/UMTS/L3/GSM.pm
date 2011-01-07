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
package UMTS::L3::GSM;

use strict;
use warnings;
use vars qw(@ISA);

use Carp ();
use UMTS::L3;

@ISA = qw(UMTS::L3);

use constant GSM_ACTIVATE_PDP_REQUEST => 0x41;
use constant GSM_ACTIVATE_PDP_ACCEPT  => 0x42;
use constant GSM_ACTIVATE_PDP_REJECT  => 0x43;
use constant GSM_REQUEST_PDP_ACTIVATION  => 0x44;
use constant GSM_REQUEST_PDP_ACTIVATION_REJECT  => 0x45;
use constant GSM_DEACTIVATE_PDP_REQUEST => 0x46;
use constant GSM_DEACTIVATE_PDP_ACCEPT  => 0x47;

use constant IEI_PROTO_CONF_OPTS => 0x27;
use constant IEI_APN             => 0x28;
use constant IEI_PDP_ADDRESS     => 0x2B;

our $PROTO = "GPRS Session Management";
our $TYPES =
{
  'Activate PDP context request'   => GSM_ACTIVATE_PDP_REQUEST,
  'Activate PDP context accept'    => GSM_ACTIVATE_PDP_ACCEPT,
  'Activate PDP context reject'    => GSM_ACTIVATE_PDP_REJECT,
  'Deactivate PDP context request' => GSM_DEACTIVATE_PDP_REQUEST,
  'Deactivate PDP context accept'  => GSM_DEACTIVATE_PDP_ACCEPT,
};


=head1 NAME

UMTS::L3::GSM - Class encapsulating GPRS Session Management messages

=head1 SYNOPSIS

  use UMTS::L3::GSM;
  $sm = UMTS::L3::GSM->decode($binstr);

=head1 DESCRIPTION

The C<UMTS::L3::GSM> class allows you to decode
GPRS Session Management messages.

The following methods are available:

=over 1

=item UMTS::L3::GSM->decode

Decode a GPRS Session Management message from a binary string.

=cut

sub decode
{
  my $class = shift;
  my $pkt = shift;

  # decode common L3 header
  (my $self, $pkt) = $class->decode_header($pkt);

  ($self->{PD} == L3_PD_GSM) or 
    Carp::croak("UMTS::L3::GSM : bad Protocol Discriminator");

  if ($self->{MTI} == GSM_ACTIVATE_PDP_REQUEST)
  {
    my ($a, $b) = unpack('CC', $pkt);
    $self->{NSAPI} = ($a & 0x0F);
    $self->{LLCSAPI} = ($b & 0x0F);
    $pkt = substr($pkt, 2);

    # QoS
    my $len = unpack('C', $pkt);
    $pkt = substr($pkt, 1 + $len);

    # Requested PDP address
    $len = unpack('C', $pkt);
    $pkt = substr($pkt, 1 + $len);

    # Optional elements
    $self->unpack_opt_elements($pkt);
  
  } elsif ($self->{MTI} == GSM_ACTIVATE_PDP_ACCEPT) {
    my $a = unpack('C', $pkt);
    $self->{LLCSAPI} = $a & 0x0F;
    $pkt = substr($pkt, 1);

    # QoS
    my $len = unpack('C', $pkt);
    $pkt = substr($pkt, 1 + $len);
   
    # Radio priority
    $a = unpack('C', $pkt);
    $self->{RadioPriority} = $a & 0x0F;
    $pkt = substr($pkt, 1);

    # Optional elements
    $self->unpack_opt_elements($pkt);

  } elsif ($self->{MTI} == GSM_DEACTIVATE_PDP_REQUEST) {
    $self->{Cause} = unpack('C', $pkt);
    $pkt = substr($pkt, 1);
  } elsif ($self->{MTI} == GSM_DEACTIVATE_PDP_ACCEPT) {
  
  }
  return $self;
}


sub pack_apn_value
{
  my $name = shift;
  my @labels = split /\./, $name;
  my $bin = '';
  foreach my $lbl (@labels)
  {
    $bin .= pack('C', length($lbl)) . $lbl;
  }
  return $bin;
}

sub unpack_apn_value
{
  my $pkt = shift;
  my @labels;
  while (length($pkt))
  {
    my $len = unpack('C', $pkt);
    push @labels, substr($pkt, 1, $len);
    $pkt = substr($pkt, 1 + $len);
  }
  return join '.', @labels;
}

sub unpack_pdp_address
{
  my $pkt = shift;
  my ($len, $torg, $tnum) = unpack('CCC', $pkt);
  my $addr = substr($pkt, 3, $len - 2);
  $pkt = substr($pkt, 3 + $len);
  return '';
}

sub unpack_opt_elements
{
  my ($self, $pkt) = @_;
  while (length($pkt))
  {
    my ($iei, $ilen) = unpack('CC', $pkt);
    my $data = substr($pkt, 2, $ilen);
    $pkt = substr($pkt, 2 + $ilen);
    if ($iei == IEI_APN) {
      $self->{APN} = unpack_apn_value($data);
    } elsif ($iei == IEI_PDP_ADDRESS) {
      $self->{PDP_ADDRESS} = unpack_pdp_address($data);
    } else {
      #print "IEI : $iei\n";
      #print "Len : $ilen\n";
    }
  }
}


1;
=back

