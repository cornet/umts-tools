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

package UMTS::GUI::Phonebook_View;

use strict;
use vars qw(@ISA);
use UMTS::Core;
use UMTS::Phonebook;
use UMTS::GUI::SMSCompose;
use Gtk2::SimpleList;

@ISA = qw(Gtk2::HBox);

sub new
{
  my $class = shift;
  
  my $params = {@_};
  
  my $self = new Gtk2::HBox( FALSE, 0 );
  
  $self->{parent} = $params->{parent};
  if (defined($self->{parent})) {
    $self->{log} = $self->{parent}->{log};
  }
  $self->{bookcache} = $params->{bookcache};
    

  my $wnd = new Gtk2::ScrolledWindow( undef, undef );
  
  $self->pack_start( $wnd, TRUE, TRUE, 0 );
  $wnd->set_policy( 'automatic', 'automatic' );
  $wnd->show();
  
  my $list = Gtk2::SimpleList->new(
    'name' => 'text',
    'number' => 'text',
    'index' => 'int',
  );

  # allown column sorting  
  my @columns = $list->get_columns;
  for (my $i = 0; $i < @columns; $i++)
  {
    $list->get_column ($i)->set_sort_column_id ($i);
  }
  
  $list->signal_connect (button_press_event => \&button_press_event, $self);
      
  $wnd->add_with_viewport( $list );
  $list->show();
  
  # store pointer to the list
  $self->{list} = $list;

  bless($self,$class);
    
  if ($self->{bookcache})  
  {
    $self->{log}->write("read phonebook cache : $self->{bookcache}");
    my @pbook = UMTS::Phonebook->readPhonebook($self->{log}, $self->{bookcache});     
    $self->setPhonebook(@pbook);
  }

  return $self;    
}


sub button_press_event 
{ 
  my ($widget, $event, $view) = @_;
          
  
  # Check for a right click
  if ($event->type() eq 'button-press'
     && $event->button() == 3)
  {
    my ($x,$y) = $event->get_coords;
    my ($path, $column, $px, $py) = $widget->get_path_at_pos($x,$y);
    my $row_ref = $widget->get_row_data_from_path ($path);
    my ($name, $value) = @{$row_ref};
    
    my $menu = new Gtk2::Menu();
    
    my $item_sms = new Gtk2::MenuItem( 'Send SMS' ); 
    $item_sms->signal_connect(activate => 
     sub {
      my $dlg = UMTS::GUI::SMSCompose->new(parent => $view->{parent}, dest => "$name <$value>");   
      $dlg->show_all;      
     });
    $menu->append( $item_sms );
     
    my $item_dial = new Gtk2::MenuItem( 'Call' ); 
    $item_dial->signal_connect(activate =>
      sub { 
        my $dlg = UMTS::GUI::Dialer->new(parent => $view->{parent}, dest => "$name <$value>");   
        $dlg->show_all;      
      });
    $menu->append( $item_dial );
    
    $menu->show_all;
    $menu->popup(
      undef, # parent menu shell
      undef, # parent menu item
      undef, # menu pos func
      undef, # data
      $event->button,
      $event->time 
    );
   
  }  
}

  
sub getPhonebook
{
  my $self = shift;
  
  my @pbook;
  defined($self->{pbook}) and @pbook = @{$self->{pbook}};
  
  return @pbook; 
}


sub setPhonebook
{
  my ($self, @pbook) = @_;
 
  $self->{pbook} = \@pbook;
  
  @{$self->{list}->{data}} = ();
  foreach my $entry (@pbook)
  {
    push @{$self->{list}->{data}}, [ $entry->{name} , $entry->{value}, $entry->{index} ];
  } 

  if ($self->{bookcache})  
  {
    $self->{log}->write("writing phonebook cache : $self->{bookcache}");
    UMTS::Phonebook->writePhonebook($self->{log}, $self->{bookcache}, @pbook);     
  }
  
}



1;
