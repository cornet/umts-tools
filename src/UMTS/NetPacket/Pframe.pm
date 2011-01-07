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
package UMTS::NetPacket::Pframe;

use strict;
use warnings;

sub decode
{
  my $class = shift;
  my ($pkt, $parent, @rest) = @_;
  
  my $self = {
    data => undef,
    tlow => 0,
    thigh => 0,    
  };

  if (defined($pkt) and $pkt ne '')
  {
    my ($plen, $plen2);
    
    ($self->{tlow}, $self->{thigh}, $plen, $plen2) = unpack('llll', $pkt);
    $pkt = substr($pkt, 16);
    
    $self->{data} = $pkt;
  }
  
  bless($self, $class);
}


sub encode
{
  my $self = shift;

  # packet length
  my $plen = length($self->{data});
  
  # timestamp
  my $hdr = pack('llll', $self->{tlow}, $self->{thigh}, $plen, $plen);
  
  return $hdr . $self->{data};
}


1;

