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

package UMTS::Dummy::Z107;

use strict;
use vars qw(@ISA);

use UMTS::Dummy;

@ISA = qw(UMTS::Dummy);

sub make_response
{
  my ($self, $dmsg) = @_;
  
  my $item;
  
  if ($dmsg eq 'AT+CGMI') {
    $item = [ 'OK', 'SAMSUNG ELECTRONICS CORPORATION' ];
  } elsif ($dmsg eq 'AT+CGMM') {
    $item = [ 'OK', '129' ];
  } elsif ($dmsg eq 'AT+CGMR') {
    $item = [ 'OK', 'WY5.1.54      1  [Nov 01 2004 13:00:00]' ];  
  } elsif ($dmsg eq 'AT+CGSN') {
    $item = [ 'OK', '354627000016255' ];
  } elsif ($dmsg =~ /^AT\+(CPBR |CPBR|CPBW|CLCC)/) {
    $item = [ 'ERROR', '' ];
  } elsif ($dmsg =~ /^AT\+CSCS=\?/) {
    $item = [ 'OK', '+CSCS: ("IRA")' ];
  } else {
    $item = $self->SUPER::make_response($dmsg);
  }
  return $item;
}

return 1;


