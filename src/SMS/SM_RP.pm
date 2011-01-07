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
package SMS::SM_RP;

use strict;
use warnings;

use Carp ();
use SMS::PDU;

use constant SM_RP_MO_DATA  => 0x0;
use constant SM_RP_MT_DATA  => 0x1;
use constant SM_RP_MO_ACK   => 0x2;
use constant SM_RP_MT_ACK   => 0x3;
use constant SM_RP_MO_ERROR => 0x4;
use constant SM_RP_MT_ERROR => 0x5;
use constant SM_RP_MO_SMMA  => 0x6;

our $SM_RP_TYPES =
{
  'RP-DATA (ms -> n)'  => SM_RP_MO_DATA,
  'RP-DATA (n -> ms)'  => SM_RP_MT_DATA,
  'RP-ACK (ms -> n)'   => SM_RP_MO_ACK,
  'RP-ACK (n -> ms)'   => SM_RP_MT_ACK,
  'RP-ERROR (ms -> n)' => SM_RP_MO_ERROR,
  'RP-ERROR (n -> ms)' => SM_RP_MT_ERROR,
  'RP-SMMA (ms -> n)'  => SM_RP_MO_SMMA,
};  


=head1 NAME

SMS::SM_RP - Class encapsulating SMS Control Protocol messages

=head1 SYNOPSIS

  use SMS::SM_RP;
  $s = SMS::SM_RP->decode($binstr);

=head1 DESCRIPTION

The C<SMS::SM_RP> class allows you to encode and decode
SMS Relay Protocol messages.

The following methods are available:

=over 1

=item SMS::SM_RP->decode

Decode an SMS Relay Protocol message from a binary string.

=cut

sub decode
{
  my $class = shift;
  my($pkt, $parent, @rest) = @_;
 
  my $self = {};

  (my $s, $self->{'RP-MR'}) = unpack('CC', $pkt);
  $pkt = substr($pkt, 2);
  $self->{'RP-MTI'} = $s & 0x7;
 
  if ( ($self->{'RP-MTI'} == SM_RP_MO_DATA) || 
       ($self->{'RP-MTI'} == SM_RP_MT_DATA) )
  {
    # RP-DATA
    my $olen = unpack('C', $pkt);
    $pkt = substr($pkt, 1 + $olen);

    my $dlen = unpack('C', $pkt);
    $pkt = substr($pkt, 1 + $dlen);

    my $mlen = unpack('C', $pkt);
    $pkt = substr($pkt, 1);
    if ($mlen != length($pkt))
    {
      Carp::croak("SM-RP length mismatch\n");
    }

    $self->{'RP-UD'} = $pkt;

  } elsif ( ($self->{'RP-MTI'} == SM_RP_MO_ACK) || 
            ($self->{'RP-MTI'} == SM_RP_MT_ACK) )
  {
    # RP-ACK
    $self->{'RP-UD'} = $pkt;

  } else {
    Carp::croak("SM-RP : unknown message type");
  }

  bless($self, $class);
}

sub msgType
{
  my $self = shift;
  my %type = reverse %{$SM_RP_TYPES};
  return $type{$self->{'RP-MTI'}};
}

1;
=back

