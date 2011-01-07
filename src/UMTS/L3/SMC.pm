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
package UMTS::L3::SMC;

use strict;
use warnings;
use vars qw(@ISA @EXPORT @EXPORT_OK);

use Carp ();
use Exporter;
use UMTS::L3;

@ISA = qw(UMTS::L3 Exporter);
@EXPORT_OK = qw(SM_CP_DATA SM_CP_ACK SM_CP_ERR);

use constant SM_CP_DATA  => 0x01;
use constant SM_CP_ACK   => 0x04;
use constant SM_CP_ERROR => 0x10;

our $PROTO = "SM Control Protocol";
our $TYPES =
{
  'SM-DATA'  => SM_CP_DATA,
  'SM-ACK'   => SM_CP_ACK,
  'SM-ERROR' => SM_CP_ERROR,
};


=head1 NAME

UMTS::L3::SMC - Class encapsulating SMS Control Protocol messages

=head1 SYNOPSIS

  use UMTS::L3::SMC;
  $s = UMTS::L3::SMC->decode($binstr);

=head1 DESCRIPTION

The C<UMTS::L3::SMC> class allows you to encode and decode
SMS Control Protocol messages.

The following methods are available:

=over 1

=item UMTS::L3::SMC->decode

Decode an SMS Control Protocol message from a binary string.

=cut

sub decode
{
  my $class = shift;
  my($pkt, $parent, @rest) = @_;
 
  # decode common L3 header
  (my $self, $pkt) = $class->decode_header($pkt);

  ($self->{PD} == L3_PD_SMC) or 
    Carp::croak("SM-CP : bad Protocol Discriminator");

  if ($self->{MTI} == SM_CP_DATA)
  {
  
    # CP-DATA PDU has length then CP-UD
    my $len = unpack("C", $pkt);
    $pkt = substr($pkt, 1);

    ($len == length($pkt)) or
      Carp::croak("SMS CP-DATA : length mismatch\n");
    $self->{'CP-UD'} = $pkt;

  } elsif ($self->{MTI} == SM_CP_ACK) {

    # CP-ACK has no more data
  
  } elsif ($self->{MTI} == SM_CP_ERROR) {
  
    # CP-ERROR has a cause
    $self->{'CP-Cause'} = unpack("C", $pkt);
    
  } else {
    Carp::croak("SM-CP : unknown message type");
  }
 
  return $self;
}

1;
=back

