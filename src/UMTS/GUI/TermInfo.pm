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

package UMTS::GUI::TermInfo;

use strict;
use vars qw(@ISA);

use UMTS::Core;
use UMTS::Phonebook;
use Gtk2::SimpleList;
use UMTS::SMS qw(:modes);

@ISA = qw(Gtk2::SimpleList);


sub new
{
  my ($class, $term) = @_;
  
  my $self = Gtk2::SimpleList->new(
    'name' => 'text',
    'value' => 'text',
  );
    
  # terminalinfp
  my $info = $term->{ue};
  my $termval = {
  'Port' => $term->{port},
  'Terminal' => ref($term), 
  'Type' => $info->name . " (".$info->type.")",
  'Manufacturer' => $info->manufacturer,
  'Model'       => $info->model,
  'Revision' => $info->revision,
  'IMEI' => $info->imei,
  'IMSI' => $info->imsi,
  'Message mode' => ($term->{msg_mode} eq SMS_MODE_PDU) ? 'PDU' : 'text',
  'Characterset' => $term->{charset},
  };
   
  
  foreach my $key (keys %{$termval}) 
  {
    push @{$self->{data}}, [ $key, $termval->{$key} ];
  }
    
  bless($self,$class);
}


1;
