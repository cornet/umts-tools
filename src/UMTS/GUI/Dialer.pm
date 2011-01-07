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

package UMTS::GUI::Dialer;

use strict;
use vars qw($OS_win @ISA);

use Gtk2::SimpleMenu;
use UMTS::Core;
use UMTS::Dialer;
use POSIX qw(strftime);

# take care of loading Win32 or POSIX module
BEGIN
{
  $OS_win = ($^O eq "MSWin32") ? 1 : 0;
}

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
    forkdialer => ($OS_win ? 0 : 1),
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
    
  # read phonebook entries
  my @pbook = UMTS::Phonebook->readPhonebook($self->{log}, $self->{bookcache});
  my @pbook_vals;
  foreach my $entry (@pbook)
  {
     push @pbook_vals, "$entry->{name} <$entry->{value}>";
  }    
 
  #  create vertical box for the frame
  my $vbox = new Gtk2::VBox(FALSE , 0);   
  $vbox->set_spacing(5);
  $vbox->set_border_width(10);
  
  # destination
  my $box_to = new Gtk2::HBox( FALSE, 0);    
  $box_to->set_spacing(5);
  my $lbl = new Gtk2::Label( 'To' );
  $box_to->pack_start( $lbl, TRUE, TRUE, 0 );
  $self->{combo} = new Gtk2::Combo();  
  $self->{combo}->set_popdown_strings(@pbook_vals);
  $self->{combo}->entry->set_text($self->{dest});
  $box_to->pack_start( $self->{combo}, FALSE, FALSE, 0);  
  $vbox->pack_start( $box_to, FALSE, TRUE, 0 );
      
  # number of calls
  my $box_calls = new Gtk2::HBox( FALSE, 0);    
  $box_calls->set_spacing(5);
  my $lbl_calls = new Gtk2::Label( 'Number of calls' );
  $box_calls->pack_start( $lbl_calls, TRUE, TRUE, 0);  
  $self->{txt_calls} = new Gtk2::Entry( );
  $self->{txt_calls}->set_text(1000);
  $box_calls->pack_start( $self->{txt_calls}, FALSE, FALSE, 0);  
  $vbox->pack_start( $box_calls, FALSE, TRUE, 0 );

  # call duration
  my $box_clen = new Gtk2::HBox( FALSE, 0);    
  $box_clen->set_spacing(5);
  my $lbl_clen = new Gtk2::Label( 'Call duration' );
  $box_clen->pack_start( $lbl_clen, TRUE, TRUE, 0);  
  $self->{txt_clen} = new Gtk2::Entry( );
  $self->{txt_clen}->set_text(120);
  $box_clen->pack_start( $self->{txt_clen}, FALSE, FALSE, 0);  
  $vbox->pack_start( $box_clen, FALSE, TRUE, 0 );
  
  # call duration
  my $box_cwait = new Gtk2::HBox( FALSE, 0);    
  $box_cwait->set_spacing(5);
  my $lbl_cwait = new Gtk2::Label( 'Pause between calls' );
  $box_cwait->pack_start( $lbl_cwait, TRUE, TRUE, 0);  
  $self->{txt_cwait} = new Gtk2::Entry( );
  $self->{txt_cwait}->set_text(60);
  $box_cwait->pack_start( $self->{txt_cwait}, FALSE, FALSE, 0);  
  $vbox->pack_start( $box_cwait, FALSE, TRUE, 0 );

  # frame / send button
  my $frame = new Gtk2::Frame( 'Dialing parameters' ); 
  $frame->add( $vbox );
  

  my $sbox = new Gtk2::HBox(FALSE, 0);  
  $sbox->pack_start( new Gtk2::Label(''), TRUE, TRUE, 0 );
  $self->{btn_dial} = new Gtk2::Button( 'Dial' );  
  $sbox->pack_start( $self->{btn_dial}, FALSE, FALSE, 0 );
  $self->{btn_stop} = new Gtk2::Button( 'Stop' );  
  $self->{btn_stop}->set_sensitive(FALSE);
  $sbox->pack_start( $self->{btn_stop}, FALSE, FALSE, 0 );

  # put window together   
  my $wbox = new Gtk2::VBox(FALSE , 0);
  $wbox->set_spacing(10);
  if (!$self->{forkdialer})
  {
    my $lbl_warn = new Gtk2::Label( 'WARNING : this window is experimental. For now, the window will freeze until the full dialing sequence completes. You have been warned! ;)' );
    $lbl_warn->set_line_wrap(TRUE);
    $wbox->pack_start( $lbl_warn, TRUE, TRUE, 0 );
  }
  $wbox->pack_start( $frame, TRUE, TRUE, 0 );
  $wbox->pack_start( $sbox, FALSE, FALSE, 0 );   
  
  $self->add( $wbox );

     
  # callback registration
  $self->signal_connect(destroy => sub { $self->closing; });
  $self->{btn_dial}->signal_connect(clicked => sub { $self->startDialer; });
  $self->{btn_stop}->signal_connect(clicked => sub { $self->stopDialer; });
  
  # set window attributes and show it
  $self->set_border_width(10);  
  #$self->set_size_request(400,300);
  
  bless($self, $class);  
}


sub closing
{
  my $self = shift;
  $self->stopDialer;
  ref($self->{parent}) or  
    Gtk2->main_quit;
}


sub startDialer
{
  my $self = shift;

  my $dest = $self->{combo}->entry->get_text;  
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
    my $label = Gtk2::Label->new("The destination number you specified ('$dest') is invalid, please try again.");
    $dialog->vbox->add ($label);
    $label->show;
    $dialog->run;  
    $dialog->destroy;
    return;
  }
  
  # get parameters for dialer
  my $call_max = $self->{txt_calls}->get_text;
  my $call_duration = $self->{txt_clen}->get_text;
  my $call_wait = $self->{txt_cwait}->get_text;
  my $call_type = 'voice';
  my $logpref = strftime("%d-%b-%Y_%H-%M-%S", localtime);
  my $reslog = UMTS::Log->new("${logpref}_results.txt");  
  my $dialer = UMTS::Dialer->new(
    call_number => $dest,
    call_max => $call_max,
    call_duration => $call_duration,
    call_wait => $call_wait,
    call_type => $call_type,
    term => $self->{term},
    log => $self->{log},
    reslog => $reslog
  );
  
  $self->{btn_dial}->set_sensitive(FALSE);

  # fork the dialer
  if ($self->{forkdialer})
  {
    $self->{btn_stop}->set_sensitive(TRUE);
    my $kidpid;
    if (!defined($kidpid = fork())) {
      die "cannot fork: $!";
    } elsif ($kidpid == 0) {
      $dialer->run;
      exit;
    } else {
      $self->{kidpid} = $kidpid;
    }
  } else {
    $dialer->run;
  }
}


sub stopDialer
{
  my $self = shift;

  if ($self->{forkdialer} && $self->{kidpid}) 
  {
    kill('INT', $self->{kidpid});
    waitpid($self->{kidpid}, 0);
  }
  $self->{btn_stop}->set_sensitive(FALSE);  
  $self->{btn_dial}->set_sensitive(TRUE);
}


1;
