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

package UMTS::GUI::Main;

use strict;
use vars qw(@ISA);

use Gtk2::SimpleMenu;
use UMTS::Core;
use UMTS::GUI::About;
use UMTS::GUI::Dialer;
use UMTS::GUI::Phonebook;
use UMTS::GUI::SMSCompose;
use UMTS::GUI::SMSExplore;
use UMTS::GUI::TermInfo;
use Getopt::Std;

@ISA = qw(Gtk2::Window);

sub new
{
  my $class = shift;
  
  my $params = {
    parent => undef,
    term => undef,
    log => UMTS::Log->new,
    @_
  };
  (defined($params->{config}->{phonebook})) and
      $params->{bookcache} = $params->{config}->{phonebook};

  # widget creation
  my $self = new Gtk2::Window( 'toplevel' );
  foreach my $key (keys %{$params}) {
    $self->{$key} = $params->{$key};
  }
    
  # callback registration
  $self->signal_connect(destroy => sub { $self->closing; });
  
  my $box1 = new Gtk2::VBox( FALSE, 0 );

  # create menu
  my $menu_tree = [
    _File => {
      item_type => '<Branch>',
      children => [
        _Quit => {
          callback => sub { $self->destroy; }
        }        
      ]
    },
    _Tools => {
      item_type => '<Branch>',
      children => [
        _Phonebook => {
          callback => sub {
            my $dlg = UMTS::GUI::Phonebook->new(parent => $self);   
            $dlg->show_all;
          }
        },        
        '_Compose SMS' => {
          callback => sub {
            my $dlg = UMTS::GUI::SMSCompose->new(parent => $self);   
            $dlg->show_all;
          }
        },
        'SMS E_xplore' => {
          callback => sub {
            my $dlg = UMTS::GUI::SMSExplore->new(parent => $self);   
            $dlg->show_all;
          }          
        },                
        _Dialer => {
          callback => sub {
            my $dlg = UMTS::GUI::Dialer->new(parent => $self);   
            $dlg->show_all;
          }
        }                
      ]
    },
    _Help => {
      item_type => '<Branch>',
      children => [
        _About => {
          callback => sub { 
            my $dialog = UMTS::GUI::About->new;
            $dialog->run;
            $dialog->destroy;                                
          }
        }
      ]
    }
  ];
  my $menu = Gtk2::SimpleMenu->new (
    menu_tree => $menu_tree,
  );  
  #$menu->get_widget('/File/About')->activate;
  $box1->pack_start( $menu->{widget}, FALSE, FALSE, 0 );  
  
  # terminal info
  my $info = UMTS::GUI::TermInfo->new($self->{term});
  $box1->pack_start($info, TRUE, TRUE, 0 );
      
  # set window attributes and show it
  $self->set_border_width(10);  
  $self->add( $box1 );
  $box1->show_all();

  $self->set_size_request(600,300);

  bless($self, $class);    
}


sub closing
{
  my $self = shift;
  ref($self->{parent}) or  
    Gtk2->main_quit;
}


1;
