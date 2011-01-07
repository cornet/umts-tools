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

package UMTS::GUI::SMSExplore_Sel;

use strict;
use vars qw(@ISA);

use UMTS::Core;
use UMTS::Phonebook;

@ISA = qw(Gtk2::VBox);

sub new
{
  my ($class, @pstore) = @_;
  
  my $self = new Gtk2::VBox( FALSE, 0 );

  # file bar
  my $filebar = new Gtk2::HBox( FALSE, 0);  
  my $lbl_file = new Gtk2::Label( 'File operations' );
  $filebar->pack_start( $lbl_file, FALSE, FALSE, 0 );  
  $self->{btn_new} = new Gtk2::Button( 'Clear' );  
  $filebar->pack_start( $self->{btn_new}, FALSE, FALSE, 0 );
  $self->{btn_read} = new Gtk2::Button( 'Open..' );  
  $filebar->pack_start( $self->{btn_read}, FALSE, FALSE, 0 );
  $self->{btn_write} = new Gtk2::Button( 'Save as..' );  
  $filebar->pack_start( $self->{btn_write}, FALSE, FALSE, 0 );
  $self->pack_start( $filebar, FALSE, FALSE, 0);
    
  # terminal bar
  my $termbar = new Gtk2::HBox( FALSE, 0);  
  my $lbl_pbook = new Gtk2::Label( 'Message storage' );
  $termbar->pack_start( $lbl_pbook, FALSE, FALSE, 0 );

  $self->{cmb_stor} = new Gtk2::Combo();
  $self->{cmb_stor}->set_popdown_strings(@pstore);
  $termbar->pack_start( $self->{cmb_stor}, FALSE, FALSE, 0 );

  $self->{btn_get} = new Gtk2::Button( 'get' );
  $termbar->pack_start( $self->{btn_get}, FALSE, FALSE, 0 );

  $self->{btn_send} = new Gtk2::Button( 'send' );
  $termbar->pack_start( $self->{btn_send}, FALSE, FALSE, 0 );
   
  $self->pack_start( $termbar, FALSE, FALSE, 0);
 
  bless($self,$class);
}


sub getStorage
{
  my $self = shift;
  return $self->{cmb_stor}->entry->get_text;
}

1;
