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

package UMTS::L3;

use strict;
use warnings;

BEGIN {
  use Exporter;
  use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

  # 3GPP TS 24.007 table 11.2
  use constant L3_PD_CC    => 0x3;
  use constant L3_PD_MM    => 0x5;
  use constant L3_PD_RR    => 0x6;
  use constant L3_PD_GMM   => 0x8;
  use constant L3_PD_SMC   => 0x9;
  use constant L3_PD_GSM   => 0xA;
  use constant L3_PD_SS    => 0xB;

  @ISA = qw(Exporter);
  @EXPORT = qw(L3_PD_CC L3_PD_MM L3_PD_GMM L3_PD_GSM L3_PD_RR L3_PD_SMC L3_PD_SS);
}

use UMTS::L3::CC;
use UMTS::L3::GMM;
use UMTS::L3::GSM;
use UMTS::L3::MM;
use UMTS::L3::RR;
use UMTS::L3::SMC;
use UMTS::L3::SS;

our $PROTO = "Layer 3 Protocol";
our $TYPES = {};


=head1 NAME

UMTS::L3 - Class for decoding 3GPP Layer 3 messages

=head1 SYNOPSIS

  use UMTS::L3;
  $l3 = UMTS::L3->decode($binstr);

=head1 DESCRIPTION

The C<UMTS::L3> class allows you to decode
3GPP Layer 3 messages.

The bulk of the implementation reside in the derived classes such as
L<UMTS::L3::CC|UMTS::L3::CC>,
L<UMTS::L3::GMM|UMTS::L3::GMM>,
L<UMTS::L3::GSM|UMTS::L3::GSM>,
and L<UMTS::L3::SMC|UMTS::L3::SMC>.

The following methods are available:

=over 1

=item UMTS::L3->decode

Decode a 3GPP Layer 3 message from a binary string.

=cut

sub decode
{
  my $class = shift;
  my($pkt, $parent, @rest) = @_;
 
  # decode common L3 header
  (my $tmp, $pkt) = $class->decode_header($pkt);
  my $pd = $tmp->{PD};

  if ($pd == L3_PD_CC) {
    return UMTS::L3::CC->decode(@_);
  } elsif ($pd == L3_PD_MM) {
    return UMTS::L3::MM->decode(@_);
  } elsif ($pd == L3_PD_RR) {
    return UMTS::L3::RR->decode(@_);
  } elsif ($pd == L3_PD_GMM) {
    return UMTS::L3::GMM->decode(@_);
  } elsif ($pd == L3_PD_SMC) {
    return UMTS::L3::SMC->decode(@_);
  } elsif ($pd == L3_PD_GSM) {
    return UMTS::L3::GSM->decode(@_);
  } elsif ($pd == L3_PD_SS) {
    return UMTS::L3::SS->decode(@_);
  } else {
    return $tmp;
  }
}


sub decode_header
{
  my $class = shift;
  my $pkt = shift;
  my $self = {};
  
  # Transaction identifier + protocol discriminator (3GPP TS 24.007)
  # Message type indicator 
  (my $a, $self->{'MTI'}) = unpack('CC', $pkt);
  $pkt = substr($pkt, 2);

  $self->{TI} = $a & 0xF0;
  $self->{PD} = $a & 0x0F;

  bless($self, $class);
  return ($self, $pkt);
}


sub msgProtocol
{
  my $self = shift;
  my $class = ref($self);
  
  no strict 'refs';
  return ${"${class}::PROTO"};
}


sub msgType
{
  my $self = shift;
  my $class = ref($self);
  
  no strict 'refs';
  my %type = reverse %{${"${class}::TYPES"}};
  my $name = $type{$self->{MTI}};
  return defined($name) ? $name : "<unknown>";
}

return 1;

=back

