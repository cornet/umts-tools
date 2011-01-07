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
package WSP::PDU::Push;

use strict;
use warnings;
use vars qw(@ISA);

use WSP::PDU qw(:types :modes);
use WSP::Headers;

@ISA = qw(WSP::PDU);


=head1 NAME

WSP::PDU:Push - Class encapsulating WSP Push PDUs

=head1 SYNOPSIS

  use WSP::PDU::Push;
  $h = WSP::PDU::Push->decode;


=head1 DESCRIPTION

The C<WSP::PDU:Push> class allows you to encode or decode Wireless Session
Protocol (WSP) Push Protocol Data Units (PDU).

The following methods are available:

=over 3

=item WSP::PDU::Push->decode( $pkt )

Construct a WSP::PDU by decoding a binary string.

=cut

sub decode
{
  my $class = shift;
  my $pkt = shift;
  my $confirmed = shift;
  my $ptype = $confirmed ? WSP_TYPE_CONFIRMEDPUSH : WSP_TYPE_PUSH;
  
  my $self = {};
  bless($self, $class);

  # Decode WSP packet

  if (defined($pkt)) {
    $pkt = $self->decode_common_fields($pkt);
    Carp::croak("WSP::PDU::Push : bad Type")
      unless ($self->{Type} == $ptype);
    
    my $wh = WSP::Headers->new;
    (my $hdr_len, $pkt) = $wh->unpack_uintvar($pkt);
    my $hdr_string = substr($pkt, 0, $hdr_len);
    $pkt = substr($pkt, $hdr_len);

    # unpack content-type
    ($self->{ContentType}, $hdr_string) = $wh->unpack_accept_value($hdr_string);
    # unpack headers
    $self->{Headers} = WSP::Headers->decode($hdr_string);

    $self->{Data} = length($pkt) ? $pkt : '';
  } else {
    $self->{TID} = 0  if ($WSP::PDU::MODE == WSP_CONNECTIONLESS);
    $self->{Type} = $ptype;
    $self->{Headers} = WSP::Headers->new;
    $self->{ContentType} = '';
    $self->{Data} = '';
  }
  return $self;
}


=item $h->encode

Encode a WSP Push PDU into a binary string.

=cut

sub encode
{
  my $self = shift;
  my $wh = WSP::Headers->new;

  # check we have a content type
  if (!length($self->{ContentType})) {
    Carp::croak("WSP Push PDU encoding requires a content-type");
  }

  # common PDU fields
  my $str = $self->encode_common_fields;

  # prepare content-type + headers
  my $wsp_headers = $wh->pack_accept_value($self->{ContentType});
  $wsp_headers .= $self->{Headers}->encode;

  # headers length (content-type+headers)
  $str .= $wh->pack_uintvar(length($wsp_headers));

  # headers contents
  $str .= $wsp_headers;

  return $str . $self->{Data};
}


=item $h->as_string

Return a string representation of a WSP Push PDU.

=cut

sub as_string
{
  my $self = shift;
  my $str = $self->common_fields_as_string;
  $str .= "ContentType: ".$self->{ContentType}."\n";
  $str .= "-- Headers --\n".$self->{Headers}->as_string;
  $str .= "-- Data --\n".$self->{Headers}->hexsprint($self->{Data})."\n";
  return $str;
}

1;
