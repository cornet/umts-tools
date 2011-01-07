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

package UMTS::Terminal::Info;

use strict;
use warnings;
use vars qw(@ISA @EXPORT_OK %EXPORT_TAGS);

use UMTS::SMS qw(:modes);

my @UEDB = (
  [ 'Huawei handset',        'huawei',        '.*',                'huawei'   ],
  [ 'Motorola C980',         'motorola',      '"MODEL=C980"',      'motorola' ],
  [ 'Motorola V980',         'motorola',      '"MODEL=V980"',      'motorola' ],
  [ 'Motorola V1050',        'motorola',      '"MODEL=V1050"',     'motorola' ],
  [ 'Motorola E1000',        'motorola',      '"MODEL=E1000"',     'motorola' ],
  [ 'Motorola E770v',        'motorola',      '"MODEL=E770v"',     'motorola' ],
  [ 'Motorola handset',      'motorola',      '.*',                'motorola' ],
  [ 'Nokia 6630',            'nokia',         'Nokia 6630',        'nokia'    ],
  [ 'Nokia handset',         'nokia',         '.*',                'nokia'    ],
  [ 'Sagem myX3-2',          'sagem',         'myX3-2 GPRS',       'default'  ],
  [ 'Sagem handset',         'sagem',         '.*',                'default'  ],
  [ 'Sony Ericsson V800',    'sony ericsson', 'AAD-3021011-BV',    'semc'     ],
  [ 'Sony Ericsson V600i',   'sony ericsson', 'AAD-3021022-BV',    'semc'     ],
  [ 'Sony Ericsson W900i',   'sony ericsson', 'AAD-3022011-BV',    'semc'     ],
  [ 'Sony Ericsson handset', 'sony ericsson', '.*',                'semc'     ],
  [ 'Sharp V902SH / V802SH', 'sharp',         'SHARP/902SH_802SH', 'sharp'    ],
  [ 'Sharp handset',         'sharp',         '.*',                'sharp'    ],
  [ 'Samsung Z107',          'samsung',       '^129',              'samsung'  ],
  [ 'Samsung handset',       'samsung',       '.*',                'samsung'  ],
  [ 'Toshiba handset',       'toshiba',       '.*',                'huawei'   ],
);


=item B<new> - Construct a new terminal instance

=cut  

sub new
{
  my ($class, $manuf, $model, $rev, $imei, $imsi) = @_;

  my $self = { 
    'title'        => "Generic handset",
    'type'         => "default",
    'manufacturer' => defined($manuf)  ? $manuf : '',
    'model'        => defined($model)  ? $model : '',
    'imei'         => defined($imei)   ? $imei  : '',
    'revision'     => defined($rev)    ? $rev   : '',
    'imsi'         => defined($imsi)   ? $imsi  : '',
  };

  my $found = 0;  
  my @handsets = @UEDB;  
  while(!$found and my $term = shift @handsets)
  {  
    my ($i_term, $i_manuf, $i_model, $i_type) = @{$term};
    if (($self->{manufacturer} =~ /^$i_manuf/i) and ($self->{model} =~ /$i_model/i)) {
    
      $self->{title} = $i_term;
      $self->{type} = $i_type;
      $found = 1;
    }
  }  
  
    
  bless($self, $class);
}


=item B<log> - Log terminal information

=cut  

sub log
{
  my ($self, $log) = @_;  
  
  $log->write("Type         : ". $self->name ." (".$self->type.")");
  $log->write("Manufacturer : ". $self->manufacturer);
  $log->write("Model        : ". $self->model);
  $log->write("Revision     : ". $self->revision);  
  $log->write("IMEI         : ". $self->imei);  
  $log->write("IMSI         : ". $self->imsi);  
}


=item B<imei> - Return terminal IMEI

=cut  

sub imei
{
  my $self = shift;
  return $self->{imei};
}


=item B<imsi> - Return terminal IMSI

=cut  

sub imsi
{
  my $self = shift;
  return $self->{imsi};
}


=item B<manufacturer> - Return terminal manufacturer

=cut  

sub manufacturer
{
  my $self = shift;
  return $self->{manufacturer};
}


=item B<model> - Return terminal model

=cut  

sub model
{
  my $self = shift;
  return $self->{model};
}


=item B<name> - Return terminal name

=cut  

sub name
{
  my $self = shift;
  return $self->{title};
}


=item B<type> - Return terminal type

=cut  

sub type
{
  my $self = shift;
  return $self->{type};
}


=item B<revision> - Return terminal revision

=cut  

sub revision
{
  my $self = shift;
  return $self->{revision};
}


=item B<getCallStat> - Return the class used to determine call status

=cut

sub getCallStat  
{  
  my $self = shift;
  my $CallStat;
        
  if ( $self->type =~ /^(blacklisted)$/ )
  {
    # on these terminals, no extra checking is done
    $CallStat = '';
  }
  elsif ( $self->type =~ /^(motorola|nokia)$/ )
  {
    # on these handsets, check ongoing calls
    $CallStat = 'UMTS::Terminal::CallList';
  }
  else
  {
    # the default behaviour is to check activity status    
    $CallStat = 'UMTS::Terminal::CallStatus';
  }
  
  return $CallStat;
}


=item B<getHangup> - Get the voice hangup command

=cut

sub getHangup
{
  my $self = shift;

  if ( $self->type =~ /^(huawei)$/ )
  {
    return 'AT+CHUP';
  } else {
    return 'ATH';
  }
}


=item B<getMessageMode> - Return the preferred SMS mode

=cut

sub getMessageMode
{
  my $self = shift;
  my $mode;
  
  if ( $self->type =~ /^samsung$/ ) 
  {
    $mode = SMS_MODE_TEXT;
  }
  else
  {
    $mode = SMS_MODE_PDU;
  }
  
  return $mode;
}


=item B<getCharacterSet> - Return the preferred characterset

=cut

sub getCharacterSet
{
  my $self = shift;
  my $set;
  
  if ($self->type =~ /^(semc|sharp)$/) {
    $set = "UTF-8";
  } else {
    $set = "GSM";
  }
  return $set;
}


