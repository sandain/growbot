#!/usr/bin/env perl

=head1 NAME

  Device::I2C::Bosche280

=head1 SYNOPSIS

  Device::I2C driver for the Bosch BMP280 and BME280 environmental sensors.

=head1 DESCRIPTION

  Device::I2C::Bosche280 is an I2C driver for the Bosch BMP280 and BME280
  environmental sensors.

  This driver is based on documentation found at:
  https://www.bosch-sensortec.com/media/boschsensortec/downloads/datasheets/bst-bmp280-ds001.pdf
  https://www.bosch-sensortec.com/media/boschsensortec/downloads/datasheets/bst-bme280-ds002.pdf

=head1 DEPENDENCIES

  Device::I2C::Bosch requires Perl version 5.10 or later.

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

=head1 APPENDIX

  The rest of the documentation details each of the object methods.

=cut

package Device::I2C::Bosche280;

use strict;
use warnings;
use 5.010;

use Device::I2C;
use IO::File;
use Exporter qw (import);

# Supported sensors
use enum qw (:BOSCHE280_SENSOR_ BMP280 BME280);
#use constant BOSCHE280_ID_BMP280_0 => 0x56;
#use constant BOSCHE280_ID_BMP280_1 => 0x57;
#use constant BOSCHE280_ID_BMP280_2 => 0x58;
#use constant BOSCHE280_ID_BME280   => 0x60;

# Power modes.
use enum qw (:BOSCHE280_MODE_ SLEEP FORCED NORMAL);
#use constant BOSCHE280_MODE_SLEEP  => 0x00;
#use constant BOSCHE280_MODE_FORCED => 0x01;
#use constant BOSCHE280_MODE_NORMAL => 0x03;

# Oversampling mode
use enum qw (:BOSCHE280_OVERSAMPLING_ OFF X1 X2 X4 X8 X16);
#use constant BOSCHE280_OVERSAMPLING_OFF => 0x00;
#use constant BOSCHE280_OVERSAMPLING_X1  => 0x01;
#use constant BOSCHE280_OVERSAMPLING_X2  => 0x02;
#use constant BOSCHE280_OVERSAMPLING_X4  => 0x03;
#use constant BOSCHE280_OVERSAMPLING_X8  => 0x04;
#use constant BOSCHE280_OVERSAMPLING_X16 => 0x05;

# Standby duration.
use constant BOSCHE280_STANDBY_0 => 0x00;  # BMP280   0.5 ms    BME280  0.5 ms
use constant BOSCHE280_STANDBY_1 => 0x01;  # BMP280  62.5 ms    BME280 62.5 ms
use constant BOSCHE280_STANDBY_2 => 0x02;  # BMP280   125 ms    BME280  125 ms
use constant BOSCHE280_STANDBY_3 => 0x03;  # BMP280   250 ms    BME280  250 ms
use constant BOSCHE280_STANDBY_4 => 0x04;  # BMP280   500 ms    BME280  500 ms
use constant BOSCHE280_STANDBY_5 => 0x05;  # BMP280  1000 ms    BME280 1000 ms
use constant BOSCHE280_STANDBY_6 => 0x06;  # BMP280  2000 ms    BME280   10 ms
use constant BOSCHE280_STANDBY_7 => 0x07;  # BMP280  4000 ms    BME280   20 ms

# Filter settings.
use enum qw (:BOSCHE280_FILTER_ OFF X2 X4 X8 X16);
#use constant BOSCHE280_FILTER_OFF => 0x00;
#use constant BOSCHE280_FILTER_2   => 0x01;
#use constant BOSCHE280_FILTER_4   => 0x02;
#use constant BOSCHE280_FILTER_8   => 0x03;
#use constant BOSCHE280_FILTER_16  => 0x04;

# Register Addresses.
use constant BOSCHE280_REG_CALIBRATION_T1 => 0x88;  # unsigned short
use constant BOSCHE280_REG_CALIBRATION_T2 => 0x8A;  # signed short
use constant BOSCHE280_REG_CALIBRATION_T3 => 0x8C;  # signed short
use constant BOSCHE280_REG_CALIBRATION_P1 => 0x8E;  # unsigned short
use constant BOSCHE280_REG_CALIBRATION_P2 => 0x90;  # signed short
use constant BOSCHE280_REG_CALIBRATION_P3 => 0x92;  # signed short
use constant BOSCHE280_REG_CALIBRATION_P4 => 0x94;  # signed short
use constant BOSCHE280_REG_CALIBRATION_P5 => 0x96;  # signed short
use constant BOSCHE280_REG_CALIBRATION_P6 => 0x98;  # signed short
use constant BOSCHE280_REG_CALIBRATION_P7 => 0x9A;  # signed short
use constant BOSCHE280_REG_CALIBRATION_P8 => 0x9C;  # signed short
use constant BOSCHE280_REG_CALIBRATION_P9 => 0x9E;  # signed short
use constant BOSCHE280_REG_CALIBRATION_H1 => 0xA1;  # unsigned char (BME280 only)
use constant BOSCHE280_REG_CALIBRATION_H2 => 0xE1;  # signed short  (BME280 only)
use constant BOSCHE280_REG_CALIBRATION_H3 => 0xE3;  # unsigned char (BME280 only)
use constant BOSCHE280_REG_CALIBRATION_H4 => 0xE4;  # signed short  (BME280 only)
use constant BOSCHE280_REG_CALIBRATION_H5 => 0xE5;  # signed short  (BME280 only)
use constant BOSCHE280_REG_CALIBRATION_H6 => 0xE7;  # signed char   (BME280 only)

use constant BOSCHE280_REG_CHIP_ID => 0xD0;   # BMP280 returns 0x56 / 0x57 / 0x58    BME280 returns 0x60
use constant BOSCHE280_REG_RESET => 0xE0;     # Write 0xB6 to reset
use constant BOSCHE280_REG_CTRL_HUM => 0xF2;  # Control oversampling of humidity (BME280 only)
use constant BOSCHE280_REG_STATUS => 0xF3;    # Device status
use constant BOSCHE280_REG_CTRL_MEAS => 0xF4; # Control oversampling of temperature and pressure, and sampling mode
use constant BOSCHE280_REG_CONFIG => 0xF5;    # Control inactive duration and the time constant of IIR filter
use constant BOSCHE280_REG_PRESS => 0xF7;     # Raw pressure data
use constant BOSCHE280_REG_TEMP => 0xFA;      # Raw temperature data
use constant BOSCHE280_REG_HUM => 0xFD;       # Raw humidity data (BME280 only)


#our @EXPORT_OK = qw ();

our @ISA = qw (Device::I2C);

sub new {
  my $class = shift;
  die "Usage: $class->new (Device Address)" unless (@_ == 1);
  my ($address) = @_;
  my $self = bless {
    address => $address,
    device  => new Device::I2C ($address, O_RDWR)
  }, $class;
  die "Unable to open I2C Device File at $address" unless ($self->device);
  return $self;
}

sub resetDevice {

}

1;
