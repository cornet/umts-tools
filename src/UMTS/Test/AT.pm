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


use strict;
use vars qw(@ISA @EXPORT);

use Exporter;

use constant P_RUN => 1;
use constant P_SUP => 2;
use constant P_RNG => 4;
use constant P_ALL => P_RUN | P_SUP | P_RNG;

@ISA = qw(Exporter);

@EXPORT = qw(
  P_RUN P_SUP P_RNG P_ALL
  testAT probeAT
);

sub testAT
{
  my($term, $cmd, $descr) = @_;  
  
  ok ( ($term->send("AT$cmd" . CR) and $term->waitfor eq 'OK'), "AT$cmd $descr");
}

sub probeAT
{
  my($term, $cmd, $descr, $probe) = @_; 
  
  defined($probe) or
    $probe = P_RUN;

  ($probe & P_RUN) and
    testAT($term, "$cmd", "($descr)");
  ($probe & P_SUP) and
    testAT($term, "$cmd?", "($descr) is supported");
  ($probe & P_RNG) and
    testAT($term, "$cmd=?", "($descr) range");    
}


1;
