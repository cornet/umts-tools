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

package UMTS::Dummy::V902SH;

use strict;
use vars qw(@ISA);

use UMTS::Dummy;

@ISA = qw(UMTS::Dummy);

sub make_response
{
  my ($self, $dmsg) = @_;
  
  my $item;
  
  if ($dmsg eq 'AT+CGMI') {
    $item = [ 'OK', 'SHARP' ];
  } elsif ($dmsg eq 'AT+CGMM') {
    $item = [ 'OK', 'SHARP/902SH_802SH' ];
  } elsif ($dmsg eq 'AT+CGMR') {
    $item = [ 'OK', '3502630000723801' ];  
  } elsif ($dmsg eq 'AT+CGSN') {
    $item = [ 'OK', '350263000072389' ];
  } elsif ($dmsg =~ /^AT\+(CMGF|CSCA|CMGS|CPBW)/) {
    $item = [ 'ERROR', '' ];
  } elsif ($dmsg =~ /^AT\+CSCS=\?/) {
    $item = [ 'OK', '+CSCS: ("GSM","IRA","8859-1","UTF-8","UCS2")' ];
  } elsif ($dmsg =~ /^AT\+CPBS=\?/) { 
    $item = [ 'OK', '+CPBS: ("FD","LD","ME","MT","SM","DC","RC","MC","EN","ON")' ];
  } else {
    $item = $self->SUPER::make_response($dmsg);
  }
  return $item;
}

return 1;


