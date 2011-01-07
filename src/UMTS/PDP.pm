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

package UMTS::PDP;

use strict;
use vars qw($OS_win);

use UMTS::Core;

# take care of loading Win32 or POSIX module
BEGIN
{
  $OS_win = ($^O eq "MSWin32") ? 1 : 0;

  # This must be in a BEGIN in order for the 'use' to be conditional
  if ($OS_win) {
    eval "use UMTS::PDP::Win32";
    die "$@\n" if ($@);
  }
  else {
    eval "use UMTS::PDP::POSIX";
    die "$@\n" if ($@);
  }
}


sub new
{
  my $class = shift;

  my $self = {
    'name' => "umtstools",
    @_
  };
  
  bless($self, $class);
}


# launch the connection
sub start
{
  my $self = shift;

  print "-> Launching connection..\n";
  if (!connectionStart($self))
  {  
    print "Could not launch the connection!\n";
    return RET_ERR;
  } 
  return RET_OK;  
}


# hangup the connection
sub stop
{
  my $self = shift;

  print "-> Hanging up connection..\n";
  if (!connectionStop($self))
  {
    print "Could not hangup the connection!\n";
    return RET_ERR;
  }
  
  return RET_OK;
}

1;
