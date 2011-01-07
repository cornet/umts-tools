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

package UMTS::PDP::POSIX;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);

use Carp ();
use Exporter;
use File::Temp qw(tmpnam);
use UMTS::Core;

use constant NL => "\n";

my $pppd = "/usr/sbin/pppd";
my $chat = "/usr/sbin/chat";

@ISA = qw(Exporter);
@EXPORT = qw(connectionStart connectionStop);

# make pppd chat file
sub makeChatFile
{
  my ($tmpfile, $number, $initstring) = @_;

  open(FILE, "> $tmpfile") or
    return RET_ERR;
  
  # abort string
  print FILE "ABORT BUSY ABORT 'NO CARRIER' ABORT VOICE ABORT 'NO DIALTONE' ABORT 'NO DIAL TONE' ABORT 'NO ANSWER' ABORT DELAYED" . NL .
        '"" "AT&F"' . NL;
  
  if ($initstring) 
  {
    $initstring =~ s/"/\\"/g;
    print FILE '"OK^M" "'. $initstring . '"' . NL;
  }

  print FILE '"OK^M" "ATD'. $number . '"' . NL .
        "CONNECT" . NL;

  close(FILE);
  return RET_OK;
}


# make pppd options file
sub makeOptionsFile
{
  my ($tmpfile, $port, $chatscript) = @_;
 
  if (!open(FILE, "> $tmpfile"))
  {
    print "Could not open temporary file '$tmpfile'\n";
    return RET_ERR;
  };
  
  print FILE "hide-password" . NL .
        "connect \"$chat -v -f $chatscript\"" . NL .
	$port . NL .
	"230400" . NL;
	
  print FILE "noipdefault" . NL . 
        "debug" . NL .
        "noauth" . NL .
        "noaccomp" . NL .
        "nopcomp" . NL .
        "noccp" . NL .
        "novj" . NL .
        "novjccomp" . NL;

  close(FILE);
  return RET_OK;
}


# set up a dialup connection
sub connectionStart
{
  my $params = shift;

  if (!$params->{port} or !$params->{number})
  {
    print "You must specify 'port' and 'number' parameters!\n";
    return RET_ERR;    
  }

  # create temporary file with chat script
  my $chatfile = tmpnam();
  if (!makeChatFile($chatfile, $params->{number}, $params->{initstring}))
  {
    print "Could not generate chat script file '$chatfile'\n";
    return RET_ERR;
  };
 
  my $optfile = tmpnam();
  if (!makeOptionsFile($optfile, $params->{port}, $chatfile))
  {
    print "Could not generate options file '$optfile'\n";
    unlink($chatfile);
    return RET_ERR;
  };

  system("sudo $pppd file $optfile");
  #print "option file : $optfile\n";
  
  #unlink($chatfile);
  #unlink($optfile);
  return RET_OK;
}


# terminate dialup connection
sub connectionStop
{
  my $props = shift;

  system("killall $pppd");
  return RET_OK;
}

1;

