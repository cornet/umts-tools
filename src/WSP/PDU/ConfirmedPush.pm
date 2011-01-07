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
package WSP::PDU::ConfirmedPush;

use strict;
use warnings;
use vars qw(@ISA);

use WSP::PDU::Push;

@ISA = qw(WSP::PDU::Push);


=head1 NAME

WSP::PDU:ConfirmedPush - Class encapsulating WSP ConfirmedPush PDUs

=head1 SYNOPSIS

  use WSP::PDU::ConfirmedPush;
  $h = WSP::PDU::ConfirmedPush->decode;


=head1 DESCRIPTION

The C<WSP::PDU:ConfirmedPush> class allows you to encode or decode
Wireless Session Protocol (WSP) ConfirmedPush Protocol Data Units (PDU).

The following methods are available:

=over 3

=item WSP::PDU::ConfirmedPush->decode( $pkt )

Construct a WSP::PDU by decoding a binary string.

=cut

sub decode
{
  my $class = shift;
  my $pkt = shift;

  my $self = WSP::PDU::Push->decode($pkt, 1);
  bless($self, $class);
}


=item $h->encode

Encode a WSP ConfirmedPush PDU into a binary string.

=item $h->as_string

Return a string representation of a WSP ConfirmedPush PDU.

=cut

1;
