#!/usr/bin/env perl

=head1 NAME

  Device::Sensor::AtlasScientific

=head1 SYNOPSIS


=head1 DESCRIPTION

  Device::Sensor::AtlasScientific is a driver for the Atlas Scientific series of
  environmental sensors.

=head1 DEPENDENCIES

  Device::Sensor::AtlasScientific requires Perl version 5.10 or later.

=head1 FEEDBACK

=head2 Reporting Bugs

  Report bugs to the GitHub issue tracker at:
  https://github.com/sandain/growbot/issues

=head1 AUTHOR - Jason M. Wood

  Email sandain@hotmail.com

=head1 COPYRIGHT AND LICENSE

  Copyright (c) 2020  Jason M. Wood <sandain@hotmail.com>

  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:

  1. Redistributions of source code must retain the above copyright notice,
     this list of conditions and the following disclaimer.
  2. Redistributions in binary form must reproduce the above copyright
     notice, this list of conditions and the following disclaimer in the
     documentation and/or other materials provided with the distribution.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
  POSSIBILITY OF SUCH DAMAGE.

=cut

package Device::Sensor::AtlasScientific;

use strict;
use warnings;
use utf8;
use v5.10;

use Device::I2C;
use IO::File;
use Exporter qw(import);

sub new {
  my $class = shift;
  die "Usage: $class->new (i2c, address)" unless (@_ == 2);
  my ($i2c, $address) = @_;
  my $io = new Device::I2C ($i2c, O_RDWR);
  # Make sure we can open the I2C bus.
  die "Error: Unable to open I2C Device File at $i2c"
    unless ($io);
  # Make sure we can open the Atlas Scientific device.
  die "Error: Unable to access device at $address"
    unless ($io->checkDevice ($address));
  # Select the device at the provided address.
  $io->selectDevice ($address);
  # Bless ourselves with our class.
  my $self = bless {
    i2c         => $i2c,
    address     => $address,
    io          => $io
  }, $class;
  return $self;
}

1;
