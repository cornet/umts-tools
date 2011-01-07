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

package UMTS::Test;

use strict;
use vars qw(@ISA @EXPORT);

use UMTS::Core;
use UMTS::Log;
use Exporter;

@ISA = qw(Exporter $UMTS::Test::Port $UMTS::Test::Terminal $log);

$UMTS::Test::Port = '';
$UMTS::Test::Terminal = 'UMTS::Dummy';
$UMTS::Test::Settings = 'TestSettings.txt';

our $log = new UMTS::Log;

sub spawnTerm
{
  my ($class, $terminal, $port) = @_;

  $class->readParams; 
  eval "use $UMTS::Test::Terminal;";
  return $UMTS::Test::Terminal->new(log => $log, port => $UMTS::Test::Port, debug => 1);
}


sub clearParams
{
  my $class = @_;
  
  ( -f $UMTS::Test::Settings ) and
    unlink($UMTS::Test::Settings);
    
  return RET_OK;
}


sub readParams
{
  ( -f $UMTS::Test::Settings) or
    return RET_ERR;
     
  open(FILE, "< $UMTS::Test::Settings") or
    exit RET_ERR;

  while (my $line = <FILE>)
  {
    if ($line =~ /^\s*([^\s=]+)\s*=\s*([^\s]+)/)
    {
      my ($var, $val) = ($1, $2);
      
      if ($var eq 'Terminal') {
        $UMTS::Test::Terminal = $val;
      } elsif ($var eq 'Port') {
        $UMTS::Test::Port = $val;
      }
    }
  }
  close(FILE);
      
  return RET_OK;     
}


sub writeParams
{
  my ($class, $params) = @_;

  open(FILE, "> $UMTS::Test::Settings") or
    exit RET_ERR;
    
  foreach my $key (keys %{$params}) {
    print FILE "$key = $params->{$key}\n";
  }  
  
  close(FILE);
  
  return RET_OK;
}


1;
