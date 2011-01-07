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

package UMTS::GUI::Phonebook;

use strict;
use vars qw(@ISA);

use Gtk2::SimpleMenu;
use UMTS::Core;
use UMTS::Phonebook;
use UMTS::GUI::Phonebook_Sel;
use UMTS::GUI::Phonebook_View;
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
  $self->signal_connect(destroy => \&closing, $self);
  
  my $box1 = new Gtk2::VBox( FALSE, 0 );
     
  my @pbooks = UMTS::Phonebook->getPhonebooks($self->{term});    
  $self->{p_sel} = UMTS::GUI::Phonebook_Sel->new(@pbooks);
  $box1->pack_start( $self->{p_sel}, FALSE, FALSE, 0 );
  $self->{p_sel}->show_all;

  $self->{p_view} = UMTS::GUI::Phonebook_View->new(parent => $self, bookcache => $self->{bookcache});
  $box1->pack_start( $self->{p_view}, TRUE, TRUE, 0 );
  $self->{p_view}->show_all;
 
  $self->{p_prog} = Gtk2::ProgressBar->new;
  $box1->pack_start( $self->{p_prog}, FALSE, TRUE, 0 );
  
  # hook get/send buttons
  $self->{p_sel}->{btn_new}->signal_connect( 'clicked' => sub { $self->newPhonebook; } );
  
  $self->{p_sel}->{btn_read}->signal_connect( 'clicked' => sub { $self->readPhonebook; } );
  $self->{p_sel}->{btn_write}->signal_connect( 'clicked' => sub { $self->writePhonebook; } );

  $self->{p_sel}->{btn_get}->signal_connect( 'clicked' => sub { $self->getPhonebook; } );
  $self->{p_sel}->{btn_send}->signal_connect( 'clicked' => sub { $self->sendPhonebook; } );
      
  # set window attributes and show it
  $self->set_border_width(10);  
  $self->add( $box1 );
  $box1->show();

  $self->set_size_request(500,600);
  
  bless($self, $class);
  $self->log("new succeeded");
  
  return $self;
}


sub closing
{
  my $self = shift;
  ref($self->{parent}) or  
    Gtk2->main_quit;
}


sub close
{
  my $self = shift;
  $self->destroy;
}


sub log
{
  my ($self, $msg) = @_;
  
  $self->{log}->write("UMTS::GUI::Phonebook::$msg"); 
}


sub makeFileFilter
{
  my $self = shift;
  my $filter = Gtk2::FileFilter->new;
  $filter->add_pattern('*.upbk');
  return $filter;
}


sub newPhonebook
{
  my $self = shift; 
  $self->log('newPhonebook : clearing phonebook'); 
  $self->{p_view}->setPhonebook();
}


sub readPhonebook
{
  my $self = shift;    
    
  my $file_chooser = Gtk2::FileChooserDialog->new (
    'Select the phonebook you want to open',
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
    $self->log("readPhonebook from '$filename'");
    my @pbook = UMTS::Phonebook->readPhonebook($self->{log}, $filename);     
    $self->{p_view}->setPhonebook(@pbook);    
  }
  
}


sub writePhonebook
{
  my $self = shift;
  
  my $file_chooser = Gtk2::FileChooserDialog->new (
    'Select file to which you want to write the phonebook',
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
    if ($filename !~ /\.upbk$/) {
      $filename .= '.upbk';
    }
    $self->log("writePhonebook to '$filename'");    
    my @pbook = $self->{p_view}->getPhonebook;
    UMTS::Phonebook->writePhonebook($self->{log}, $filename, @pbook);     
  }
}


sub getPhonebook
{
  my $self = shift;    

  my $book = $self->{p_sel}->getBook;
  $self->log("getPhonebook : getting phonebook '$book' from terminal");
  my @pbook = UMTS::Phonebook->getPhonebookDump($self->{term}, $book);
  $self->{p_view}->setPhonebook(@pbook);    
}


sub sendPhonebook
{
  my $self = shift;    
  my $book = $self->{p_sel}->getBook;
  my @pbook  = $self->{p_view}->getPhonebook;
  $self->log("sendPhonebook : sending phonebook '$book' to terminal");  
  UMTS::Phonebook->setPhonebookDump($self->{term}, $book, @pbook);   
}


1;
