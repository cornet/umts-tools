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

package UMTS::GUI::SMSCompose;

use strict;
use warnings;
use vars qw(@ISA);

use Gtk2::SimpleMenu;
use Getopt::Std;
use UMTS::Core;
use UMTS::SMS qw(:modes);

@ISA = qw(Gtk2::Window);

sub new
{
  my $class = shift;
  
  my $params = {
    parent => undef,
    term => undef,
    log => UMTS::Log->new,
    dest => '',
    message => '',
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
    
  my $box1 = new Gtk2::VBox( FALSE, 0 );
  $box1->set_spacing(5);

  my $box_to = new Gtk2::HBox( FALSE, 0);    
  $box_to->set_spacing(10);
  my $lbl = new Gtk2::Label( 'Recipient' );
  $box_to->pack_start( $lbl, FALSE, TRUE, 0 );
  
  $self->{combo} = new Gtk2::Combo();  
  my @pbook = UMTS::Phonebook->readPhonebook($self->{log}, $self->{bookcache});
  my @pbook_vals;
  foreach my $entry (@pbook)
  {
     push @pbook_vals, "$entry->{name} <$entry->{value}>";
  }    
  $self->{combo}->set_popdown_strings(@pbook_vals);
    $self->{combo}->entry->set_text($self->{dest});
  $box_to->pack_start( $self->{combo}, TRUE, TRUE, 0);    
  
  my $box_opts = new Gtk2::HBox( FALSE, 0);    
  $box_opts->set_spacing(10);
  $self->{chk_flash} = new Gtk2::CheckButton( 'Flash message' );
  $box_opts->pack_start( $self->{chk_flash}, TRUE, TRUE, 0 );  
  $self->{chk_srr} = new Gtk2::CheckButton( 'Delivery report' );
  $box_opts->pack_start( $self->{chk_srr}, TRUE, TRUE, 0 );  
  $self->{btn_send} = new Gtk2::Button( 'Send' );  
  $box_opts->pack_start( $self->{btn_send}, FALSE, FALSE, 0 );  
  
  # assemple options
  $box1->pack_start( $box_to, FALSE, TRUE, 0 );
  $box1->pack_start( $box_opts, FALSE, TRUE, 0 );
        
  my $scroll = new Gtk2::ScrolledWindow;
  $scroll->set_policy( 'automatic', 'automatic' );

  my $frame = new Gtk2::Frame( 'Message body' );
    #use Gtk2::Notepad;
  #$self->{txt_message} = new Gtk2::Notebook;
  $self->{txt_message} = new Gtk2::TextView;
  $self->{txt_message}->set_wrap_mode('word');
  $self->{txt_message}->show;
  $scroll->add ($self->{txt_message});
  $scroll->set_border_width(10);
  $frame->add( $scroll );
#  $frame->add($self->{txt_message});
  $box1->pack_start( $frame, TRUE, TRUE, 0 );
   
  # callback registration
  $self->signal_connect(destroy => sub { $self->closing; });
  $self->{btn_send}->signal_connect(clicked => sub { $self->sendMessage; });
  
  # set window attributes and show it
  $self->set_border_width(10);  
  $self->add( $box1 );

  $self->set_size_request(400,300);
  
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


sub log
{
  my ($self, $msg) = @_;  
  $self->{log}->write("UMTS::GUI::SMSWindow::$msg"); 
}


sub sendMessage
{
  my $self = shift;

  my $dest = $self->{combo}->entry->get_text;  
  my $flash = $self->{chk_flash}->get_active;
  my $srr = $self->{chk_srr}->get_active;
  
  $dest =~ s/\s$//;
  $dest =~ s/^\s$//;
  if ($dest !~ /^\+?[0-9]+$/) {
    $dest =~ s/^.* <(.*)>$/$1/;
  }
  if ($dest !~ /^\+?[0-9]+$/) {
    my $dialog = Gtk2::Dialog->new(
      'Invalid recipient number', $self,
      'destroy-with-parent',
      'gtk-ok' => 'none' );
    my $label = Gtk2::Label->new("The recipient number you specified ('$dest') is invalid, please try again.");
    $dialog->vbox->add ($label);
    $label->show;
    $dialog->run;  
    $dialog->destroy;
    return;
  }

  # get message  
  my $buffer = $self->{txt_message}->get_buffer;
  my ($start, $end) = $buffer->get_bounds;
  my $msg = $buffer->get_text($start, $end, 0);
  $msg or $msg = ' ';
  $self->log("sendMessage ($dest, $msg)");   
  
  $self->{term}->setMessageMode(SMS_MODE_PDU);    
  my $resp = $self->{term}->sendSMSTextMessage($dest, $msg, 'readreport' => $srr, 'flash' => $flash);
  
  if ($resp eq RET_OK) {
    $self->destroy;
  } else {
     my $dialog = Gtk2::Dialog->new(
    'Error while sending SMS', $self,
    'destroy-with-parent',
    'gtk-ok' => 'none' );
    my $label = Gtk2::Label->new('An error occured while sending the SMS.');
    $dialog->vbox->add ($label);    
    $label->show;
    $dialog->run;
    $dialog->destroy;
  }
}


1;
