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
package WSP::PDU::Disconnect;

use strict;
use warnings;
use vars qw(@ISA);

use WSP::PDU qw(:types :modes);
use WSP::Headers;

@ISA = qw(WSP::PDU);


=head1 NAME

WSP::PDU::Disconnect - Class encapsulating WSP Disconnect PDUs

=head1 SYNOPSIS

  use WSP::PDU::Disconnect;
  $h = WSP::PDU::Disconnect->decode;


=head1 DESCRIPTION

The C<WSP::PDU:Disconnect> class allows you to encode or decode Wireless
Session Protocol (WSP) Disconnect Protocol Data Units (PDU).

The following methods are available:

=over 3

=item WSP::PDU::Disconnect->decode( $pkt )

Construct a WSP::PDU by decoding a binary string.

=cut

sub decode
{
  my $class = shift;
  my $pkt = shift;
  
  my $self = {};
  bless($self, $class);

  # Decode WSP packet

  if (defined($pkt)) {
    $pkt = $self->decode_common_fields($pkt);
    Carp::croak("WSP::PDU::Disconnect : bad Type")
      unless ($self->{Type} == WSP_TYPE_DISCONNECT);
    
    my $wh = WSP::Headers->new;
    $self->{ServerSessionId} = $wh->unpack_uintvar($pkt); 
  } else {
    $self->{TID} = 0  if ($WSP::PDU::MODE == WSP_CONNECTIONLESS);
    $self->{Type} = WSP_TYPE_DISCONNECT;
    $self->{ServerSessionId} = 0;
  }
  return $self;
}


=item $h->encode

Encode a WSP Disconnect PDU into a binary string.

=cut

sub encode
{
  my $self = shift;
  my $wh = WSP::Headers->new;

  # common PDU fields
  my $str = $self->encode_common_fields;
  $str .= $wh->pack_uintvar($self->{ServerSessionId});

  return $str;
}


=item $h->as_string

Return a string representation of a WSP Disconnect PDU.

=cut

sub as_string
{
  my $self = shift;
  my $str = $self->common_fields_as_string;
  $str .= "ServerSessionId: ".$self->{ServerSessionId}."\n";
  return $str;
}

1;
