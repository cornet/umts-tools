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
package UMTS::L3::RR;

use strict;
use warnings;
use vars qw(@ISA);

use Carp ();
use UMTS::L3;

@ISA = qw(UMTS::L3);

our $PROTO = "Radio Ressource management";
our $TYPES =
{
};

=head1 NAME

UMTS::L3::SS - Class encapsulating Radio Ressource management messages

=head1 SYNOPSIS

  use UMTS::L3::RR;
  $ss = UMTS::L3::RR->decode($binstr);

=head1 DESCRIPTION

The C<UMTS::L3::RR> class allows you to decode
Radio Ressource management messages.

The following methods are available:

=over 1

=item UMTS::L3::RR->decode

Decode a Radio Ressource management message from a binary string.

=cut

sub decode
{
  my $class = shift;
  my $pkt = shift;

  # decode common L3 header
  (my $self, $pkt) = $class->decode_header($pkt);

  ($self->{PD} == L3_PD_RR) or 
    Carp::croak("UMTS::L3::RR : bad Protocol Discriminator");

  return $self;
}


1;
=back

