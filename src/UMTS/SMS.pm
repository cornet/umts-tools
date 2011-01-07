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

package UMTS::SMS;

use strict;
use warnings;
use vars qw(@ISA @EXPORT_OK %EXPORT_TAGS);

use Exporter;
use UMTS::Core;
use UMTS::SMS::Entry;

@ISA = qw(Exporter);
@EXPORT_OK = qw(
SMS_MODE_PDU SMS_MODE_TEXT
SMS_STAT_MT_READ SMS_STAT_MT_UNREAD SMS_STAT_MO_READ SMS_STAT_MO_UNREAD SMS_STAT_ALL SMS_STAT_TEMPLATE
);
%EXPORT_TAGS = (
  modes => [qw(SMS_MODE_PDU SMS_MODE_TEXT)],
  stat => [qw(SMS_STAT_MT_READ SMS_STAT_MT_UNREAD SMS_STAT_MO_READ SMS_STAT_MO_UNREAD SMS_STAT_ALL SMS_STAT_TEMPLATE)],
);

use constant SMS_MODE_PDU    => 0;
use constant SMS_MODE_TEXT   => 1;

use constant SMS_STAT_MT_UNREAD  => 0;
use constant SMS_STAT_MT_READ    => 1;
use constant SMS_STAT_MO_UNREAD  => 2;
use constant SMS_STAT_MO_READ    => 3;
use constant SMS_STAT_ALL        => 4;
use constant SMS_STAT_TEMPLATE   => 16;


=head1 NAME

UMTS::SMS - Module for reading SMS storage on UMTS/GSM terminals

=head1 SYNOPSIS

  use UMTS::SMS;
  @pbooks = UMTS::SMS->getStorages($term);

=head1 DESCRIPTION

The C<UMTS::SMS> module allows you to retrieve SMS messages that are
stored on a terminal. 

The following methods are available:

=over 1

=item B<getStorages> - Retrieve available messages storages

This method allows you to retrieve the available

=cut  

sub getStorages
{
  my ($class, $term) = @_;

  $term->send("AT+CPMS=?" . CR);
  my $resp = $term->waitfor;
  
  # for debugging
  #$term->{extra} = "+CPMS: ("MT","IM","OM","BM","DM"),("OM","DM"),("IM")\n";
  #$resp = "OK";
  
  if ($resp ne "OK")
  {
    $term->log("getStorages : error getting storages ($resp)");
    return;  
  }
    
  my $pstor = $term->{extra};
  if ($pstor !~ /^\+CPMS:\s*\((.*)\)/)
  {
    $term->log("getSorages : could not parse $pstor");
    return;
  }  
  
  if (my @books = eval("( $1 );"))
  {
    return @books;
  } else {
    $term->log("getStorages : error evaluating $1");
    return;      
  }
}


=item B<setStorage> - set the message storage

=cut  

sub setStorage
{
  my ($class, $term, $stor) = @_;
  
  $term->send("AT+CPMS=\"$stor\"" . CR);
  my $resp = $term->waitfor;
  if ($resp ne "OK")
  {
    $term->log("setStorage : could not select storage `$stor` ($resp)");
    return RET_ERR;
  }

  return RET_OK;  
}


=item B<getMessages> - read messages from the terminal

=cut  

sub getMessages
{
  my ($class, $term, @stats) = @_;
  my @msgs;    
  
  if (!(@stats > 0)) {
    push @stats, SMS_STAT_MT_READ;
  }

  foreach my $stat (@stats) {    
    if ($term->{msg_mode} eq SMS_MODE_PDU) {
      $term->send("AT+CMGL=$stat" . CR);
      
      if ($term->waitfor ne "OK") {
        $term->log("getMessages : failed to get messages of type $stat");
        return RET_ERR;
      }
    
      my @lines = split /[\r\n]+/, $term->{extra};    
      while (my $line = shift @lines)
      {
        if ($line =~ /^\+CMGL: ([0-9]+),\s*([0-9]+),\s*([^,]*),\s*([0-9]+)/)  
        {
          my ($t_index, $t_stat, $t_alpha, $t_length) = unquote($1, $2, $3, $4);
          my $t_data = shift @lines;
          my $m = UMTS::SMS::Entry->new(
            index => $t_index,
            stat => $t_stat,
            alpha => $t_alpha,
            length => $t_length,
            data => $t_data
          );
          push @msgs, $m;
        }
      }
    } elsif ($term->{msg_mode} eq SMS_MODE_TEXT) {
      $term->send("AT+CMGL" . CR);
      
      if ($term->waitfor ne "OK") {
        $term->log("getMessages : failed to get messages");
        return RET_ERR;
      }
    
      my @lines = split /[\r\n]+/, $term->{extra};  
      while (my $line = shift @lines)
      {
        if ($line =~ /^\+CMGL: (.*)/)  
        {
          my $m = {};
          ($m->{index}, $m->{stat}, $m->{from}) = unquote(split /,\s*/, $1);
          $m->{data} = shift @lines;
	  
          # if necessary, do encoding conversion
          $m->{data} = Encode::decode($term->{charset}, $m->{data}) if $term->{charset};
          push @msgs, $m;
        }
      }
    }
  }
      
  return @msgs;
}


=item B<setMessages> - write messages to the terminal

=cut  

sub setMessages
{
  my ($class, $term, @mbox) = @_;
  
  my $ret = RET_OK;  
  foreach my $entry (@mbox) {
    # write entry to the terminal's phonebook
    my $result;
    if ($term->{msg_mode} eq SMS_MODE_PDU) {
      my $pkt = SMS::PDU->decode(pack('H*', $entry->{data}));
      $result = $term->sendPDUs('CMGW', $pkt);
    } else {
      # TODO : fix me
      $term->log("SMS::Entry::set : text mode not implemented yet!");
      $result = RET_ERR;
    }
    $ret = RET_ERR unless ($result eq RET_OK);
  }
    
  return $ret;
}



=item B<deleteMessage> - delete a message stored on the handset

=cut 

sub deleteMessage
{
  my ($class, $term, $index) = @_;
  $term->send("AT+CMGD=$index" . CR);
  
  if ($term->waitfor ne "OK") {
    $term->log("deleteMessage : failed to delete message");
    return RET_ERR;
  }
  
  return RET_OK;
}


=item B<readMessages> - Reads messages from a file

=cut 

sub readMessages
{
  my ($class, $log, $file) = @_;

  my @mbox;  

  if (open(FILE, "< $file")) {
  
    # read messages
    my @lines = <FILE>;  
    close FILE;
  
    # import the messages
    foreach my $line (@lines) {
      my $m = UMTS::SMS::Entry->parse($line);
      push @mbox, $m;
    }
  
  } else {
  
    # error opening file
    $log->write("Could not open file '$file'");
    
  }  

  return @mbox;
}


=item B<writeMessages> - Writes messages to a file

=cut 

sub writeMessages
{
  my ($class, $log, $file, @mbox) = @_;
    
    
  if (open(FILE, "> $file")) {
  
    # write messages
    foreach my $m (@mbox) {
      print FILE $m->dump;
    }  
    close FILE;
    
  } else {
    
    # error opening file
    log->write("Could not open file '$file'");
    
  }
}


sub unquote
{
  my @ins = @_;
  my @out;
  
  foreach my $in (@ins) {
    $in =~ s/^\"(.*)\"$/$1/;
    push @out, $in;
  }
  return (@out > 1) ? @out : shift @out;
}


return 1;

=back

