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

package UMTS::Dummy;

use strict;
use vars qw(@ISA);

use UMTS::Core;
use UMTS::Terminal::Call;
use UMTS::Terminal::Common;
use UMTS::Terminal::Keys;
use UMTS::Terminal::SMS;
use UMTS::Phonebook;

@ISA = qw(UMTS::Terminal::Common UMTS::Terminal::Call UMTS::Terminal::Keys UMTS::Terminal::SMS);


=item B<new> - Construct a new terminal instance

=cut  

sub new
{
  my $class = shift;
  my %params = @_;
    
  my $self = {};  
  UMTS::Terminal::Common::init($self, @_);
  $self->{queue} = [];
  $self->{calls} = '';
  $self->{activ} = 0;
  $self->{pbook} = ();
  
  bless ($self, $class);
}


sub are_match
{
}


sub close
{
}


sub make_response
{
  my ($self, $dmsg) = @_;  
  my $item;

  if ($self->{in_msg}) {        
    $item = [ 'OK', '' ]; 
    $self->{in_msg} = 0;
  }    
  elsif ($dmsg =~ /^ATD([^;]*);?/i) {
    $self->{calls} = "+CLCC: 1,$1,0,0,0,,129,";
    $self->{activ} = 4;
    $item = [ 'OK', '' ];
  } elsif ($dmsg =~ /^ATH/i) {
    $self->{calls} = '';
    $self->{activ} = 0;  
    $item = [ 'OK', '' ];
  } elsif ($dmsg =~ /^AT\+CSQ$/i) {
    # signal quality
    $item = [ 'OK', '+CSQ: 27,99' ]; 
  } elsif ($dmsg =~ /^AT\+CGMI$/i) {
    $item = [ 'OK', '+CGMI: "Foo Corporation"' ];
  } elsif ($dmsg =~ /^AT\+CGMM$/i) {
    $item = [ 'OK', '+CGMM: Bar950' ];
  } elsif ($dmsg =~ /^AT\+CGMR$/i) {
    $item = [ 'OK', '+CGMR: "X_1.2.3_25F"' ];  
  } elsif ($dmsg =~ /^AT\+CGSN$/i) {
    $item = [ 'OK', '+CGSN: 0044000011223344' ];
  } elsif ($dmsg =~ /^AT\+CIMI$/i) {
    $item = [ 'OK', '+CIMI: 112233445566778' ];
  } elsif ($dmsg =~ /^AT\+CLCC$/i) {
    $item = [ 'OK', $self->{calls} ];
  } elsif ($dmsg =~ /^AT\+CMGF=\?$/i) {
    $item = [ 'OK', '+CMGF: (0-1)' ];
  } elsif ($dmsg =~ /^AT\+CMGF=([01])$/) {
    $item = [ 'OK', ''];
  } elsif ($dmsg =~ /^AT\+CMGL=([0-9]+)$/i) {
    my $index = $1;
    my $out = '';
    $item = [ 'OK', $out ];    
  } elsif ($dmsg =~ /^AT\+CMGS=\?$/i) {
    $item = [ 'OK', '' ];
  } elsif ($dmsg =~ /^AT\+CMGS=/i) {
    $self->{in_msg} = 1;
    $item = [ '>', ''];
  } elsif ($dmsg =~ /^AT\+CKPD=\"([0-9]+)\"$/i) {
    $self->{kpd} = $1;  
    $item = [ 'OK', ''];    
  } elsif ($dmsg =~ /^AT\+CPAS=\?$/i) {
    $item = [ 'OK', '+CPAS: (0,3,4)' ];
  } elsif ($dmsg =~ /^AT\+CPAS$/i) {
    $item = [ 'OK', '+CPAS: '.$self->{activ} ];
  } elsif ($dmsg =~ /^AT\+CPBR=\?$/i) {
    $item = [ 'OK', '+CPBR: (1-700),40,20' ];
  } elsif ($dmsg =~ /^AT\+CPBR=([0-9]+)$/i) {
    my $index = $1;
    my $out = '';
    if (defined(my $entry = $self->{pbook}->{$index})) {
      $out = "+CPBR: $entry->{index},\"$entry->{value}\",$entry->{type},\"$entry->{name}\"";
    }
    $item = [ 'OK', $out ];    
  } elsif ($dmsg =~ /^AT\+CPBW=\?$/i) {
    $item = [ 'OK', '+CPBW: (1-700),40,(129,145),20' ];    
  } elsif ($dmsg =~ /^AT\+CPBW=([0-9]+),\s*\"(.*)\",\s*([0-9]+),\s*\"(.*)\"/i) {
    $self->{pbook}->{$1} = UMTS::Phonebook::Entry->new(index => $1, value => $2, type => $3, name => $4);
    $item = [ 'OK', ''];  
  } elsif ($dmsg =~ /^AT\+CPBS=\?$/i) {
    $item = [ 'OK', '+CPBS: ("ME","SM","MT","ON","DC","MC","RC","EN","AD","QD","SD","FD")' ];    
  } elsif ($dmsg =~ /^AT\+CPBS=\"(.*)\"/i) {
    $item = [ 'OK', ''];    
  } elsif ($dmsg =~ /^AT\+CPMS=\?$/i) {  
    $item = [ 'OK', '+CPMS: ("MT","IM","OM","BM","DM"),("OM","DM"),("IM")' ];
  } elsif ($dmsg =~ /^AT\+CPMS=\"(.*)\"/i) {
    $item = [ 'OK', ''];            
  } elsif ($dmsg =~ /^AT\+CSCS=\?$/i) {
    $item = [ 'OK', '+CSCS: ("GSM","IRA","8859-1","UTF-8","UCS2")' ];
  } elsif ($dmsg =~ /^AT\+CSCS=\"(.*)\"$/i) {
    $item = [ 'OK', ''];
  } else {
    $item = [ 'ERROR', 'unsupported command' ];
  }  
  return $item;
}


=item B<readPhonebook> - Reads a phonebook from file

=cut  

sub readPhonebook
{
  my ($self, $file) = @_;
  
  my %bar;
  my @pbook = UMTS::Phonebook->readPhonebook($self->{log}, $file);
  foreach my $entry (@pbook)
  {
    $bar{$entry->{index}} = $entry;
  }
  $self->{pbook} = \%bar;
}


=item B<reset> - Reset the terminal

=cut  

sub reset
{
  my $self = shift;

  $self->logDebug("reset : resetting terminal");

  return RET_OK;
}


sub resetMatch
{

}

=item B<send> - Send a command to the terminal

=cut
sub send
{
  my ($self, $msg) = @_;

  my $dmsg = $msg;
  my $cr = CR;
  $dmsg =~ s/$cr$//;
  $self->logDebug("send : [$dmsg]");

  my $item = $self->make_response($dmsg);  
  ref($item) and
    push @{$self->{queue}}, $item;
  
  return RET_OK;
}


=item B<waitfor> - Wait until we get a given response

=cut  

sub waitfor
{
  my $self = shift;
  my ($match, $extra);
  
  if (my $item = pop @{$self->{queue}})
  {
    ($match, $extra) = @{$item};
    $self->logDebug("waitfor : got: [$match]");
    $self->logDebug("waitfor : extra: [$extra]");
  }
  else
  {
    $self->logDebug("waitfor : empty queue"); 
    $self->wait(5); 
  }  
  $self->{extra} = $extra;  
  return $match;
}


return 1;


