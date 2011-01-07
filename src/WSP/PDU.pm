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
package WSP::PDU;

use strict;
use warnings;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

BEGIN {
  @ISA = qw(Exporter);

  # Default exports
  @EXPORT = qw(WSP_CONNECTIONMODE WSP_CONNECTIONLESS);

  # Other items we are prepared to export if requested
  @EXPORT_OK = qw(
  WSP_TYPE_CONNECT WSP_TYPE_CONNECTREPLY WSP_TYPE_REDIRECT WSP_TYPE_REPLY WSP_TYPE_DISCONNECT WSP_TYPE_PUSH WSP_TYPE_CONFIRMEDPUSH WSP_TYPE_SUSPEND WSP_TYPE_RESUME WSP_TYPE_GET WSP_TYPE_OPTIONS WSP_TYPE_HEAD WSP_TYPE_DELETE WSP_TYPE_TRACE WSP_TYPE_POST WSP_TYPE_PUT WSP_TYPE_DATA
  );

  %EXPORT_TAGS = (
  types => [qw(WSP_TYPE_CONNECT WSP_TYPE_CONNECTREPLY WSP_TYPE_REDIRECT WSP_TYPE_REPLY WSP_TYPE_DISCONNECT WSP_TYPE_PUSH WSP_TYPE_CONFIRMEDPUSH WSP_TYPE_SUSPEND WSP_TYPE_RESUME WSP_TYPE_GET WSP_TYPE_OPTIONS WSP_TYPE_HEAD WSP_TYPE_DELETE WSP_TYPE_TRACE WSP_TYPE_POST WSP_TYPE_PUT WSP_TYPE_DATA)],
  modes => [qw(WSP_CONNECTIONMODE WSP_CONNECTIONLESS)],
  );
}

use constant WSP_CONNECTIONMODE		=> 0;
use constant WSP_CONNECTIONLESS		=> 1;

use constant WSP_TYPE_CONNECT		=> 0x01;
use constant WSP_TYPE_CONNECTREPLY	=> 0x02;
use constant WSP_TYPE_REDIRECT		=> 0x03;
use constant WSP_TYPE_REPLY		=> 0x04;
use constant WSP_TYPE_DISCONNECT	=> 0x05;
use constant WSP_TYPE_PUSH		=> 0x06;
use constant WSP_TYPE_CONFIRMEDPUSH	=> 0x07;
use constant WSP_TYPE_SUSPEND		=> 0x08;
use constant WSP_TYPE_RESUME		=> 0x09;
use constant WSP_TYPE_GET		=> 0x40;
use constant WSP_TYPE_OPTIONS		=> 0x41;
use constant WSP_TYPE_HEAD		=> 0x42;
use constant WSP_TYPE_DELETE		=> 0x43;
use constant WSP_TYPE_TRACE		=> 0x44;
use constant WSP_TYPE_POST		=> 0x60;
use constant WSP_TYPE_PUT		=> 0x61;
use constant WSP_TYPE_DATA		=> 0x80;

use Exporter;
use WSP::PDU::Disconnect;
use WSP::PDU::Push;
use WSP::PDU::ConfirmedPush;
use WSP::PDU::Suspend;

our $MODE = WSP_CONNECTIONMODE;
our $WSP_TYPES = {
  'Connect'		=> WSP_TYPE_CONNECT,
  'ConnectReply'	=> WSP_TYPE_CONNECTREPLY,
  'Redirect'		=> WSP_TYPE_REDIRECT,
  'Reply'		=> WSP_TYPE_REPLY,
  'Disconnect'		=> WSP_TYPE_DISCONNECT,
  'Push'  		=> WSP_TYPE_PUSH,
  'ConfirmedPush'	=> WSP_TYPE_CONFIRMEDPUSH,
  'Suspend'		=> WSP_TYPE_SUSPEND,
  'Resume'		=> WSP_TYPE_RESUME,
  'Get'			=> WSP_TYPE_GET,
  'Options'		=> WSP_TYPE_OPTIONS,
  'Head'		=> WSP_TYPE_HEAD,
  'Delete'		=> WSP_TYPE_DELETE,
  'Trace'		=> WSP_TYPE_TRACE,
  'Post'		=> WSP_TYPE_POST,
  'Put'			=> WSP_TYPE_PUT,
  'Data'		=> WSP_TYPE_DATA,
};


=head1 NAME

WSP::PDU - Class for decoding WSP Protocol Data Units

=head1 SYNOPSIS

  use WSP::PDU;
  $h = WSP::PDU->decode($binary_string);
  
  $binary_string = $h->encode;

=head1 DESCRIPTION

The C<WSP::PDU> class allows you to decode Wireless Session Protocol
(WSP) Protocol Data Units (PDU). For encoding, you should refer to 
subclasses such as
L<WSP::PDU::ConfirmedPush|WSP::PDU::ConfirmedPush>,
L<WSP::PDU::Disconnect|WSP::PDU::disconnect>,
L<WSP::PDU::Push|WSP::PDU::Push>,
or L<WSP::PDU::Suspend|WSP::PDU::Suspend>.

The following methods are available:

=over 1


=item WSP::PDU->decode( $pkt )

Constructs a WSP::PDU by decoding a binary string.

=cut

sub decode
{
  my $class = shift;
  my $pkt = shift;

  # Decode WSP packet
  if (!defined($pkt)) {
    Carp::croak("WSP::PDU->decode() requires a binary string as input");
  }

  my $tmp = {};
  decode_common_fields($tmp, $pkt);
  if ($tmp->{Type} == WSP_TYPE_DISCONNECT) {
    return WSP::PDU::Disconnect->decode($pkt, @_);
  } elsif ($tmp->{Type} == WSP_TYPE_PUSH) {
    return WSP::PDU::Push->decode($pkt, @_);
  } elsif ($tmp->{Type} == WSP_TYPE_CONFIRMEDPUSH) {
    return WSP::PDU::ConfirmedPush->decode($pkt, @_);
  } elsif ($tmp->{Type} == WSP_TYPE_SUSPEND) {
    return WSP::PDU::Suspend->decode($pkt, @_);
  } else {
    Carp::croak(sprintf("Decoding of packet type %.2X is not implemented", $tmp->{Type}));
  }
}


# $h->encode_common_fields
# Encodes common fields of a WSP PDU into a binary string.

sub encode_common_fields
{
  my $self = shift;
  my $str;

  # Build headers
  # transaction ID
  if ($MODE == WSP_CONNECTIONLESS)
  {
    $str .= pack('C', $self->{TID});
  }
  $str .= pack('C', $self->{Type});
  return $str;
}


# $h->decode_common_fields
# Decodes common fields of a WSP PDU from a binary string.

sub decode_common_fields
{
  my ($self, $pkt) = @_;

  if ($MODE == WSP_CONNECTIONLESS)
  {
    $self->{TID} = unpack("C", $pkt);
    $pkt = substr($pkt, 1);
  }
  $self->{Type} = unpack("C", $pkt);
  $pkt = substr($pkt, 1);

  return $pkt;
}


# $h->common_fields_as_string
# Returns a string representation of WSP PDU common fields

sub common_fields_as_string
{
  my $self = shift;
  my $str;
  if ($MODE == WSP_CONNECTIONLESS)
  {
    $str .= "TID: $self->{TID}\n";
  }
  $str .= "Type: $self->{Type}\n";
  return $str;
}

sub msgType
{
  my $self = shift;
  my %type = reverse %{$WSP_TYPES};
  return $type{$self->{Type}};
}

1;
