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

package UMTS::Dummy::V1050;

use strict;
use vars qw(@ISA);

use UMTS::Dummy;

@ISA = qw(UMTS::Dummy);

sub make_response
{
  my ($self, $dmsg) = @_;
  
  my $item;
  
  if ($dmsg eq 'AT+CGMI') {
    $item = [ 'OK', '+CGMI: "Motorola CE, Copyright 2005"' ];
  } elsif ($dmsg eq 'AT+CGMM') {
    $item = [ 'OK', '+CGMM: "GSM900","GSM1800","GSM1900","WCDMA","MODEL=V1050"' ];
  } elsif ($dmsg eq 'AT+CGMR') {
    $item = [ 'OK', '+CGMR: "R26LD_U_83.37.43I"' ];  
  } elsif ($dmsg eq 'AT+CGSN') {
    $item = [ 'OK', '+CGSN: IMEI004400008400739' ];
  } else {
    $item = $self->SUPER::make_response($dmsg);
  }
  return $item;
}

return 1;


