#!/usr/bin/env perl

=head1 NAME

  Device::Sensor::Bosch280

=head1 SYNOPSIS

  use strict;
  use warnings;
  use utf8;
  use v5.10;
  use open qw/:std :utf8/;

  use Device::Sensor::Bosch280 qw (
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
  );

  # The I2C device file.
  my $device = '/dev/i2c-1';

  # The address of the BME280 or BMP280 (0x76 or 0x77).
  my $address = 0x77;

  # Load this driver.
  my $bme280 = Device::Sensor::Bosch280->new ($device, $address);

  # Verify the model of the device.
  die "Unexpected model" unless ($bme280->{model} == BOSCH280_SENSOR_BME280);

  # Perform a soft reset on the device.
  $bme280->reset;

  # Modify the controls on the device.
  my $ctrl = $bme280->controls;
  $ctrl->{temperature} = BOSCH280_OVERSAMPLING_X2;
  $ctrl->{pressure} = BOSCH280_OVERSAMPLING_X2;
  $ctrl->{mode} = BOSCH280_MODE_FORCED;
  $ctrl->{humidity} = BOSCH280_OVERSAMPLING_X2;
  $bme280->controls ($ctrl);

  # Get a measurement from the device.
  my ($temperature, $pressure, $humidity) = $bme280->measure;
  printf "Temperature:\t%.2f °C\n", $temperature;
  printf "Pressure:\t%.2f hPa\n", $pressure;
  printf "Humidity:\t%.2f %%\n", $humidity;

=head1 DESCRIPTION

  Device::Sensor::Bosch280 is an I2C driver for the Bosch BMP280 and BME280
  environmental sensors.

  This driver is based on documentation found at:
  https://www.bosch-sensortec.com/media/boschsensortec/downloads/datasheets/bst-bmp280-ds001.pdf
  https://www.bosch-sensortec.com/media/boschsensortec/downloads/datasheets/bst-bme280-ds002.pdf

  And reference C code provided by Bosch Sensortec:
  https://github.com/BoschSensortec/BME280_driver

=head2 Methods

=over 12

=item C<new>

  Returns a new Device::Sensor::Bosch280 object.

=item C<id>

  Returns the identifier of the device.

=item C<reset>

  Perform a soft reset on the device.

=item C<status>

  Get the status of the device.

=item C<controls>

  Get or set the controls of the device.

=item C<config>

  Get or set the configuration of the device.

=item C<temperature>

  Get a temperature measurement from the device.

=item C<pressure>

  Get a presssure measurement from the device.

=item C<humidity>

  Get a humidity measurement from the device.

=item C<measure>

  Get a temperature, pressure, and humidity measure from the device.

=back

=head1 DEPENDENCIES

  Device::Sensor::Bosch280 requires Perl version 5.10 or later.

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

package Device::Sensor::Bosch280;

use strict;
use warnings;
use utf8;
use v5.10;

use Device::I2C;
use IO::File;
use Exporter qw (import);
use Time::HiRes qw (usleep);

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
use constant BOSCH280_TEMPERATURE_MIN => -40;      # Minimum temperature (C)
use constant BOSCH280_TEMPERATURE_MAX =>  85;      # Maximum temperature (C)
use constant BOSCH280_PRESSURE_MIN    =>  30000;   # Minimum pressure (Pa)
use constant BOSCH280_PRESSURE_MAX    =>  110000;  # Maximum pressure (Pa)
use constant BOSCH280_HUMIDITY_MIN    =>  0;       # Minimum humidity (%)
use constant BOSCH280_HUMIDITY_MAX    =>  100;     # Maximum humidity (%)

## Private constants.

# Supported sensor identifiers.
use constant BOSCH280_ID_BMP280_0 => 0x56;
use constant BOSCH280_ID_BMP280_1 => 0x57;
use constant BOSCH280_ID_BMP280_2 => 0x58;
use constant BOSCH280_ID_BME280   => 0x60;

# BMP280 standby duration (μs).
use constant BOSCH280_STANDBY_X0_BMP280 =>     500;
use constant BOSCH280_STANDBY_X1_BMP280 =>   62500;
use constant BOSCH280_STANDBY_X2_BMP280 =>  125000;
use constant BOSCH280_STANDBY_X3_BMP280 =>  250000;
use constant BOSCH280_STANDBY_X4_BMP280 =>  500000;
use constant BOSCH280_STANDBY_X5_BMP280 => 1000000;
use constant BOSCH280_STANDBY_X6_BMP280 => 2000000;
use constant BOSCH280_STANDBY_X7_BMP280 => 4000000;

# BME280 standby duration (μs).
use constant BOSCH280_STANDBY_X0_BME280 =>     500;
use constant BOSCH280_STANDBY_X1_BME280 =>   62500;
use constant BOSCH280_STANDBY_X2_BME280 =>  125000;
use constant BOSCH280_STANDBY_X3_BME280 =>  250000;
use constant BOSCH280_STANDBY_X4_BME280 =>  500000;
use constant BOSCH280_STANDBY_X5_BME280 => 1000000;
use constant BOSCH280_STANDBY_X6_BME280 =>   10000;
use constant BOSCH280_STANDBY_X7_BME280 =>   20000;

# Register addresses.
use constant BOSCH280_REG_CHIP_ID       => 0xD0;  # Chip Identifier.
use constant BOSCH280_REG_RESET         => 0xE0;  # Reset.
use constant BOSCH280_REG_CTRL_HUM      => 0xF2;  # Control humidity oversampling (BME280 only).
use constant BOSCH280_REG_STATUS        => 0xF3;  # Device status.
use constant BOSCH280_REG_CTRL_MEAS     => 0xF4;  # Control temperature and pressure oversampling.
use constant BOSCH280_REG_CONFIG        => 0xF5;  # Config IIR filter.
use constant BOSCH280_REG_DATA          => 0xF7;  # Raw temperature, pressure, and pressure data.
use constant BOSCH280_REG_CALIBRATION_0 => 0x88;  # Pressure and temperature.
use constant BOSCH280_REG_CALIBRATION_1 => 0xE1;  # Humidity.

# Register lengths.
use constant BOSCH280_DATA_LENGTH_0        =>  6;  # Length of temperature and pressure data.
use constant BOSCH280_DATA_LENGTH_1        =>  2;  # Length of humidity data (BME280 only).
use constant BOSCH280_CALIBRATION_LENGTH_0 => 26;  # Length of temperature and pressure calibration data.
use constant BOSCH280_CALIBRATION_LENGTH_1 =>  7;  # Length of humidity calibration data (BME280 only).

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

## Private methods.

my $_extract_bits = sub {
  my $self = shift;
  my ($value, $i, $n) = @_;
  return ((1 << $n) - 1) & ($value >> $i);
};

my $_get_model = sub {
  my $self = shift;
  return BOSCH280_SENSOR_BME280 if ($self->{id} == BOSCH280_ID_BME280);
  return BOSCH280_SENSOR_BMP280 if ($self->{id} == BOSCH280_ID_BMP280_2);
  return BOSCH280_SENSOR_BMP280 if ($self->{id} == BOSCH280_ID_BMP280_1);
  return BOSCH280_SENSOR_BMP280 if ($self->{id} == BOSCH280_ID_BMP280_0);
};

my $_get_calibration = sub {
  my $self = shift;
  my %calibration;
  # Read the temperature and pressure calibration data.
  my @cal0 = $self->{io}->readBlockData (
    BOSCH280_REG_CALIBRATION_0, BOSCH280_CALIBRATION_LENGTH_0
  );
  # Extract the temperature data.
  $calibration{T1} = $cal0[1] << 8 | $cal0[0];             # T1: unsigned short.
  $calibration{T2} = $cal0[3] << 8 | $cal0[2];             # T2: signed short.
  $calibration{T2} -= 2 ** 16 if ($calibration{T2} >= 2 ** 15);
  $calibration{T3} = $cal0[5] << 8 | $cal0[4];             # T3: signed short.
  $calibration{T3} -= 2 ** 16 if ($calibration{T3} >= 2 ** 15);
  # Extract the pressure data.
  $calibration{P1} = $cal0[7] << 8 | $cal0[6];             # P1: unsigned short.
  $calibration{P2} = $cal0[9] << 8 | $cal0[8];             # P2: signed short.
  $calibration{P2} -= 2 ** 16 if ($calibration{P2} >= 2 ** 15);
  $calibration{P3} = $cal0[11] << 8 | $cal0[10];           # P3: signed short.
  $calibration{P3} -= 2 ** 16 if ($calibration{P3} >= 2 ** 15);
  $calibration{P4} = $cal0[13] << 8 | $cal0[12];           # P4: signed short.
  $calibration{P4} -= 2 ** 16 if ($calibration{P4} >= 2 ** 15);
  $calibration{P5} = $cal0[15] << 8 | $cal0[14];           # P5: signed short.
  $calibration{P5} -= 2 ** 16 if ($calibration{P5} >= 2 ** 15);
  $calibration{P6} = $cal0[17] << 8 | $cal0[16];           # P6: signed short.
  $calibration{P6} -= 2 ** 16 if ($calibration{P6} >= 2 ** 15);
  $calibration{P7} = $cal0[19] << 8 | $cal0[18];           # P7: signed short.
  $calibration{P7} -= 2 ** 16 if ($calibration{P7} >= 2 ** 15);
  $calibration{P8} = $cal0[21] << 8 | $cal0[20];           # P8: signed short.
  $calibration{P8} -= 2 ** 16 if ($calibration{P8} >= 2 ** 15);
  $calibration{P9} = $cal0[23] << 8 | $cal0[22];           # P9: signed short.
  $calibration{P9} -= 2 ** 16 if ($calibration{P9} >= 2 ** 15);
  if ($self->{model} == BOSCH280_SENSOR_BME280) {
    # Read the humidity calibration data.
    my @cal1 = $self->{io}->readBlockData (
      BOSCH280_REG_CALIBRATION_1, BOSCH280_CALIBRATION_LENGTH_1
    );
    # Extract the humidity data.
    $calibration{H1} = $cal0[25];                          # H1: unsigned char.
    $calibration{H2} = $cal1[1] << 8 | $cal1[0];           # H2: signed short.
    $calibration{H3} = $cal1[2];                           # H3: unsigned char.
    $calibration{H4} = $cal1[3] * 16 | $cal1[4] & 0x0F;    # H4: signed short.
    $calibration{H4} -= 2 ** 16 if ($calibration{H4} >= 2 ** 15);
    $calibration{H5} = $cal1[5] * 16 | $cal1[4] >> 4;      # H5: signed short.
    $calibration{H5} -= 2 ** 16 if ($calibration{H5} >= 2 ** 15);
    $calibration{H6} = $cal1[6];                           # H6: signed char.
    $calibration{H6} -= 2 ** 8 if ($calibration{H6} >= 2 ** 7);
  }
  return \%calibration;
};

my $_get_controls = sub {
  my $self = shift;
  # Read the controls for temperature, pressure, and the mode of operation.
  my $meas = $self->{io}->readByteData (BOSCH280_REG_CTRL_MEAS);
  my $osrs_t = $self->$_extract_bits ($meas, 5, 3);
  my $osrs_p = $self->$_extract_bits ($meas, 2, 3);
  my $mode = $self->$_extract_bits ($meas, 0, 1);
  my $osrs_h = BOSCH280_OVERSAMPLING_OFF;
  if ($self->{model} == BOSCH280_SENSOR_BME280) {
    # Read the controls for humidity.
    my $hum_meas = $self->{io}->readByteData (BOSCH280_REG_CTRL_HUM);
    $osrs_h = $self->$_extract_bits ($hum_meas, 0, 3);
  }
  my $ctrl = {
    temperature => $osrs_t,
    pressure => $osrs_p,
    humidity => $osrs_h,
    mode => $mode
  };
  return $ctrl;
};

my $_get_config = sub {
  my $self = shift;
  my $config = $self->{io}->readByteData (BOSCH280_REG_CONFIG);
  my $t_sb = $self->$_extract_bits ($config, 5, 3);
  my $filter = $self->$_extract_bits ($config, 2, 3);
  my $spi3w_en = $self->$_extract_bits ($config, 0, 1);
  my $cfg = {
    standby => $t_sb,
    filter => $filter,
    spi_enable => $spi3w_en
  };
  return $cfg;
};

my $_get_measure_time = sub {
  my $self = shift;
  my $t_measure = 1;
  # Account for temperature oversampling.
  $t_measure += 2 *  1 if ($self->{controls}->{temperature} == BOSCH280_OVERSAMPLING_X1);
  $t_measure += 2 *  2 if ($self->{controls}->{temperature} == BOSCH280_OVERSAMPLING_X2);
  $t_measure += 2 *  4 if ($self->{controls}->{temperature} == BOSCH280_OVERSAMPLING_X4);
  $t_measure += 2 *  8 if ($self->{controls}->{temperature} == BOSCH280_OVERSAMPLING_X8);
  $t_measure += 2 * 16 if ($self->{controls}->{temperature} == BOSCH280_OVERSAMPLING_X16);
  # Account for pressure oversampling.
  $t_measure += 2 *  1 + 0.5 if ($self->{controls}->{pressure} == BOSCH280_OVERSAMPLING_X1);
  $t_measure += 2 *  2 + 0.5 if ($self->{controls}->{pressure} == BOSCH280_OVERSAMPLING_X2);
  $t_measure += 2 *  4 + 0.5 if ($self->{controls}->{pressure} == BOSCH280_OVERSAMPLING_X4);
  $t_measure += 2 *  8 + 0.5 if ($self->{controls}->{pressure} == BOSCH280_OVERSAMPLING_X8);
  $t_measure += 2 * 16 + 0.5 if ($self->{controls}->{pressure} == BOSCH280_OVERSAMPLING_X16);
  return $t_measure if ($self->{model} == BOSCH280_SENSOR_BMP280);
  # Account for humidity oversampling.
  $t_measure += 2 *  1 + 0.5 if ($self->{controls}->{humidity} == BOSCH280_OVERSAMPLING_X1);
  $t_measure += 2 *  2 + 0.5 if ($self->{controls}->{humidity} == BOSCH280_OVERSAMPLING_X2);
  $t_measure += 2 *  4 + 0.5 if ($self->{controls}->{humidity} == BOSCH280_OVERSAMPLING_X4);
  $t_measure += 2 *  8 + 0.5 if ($self->{controls}->{humidity} == BOSCH280_OVERSAMPLING_X8);
  $t_measure += 2 * 16 + 0.5 if ($self->{controls}->{humidity} == BOSCH280_OVERSAMPLING_X16);
  return $t_measure;
};

my $_get_max_measure_time = sub {
  my $self = shift;
  my $t_measure = 1.25;
  # Account for temperature oversampling.
  $t_measure += 2.3 *  1 if ($self->{controls}->{temperature} == BOSCH280_OVERSAMPLING_X1);
  $t_measure += 2.3 *  2 if ($self->{controls}->{temperature} == BOSCH280_OVERSAMPLING_X2);
  $t_measure += 2.3 *  4 if ($self->{controls}->{temperature} == BOSCH280_OVERSAMPLING_X4);
  $t_measure += 2.3 *  8 if ($self->{controls}->{temperature} == BOSCH280_OVERSAMPLING_X8);
  $t_measure += 2.3 * 16 if ($self->{controls}->{temperature} == BOSCH280_OVERSAMPLING_X16);
  # Account for pressure oversampling.
  $t_measure += 2.3 *  1 + 0.575 if ($self->{controls}->{pressure} == BOSCH280_OVERSAMPLING_X1);
  $t_measure += 2.3 *  2 + 0.575 if ($self->{controls}->{pressure} == BOSCH280_OVERSAMPLING_X2);
  $t_measure += 2.3 *  4 + 0.575 if ($self->{controls}->{pressure} == BOSCH280_OVERSAMPLING_X4);
  $t_measure += 2.3 *  8 + 0.575 if ($self->{controls}->{pressure} == BOSCH280_OVERSAMPLING_X8);
  $t_measure += 2.3 * 16 + 0.575 if ($self->{controls}->{pressure} == BOSCH280_OVERSAMPLING_X16);
  return $t_measure if ($self->{model} == BOSCH280_SENSOR_BMP280);
  # Account for humidity oversampling.
  $t_measure += 2.3 *  1 + 0.575 if ($self->{controls}->{humidity} == BOSCH280_OVERSAMPLING_X1);
  $t_measure += 2.3 *  2 + 0.575 if ($self->{controls}->{humidity} == BOSCH280_OVERSAMPLING_X2);
  $t_measure += 2.3 *  4 + 0.575 if ($self->{controls}->{humidity} == BOSCH280_OVERSAMPLING_X4);
  $t_measure += 2.3 *  8 + 0.575 if ($self->{controls}->{humidity} == BOSCH280_OVERSAMPLING_X8);
  $t_measure += 2.3 * 16 + 0.575 if ($self->{controls}->{humidity} == BOSCH280_OVERSAMPLING_X16);
  return $t_measure;
};

my $_get_standyby_time = sub {
  my $self = shift;
  if ($self->{model} == BOSCH280_SENSOR_BME280) {
    return BOSCH280_STANDBY_X0_BME280 if ($self->{config}->{standby} == BOSCH280_STANDBY_X0);
    return BOSCH280_STANDBY_X1_BME280 if ($self->{config}->{standby} == BOSCH280_STANDBY_X1);
    return BOSCH280_STANDBY_X2_BME280 if ($self->{config}->{standby} == BOSCH280_STANDBY_X2);
    return BOSCH280_STANDBY_X3_BME280 if ($self->{config}->{standby} == BOSCH280_STANDBY_X3);
    return BOSCH280_STANDBY_X4_BME280 if ($self->{config}->{standby} == BOSCH280_STANDBY_X4);
    return BOSCH280_STANDBY_X5_BME280 if ($self->{config}->{standby} == BOSCH280_STANDBY_X5);
    return BOSCH280_STANDBY_X6_BME280 if ($self->{config}->{standby} == BOSCH280_STANDBY_X6);
    return BOSCH280_STANDBY_X7_BME280 if ($self->{config}->{standby} == BOSCH280_STANDBY_X7);
  }
  elsif ($self->{model} == BOSCH280_SENSOR_BMP280) {
    return BOSCH280_STANDBY_X0_BMP280 if ($self->{config}->{standby} == BOSCH280_STANDBY_X0);
    return BOSCH280_STANDBY_X1_BMP280 if ($self->{config}->{standby} == BOSCH280_STANDBY_X1);
    return BOSCH280_STANDBY_X2_BMP280 if ($self->{config}->{standby} == BOSCH280_STANDBY_X2);
    return BOSCH280_STANDBY_X3_BMP280 if ($self->{config}->{standby} == BOSCH280_STANDBY_X3);
    return BOSCH280_STANDBY_X4_BMP280 if ($self->{config}->{standby} == BOSCH280_STANDBY_X4);
    return BOSCH280_STANDBY_X5_BMP280 if ($self->{config}->{standby} == BOSCH280_STANDBY_X5);
    return BOSCH280_STANDBY_X6_BMP280 if ($self->{config}->{standby} == BOSCH280_STANDBY_X6);
    return BOSCH280_STANDBY_X7_BMP280 if ($self->{config}->{standby} == BOSCH280_STANDBY_X7);
  }
};

my $_get_data = sub {
  my $self = shift;
  my ($temperature, $pressure, $humidity);
  my $length = BOSCH280_DATA_LENGTH_0;
  if ($self->{model} == BOSCH280_SENSOR_BME280) {
    $length = BOSCH280_DATA_LENGTH_0 + BOSCH280_DATA_LENGTH_1
  }
  my @data = $self->{io}->readBlockData (BOSCH280_REG_DATA, $length);
  $temperature = ($data[3] << 12) | ($data[4] << 4) | ($data[5] >> 4);
  $pressure = ($data[0] << 12) | ($data[1] << 4) | ($data[2] >> 4);
  if ($self->{model} == BOSCH280_SENSOR_BME280) {
    $humidity = $data[7] | ($data[6] << 8);
  }
  my $data = {
    temperature => $temperature,
    pressure => $pressure,
    humidity => $humidity
  };
  return $data;
};

my $_set_controls = sub {
  my $self = shift;
  my ($ctrl) = @_;
  # The humidity controls need to be set first.
  if ($self->{model} == BOSCH280_SENSOR_BME280) {
    # Write the controls for humidity.
    $self->{io}->writeByteData (BOSCH280_REG_CTRL_HUM, $ctrl->{humidity});
  }
  # Write the controls for temperature, pressure, and the mode of operation.
  my $meas = $ctrl->{temperature} << 5 | $ctrl->{pressure} << 2 | $ctrl->{mode};
  $self->{io}->writeByteData (BOSCH280_REG_CTRL_MEAS, $meas);
  return $ctrl;
};

my $_set_config = sub {
  my $self = shift;
  my ($cfg) = @_;
  # Write the config.
  my $config = $cfg->{standby} << 5 | $cfg->{filter} << 2 | $cfg->{spi_enable};
  $self->{io}->writeByteData (BOSCH280_REG_CONFIG, $config);
  return $cfg;
};

my $_compensate_temperature = sub {
  my $self = shift;
  my ($t) = @_;
  my ($var1, $var2);
  my $cal = $self->{calibration};
  $var1 = $cal->{T2} * ($t / 16384 - $cal->{T1} / 1024);
  $var2 = $cal->{T3} * ($t / 131072 - $cal->{T1} / 8192) ** 2;
  $cal->{t_fine} = ($var1 + $var2);
  my $temperature = $cal->{t_fine} / 5120;
  return BOSCH280_TEMPERATURE_MIN if ($temperature < BOSCH280_TEMPERATURE_MIN);
  return BOSCH280_TEMPERATURE_MAX if ($temperature > BOSCH280_TEMPERATURE_MAX);
  return $temperature;
};

my $_compensate_pressure = sub {
  my $self = shift;
  my ($p) = @_;
  my ($var1, $var2, $var3);
  my $cal = $self->{calibration};
  $var1 = $cal->{t_fine} / 2 - 64000;
  $var2 = $var1 ** 2 * $cal->{P6} / 32768;
  $var2 = $var2 + $var1 * $cal->{P5} * 2;
  $var2 = $var2 / 4 + $cal->{P4} * 65536;
  $var3 = $cal->{P3} * $var1 ** 2 / 524288;
  $var1 = ($var3 + $cal->{P2} * $var1) / 524288;
  $var1 = (1 + $var1 / 32768) * $cal->{P1};
  return BOSCH280_PRESSURE_MIN if ($var1 < 1e-10);
  my $pressure = 1048576 - $p;
  $pressure = ($pressure - $var2 / 4096) * 6250 / $var1;
  $var1 = $cal->{P9} * $pressure ** 2 / 2147483648;
  $var2 = $pressure * $cal->{P8} / 32768;
  $pressure += ($var1 + $var2 + $cal->{P7}) / 16;
  return BOSCH280_PRESSURE_MIN if ($pressure < BOSCH280_PRESSURE_MIN);
  return BOSCH280_PRESSURE_MAX if ($pressure > BOSCH280_PRESSURE_MAX);
  return $pressure;
};

my $_compensate_humidity = sub {
  my $self = shift;
  my ($h) = @_;
  my $cal = $self->{calibration};
  my $t = $cal->{t_fine} - 76800;
  my $humidity = $h - ($cal->{H4} * 64 + $cal->{H5} / 16384 * $t);
  $humidity *= $cal->{H2} / 65536;
  $humidity *= 1 + $cal->{H6} / 67108864 * $t * (1 + $cal->{H3} / 67108864 * $t);
  $humidity *= 1 - $cal->{H1} * $humidity / 524288;
  return BOSCH280_HUMIDITY_MIN if ($humidity < BOSCH280_HUMIDITY_MIN);
  return BOSCH280_HUMIDITY_MAX if ($humidity > BOSCH280_HUMIDITY_MAX);
  return $humidity;
};

## Public methods.

sub new {
  my $class = shift;
  die "Usage: $class->new (i2c, address)" unless (@_ == 2);
  my ($i2c, $address) = @_;
  my $io = new Device::I2C ($i2c, O_RDWR);
  # Make sure we can open the I2C bus.
  die "Error: Unable to open I2C Device File at $i2c"
    unless ($io);
  # Make sure we can open the BME280 or BMP280 device.
  die "Error: Unable to access device at $address"
    unless ($io->checkDevice ($address));
  # Select the device at the provided address.
  $io->selectDevice ($address);
  # Bless ourselves with our class.
  my $self = bless {
    i2c         => $i2c,
    address     => $address,
    io          => $io,
    id          => undef,
    model       => undef,
    calibration => undef,
    controls    => undef,
    config      => undef
  }, $class;
  # Read the device id.
  $self->{id} = $io->readByteData (BOSCH280_REG_CHIP_ID);
  # Figure out the model of the device.
  $self->{model} = $self->$_get_model;
  die "Error: Unrecognized device " . $self->{id} unless (defined $self->{model});
  # Read the calibration data.
  $self->{calibration} = $self->$_get_calibration;
  # Read the environmental controls and the mode of operation.
  $self->{controls} = $self->$_get_controls;
  # Read the config.
  $self->{config} = $self->$_get_config;
  return $self;
}

sub id {
  my $self = shift;
  return $self->{id};
}

sub reset {
  my $self = shift;
  $self->{io}->writeByteData (BOSCH280_REG_RESET, BOSCH280_CMD_RESET);
  # The startup time is 2 ms for both BME280 and BMP280. However, in case it
  # takes longer to copy the NVM data, monitor the status before returning
  # control.
  my $im_update = 1;
  while ($im_update) {
    usleep (2000);
    ($im_update, $_) = $self->status;
  }
}

sub status {
  my $self = shift;
  my $status = $self->{io}->readByteData (BOSCH280_REG_STATUS);
  my @status = reverse split //, unpack "B*", $status;
  return ($status[0], $status[3]);
}

sub controls {
  my $self = shift;
  my ($ctrl) = @_;
  $ctrl = $self->$_get_controls unless (defined $ctrl);
  return $self->$_set_controls ($ctrl);
}

sub config {
  my $self = shift;
  my ($cfg) = @_;
  $cfg = $self->$_get_config unless (defined $cfg);
  return $self->$_set_config ($cfg);
}

sub temperature {
  my $self = shift;
  my $data = $self->$_get_data;
  return $self->$_compensate_temperature ($data->{temperature});
}

sub pressure {
  my $self = shift;
  my $data = $self->$_get_data;
  return $self->$_compensate_pressure ($data->{pressure}) / 100;
}

sub humidity {
  my $self = shift;
  my $data = $self->$_get_data;
  return $self->$_compensate_humidity ($data->{humidity});
}

sub measure {
  my $self = shift;
  my $data = $self->$_get_data;
  my $t = $self->$_compensate_temperature ($data->{temperature});
  my $p = $self->$_compensate_pressure ($data->{pressure}) / 100;
  my $h = $self->$_compensate_humidity ($data->{humidity});
  return ($t, $p, $h);
}

1;
