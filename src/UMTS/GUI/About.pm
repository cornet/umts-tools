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

package UMTS::GUI::About;

use strict;
use vars qw(@ISA);

use UMTS::App;
use Gtk2;

@ISA = qw(Gtk2::Dialog);

sub new
{
  my ($class, $parent) = @_;
  
  my $dialog = Gtk2::Dialog->new(
    'About umts-tools', $parent,
    'destroy-with-parent',
    'gtk-ok' => 'none' );

 $dialog->set_border_width(10);   
 $dialog->vbox->set_spacing(15);   

         
  my $title = Gtk2::Label->new("umts-tools $UMTS::App::VERSION");
  
  my $font_desc = Gtk2::Pango::FontDescription->from_string ("Sans 20");
  $title->modify_font ($font_desc);
  
  $dialog->vbox->add ($title);    
  $title->show;
  my $label = Gtk2::Label->new(  
'umts-tools - tools for manipulating 3G terminals
Copyright (C) 2004-2005 Jeremy Laine <jeremy.laine@m4x.org>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA');
  $dialog->vbox->add ($label); 
  $label->show;
  
  bless($dialog, $class);
}

