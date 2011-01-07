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
package UMTS::L3::CC;

use strict;
use warnings;
use vars qw(@ISA);

use Carp ();
use UMTS::L3;

@ISA = qw(UMTS::L3);

our $PROTO = "Call Control";
our $TYPES =
{
  'Alerting'             => 0x01,
  'Call Confirmed'       => 0x08,
  'Call Proceeding'      => 0x02,
  'Connect'              => 0x07,
  'Connect Acknowledge'  => 0x0F,
  'Emergency Setup'      => 0x0D,
  'Progress'             => 0x03,
  'CC-Establishment'     => 0x04,
  'CC-Establishment Confirmed' => 0x06,
  'Recall'               => 0x0B,
  'Start CC'             => 0x09,
  'Setup'                => 0x05,
  'Modify'               => 0x17,
  'Modify Complete'      => 0x1F,
  'Modify Reject'        => 0x13,
  'User Information'     => 0x10,
  'Hold'                 => 0x18,
  'Hold Acknowledge'     => 0x19,
  'Hold Reject'          => 0x1A,
  'Retrieve'             => 0x1C,
  'Retrieve Acknowledge' => 0x1D,
  'Retrieve Reject'      => 0x1E,
  'Disconnect'           => 0x25,
  'Release'              => 0x2D,
  'Release Complete'     => 0x2A,
  'Congestion Control'   => 0x39,
  'Notify'               => 0x3E,
  'Status'               => 0x3D,
  'Status Enquiry'       => 0x34,
  'Start DTMF'           => 0x35,
  'Stop DTMF'            => 0x31,
  'Stop DTMF Acknowledge'=> 0x32,
  'Start DTMF Acknowledge'=> 0x36,
  'Start DTMF Reject'    => 0x37,
  'Facility'             => 0x3A,
};

=head1 NAME

UMTS::L3::CC - Class encapsulating Call Control messages

=head1 SYNOPSIS

  use UMTS::L3::CC;
  $cc = UMTS::L3::CC->decode($binstr);

=head1 DESCRIPTION

The C<UMTS::L3::CC> class allows you to decode Call Control messages.

The following methods are available:

=over 1

=item UMTS::L3::CC->decode

Decode a Call Control message from a binary string.

=cut

sub decode
{
  my $class = shift;
  my $pkt = shift;

  # decode common L3 header
  (my $self, $pkt) = $class->decode_header($pkt);

  ($self->{PD} == L3_PD_CC) or 
    Carp::croak("UMTS::L3::CC : bad Protocol Discriminator");

  return $self;
}


1;
=back

