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

package UMTS::GUI::SMSExplore;

use strict;
use vars qw(@ISA);

use Gtk2::SimpleMenu;
use UMTS::Core;
use UMTS::Phonebook;
use UMTS::SMS qw(:stat);
use UMTS::GUI::SMSExplore_Sel;
use UMTS::GUI::SMSExplore_View;
use Getopt::Std;

@ISA = qw(Gtk2::Window);


sub new
{
  my $class = shift;
  
  my $params = {
    bookcache => '',
    parent => undef,
    term => undef,
    log => UMTS::Log->new,
    @_
  };
  
  if (defined($params->{parent})) {
    $params->{log} = $params->{parent}->{log};
    $params->{term} = $params->{parent}->{term};
    $params->{bookcache} = $params->{parent}->{bookcache};  
  };
    
  # widget creation
  my $self = new Gtk2::Window( 'toplevel' );
  foreach my $key (keys %{$params}) {
    $self->{$key} = $params->{$key};
  }
  
  # callback registration
  $self->signal_connect(destroy => sub { $self->closing; });
  
  my $box1 = new Gtk2::VBox( FALSE, 0 );
     
  my @pstore = UMTS::SMS->getStorages($self->{term});    
  $self->{p_sel} = UMTS::GUI::SMSExplore_Sel->new(@pstore);
  $box1->pack_start( $self->{p_sel}, FALSE, FALSE, 0 );
  $self->{p_sel}->show_all;

  $self->{p_view} = UMTS::GUI::SMSExplore_View->new(parent => $self, bookcache => $self->{bookcache});
  $box1->pack_start( $self->{p_view}, TRUE, TRUE, 0 );
  $self->{p_view}->show_all;

  # hook get/send buttons
  $self->{p_sel}->{btn_new}->signal_connect( 'clicked' => sub { $self->clearMessages; } );
  
  $self->{p_sel}->{btn_read}->signal_connect( 'clicked' => sub { $self->readMessages; } );
  $self->{p_sel}->{btn_write}->signal_connect( 'clicked' => sub { $self->writeMessages; } );

  $self->{p_sel}->{btn_get}->signal_connect( 'clicked' => sub { $self->getMessages; } );
  $self->{p_sel}->{btn_send}->signal_connect( 'clicked' => sub { $self->setMessages; } );
  
  # set window attributes and show it
  $self->set_border_width(10);  
  $self->add( $box1 );
  $box1->show();

  $self->set_size_request(700,300);
  
  bless($self, $class);
  $self->log("new succeeded");

  $self->getMessages($self);
  
  return $self;
}


sub closing
{
  my $self = shift; 
  ref($self->{parent}) or  
    Gtk2->main_quit;
}


sub log
{
  my ($self, $msg) = @_;  
  $self->{log}->write("UMTS::GUI::SMSExplore::$msg"); 
}


sub makeFileFilter
{
  my $filter = Gtk2::FileFilter->new;
  $filter->add_pattern('*.umbox');
  return $filter;
}


sub clearMessages
{
  my $self = shift; 
  $self->log('clear : clearing messages'); 
  $self->{p_view}->setMessages();
}


sub readMessages
{
  my $self = shift;    
  
  my $file_chooser = Gtk2::FileChooserDialog->new (
    'Select the messages you want to open',
    undef, 'open',
    'gtk-cancel' => 'cancel',
    'gtk-ok' => 'ok' );
  $file_chooser->set_filter($self->makeFileFilter);    
  my $filename = '';
  if ('ok' eq $file_chooser->run) {
    $filename = $file_chooser->get_filename;
  }  
  $file_chooser->destroy;                                  
  
  if ($filename)
  {
    $self->log("readMessages from '$filename'");
    my @mbox = UMTS::SMS->readMessages($self->{log}, $filename);     
    $self->{p_view}->setMessages(@mbox);    
  }
  
}


sub writeMessages
{
  my $self = shift;
  
  my $file_chooser = Gtk2::FileChooserDialog->new (
    'Write the messages to..',
    undef, 'save',
    'gtk-cancel' => 'cancel',
    'gtk-ok' => 'ok' );
  $file_chooser->set_filter($self->makeFileFilter);    
  my $filename = '';
  if ('ok' eq $file_chooser->run) {
    $filename = $file_chooser->get_filename;
  }  
  $file_chooser->destroy;                                  

  if ($filename)
  {
    if ($filename !~ /\.umbox$/) {
      $filename .= '.umbox';
    }
    $self->log("writeMessages to '$filename'");    
    my @mbox = $self->{p_view}->getMessages;
    UMTS::SMS->writeMessages($self->{log}, $filename, @mbox);     
  }
}


sub getMessages
{
  my $self = shift;

  my $storage = $self->{p_sel}->getStorage;
  
  $self->log("getMessages : getting messages from terminal");    
  UMTS::SMS->setStorage($self->{term}, $storage);  
  my @messages = UMTS::SMS->getMessages($self->{term}, SMS_STAT_ALL);
  $self->{p_view}->setMessages(@messages);    
}


sub setMessages
{
  my $self = shift;
  
  my $storage = $self->{p_sel}->getStorage;  
  $self->log("setMessages : sending messages to terminal");    
  UMTS::SMS->setStorage($self->{term}, $storage);  
  my @messages = $self->{p_view}->getMessages;    
  UMTS::SMS->setMessages($self->{term}, @messages);
}

1;
