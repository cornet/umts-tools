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

package UMTS::Core;

use strict;
use warnings;
use vars  qw(@ISA @EXPORT @EXPORT_OK $VERSION);

$VERSION = "0.9.4pre1";
@ISA = qw(Exporter);
@EXPORT = qw(CR CTRL_Z RET_OK RET_ERR TRUE FALSE);
@EXPORT_OK = qw(read_binary);

use constant RET_OK => 1;
use constant RET_ERR => 0;

use constant CR => "\r";
use constant CTRL_Z => chr(26);
 
use constant TRUE => 1;
use constant FALSE => 0;

use Carp ();
use Exporter;

sub read_binary
{
  my $file = shift;
  open(FILE, "< $file") or Carp::croak("Unable to open file '$file'");
  binmode(FILE);
  my $buff;
  my $data;
  while(my $len = sysread(FILE, $buff, 1024))
  {
    $data .= $buff;
  }
  close(FILE);

  return $data;
}


return 1;

