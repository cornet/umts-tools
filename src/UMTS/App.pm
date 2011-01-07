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

package UMTS::App;

use strict;
use warnings;
use vars qw($VERSION);

use Config::General;
use UMTS::Log;
use UMTS::Dummy;
use UMTS::Terminal;

$VERSION = $UMTS::Core::VERSION;

use constant CONFIGDIR => ($^O eq "MSWin32") ? "c:/.umts-tools" : "$ENV{'HOME'}/.umts-tools";
use constant USERCONFIG => CONFIGDIR . "/config";


# default configuration

sub read_config
{
  my $config =
  {
      terminal => 'UMTS::Terminal',
      port => '',
      debug => 0,
      logfile => '',
      phonebook => CONFIGDIR . "/default.upbk",
  };

  if (!-d CONFIGDIR) {
    mkdir(CONFIGDIR);    
  }
  
  if (-f USERCONFIG) {
  
    my $conf = new Config::General(
      -ConfigFile => USERCONFIG,
      -AllowMultiOptions =>"yes",
      -LowerCaseNames =>"yes"
    );
    my %rawconf = $conf->getall;
    foreach my $key(%rawconf) {
      $config->{$key} = $rawconf{$key};
    }
  }
  
  return $config;
}


sub parse_opts
{
  my ($class, %opts) = @_;
  
  my $config = $class->read_config;
  
  if (defined($opts{d})) {
    $config->{debug} = $opts{d};
  }
  
  if (defined($opts{l})) {
    $config->{logfile} = $opts{l};
  }
  
  if (defined($opts{p})) {
    $config->{port} = $opts{p};
    $config->{terminal} = 'UMTS::Terminal';
  }
  
  if (defined($opts{z})) {
    $config->{port} = '';
    $config->{terminal} = 'UMTS::Dummy';  
  }
  
  return $config;
}

sub make_log
{
  my ($class, $config) = @_;
  
  return UMTS::Log->new($config->{logfile});
}


sub make_term
{
  my ($class, $config, $log) = @_;
  
  defined($log) or $log = $class->make_log($config);
  
  my $termclass = $config->{terminal};  
  my $term = $termclass->new(log => $log, port => $config->{port}, debug => $config->{debug});

  if (!ref($term)) {
    $log->write("failed to open terminal '$config->{port}'");
    return;
  }
  
  # reset the terminal
  if (!$term->reset) {
    $log->write("terminal did not reset!"); 
    return;
  }
      
  # if this is a dummy terminal, load phonebook
  #if ($opts{z} and $opts{r}) {
  #  $term->readPhonebook($opts{r});
  #}
  
  # log terminal information
  $term->cacheTermInfo(1);

  # set default character & messagemode
  $term->setCharacterSet($term->{ue}->getCharacterSet);
  $term->setMessageMode($term->{ue}->getMessageMode);
  
  return $term;
}


sub usage
{
  my $opts = 
        " Common options:\n".
        "  -d          debugging mode\n".
        "  -l<log>     write log to <log>\n".
        "  -h          display this help message\n".
        "  -p<port>    terminal is connected to serial port <port>\n".
        "              e.g. '\\\\.\\COM12', '/dev/usb/acm/0'\n".     
        "  -z          use dummy terminal\n\n";
  return $opts;
}


return 1;

