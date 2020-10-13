#!/usr/bin/env perl

=encoding utf8

=head1 NAME

Device::Bosch280 - Driver for Bosch BMP280 and BME280 environmental sensors.

=head1 SYNOPSIS

  use strict;
  use warnings;
  use utf8;
  use v5.10;
  use Time::HiRes qw (usleep);

  use Device::Bosch280 qw (
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
  my $bme280 = Device::Bosch280->new ($device, $address);

  # Verify the model of the device.
  die "Unexpected model" unless ($bme280->{model} == BOSCH280_SENSOR_BME280);

  # Perform a soft reset on the device.
  $bme280->reset;

  # Wait for the startup to finish.
  my ($im_update, $measuring) = $bme280->status;
  while ($im_update) {
    usleep $bme280->startupTime;
    ($im_update, $measuring) = $bme280->status;
  }

  # Modify the controls to use forced mode and X2 sampling.
  my $ctrl = $bme280->controls;
  $ctrl->{temperature} = BOSCH280_OVERSAMPLING_X2;
  $ctrl->{pressure} = BOSCH280_OVERSAMPLING_X2;
  $ctrl->{humidity} = BOSCH280_OVERSAMPLING_X2;
  $ctrl->{mode} = BOSCH280_MODE_FORCED;
  $bme280->controls ($ctrl);

  # Wait for the measurement to finish.
  usleep $bme280->measureTime;
  ($im_update, $measuring) = $bme280->status;
  while ($measuring) {
    usleep $bme280->maxMeasureTime - $bme280->measureTime;
    ($im_update, $measuring) = $bme280->status;
  }

  # Get a measurement from the device.
  my ($temperature, $pressure, $humidity) = $bme280->measure;
  printf "Temperature:\t%.2f °C\n", $temperature;
  printf "Pressure:\t%.2f hPa\n", $pressure / 100;
  printf "Humidity:\t%.2f %%\n", $humidity;

  # Modify the configuration to use standby X0 (500 µs) and filter to off.
  my $cfg = $bme280->config;
  $cfg->{standby} = BOSCH280_STANDBY_X0;
  $cfg->{filter} = BOSCH280_FILTER_OFF;
  $bme280->config ($cfg);

  # Modify the controls to use normal mode and X4 sampling.
  $ctrl->{temperature} = BOSCH280_OVERSAMPLING_X4;
  $ctrl->{pressure} = BOSCH280_OVERSAMPLING_X4;
  $ctrl->{humidity} = BOSCH280_OVERSAMPLING_X4;
  $ctrl->{mode} = BOSCH280_MODE_NORMAL;
  $bme280->controls ($ctrl);

  # Get ten measurements.
  for (my $i = 0; $i < 10; $i ++) {
    # Wait for the measurement to finish.
    usleep $bme280->measureTime;
    ($im_update, $measuring) = $bme280->status;
    while ($measuring) {
      usleep $bme280->maxMeasureTime - $bme280->measureTime;
      ($im_update, $measuring) = $bme280->status;
    }
    # Get a measurement from the device.
    ($temperature, $pressure, $humidity) = $bme280->measure;
    printf "%2d: temperature:\t%.2f °C\n", $i, $temperature;
    printf "%2d: pressure:   \t%.2f hPa\n", $i, $pressure / 100;
    printf "%2d: humidity:   \t%.2f %%\n", $i, $humidity;

    # Wait for the standby time.
    usleep $bme280->standbyTime;
  }

  # Modify the controls to use sleep mode.
  $ctrl->{mode} = BOSCH280_MODE_SLEEP;
  $bme280->controls ($ctrl);

=head1 DESCRIPTION

Device::Bosch280 is a driver for Bosch BMP280 and BME280 environmental sensors.

This driver is based on documentation found at:

L<https://www.bosch-sensortec.com/media/boschsensortec/downloads/datasheets/bst-bmp280-ds001.pdf>

L<https://www.bosch-sensortec.com/media/boschsensortec/downloads/datasheets/bst-bme280-ds002.pdf>

And reference C code provided by Bosch Sensortec:

L<https://github.com/BoschSensortec/BME280_driver>

According to the documentation provided by Bosch Sensortec, the following modes
of opperation are recommended:

=over 12

=item Weather Monitoring

Low data rate needed. Noise in measurements are not a major concern. Monitor
pressure, temperature, and humidity.

  Sensor mode: forced, 1 sample / minute
  Oversampling: pressure X1, temperature X1, humidity X1
  IIR filter: off

=item Humidity Sensing

Low data rate needed. Noise in measurements are not a major concern. Monitor
temperature and humidity.

  Sensor mode: forced, 1 sample / second
  Oversampling: pressure X0, temperature X1, humidity X1
  IIR filter: off

=item Indoor Navigation

High data rate needed. Noise in pressure (altitude) a major concern. Monitor
pressure, temperature, and humidity.

  Sensor mode: normal, standby X0 (0.5 ms)
  Oversampling: pressure X16, temperature X2, humidity X1
  IIR filter: X16

=item Gaming

High data rate needed. Noise in pressure (altitude) a major concern. Monitor
pressure and temperature.

  Sensor mode: normal, standby X0 (0.5 ms)
  Oversampling: pressure X4, temperature X2, humidity X0
  IIR filter: X16

=back

=head2 Methods

=over 12

=item C<new>

Returns a new Device::Bosch280 object.

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

=item C<measureTime>

Returns the amount of time in µseconds for a measurement to run based on the
current settings.

=item C<maxMeasureTime>

Returns the maximum amount of time in µseconds for a measurement to run based on
the current settings.

=item C<standbyTime>

Returns the standby time in µseconds (used in normal mode).

=item C<startupTime>

Returns the startup time in µseconds.

=back

=head1 DEPENDENCIES

Device::Bosch280 requires Perl version 5.10 or later.

=head1 FEEDBACK

=head2 Reporting Bugs

Report bugs to the GitHub issue tracker at:

L<https://github.com/sandain/growbot/issues>

=head1 AUTHOR

Jason M. Wood L<sandain@hotmail.com|mailto:sandain@hotmail.com>

=head1 COPYRIGHT AND LICENSE

  Copyright (c) 2020 Jason M. Wood

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

package Device::Bosch280;

use strict;
use warnings;
use utf8;
use v5.10;

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

# IIR filter settings.
use constant BOSCH280_FILTER_OFF => 0x00;
use constant BOSCH280_FILTER_X2  => 0x01;
use constant BOSCH280_FILTER_X4  => 0x02;
use constant BOSCH280_FILTER_X8  => 0x03;
use constant BOSCH280_FILTER_X16 => 0x04;

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

# BME280 startup duration (μs).
use constant BOSCH280_STARTUP_DURATION => 2000;

# Register addresses.
use constant BOSCH280_REG_CHIP_ID       => 0xD0;
use constant BOSCH280_REG_RESET         => 0xE0;
use constant BOSCH280_REG_CTRL_HUM      => 0xF2;
use constant BOSCH280_REG_STATUS        => 0xF3;
use constant BOSCH280_REG_CTRL_MEAS     => 0xF4;
use constant BOSCH280_REG_CONFIG        => 0xF5;
use constant BOSCH280_REG_DATA          => 0xF7;
use constant BOSCH280_REG_CALIBRATION_0 => 0x88;
use constant BOSCH280_REG_CALIBRATION_1 => 0xE1;

# Register lengths.
use constant BOSCH280_DATA_LENGTH_0        =>  6;
use constant BOSCH280_DATA_LENGTH_1        =>  2;
use constant BOSCH280_CALIBRATION_LENGTH_0 => 26;
use constant BOSCH280_CALIBRATION_LENGTH_1 =>  7;

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

my $_extractBits = sub {
  my $self = shift;
  my ($value, $i, $n) = @_;
  return ((1 << $n) - 1) & ($value >> $i);
};

my $_getModel = sub {
  my $self = shift;
  return BOSCH280_SENSOR_BME280 if ($self->{id} == BOSCH280_ID_BME280);
  return BOSCH280_SENSOR_BMP280 if ($self->{id} == BOSCH280_ID_BMP280_2);
  return BOSCH280_SENSOR_BMP280 if ($self->{id} == BOSCH280_ID_BMP280_1);
  return BOSCH280_SENSOR_BMP280 if ($self->{id} == BOSCH280_ID_BMP280_0);
};

my $_getCalibration = sub {
  my $self = shift;
  my %calibration;
  # Read the temperature and pressure calibration data.
  my @cal0 = $self->{io}->readBlockData (
    BOSCH280_REG_CALIBRATION_0, BOSCH280_CALIBRATION_LENGTH_0
  );
  # Extract the temperature data.
  # T1: unsigned short.
  $calibration{T1} = $cal0[1] << 8 | $cal0[0];
  # T2: signed short.
  $calibration{T2} = $cal0[3] << 8 | $cal0[2];
  $calibration{T2} -= 2 ** 16 if ($calibration{T2} >= 2 ** 15);
  # T3: signed short.
  $calibration{T3} = $cal0[5] << 8 | $cal0[4];
  $calibration{T3} -= 2 ** 16 if ($calibration{T3} >= 2 ** 15);
  # Extract the pressure data.
  # P1: unsigned short.
  $calibration{P1} = $cal0[7] << 8 | $cal0[6];
  # P2: signed short.
  $calibration{P2} = $cal0[9] << 8 | $cal0[8];
  $calibration{P2} -= 2 ** 16 if ($calibration{P2} >= 2 ** 15);
  # P3: signed short.
  $calibration{P3} = $cal0[11] << 8 | $cal0[10];
  $calibration{P3} -= 2 ** 16 if ($calibration{P3} >= 2 ** 15);
  # P4: signed short.
  $calibration{P4} = $cal0[13] << 8 | $cal0[12];
  $calibration{P4} -= 2 ** 16 if ($calibration{P4} >= 2 ** 15);
  # P5: signed short.
  $calibration{P5} = $cal0[15] << 8 | $cal0[14];
  $calibration{P5} -= 2 ** 16 if ($calibration{P5} >= 2 ** 15);
  # P6: signed short.
  $calibration{P6} = $cal0[17] << 8 | $cal0[16];
  $calibration{P6} -= 2 ** 16 if ($calibration{P6} >= 2 ** 15);
  # P7: signed short.
  $calibration{P7} = $cal0[19] << 8 | $cal0[18];
  $calibration{P7} -= 2 ** 16 if ($calibration{P7} >= 2 ** 15);
  # P8: signed short.
  $calibration{P8} = $cal0[21] << 8 | $cal0[20];
  $calibration{P8} -= 2 ** 16 if ($calibration{P8} >= 2 ** 15);
  # P9: signed short.
  $calibration{P9} = $cal0[23] << 8 | $cal0[22];
  $calibration{P9} -= 2 ** 16 if ($calibration{P9} >= 2 ** 15);
  if ($self->{model} == BOSCH280_SENSOR_BME280) {
    # Read the humidity calibration data.
    my @cal1 = $self->{io}->readBlockData (
      BOSCH280_REG_CALIBRATION_1, BOSCH280_CALIBRATION_LENGTH_1
    );
    # Extract the humidity data.
    # H1: unsigned char.
    $calibration{H1} = $cal0[25];
    # H2: signed short.
    $calibration{H2} = $cal1[1] << 8 | $cal1[0];
    # H3: unsigned char.
    $calibration{H3} = $cal1[2];
    # H4: signed short.
    $calibration{H4} = $cal1[3] * 16 | $cal1[4] & 0x0F;
    $calibration{H4} -= 2 ** 16 if ($calibration{H4} >= 2 ** 15);
    # H5: signed short.
    $calibration{H5} = $cal1[5] * 16 | $cal1[4] >> 4;
    $calibration{H5} -= 2 ** 16 if ($calibration{H5} >= 2 ** 15);
    # H6: signed char.
    $calibration{H6} = $cal1[6];
    $calibration{H6} -= 2 ** 8 if ($calibration{H6} >= 2 ** 7);
  }
  return \%calibration;
};

my $_getControls = sub {
  my $self = shift;
  # Read the controls for temperature, pressure, and the mode of operation.
  my $meas = $self->{io}->readByteData (BOSCH280_REG_CTRL_MEAS);
  my $osrs_t = $self->$_extractBits ($meas, 5, 3);
  my $osrs_p = $self->$_extractBits ($meas, 2, 3);
  my $mode = $self->$_extractBits ($meas, 0, 1);
  my $osrs_h = BOSCH280_OVERSAMPLING_OFF;
  if ($self->{model} == BOSCH280_SENSOR_BME280) {
    # Read the controls for humidity.
    my $hum_meas = $self->{io}->readByteData (BOSCH280_REG_CTRL_HUM);
    $osrs_h = $self->$_extractBits ($hum_meas, 0, 3);
  }
  my $ctrl = {
    temperature => $osrs_t,
    pressure => $osrs_p,
    humidity => $osrs_h,
    mode => $mode
  };
  return $ctrl;
};

my $_getConfig = sub {
  my $self = shift;
  my $config = $self->{io}->readByteData (BOSCH280_REG_CONFIG);
  my $t_sb = $self->$_extractBits ($config, 5, 3);
  my $filter = $self->$_extractBits ($config, 2, 3);
  my $spi3w_en = $self->$_extractBits ($config, 0, 1);
  my $cfg = {
    standby => $t_sb,
    filter => $filter,
    spi_enable => $spi3w_en
  };
  return $cfg;
};

my $_getMeasureTime = sub {
  my $self = shift;
  my @coefficients = (0, 1, 2, 4, 8, 16);
  my $t_measure = 1;
  # Account for temperature oversampling.
  $t_measure += 2 * $coefficients[$self->{controls}->{temperature}];
  # Account for pressure oversampling.
  $t_measure += 2 * $coefficients[$self->{controls}->{pressure}] + 0.5;
  # Return measure time in μseconds if model is BMP280.
  return $t_measure * 1000 if ($self->{model} == BOSCH280_SENSOR_BMP280);
  # Account for humidity oversampling.
  $t_measure += 2 * $coefficients[$self->{controls}->{humidity}] + 0.5;
  # Return measure time in μseconds.
  return $t_measure * 1000;
};

my $_getMaxMeasureTime = sub {
  my $self = shift;
  my @coefficients = (0, 1, 2, 4, 8, 16);
  my $t_measure = 1.25;
  # Account for temperature oversampling.
  $t_measure += 2.3 * $coefficients[$self->{controls}->{temperature}];
  # Account for pressure oversampling.
  $t_measure += 2.3 * $coefficients[$self->{controls}->{pressure}] + 0.575;
  # Return measure time in μseconds if model is BMP280.
  return $t_measure * 1000 if ($self->{model} == BOSCH280_SENSOR_BMP280);
  # Account for humidity oversampling.
  $t_measure += 2.3 * $coefficients[$self->{controls}->{humidity}] + 0.575;
  # Return measure time in μseconds.
  return $t_measure * 1000;
};

my $_getStandybyTime = sub {
  my $self = shift;
  my @coefficients;
  if ($self->{model} == BOSCH280_SENSOR_BME280) {
    @coefficients = (
      BOSCH280_STANDBY_X0_BME280,
      BOSCH280_STANDBY_X1_BME280,
      BOSCH280_STANDBY_X2_BME280,
      BOSCH280_STANDBY_X3_BME280,
      BOSCH280_STANDBY_X4_BME280,
      BOSCH280_STANDBY_X5_BME280,
      BOSCH280_STANDBY_X6_BME280,
      BOSCH280_STANDBY_X7_BME280
    );
  }
  elsif ($self->{model} == BOSCH280_SENSOR_BMP280) {
    @coefficients = (
      BOSCH280_STANDBY_X0_BMP280,
      BOSCH280_STANDBY_X1_BMP280,
      BOSCH280_STANDBY_X2_BMP280,
      BOSCH280_STANDBY_X3_BMP280,
      BOSCH280_STANDBY_X4_BMP280,
      BOSCH280_STANDBY_X5_BMP280,
      BOSCH280_STANDBY_X6_BMP280,
      BOSCH280_STANDBY_X7_BMP280
    );
  }
  return $coefficients[$self->{config}->{standby}];
};

my $_getData = sub {
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

my $_setControls = sub {
  my $self = shift;
  my ($ctrl) = @_;
  # Update the values stored locally.
  $self->{controls} = $ctrl;
  $self->{measureTime} = $self->$_getMeasureTime;
  $self->{maxMeasureTime} = $self->$_getMaxMeasureTime;
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

my $_setConfig = sub {
  my $self = shift;
  my ($cfg) = @_;
  # Update the values stored locally.
  $self->{config} = $cfg;
  $self->{standbyTime} = $self->$_getStandybyTime;
  # Write the config.
  my $config = $cfg->{standby} << 5 | $cfg->{filter} << 2 | $cfg->{spi_enable};
  $self->{io}->writeByteData (BOSCH280_REG_CONFIG, $config);
  return $cfg;
};

my $_compensateTemperature = sub {
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

my $_compensatePressure = sub {
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

my $_compensateHumidity = sub {
  my $self = shift;
  my ($h) = @_;
  my $cal = $self->{calibration};
  my $t = $cal->{t_fine} - 76800;
  my $humidity = $h - ($cal->{H4} * 64 + $cal->{H5} / 16384 * $t);
  $humidity *= $cal->{H2} / 65536;
  $humidity *= 1 + $cal->{H6} / 2 ** 26 * $t * (1 + $cal->{H3} / 2 ** 26 * $t);
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
    i2c            => $i2c,
    address        => $address,
    io             => $io,
    id             => undef,
    model          => undef,
    calibration    => undef,
    controls       => undef,
    config         => undef,
    measureTime    => undef,
    maxMeasureTime => undef,
    standbyTime    => undef
  }, $class;
  # Read the device id.
  $self->{id} = $io->readByteData (BOSCH280_REG_CHIP_ID);
  # Figure out the model of the device.
  $self->{model} = $self->$_getModel;
  unless (defined $self->{model}) {
    die "Error: Unrecognized device " . $self->{id};
  }
  # Read the calibration data.
  $self->{calibration} = $self->$_getCalibration;
  # Read the environmental controls and the mode of operation.
  $self->{controls} = $self->$_getControls;
  # Read the config.
  $self->{config} = $self->$_getConfig;
  return $self;
}

sub id {
  my $self = shift;
  return $self->{id};
}

sub reset {
  my $self = shift;
  $self->{io}->writeByteData (BOSCH280_REG_RESET, BOSCH280_CMD_RESET);
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
  # Check if controls are changing.
  if (defined $ctrl) {
    # Fill in empty values with current values.
    unless (defined $ctrl->{temperature}) {
      $ctrl->{temperature} = $self->{controls}{temperature};
    }
    unless (defined $ctrl->{pressure}) {
      $ctrl->{pressure} = $self->{controls}{pressure};
    }
    unless (defined $ctrl->{humidity}) {
      $ctrl->{humidity} = $self->{controls}{humidity};
    }
    $ctrl->{mode} = $self->{controls}{mode} unless (defined $ctrl->{mode});
    # Verify that values are within range.
    die "Invalid temperature control " . $ctrl->{temperature} unless (
      $ctrl->{temperature} >= BOSCH280_OVERSAMPLING_OFF &&
      $ctrl->{temperature} <= BOSCH280_OVERSAMPLING_X16
    );
    die "Invalid pressure control " . $ctrl->{pressure} unless (
      $ctrl->{pressure} >= BOSCH280_OVERSAMPLING_OFF &&
      $ctrl->{pressure} <= BOSCH280_OVERSAMPLING_X16
    );
    die "Invalid humidity control " . $ctrl->{humidity} unless (
      $ctrl->{humidity} >= BOSCH280_OVERSAMPLING_OFF &&
      $ctrl->{humidity} <= BOSCH280_OVERSAMPLING_X16
    );
    die "Invalid mode " . $ctrl->{mode} unless (
      $ctrl->{mode} == BOSCH280_MODE_SLEEP ||
      $ctrl->{mode} == BOSCH280_MODE_FORCED ||
      $ctrl->{mode} == BOSCH280_MODE_NORMAL
    );
    # Set the controls to the new values, and return the values as set.
    return $self->$_setControls ($ctrl);
  }
  # Return the currently set values.
  return $self->$_getControls;
}

sub config {
  my $self = shift;
  my ($cfg) = @_;
  # Check if configs are changing.
  if (defined $cfg) {
    # Fill in empty values with current values.
    unless (defined $cfg->{standby}) {
      $cfg->{standby} = $self->{config}{standby};
    }
    unless (defined $cfg->{filter}) {
      $cfg->{filter} = $self->{config}{filter};
    }
    unless (defined $cfg->{spi_enable}) {
      $cfg->{spi_enable} = $self->{config}{spi_enable};
    }
    # Verify that values are within range.
    die "Invalid standby config " . $cfg->{standby} unless (
      $cfg->{standby} >= BOSCH280_STANDBY_X0 &&
      $cfg->{standby} <= BOSCH280_STANDBY_X7
    );
    die "Invalid filter config " . $cfg->{filter} unless (
      $cfg->{filter} >= BOSCH280_FILTER_OFF &&
      $cfg->{filter} <= BOSCH280_FILTER_X16
    );
    die "Invalid spi_enable config " . $cfg->{spi_enable} unless (
      $cfg->{spi_enable} == 0x00 || $cfg->{spi_enable} == 0x01
    );
    # Set the config to the new values, and return the values as set.
    return $self->$_setConfig ($cfg);
  }
  # Return the currently set values.
  return $self->$_getConfig;
}

sub temperature {
  my $self = shift;
  my $data = $self->$_getData;
  return $self->$_compensateTemperature ($data->{temperature});
}

sub pressure {
  my $self = shift;
  my $data = $self->$_getData;
  return $self->$_compensatePressure ($data->{pressure});
}

sub humidity {
  my $self = shift;
  my $data = $self->$_getData;
  return $self->$_compensateHumidity ($data->{humidity});
}

sub measure {
  my $self = shift;
  my $data = $self->$_getData;
  my $t = $self->$_compensateTemperature ($data->{temperature});
  my $p = $self->$_compensatePressure ($data->{pressure});
  my $h = $self->$_compensateHumidity ($data->{humidity});
  return ($t, $p, $h);
}

sub measureTime {
  my $self = shift;
  return $self->{measureTime};
}

sub maxMeasureTime {
  my $self = shift;
  return $self->{maxMeasureTime};
}

sub standbyTime {
  my $self = shift;
  return $self->{standbyTime};
}

sub startupTime {
  my $self = shift;
  return BOSCH280_STARTUP_DURATION;
}

1;
