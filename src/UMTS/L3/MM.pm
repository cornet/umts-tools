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
package UMTS::L3::MM;

use strict;
use warnings;
use vars qw(@ISA);

use Carp ();
use UMTS::L3;

@ISA = qw(UMTS::L3);

our $PROTO = "Mobility Management";
our $TYPES =
{
  'IMSI Detach Indication'    => 0x01,
  'Location Updating Accept'  => 0x02,
  'Location Updating Reject'  => 0x04,
  'Location Updating Request' => 0x08,
  'Authentication Reject'     => 0x11,
  'Authentication Request'    => 0x12,
  'Authentication Response'   => 0x14,
  'Authentication Failure'    => 0x1C,
  'Identity Request'          => 0x18,
  'Identity Response'         => 0x19,
  'TMSI Reallocation Command' => 0x1A,
  'TMSI Reallocation Complete'=> 0x1B,
  'CM Service Accept'         => 0x21, 
  'CM Service Reject'         => 0x22, 
  'CM Service Abort'          => 0x23, 
  'CM Service Request'        => 0x24, 
  'CM Service Prompt'         => 0x25, 
  'Reserved'                  => 0x26, 
  'CM Re-Establishment Request'=> 0x28, 
  'Abort'                     => 0x29, 
  'MM Null'                   => 0x30, 
  'MM Status'                 => 0x31, 
  'MM Information'            => 0x32, 
};

=head1 NAME

UMTS::L3::MM - Class encapsulating Mobility Management messages

=head1 SYNOPSIS

  use UMTS::L3::MM;
  $mm = UMTS::L3::MM->decode($binstr);

=head1 DESCRIPTION

The C<UMTS::L3::MM> class allows you to decode
Mobility Management messages.

The following methods are available:

=over 1

=item UMTS::L3::MM->decode

Decode a Mobility Management message from a binary string.

=cut

sub decode
{
  my $class = shift;
  my $pkt = shift;

  # decode common L3 header
  (my $self, $pkt) = $class->decode_header($pkt);

  ($self->{PD} == L3_PD_MM) or 
    Carp::croak("UMTS::L3::MM : bad Protocol Discriminator");

  return $self;
}


1;
=back

