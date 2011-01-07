#!/usr/bin/perl
#
# umts-tools - tools for manipulating 3G terminals
# Copyright (C) 2004-2005 Jeremy Lainé <jeremy.laine@m4x.org>
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

package UMTS::Terminal::Keys;

use strict;
use warnings;

use Carp ();
use UMTS::Core;

sub gotoIdleScreen
{
  my $self = shift;
  my $ret = RET_OK;
  
  $self->cacheTermInfo;
  if ($self->{ue}->type eq 'motorola')
  {
    $self->send("AT+CKPD=ee" . CR);
    $self->waitfor;
  } elsif ($self->{ue}->type eq 'semc') {
    $self->send('AT+CKPD=":R",20,10' . CR);
    $self->waitfor;
    $self->wait(4);
  } else {
    $self->log("gotoIdleScreen : unsupported terminal");
    $ret = RET_ERR;
  }

  return $ret
}


sub clearCache
{
  my $self = shift;
  my $ret = RET_OK;
  
  $self->cacheTermInfo;
  my $str = '';
  my $wait = 0;
  if ($self->{ue}->type eq 'motorola')
  {
    $wait = 6;
    my $revision = $self->{ue}->revision;
    if ($revision =~ /_U_85\./) {    
      $str = "AT+CKPD=m^[vvvvvv[vvv[";
    }
  } elsif ($self->{ue}->type eq 'semc') {
    $wait = 2;
    my $model = $self->{ue}->model;
    if ($model eq 'AAD-3021011-BV') {
      # V800
      $str = 'AT+CKPD=":D*65:J"';
    }
  }

  if ($str) {
    $self->send($str . CR);
    $self->waitfor;
    $wait && $self->wait($wait);
    $ret = RET_OK;
  } else {
    $self->log("clearCache : unsupported terminal");
    $ret = RET_ERR;
  }
  
  return $ret;
}


sub launchBrowser
{
  my $self = shift;
  my $ret = RET_OK;
  
  $self->cacheTermInfo;
  if ($self->{ue}->type eq 'motorola')
  {
    $self->send("AT+CKPD=]" . CR);
    $self->waitfor;
  } elsif ($self->{ue}->type eq 'semc') {
    $self->send('AT+CKPD=":O"' . CR);
    $self->waitfor;
  } else {
    $self->log("launchBrowser : unsupported terminal");
    $ret = RET_ERR;
  }
  
  return $ret;
}


sub wakeup
{
  my $self = shift;
  my $ret = RET_OK;
  
  $self->cacheTermInfo;
  if ($self->{ue}->type eq 'motorola')
  {
    $self->send("AT+CKPD=c" . CR);
    $self->waitfor;
  } elsif ($self->{ue}->type eq 'semc') {
    $self->send('AT+CKPD=":R"' . CR);
    $self->waitfor;
    $self->wait(1);
  } else {
    $self->log("wakeup : unsupported terminal");
    $ret = RET_ERR;
  }

  return $ret;
}

1;

