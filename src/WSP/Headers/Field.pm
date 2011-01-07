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

package WSP::Headers::Field;

use strict;
use vars qw(@ISA @EXPORT);

use Carp ();
use Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(LIST NOLIST BRKLIST FIELD_VALUE_STRING FIELD_VALUE_ENCODED FIELD_VALUE_DATA FIELD_VALUE_DATA FIELD_VALUE_NONE);

# no list
use constant NOLIST => 0;

# LIST is a comma-separated list such as is described in the "#rule"
# entry of RFC2616 section 2.1.
use constant LIST => 1;

# BROKEN_LIST is a list of "challenge" or "credentials" elements
# such as described in RFC2617.  I call it broken because the
# parameters are separated with commas, instead of with semicolons
# like everywhere else in HTTP.  Parsing is more difficult because
# commas are also used to separate list elements.
use constant BRKLIST => 2;

use constant FIELD_VALUE_STRING		=> 1;
use constant FIELD_VALUE_ENCODED	=> 2;
use constant FIELD_VALUE_DATA 		=> 3;
use constant FIELD_VALUE_NONE 		=> 4;


sub new
{
  my ($class, $href) = @_;
  my @hdef = @{$href};
  
  my $self = bless {
    'name' => $hdef[0],
    'id'   => $hdef[1],
    'list' => NOLIST
  }, $class;


  if ($hdef[2])
  {
    $self->{'pack_function'} = 'pack_' . $hdef[2];
    $self->{'unpack_function'} = 'unpack_' . $hdef[2];
  }

  $self->{list} = $hdef[3] if ($hdef[3]);

  $self;
}


1;

