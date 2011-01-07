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
package UMTS::NetPacket::Ethernet;

use strict;
use warnings;
use vars qw(@ISA @EXPORT @EXPORT_OK);

use Exporter;
use NetPacket::Ethernet qw(:types);

@ISA = qw(NetPacket::Ethernet Exporter);

@EXPORT = qw(
  ETH_TYPE_IP ETH_TYPE_ARP ETH_TYPE_APPLETALK
  ETH_TYPE_SNMP ETH_TYPE_IPv6 ETH_TYPE_PPP
);


sub encode
{
  my $self = shift;

  # source and destination
  my($sm_lo, $sm_hi, $dm_lo, $dm_hi);

  my $src = zpad($self->{src_mac}, 12);
  my $dest = zpad($self->{dest_mac}, 12);
  
  my $hdr = pack('H*', $dest . $src);

  # type
  $hdr .= pack('n', (defined($self->{type}) ? $self->{type} : 0x00));

  return $hdr . (defined($self->{data}) ? $self->{data} : '');
}


sub zpad
{
  my ($val, $len) = @_;
  my $pad = '0' x $len;
  my $full = (defined($val) ? $val : '') . $pad;
  return substr($full, 0, $len);  
}

1;

