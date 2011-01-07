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
package UMTS::L3::GMM;

use strict;
use warnings;
use vars qw(@ISA);

use Carp ();
use UMTS::L3;

@ISA = qw(UMTS::L3);

our $PROTO = "GPRS Mobility Management";
our $TYPES =
{
  'Attach Request'                 => 0x01,
  'Attach Accept'                  => 0x02,
  'Attach Complete'                => 0x03,
  'Attach Reject'                  => 0x04,
  'Detach Request'                 => 0x05,
  'Detach Accept'                  => 0x06,
  'Routing Area Update Request'    => 0x08,
  'Routing Area Update Accept'     => 0x09,
  'Routing Area Update Complete'   => 0x0A,
  'Routing Area Update Reject'     => 0x0B,
  'Service Request'                => 0x0C,
  'Service Accept'                 => 0x0D,
  'Service Reject'                 => 0x0E,
  'P-TMSI Reallocation Command'    => 0x10,
  'P-TMSI Reallocation Complete'   => 0x11,
  'Authentication and Ciphering Req'    => 0x12,
  'Authentication and Ciphering Resp'   => 0x13,
  'Authentication and Ciphering Rej'    => 0x14,
  'Authentication and Ciphering Failure'=> 0x1B,
  'Identity Request'               => 0x15,
  'Identity Response'              => 0x16,
  'GMM Status'                     => 0x20,
  'GMM Response'                   => 0x21,
};


=head1 NAME

UMTS::L3::GMM - Class encapsulating GPRS Mobility Management messages

=head1 SYNOPSIS

  use UMTS::L3::GMM;
  $mm = UMTS::L3::GMM->decode($binstr);

=head1 DESCRIPTION

The C<UMTS::L3::GMM> class allows you to decode
GPRS Mobility Management messages.

The following methods are available:

=over 1

=item UMTS::L3::GMM->decode

Decode a GPRS Mobility Management message from a binary string.

=cut

sub decode
{
  my $class = shift;
  my $pkt = shift;

  # decode common L3 header
  (my $self, $pkt) = $class->decode_header($pkt);

  ($self->{PD} == L3_PD_GMM) or 
    Carp::croak("UMTS::L3::GMM : bad Protocol Discriminator");
  
  return $self;
}


1;
=back

