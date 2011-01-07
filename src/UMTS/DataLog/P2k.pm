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

package UMTS::DataLog::P2k;

use strict;

use Carp ();
use WSP::Headers;

use constant MIN_PRIM_SIZE => 12;
use constant MAX_PRIM_SIZE => 65536;
use constant BLOCK_SIZE => 8192;
use constant SYNC_PATTERN  => 0xB5C;


sub new
{
  my $class = shift;
  my $self = {
    'callback' => \&process_primitive,
  };
  bless($self, $class);
}


sub get_primitive_length
{
  my ($self, $bin) = @_;
  return 0 if (length($bin) < MIN_PRIM_SIZE);

  my ($a, $msglength) = unpack("nn", $bin);
  my $syncpattern = ($a & 0xFFF0) >> 4;
  return -1 unless ($syncpattern == SYNC_PATTERN);
  
  return 0 if (length($bin) < $msglength);
  return $msglength;
}


sub get_primitive_skip
{
  my ($self, $bin) = @_;
  my $blen = length($bin);
  my $startpos;
  for (my $i=0; $i < $blen; $i++)
  {
    my $tmp = unpack("n", substr($bin, $i, 2));
    if ((($tmp & 0xFFF0) >> 4) == SYNC_PATTERN)
    {
      return $i;
    }
  }
  return;
}

sub hexsprint
{
  my $self = shift;
  WSP::Headers->hexsprint(@_);
}


sub unpack_primitive
{
  my ($self, $bin) = @_;
  my $prim = { 'MsgName' => "" };
  (my $a, $prim->{MsgLength}, $prim->{TimeStamp}, $prim->{MsgID}) = unpack("nnNN", $bin);
  $prim->{SyncPattern} = ($a & 0xFFF0) >> 4;
  $prim->{MsgOrig}     = ($a & 0x000C) >> 2;
  $prim->{LogMsgType}  = ($a & 0x0003);
  Carp::croak("Invalid SyncPattern : $prim->{SyncPattern}") 
    unless ($prim->{SyncPattern} == SYNC_PATTERN);
  my $pos = 12;

  # 0x00 : Send
  # 0x01 : Receive
  # 0x02 : Reply
  # 0x03 : Arbitrary
  if ($prim->{LogMsgType} < 0x03)
  {
    ($prim->{DestPortID}, $prim->{ReplyPortID}, $prim->{Reserved}, $prim->{MsgPriority}) = unpack("NNCC", substr($bin, $pos));
    $pos += 10;
  }
  $prim->{Block} = substr($bin, 0, $prim->{MsgLength});
  $prim->{Body} = substr($bin, $pos, $prim->{MsgLength} - $pos);
  return $prim;
}


sub print_primitive
{
  my ($self, $prim) = @_;

  my $str = "";
  $str .= "HEADER :\n--------\n\n";
  $str .= sprintf("MsgName       : %s\n", $prim->{MsgName});
  $str .= sprintf("SyncPattern   : %.4X\n", $prim->{SyncPattern});
  $str .= sprintf("MsgOrig       : %.2X\n", $prim->{MsgOrig});
  $str .= sprintf("LogMsgType    : %.2X\n", $prim->{LogMsgType});
  $str .= sprintf("MsgLength     : %.4X\n", $prim->{MsgLength});
  $str .= sprintf("TimeStamp     : %.8X\n", $prim->{TimeStamp});
  $str .= sprintf("MsgID         : %.8X\n", $prim->{MsgID});
  if (defined($prim->{DestPortID}))
  {
    $str .= sprintf("DestPortID    : %.8X\n", $prim->{DestPortID});
    $str .= sprintf("ReplyPortID   : %.8X\n", $prim->{ReplyPortID});
    $str .= sprintf("Reserved      : %.2X\n", $prim->{Reserved});
    $str .= sprintf("MsgPriority   : %.2X\n", $prim->{MsgPriority});
  }
  $str .= sprintf("\n\n");
  $str .= sprintf("BODY :\n-----\n\n");
  $str .= sprintf("Body hex dump :\n");
  $str .= sprintf("%s\n\n", $self->hexsprint($prim->{Body}));
  $str .= sprintf("Logger block hex dump :\n");
  $str .= sprintf("%s\n\n", $self->hexsprint($prim->{Block}));
  $str .= sprintf("\n");

  return $str;
}


sub process_primitive
{
  my ($self,$prim) = @_;
  
  # override to do something
}


sub parse
{
  my ($self, $file) = @_;
  $file or $file = "-";

  if (!open(FP, "<$file"))
  {
    Carp::croak("P2k log parsing failed, could not open '$file'");
  }
  binmode(FP);

  # process the primitives
  my $buff = "";
  my $end = 0;
  my $nprim = 0;
  
  while (!$end)
  {
    my $plen = $self->get_primitive_length($buff);

    if ($plen > 0)
    {
      # we have a primitive
      my $prim = $self->unpack_primitive(substr($buff, 0, $plen));
 
      $nprim++;
      my $func = $self->{callback};
      &$func($self,$prim);
     
      $buff = substr($buff, $plen);
    } elsif ($plen == 0) {
      # we have an incomplete primitive, we need more data
      if (!eof(FP))
      {
        # read some more data
        my $block;
        my $blen = read(FP, $block, BLOCK_SIZE);
        if (!defined($blen))
        {
          print STDERR "Error while reading!\n";
          $end = 1;
        } else {
          $buff .= $block;
        }
      } else {
        # we cannot read any more data
        $end = 1;
      }
    } else {
      # we got a bad primitive, skip
      my $startpos = $self->get_primitive_skip($buff);
      if (defined($startpos))
      {
        print STDERR "Bad primitive, discarding $startpos bytes.\n";
        $buff = substr($buff, $startpos);
      } else {
        print STDERR "Could resync to after bad primitive, aborting.\n";
        $end = 1;
      }
    }
  }
  close(FP);

  return $nprim;
}

1;
