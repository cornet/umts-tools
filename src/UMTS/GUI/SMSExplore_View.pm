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

package UMTS::GUI::SMSExplore_View;

use strict;
use vars qw(@ISA);
use UMTS::Core;
use UMTS::SMS qw(:stat);
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
  #$self->{bookcache} = $params->{bookcache};
    

  my $wnd = new Gtk2::ScrolledWindow( undef, undef );
  
  $self->pack_start( $wnd, TRUE, TRUE, 0 );
  $wnd->set_policy( 'automatic', 'automatic' );
  $wnd->show();
  
  my $list = Gtk2::SimpleList->new(
    'dir' => 'text',
    'new' => 'text',
    'index' => 'int',
    'number' => 'text',
    'message' => 'text',
    'smsc' => 'text'
  );
  #$list->set_column_editable (0, TRUE);
  
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
    my ($dir, $new, $index, $number) = @{$row_ref};
    
    my $menu = new Gtk2::Menu();
    
    my $item_reply = new Gtk2::MenuItem( 'Reply by SMS' ); 
    $item_reply->signal_connect(activate => 
     sub {
      my $dlg = UMTS::GUI::SMSCompose->new(parent => $view->{parent}, dest => $number);   
      $dlg->show_all;      
     });
    $menu->append( $item_reply );
     
    my $item_delete = new Gtk2::MenuItem( 'Delete' ); 
    $item_delete->signal_connect(activate =>
      sub { 
        UMTS::SMS->deleteMessage($view->{parent}->{term}, $index);
        $view->{parent}->getMessages($view->{parent});
      });
    $menu->append( $item_delete );
    
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


sub getMessages
{
  my $self = shift;
  
  my @mbox;
  defined($self->{mbox}) and @mbox = @{$self->{mbox}};
  
  return @mbox; 
}


sub setMessages
{
  my ($self, @mbox) = @_;
 
  $self->{mbox} = \@mbox;
  
  @{$self->{list}->{data}} = ();
  foreach my $msg (@mbox)
  {
    my $sms = SMS::PDU->decode(pack('H*', $msg->{data}));
    my $data = $sms->{'TP-UD'}->{data};     
    my $stat = $msg->{stat};
    my $smsc = $sms->{smsc};
    
    # determine direction of message (MO / MT)
    my $dir;    
    if (($stat eq SMS_STAT_MO_UNREAD) or ($stat eq SMS_STAT_MO_READ)) {
      $dir = "=>";
    } elsif (($stat eq SMS_STAT_MT_UNREAD) or ($stat eq SMS_STAT_MT_READ)) {      
      $dir = "<=";
    } else {
      $dir = "?";
    }
    
    # determine if message is unread
    my $new = (($stat eq SMS_STAT_MO_UNREAD) or ($stat eq SMS_STAT_MT_UNREAD)) ? '*' : '';
    
    push @{$self->{list}->{data}}, [ $dir, $new, $msg->{index}, $sms->getNumber, $data, $smsc ];
  }
  
}


1;
