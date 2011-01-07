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

package UMTS::PDP::Win32;

use strict;
use vars qw(@ISA @EXPORT);

use Carp ();
use Exporter;
use File::Temp qw(tmpnam);
use Win32::Registry;
use UMTS::Core;

use constant NL => "\r\n";

@ISA = qw(Exporter);
@EXPORT = qw(connectionStart connectionStop);

# find the registy key holding all the modems
sub registryFindModemsKey
{  
  my ($regClasses, $regModems, @kids);
  $main::HKEY_LOCAL_MACHINE->Open("SYSTEM\\CurrentControlSet\\Control\\Class", $regClasses)
    or Carp::croak("Could not open Windows registry");
  $regClasses->GetKeys(\@kids);
  foreach my $k (@kids) {
    my ($regClass, %regVals);
    $regClasses->Open($k, $regClass);
    $regClass->GetValues(\%regVals);
    if ($regVals{'Class'}[2] eq 'Modem')
    {
      $regModems = $regClass;
      last;
    } else {
      $regClass->Close();
    }   
  }
  $regClasses->Close();
  return $regModems;
}


# find the registry key for a specific modem
sub registryFindModem
{
  my ($searchKey, $searchVal) = @_;

  my $regModems = registryFindModemsKey;
  if (!$regModems)
  {
    print "Could not find the modems in the registry.\n";
    return RET_ERR;
  }

  my ($regModem, @kids);
  $regModems->GetKeys(\@kids);
  foreach my $k (@kids)
  {
    my ($regKey, %regVals);
    $regModems->Open($k, $regKey);
    $regKey->GetValues(\%regVals);
    if (uc($regVals{$searchKey}[2]) eq uc($searchVal))
    {
      $regModem = $regKey;
      last;
    } else {
      $regKey->Close;
    }
  } 
  return $regModem; 
}


# find the registry key for a modem by name
sub registryFindModemByName
{
  my $modemname = shift;
  return registryFindModem("FriendlyName", $modemname);  
}


# find the registry key for a modem by COM port
sub registryFindModemByPort
{
  my $comport = shift;
  return registryFindModem("AttachedTo", $comport);  
}


# set up a dialup connection
sub connectionStart
{
  my $params = shift;

  if (!$params->{name} or !$params->{port} or !$params->{number})
  {
    print "You must specify 'name', 'port' and 'number' parameters!\n";
    return RET_ERR;    
  }
 
  if ($params->{port} =~ /^\\\\.\\(COM[0-9]+)$/i)
  {
    $params->{port} = $1;
  }
  
  my $regModem = registryFindModemByPort($params->{port});
  if (!$regModem)
  {
    print "Could not find modem corresponding to port '$params->{port}' in registry\n";
    return RET_ERR;
  }

  # if requested, set the modem init string
  if ($params->{initstring})
  {
    my $init = $params->{initstring};
    $init =~ s/^AT//;
    $regModem->SetValueEx('UserInit', 0, REG_SZ, $init);
  }
  $regModem->Close();

  # create temporary file with connection parameters
  my $tmpfile = tmpnam();

  if (!open(FILE, "> $tmpfile"))
  {
    print "Could not open temporary file '$tmpfile'\n";
    return RET_ERR;
  };
  print FILE "[UMTSTOOLS]". NL .
  "Encoding=1" . NL .
  "Type=1" . NL . 
  "AutoLogon=0" . NL .
  "BaseProtocol=1" . NL .
  "LcpExtensions=1" . NL .
  NL .
  "MEDIA=serial" . NL .
  "Port=". $params->{port} . NL .
  NL .
  "DEVICE=modem" . NL .
  "PhoneNumber=". $params->{number} . NL; 
  close(FILE);

  # launch the dialup connection
  my $ret = system("rasdial UMTSTOOLS /phonebook:$tmpfile");
  unlink($tmpfile);

  return $ret ? RET_ERR : RET_OK;  
}


# terminate dialup connection
sub connectionStop
{
  my $props = shift;

  my $ret = system("rasdial /disconnect");
  return $ret ? RET_ERR : RET_OK;
}


1;
