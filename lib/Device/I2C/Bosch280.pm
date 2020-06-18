#!/usr/bin/env perl

=head1 NAME

  Device::I2C::Bosch280

=head1 SYNOPSIS

  Device::I2C driver for the Bosch BMP280 and BME280 environmental sensors.

=head1 DESCRIPTION

  Device::I2C::Bosch280 is an I2C driver for the Bosch BMP280 and BME280
  environmental sensors.

  This driver is based on documentation found at:
  https://www.bosch-sensortec.com/media/boschsensortec/downloads/datasheets/bst-bmp280-ds001.pdf
  https://www.bosch-sensortec.com/media/boschsensortec/downloads/datasheets/bst-bme280-ds002.pdf

  And reference C code provided by Bosch Sensortec:
  https://github.com/BoschSensortec/BME280_driver

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

package Device::I2C::Bosch280;

use strict;
use warnings;
use 5.010;

use Device::I2C;
use IO::File;
use Exporter qw (import);

## Public constants.

# Supported sensors.
use constant BOSCH280_SENSOR_BMP280 => 0x01;
use constant BOSCH280_SENSOR_BME280 => 0x02;

# Power modes.
use constant BOSCH280_MODE_SLEEP  => 0x00;
use constant BOSCH280_MODE_FORCED => 0x01;
use constant BOSCH280_MODE_NORMAL => 0x03;

# Oversampling mode.
use constant BOSCH280_OVERSAMPLING_OFF => 0x00;
use constant BOSCH280_OVERSAMPLING_X1  => 0x01;
use constant BOSCH280_OVERSAMPLING_X2  => 0x02;
use constant BOSCH280_OVERSAMPLING_X4  => 0x03;
use constant BOSCH280_OVERSAMPLING_X8  => 0x04;
use constant BOSCH280_OVERSAMPLING_X16 => 0x05;

# Standby duration.
use constant BOSCH280_STANDBY_X0 => 0x00;  # BMP280   0.5 ms    BME280  0.5 ms
use constant BOSCH280_STANDBY_X1 => 0x01;  # BMP280  62.5 ms    BME280 62.5 ms
use constant BOSCH280_STANDBY_X2 => 0x02;  # BMP280   125 ms    BME280  125 ms
use constant BOSCH280_STANDBY_X3 => 0x03;  # BMP280   250 ms    BME280  250 ms
use constant BOSCH280_STANDBY_X4 => 0x04;  # BMP280   500 ms    BME280  500 ms
use constant BOSCH280_STANDBY_X5 => 0x05;  # BMP280  1000 ms    BME280 1000 ms
use constant BOSCH280_STANDBY_X6 => 0x06;  # BMP280  2000 ms    BME280   10 ms
use constant BOSCH280_STANDBY_X7 => 0x07;  # BMP280  4000 ms    BME280   20 ms

# Filter settings.
use constant BOSCH280_FILTER_OFF => 0x01;
use constant BOSCH280_FILTER_X2  => 0x02;
use constant BOSCH280_FILTER_X4  => 0x03;
use constant BOSCH280_FILTER_X8  => 0x04;
use constant BOSCH280_FILTER_X16 => 0x05;

# Minimum and maximum values.
use constant BOSCH280_TEMPERATURE_MIN => -40; # Minimum temperature (C)
use constant BOSCH280_TEMPERATURE_MAX => 85;  # Maximum temperature (C)
use constant BOSCH280_PRESSURE_MIN => 300;    # Minimum pressure (hPa)
use constant BOSCH280_PRESSURE_MAX => 1100;   # Maximum pressure (hPa)
use constant BOSCH280_HUMIDITY_MIN => 0;      # Minimum humidity (%)
use constant BOSCH280_HUMIDITY_MAX => 100;    # Maximum humidity (%)

## Private constants.

# Supported sensor identifiers.
use constant BOSCH280_ID_BMP280_0 => 0x56;
use constant BOSCH280_ID_BMP280_1 => 0x57;
use constant BOSCH280_ID_BMP280_2 => 0x58;
use constant BOSCH280_ID_BME280   => 0x60;

# BMP280 standby duration (ms).
use constant BOSCH280_STANDBY_X0_BMP280 =>    0.5;
use constant BOSCH280_STANDBY_X1_BMP280 =>   62.5;
use constant BOSCH280_STANDBY_X2_BMP280 =>  125;
use constant BOSCH280_STANDBY_X3_BMP280 =>  250;
use constant BOSCH280_STANDBY_X4_MP280  =>  500;
use constant BOSCH280_STANDBY_X5_BMP280 => 1000;
use constant BOSCH280_STANDBY_X6_BMP280 => 2000;
use constant BOSCH280_STANDBY_X7_BMP280 => 4000;

# BME280 standby duration (ms).
use constant BOSCH280_STANDBY_X0_BME280 =>    0.5;
use constant BOSCH280_STANDBY_X1_BME280 =>   62.5;
use constant BOSCH280_STANDBY_X2_BME280 =>  125;
use constant BOSCH280_STANDBY_X3_BME280 =>  250;
use constant BOSCH280_STANDBY_X4_BME280 =>  500;
use constant BOSCH280_STANDBY_X5_BME280 => 1000;
use constant BOSCH280_STANDBY_X6_BME280 =>   10;
use constant BOSCH280_STANDBY_X7_BME280 =>   20;

# Register addresses.
use constant BOSCH280_REG_CHIP_ID       => 0xD0;  # Chip Identifier.
use constant BOSCH280_REG_RESET         => 0xE0;  # Reset.
use constant BOSCH280_REG_CTRL_HUM      => 0xF2;  # Control humidity oversampling (BME280 only).
use constant BOSCH280_REG_STATUS        => 0xF3;  # Device status.
use constant BOSCH280_REG_CTRL_MEAS     => 0xF4;  # Control temperature & pressure oversampling.
use constant BOSCH280_REG_CONFIG        => 0xF5;  # Config IIR filter.
use constant BOSCH280_REG_PRESS         => 0xF7;  # Raw pressure data.
use constant BOSCH280_REG_TEMP          => 0xFA;  # Raw temperature data.
use constant BOSCH280_REG_HUM           => 0xFD;  # Raw humidity data (BME280 only).
use constant BOSCH280_REG_CALIBRATION_0 => 0x88;  # Pressure and temperature.
use constant BOSCH280_REG_CALIBRATION_1 => 0xE1;  # Humidity.

# Register lengths.
use constant BOSCH280_TEMP_LENGTH  => 3;           # Length of temperature data.
use constant BOSCH280_PRESS_LENGTH => 3;           # Length of pressure data.
use constant BOSCH280_HUM_LENGTH   => 2;           # Length of humidity data (BME280 only).
use constant BOSCH280_CALIBRATION_LENGTH_0 => 26;  # Length of temperature & pressure calibration data.
use constant BOSCH280_CALIBRATION_LENGTH_1 => 7;   # Length of humidity calibration data (BME280 only).

# Reset command.
use constant BOSCH280_CMD_RESET => 0xB6;

our @EXPORT_OK = qw (
  BOSCH280_SENSOR_BMP280
  BOSCH280_SENSOR_BME280
  BOSCH280_OVERSAMPLING_OFF
  BOSCH280_OVERSAMPLING_X1
  BOSCH280_OVERSAMPLING_X2
  BOSCH280_OVERSAMPLING_X4
  BOSCH280_OVERSAMPLING_X8
  BOSCH280_OVERSAMPLING_X16
  BOSCH280_MODE_SLEEP
  BOSCH280_MODE_FORCED
  BOSCH280_MODE_NORMAL
  BOSCH280_STANDBY_X0
  BOSCH280_STANDBY_X1
  BOSCH280_STANDBY_X2
  BOSCH280_STANDBY_X3
  BOSCH280_STANDBY_X4
  BOSCH280_STANDBY_X5
  BOSCH280_STANDBY_X6
  BOSCH280_STANDBY_X7
  BOSCH280_FILTER_OFF
  BOSCH280_FILTER_X2
  BOSCH280_FILTER_X4
  BOSCH280_FILTER_X8
  BOSCH280_FILTER_X16
  BOSCH280_TEMPERATURE_MIN
  BOSCH280_TEMPERATURE_MAX
  BOSCH280_PRESSURE_MIN
  BOSCH280_PRESSURE_MAX
  BOSCH280_HUMIDITY_MIN
  BOSCH280_HUMIDITY_MAX
);

our @ISA = qw (Device::I2C);

sub new {
  my $class = shift;
  die "Usage: $class->new (i2c, address)" unless (@_ == 2);
  my ($i2c, $address) = @_;
  my $device = new Device::I2C ($i2c, O_RDWR);
  # Make sure we can open the I2C bus.
  die "Error: Unable to open I2C Device File at $i2c"
    unless ($device);
  # Make sure we can open the BME280 or BMP280 device.
  die "Error: Unable to access device at $address"
    unless ($device->checkDevice ($address));
  # Select the device at the provided address.
  $device->selectDevice ($address);
  # Bless ourselves with our class.
  my $self = bless {
    i2c         => $i2c,
    address     => $address,
    device      => $device
  }, $class;
  return $self;
}

1;
