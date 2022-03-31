=encoding utf8

=head1 NAME

Device::AtlasScientific - Driver for Atlas Scientific series of environmental
robotic devices.

=head1 SYNOPSIS

  use strict;
  use warnings;
  use utf8;
  use v5.14;

  use Device::AtlasScientific;

  # The I2C device file.
  my $device = '/dev/i2c-1';

  # The address of the Atlas Scientific pH sensor device.
  my $address = 0x63;

  # Load this driver for the pH sensor.
  my $pH = Device::AtlasScientific->new ($device, $address);

  # Print out a pH measurement.
  printf "ph: %0.2f\n", $ph->measure;

  # Close the device.
  $ph->close;

=head1 DESCRIPTION

Device::AtlasScientific is a driver for the Atlas Scientific series of
environmental robotic devices.

This driver is based on documentation found at:

=over 12

=item * Temperature meter:
L<https://atlas-scientific.com/files/EZO_RTD_Datasheet.pdf>

=item * pH meter:
L<https://atlas-scientific.com/files/pH_EZO_Datasheet.pdf>

=item * Electrical conductivity meter:
L<https://atlas-scientific.com/files/EC_EZO_Datasheet.pdf>

=item * Oxygen reduction potential meter:
L<https://atlas-scientific.com/files/ORP_EZO_Datasheet.pdf>

=item * Dissolved oxygen meter:
L<https://atlas-scientific.com/files/DO_EZO_Datasheet.pdf>

=item * Peristaltic pump:
L<https://atlas-scientific.com/files/EZO_PMP_Datasheet.pdf>

=item * Large Peristaltic pump:
L <https://atlas-scientific.com/files/EZO_PMP_L_Datasheet.pdf>

=item * Carbon dioxide (gas) meter:
L<https://atlas-scientific.com/files/EZO_CO2_Datasheet.pdf>

=item * Oxygen (gas) meter:
L<https://atlas-scientific.com/files/EZO_O2_datasheet.pdf>

=item * Humidity meter:
L<https://atlas-scientific.com/files/EZO-HUM-Datasheet.pdf>

=item * Pressure meter:
L<https://atlas-scientific.com/files/EZO-PRS-Datasheet.pdf>

=item * Flow meter:
L<https://atlas-scientific.com/files/flow_EZO_Datasheet.pdf>

=item * Color sensing meter:
L<https://atlas-scientific.com/files/EZO_RGB_Datasheet.pdf>

=back

=head2 Methods

=over 12

=item C<new>

Returns a new Device::AtlasScientific object.

=item C<close>

Closes input/output to the device.

=item C<measure>

Returns a single measurement from the device.

=item C<baud>

Changes the device to use serial mode at the given baud rate. Warning: This
driver does not currently support serial mode.

=item C<calibration>

Perform a calibration on the device. Returns whether or not the device is
calibrated. If arguments are provided, they are passed on to the device.

Generic arguments:

=over 12

=item C<clear>

Clear the calibration of the device.

=item C<numeric value>

Calibrate the device at the provided value.

=back

EZO pH options:

=over 12

=item C<mid>

Single point calibration at mid point.

=item C<low>

Two point calibration at low point.

=item C<high>

Three point calibration at high point.

=back

EZO EC options:

=over 12

=item C<low>

Low end calibration, numeric value required.

=item C<high>

High end calibration, numeric value required.

=item C<dry>

Dry calibration.

=back

EZO DO options:

=over 12

=item C<atm>

Calibrate to atmospheric oxygen levels.

=back

=item C<calibrationExport>

Export the calibration string from the device.

=item C<calibrationImport>

Import a calibration string into the device.

=item C<factoryReset>

Clear custom configuration and reboot the device.

=item C<find>

Rapidly blink the LED on the device until a new command is sent. Used to help
find the device.

=item C<flowRateUnit>

Modify the time unit for the flow rate returned for EZO-FLOW devices. Valid
options include s, m, and h. The current time unit for the flow rate will be
returned given no input.

=item C<i2c>

Changes the I2C address of the device. Warning: This device will become
unreachable until a new driver is instantiated.

=item C<information>

Returns the device model and firmware version.

=item C<ledIndicator>

Returns whether the indicator LED is currently on or off. Turns the indicator
LED on or off if provided.

=item C<name>

Returns the name of the device. Sets the name of the device if provided. Names
can only contain printable characters and no spaces.

=item C<options>

Returns currently configured options. Sets the options for the device if
provided. Requires both and option name, and value (0 or 1).

=item C<plock>

Returns the status of the protocol lock. Sets the protocol lock if provided.
A value of 1 enables the protocol lock. A value of 0 disables the protocol lock.

=item C<pressureUnit>

Modify the pressure unit returned for EZO-PRS devices. Valid options include
1/0 to add/remove unit from output, psi, atm, bar, kPa, inh2o, and cmh2o. The
current unit will be returned given no input.

=item C<sleep>

Put the device to sleep.

=item C<status>

Returns the reason for the last restart and the voltage at the Vcc pin.

=back

=head1 DEPENDENCIES

Device::AtlasScientific requires Perl version 5.14 or later.

=head1 FEEDBACK

=head2 Reporting Bugs

Report bugs to the GitHub issue tracker at:

L<https://github.com/sandain/growbot/issues>

=head1 AUTHOR

Jason M. Wood L<sandain@hotmail.com|mailto:sandain@hotmail.com>

=head1 COPYRIGHT AND LICENSE

  Copyright (c) 2020-2022 Jason M. Wood

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

package Device::AtlasScientific;

use strict;
use warnings;
use utf8;
use v5.14;
use version;
use Device::I2C;
use Exporter qw(import);
use IO::File;
use Time::HiRes qw (usleep);

## Public constants.

# Supported devices.
use constant EZO_RTD  => 'RTD';  # Temperature
use constant EZO_PH   => 'PH';   # pH
use constant EZO_EC   => 'EC';   # Electrical conductivity
use constant EZO_ORP  => 'ORP';  # Oxidation-reduction potential
use constant EZO_DO   => 'DO';   # Dissolved oxygen
use constant EZO_PMP  => 'PMP';  # Peristaltic pump
use constant EZO_PMPL => 'PMPL'; # Large Peristaltic pump
use constant EZO_CO2  => 'CO2';  # Carbon dioxide (gas)
use constant EZO_O2   => 'O2';   # Oxygen (gas)
use constant EZO_HUM  => 'HUM';  # Humidity
use constant EZO_PRS  => 'PRS';  # Pressure
use constant EZO_FLOW => 'FLO';  # Flow
use constant EZO_RGB  => 'RGB';  # RGB

# Restart reason from status command.
use constant EZO_RESTART_REASON_POWEROFF => 'P';
use constant EZO_RESTART_REASON_RESET    => 'S';
use constant EZO_RESTART_REASON_BROWNOUT => 'B';
use constant EZO_RESTART_REASON_WATCHDOG => 'W';
use constant EZO_RESTART_REASON_UNKNOWN  => 'U';

## Private constants.

# Response location and maximum response length.
use constant EZO_RESPONSE_LOCATION => 0x00;
use constant EZO_RESPONSE_LENGTH => 52;

# Response codes.
use constant EZO_RESPONSE_SUCCESS => 0x01;
use constant EZO_RESPONSE_ERROR   => 0x02;
use constant EZO_RESPONSE_BUSY    => 0xfe;
use constant EZO_RESPONSE_NO_DATA => 0xff;

our @EXPORT_OK = qw (
  EZO_RTD
  EZO_PH
  EZO_EC
  EZO_ORP
  EZO_DO
  EZO_PMP
  EZO_PMPL
  EZO_CO2
  EZO_O2
  EZO_HUM
  EZO_PRS
  EZO_FLOW
  EZO_RGB
  EZO_RESTART_REASON_POWEROFF
  EZO_RESTART_REASON_RESET
  EZO_RESTART_REASON_BROWNOUT
  EZO_RESTART_REASON_WATCHDOG
  EZO_RESTART_REASON_UNKNOWN
);

# Private methods. Defined below.
my $_sendCommand;
my $_getResponse;
my $_getInformation;
my $_is_number;
my $_require_firmware;

## Public methods.

sub new {
  my $class = shift;
  die "Usage: $class->new (i2c, address)" unless (@_ == 2);
  my ($i2c, $address) = @_;
  my $io = new Device::I2C ($i2c, O_RDWR);
  # Make sure we can open the I2C bus.
  die "Error: Unable to open I2C Device File at $i2c"
    unless ($io);
  # Make sure the address is numeric instead of a string.
  $address = hex $address if ($address & ~$address);
  # Make sure we can open the Atlas Scientific device.
  die sprintf "Error: Unable to access device at 0x%X", $address
    unless ($io->checkDevice ($address));
  # Select the device at the provided address.
  $io->selectDevice ($address);
  # Bless ourselves with our class.
  my $self = bless {
    i2c         => $i2c,
    address     => $address,
    io          => $io,
    model       => undef,
    firmware    => undef
  }, $class;
  # Retrieve the device model and firmware version.
  ($self->{model}, $self->{firmware}) = $self->$_getInformation;
  return $self;
}

sub close {
  my $self = shift;
  $self->{io}->close;
}

sub measure {
  my $self = shift;
  $self->$_sendCommand ("R");
  # Each model has a different delay.
  my $delay;
  $delay = 600000 if ($self->{model} eq EZO_RTD);
  $delay = 900000 if ($self->{model} eq EZO_PH);
  $delay = 600000 if ($self->{model} eq EZO_EC);
  $delay = 900000 if ($self->{model} eq EZO_ORP);
  $delay = 600000 if ($self->{model} eq EZO_DO);
  $delay = 300000 if ($self->{model} eq EZO_PMP);
  $delay = 300000 if ($self->{model} eq EZO_PMPL);
  $delay = 900000 if ($self->{model} eq EZO_CO2);
  $delay = 900000 if ($self->{model} eq EZO_O2);
  $delay = 300000 if ($self->{model} eq EZO_HUM);
  $delay = 900000 if ($self->{model} eq EZO_PRS);
  $delay = 300000 if ($self->{model} eq EZO_FLOW);
  $delay = 300000 if ($self->{model} eq EZO_RGB);
  # Give the device a moment to respond.
  usleep $delay;
  my @response = split ",", $self->$_getResponse;
  # Read the device options.
  my @options = $self->options;
  # Extract the measurement(s) from the response based on the model.
  my $measure;
  if ($self->{model} eq EZO_RTD) {
    $measure->{temperature} = {
      value => $response[0],
      unit  => "°C",
      minimum => -126.000,
      maximum => 1254
    };
  }
  if ($self->{model} eq EZO_PH) {
    $measure->{pH} = {
      value => $response[0],
      unit  => "pH",
      minimum => 0.001,
      maximum => 14.000
    };
  }
  if ($self->{model} eq EZO_EC) {
    for (my $i = 0; $i < @options; $i ++) {
      $measure->{conductivity} = {
        value => $response[$i],
        unit  => "μS/cm",
        minimum => 0.07,
        maximum => 500000
      } if ($options[$i] eq 'EC');
      $measure->{total_dissolved_solids} = {
        value => $response[$i],
        unit  => "PPM",
        minimum => 0,
        maximum => 500000
      } if ($options[$i] eq 'TDS');
      $measure->{salinity} = {
        value => $response[$i],
        unit  => "PSU",
        minimum => 0.00,
        maximum => 42.00
      } if ($options[$i] eq 'S');
      $measure->{specific_gravity} = {
        value => $response[$i],
        unit  => "",
        minimum => 1.00,
        maximum =>1.300
      } if ($options[$i] eq 'SG');
    }
  }
  if ($self->{model} eq EZO_ORP) {
    $measure->{oxygen_reduction_potential} = {
      value => $response[0],
      unit  => "mV",
      minimum => -1019.9,
      maximum => 1019.9
    };
  }
  if ($self->{model} eq EZO_DO) {
    for (my $i = 0; $i < @options; $i ++) {
      $measure->{dissolved_oxygen} = {
        value => $response[$i],
        unit  => "mg/L",
        minimum => 0.01,
        maximum => 100
      } if ($options[$i] eq 'MG');
      $measure->{saturation} = {
        value => $response[$i],
        unit  => "%",
        minimum => 0.1,
        maximum => 400
      } if ($options[$i] eq '%');
    }
  }
  if ($self->{model} eq EZO_PMP or $self->{model} eq EZO_PMPL) {
    for (my $i = 0; $i < @options; $i ++) {
      $measure->{volume} = {
        value => $response[$i],
        unit  => "mL",
        minimum => 0,
        maximum => 45000
      } if ($options[$i] eq 'V');
      $measure->{total_volume} = {
        value => $response[$i],
        unit  => "mL",
        minimum => 0,
        maximum => 45000
      } if ($options[$i] eq 'TV');
      $measure->{absolute_total_volume} = {
        value => $response[$i],
        unit  => "mL",
        minimum => 0,
        maximum => 45000
      } if ($options[$i] eq 'ATV');
    }
  }
  if ($self->{model} eq EZO_CO2) {
    for (my $i = 0; $i < @options; $i ++) {
      $measure->{carbon_dioxide} = {
        value => $response[$i],
        unit  => "PPM",
        minimum => 0,
        maximum => 10000
      } if ($options[$i] eq 'PPM');
      $measure->{temperature} = {
        value => $response[$i],
        unit  => "°C",
        minimum => -20,
        maximum => 50
      } if ($options[$i] eq 'T');
    }
  }
  if ($self->{model} eq EZO_O2) {
    for (my $i = 0; $i < @options; $i ++) {
      $measure->{oxygen} = {
        value => $response[$i],
        unit  => "PPT",
        minimum => 0,
        maximum => 10000
      } if ($options[$i] eq 'PPT');
      $measure->{percent} = {
        value => $response[$i],
        unit  => "%",
        minimum => 0,
        maximum => 42
      } if ($options[$i] eq '%');
    }
  }
  if ($self->{model} eq EZO_HUM) {
    for (my $i = 0; $i < @options; $i ++) {
      $measure->{humidity} = {
        value => $response[$i],
        unit  => "%",
        minimum => 0,
        maximum => 100
      } if ($options[$i] eq 'HUM');
      $measure->{temperature} = {
        value => $response[$i],
        unit  => "°C",
        minimum => -20,
        maximum => 50
      } if ($options[$i] eq 'T');
      $measure->{dew_point} = {
        value => $response[$i],
        unit  => "°C",
        minimum => -20,
        maximum => 50
      } if ($options[$i] eq 'DEW');
    }
  }
  if ($self->{model} eq EZO_PRS) {
    my $unit = $self->pressureUnit;
    $unit = $response[1] if ($unit == 1);
    # Max depends on the unit.
    my $max;
    $max = 50.000 if ($unit eq "psi");
    $max = 3.402 if ($unit eq "atm");
    $max = 3.447 if ($unit eq "bar");
    $max = 344.738 if ($unit eq "kPa");
    $max = 1385.38 if ($unit eq "in h2o");
    $max = 3515.34 if ($unit eq "cm h2o");
    $measure->{pressure} = {
      value => $response[0],
      unit  => $unit,
      minimum => 0,
      maximum => $max
    };
  }
  if ($self->{model} eq EZO_FLOW) {
    for (my $i = 0; $i < @options; $i ++) {
      $measure->{total_volume} = {
        value => $response[$i],
        unit  => "L",
        minimum => 0,
        maximum => 100000
      } if ($options[$i] eq 'TV');
      $measure->{flow_rate} = {
        value => $response[$i],
        unit  => sprintf "L/%s", $self->flowRateUnit,
        minimum => 0,
        maximum => 1000
      } if ($options[$i] eq 'FR');
    }
  }
  if ($self->{model} eq EZO_RGB) {
    for (my $i = 0; $i < @options; $i ++) {
      $measure->{RGB} = {
        value => $response[$i],
        unit  => "RGB",
        minimum => 0,
        maximum => 255
      } if ($options[$i] eq 'RGB');
      $measure->{LUX} = {
        value => $response[$i],
        unit  => "LUX",
        minimum => 0,
        maximum => 65535
      } if ($options[$i] eq 'LUX');
      $measure->{CIE} = {
        value => $response[$i],
        unit  => "CIE",
        minimum => 0,
        maximum => 100
      } if ($options[$i] eq 'CIE');
    }
  }
  return $measure;
}

sub baud {
  my $self = shift;
  my ($rate) = @_;
  my $command = "Baud";
  # Prior to RTD v.2.01 command is called Serial.
  $command = "Serial" if (
    $self->{model} eq EZO_RTD &&
    version->parse ($self->{firmware}) < version->parse ("2.01")
  );
  die "Invalid baud rate" unless (
    $rate == 300 || $rate == 1200 || $rate == 2400 || $rate == 9600 ||
    $rate == 19200 || $rate == 38400 || $rate == 57600 || $rate == 115200
  );
  # Send the command to the device.
  $self->$_sendCommand ($command . "," . $rate);
  # Give the device a moment to reboot.
  usleep 1000000;
}

sub calibration {
  my $self = shift;
  my ($arg, $value) = @_;
  # Make sure this feature is supported on this device.
  die "Feature not available on " . $self->{model} unless (
    $self->{model} eq EZO_RTD or
    $self->{model} eq EZO_PH or
    $self->{model} eq EZO_EC or
    $self->{model} eq EZO_ORP or
    $self->{model} eq EZO_DO or
    $self->{model} eq EZO_PMP or
    $self->{model} eq EZO_PMPL or
    $self->{model} eq EZO_CO2 or
    $self->{model} eq EZO_O2 or
    $self->{model} eq EZO_RGB
  );
  # Handle EZO_RGB device calibration. There are no arguments to handle.
  if ($self->{model} eq EZO_RGB) {
    # Send the calibration command.
    $self->$_sendCommand ("Cal");
    # Give the device a moment to respond.
    usleep 300000;
    # Return indicating that the device is calibrated.
    return 1;
  }
  # If no argument was provided, check if the device is calibrated.
  if (not defined $arg) {
    # Check if the device is calibrated.
    $self->$_sendCommand ("Cal,?");
    # Give the device a moment to respond.
    usleep 300000;
    my ($c, $num) = split /,/, $self->$_getResponse;
    die "Invalid response from device" unless (uc $c eq "?CAL");
    # Return with the current state of calibration.
    return $num;
  }
  # Handle the clear calibration option.
  if (uc $arg eq "CLEAR") {
    # Send the clear command.
    $self->$_sendCommand ("Cal,clear");
    # Give the device a moment to respond.
    usleep 300000;
    # Return indicating that the device is not calibrated.
    return 0;
  }
  # Handle EZO_RTD device calibration.
  if ($self->{model} eq EZO_RTD) {
    # Make sure arg is a valid number.
    die "Invalid calibration point: $arg"
      unless (defined $arg and $self->$_is_number ($arg));
    # Send the calibration command with the provided temperature.
    $self->$_sendCommand ("Cal," . $arg);
    # Give the device a moment to respond.
    usleep 600000;
    # Return indicating that the device is calibrated.
    return 1;
  }
  # Handle EZO_PH device calibration.
  if ($self->{model} eq EZO_PH) {
    die "Invalid calibration point" unless (
      defined $arg and
      uc $arg eq 'LOW' or uc $arg eq 'MID' or $arg eq 'HIGH'
    );
    # Make sure value is a valid number.
    die "Invalid calibration pH: $arg" unless ($self->$_is_number ($value));
    # Send the calibration command with the provided pH.
    $self->$_sendCommand ("Cal," . $arg . "," . $value);
    # Give the device a moment to respond.
    usleep 900000;
    # Return indicating that the device is calibrated.
    return 1;
  }
  # Handle EZO_EC device calibration.
  if ($self->{model} eq EZO_EC) {
    die "Invalid calibration point: $arg" unless (
      defined $arg and
      uc $arg eq 'LOW' or uc $arg eq 'HIGH' or $arg eq 'DRY' or
      $self->$_is_number ($arg)
    );
    die "Invalid calibration point: $value" if (
      (uc $arg eq 'LOW' or uc $arg eq 'HIGH') and
      defined $value and $self->$_is_number ($value)
    );
    # Send the desired calibration command.
    $self->$_sendCommand ("Cal,dry") if (uc $arg eq 'DRY');
    $self->$_sendCommand ("Cal,low," . $value) if (uc $arg eq 'LOW');
    $self->$_sendCommand ("Cal,high," . $value) if (uc $arg eq 'HIGH');
    $self->$_sendCommand ("Cal," . $arg) if ($self->$_is_number ($arg));
    # Give the device a moment to respond.
    usleep 600000;
    # Return indicating that the device is calibrated.
    return 1;
  }
  # Handle EZO_ORP device calibration.
  if ($self->{model} eq EZO_ORP) {
    # Make sure arg is a valid number.
    die "Invalid calibration point: $arg"
      unless (defined $arg and $self->$_is_number ($arg));
    # Send the calibration command with the provided ORP value.
    $self->$_sendCommand ("Cal," . $arg);
    # Give the device a moment to respond.
    usleep 900000;
    # Return indicating that the device is calibrated.
    return 1;
  }
  # Handle EZO_DO device calibration.
  if ($self->{model} eq EZO_DO) {
    die "Invalid calibration point: $arg" unless (
      defined $arg and uc $arg eq 'ATM' or $self->$_is_number ($arg)
    );
    # Send the desired calibration command.
    $self->$_sendCommand ("Cal") if (uc $arg eq 'ATM');
    $self->$_sendCommand ("Cal," . $arg) if ($self->$_is_number ($arg));
    # Give the device a moment to respond.
    usleep 1300000;
    # Return indicating that the device is calibrated.
    return 1;
  }
  # Handle EZO_PMP and EZO_PMPL device calibration.
  if ($self->{model} eq EZO_PMP || $self->{model} eq EZO_PMPL) {
    die "Invalid calibration point: $arg" unless (
      defined $arg and $self->$_is_number ($arg)
    );
    # Send the desired calibration command.
    $self->$_sendCommand ("Cal," . $arg) if ($self->$_is_number ($arg));
    # Give the device a moment to respond.
    usleep 300000;
    # Return indicating that the device is calibrated.
    return 1;
  }
  # Handle EZO_CO2 device calibration.
  if ($self->{model} eq EZO_CO2) {
    die "Invalid calibration point: $arg" unless (
      defined $arg and $self->$_is_number ($arg)
    );
    # Send the desired calibration command.
    $self->$_sendCommand ("Cal," . $arg) if ($self->$_is_number ($arg));
    # Give the device a moment to respond.
    usleep 900000;
    # Return indicating that the device is calibrated.
    return 1;
  }
  # Handle EZO_O2 device calibration.
  if ($self->{model} eq EZO_O2) {
    die "Invalid calibration point: $arg" unless (
      defined $arg and $self->$_is_number ($arg)
    );
    # Send the desired calibration command.
    $self->$_sendCommand ("Cal," . $arg) if ($self->$_is_number ($arg));
    # Give the device a moment to respond.
    usleep 1300000;
    # Return indicating that the device is calibrated.
    return 1;
  }
}

sub calibrationExport {
  my $self = shift;
  # Make sure this feature is supported on this device.
  die "Feature not available on " . $self->{model} unless (
    $self->{model} eq EZO_RTD or
    $self->{model} eq EZO_PH or
    $self->{model} eq EZO_EC or
    $self->{model} eq EZO_ORP or
    $self->{model} eq EZO_DO
  );
  # Make sure the firmware supports this feature on this device.
  $self->$_require_firmware (EZO_RTD, "2.10");
  $self->$_require_firmware (EZO_PH, "2.10");
  $self->$_require_firmware (EZO_EC, "2.10");
  $self->$_require_firmware (EZO_ORP, "2.10");
  $self->$_require_firmware (EZO_DO, "2.10");
  # First ask for the calibration string info.
  $self->$_sendCommand ("Export,?");
  # Give the device a moment to respond.
  usleep 300000;
  my ($e, $num, $bytes) = split /,/, $self->$_getResponse;
  # The number of calibration strings is off by one when the number of bytes is
  # divisible by 12.
  $num -- if ($bytes % 12 == 0);
  die "Invalid response from device" unless (uc $e eq "?EXPORT");
  # Ask for each calibration string.
  my @calibration;
  for (my $i = 0; $i < $num; $i ++) {
    $self->$_sendCommand ("Export");
    # Give the device a moment to respond.
    usleep 300000;
    my $response = $self->$_getResponse;
    push @calibration, $response;
  }
  $self->$_sendCommand ("Export");
  # Give the device a moment to respond.
  usleep 300000;
  die "Error exporting calibration" unless (uc $self->$_getResponse eq "*DONE");
  my $b = eval join '+', map { length $_ } @calibration;
  die "Invalid calibration" unless ($bytes == $b);
  return @calibration;
}

sub calibrationImport {
  my $self = shift;
  my @calibration = @_;
  # Make sure this feature is supported on this device.
  die "Feature not available on " . $self->{model} unless (
    $self->{model} eq EZO_RTD or
    $self->{model} eq EZO_PH or
    $self->{model} eq EZO_EC or
    $self->{model} eq EZO_ORP or
    $self->{model} eq EZO_DO
  );
  # Make sure the firmware supports this feature on this device.
  $self->$_require_firmware (EZO_RTD, "2.10");
  $self->$_require_firmware (EZO_PH, "2.10");
  $self->$_require_firmware (EZO_EC, "2.10");
  $self->$_require_firmware (EZO_ORP, "2.10");
  $self->$_require_firmware (EZO_DO, "2.10");
  # Import the calibration.
  foreach my $cal (@calibration) {
    $self->$_sendCommand ("Import," . $cal);
    # Give the device a moment to respond.
    usleep 300000;
  }
  # Give the device a moment to reboot.
  usleep 1000000;
}

sub factoryReset {
  my $self = shift;
  my $command = "Factory";
  # Some firmware versions call this command X.
  $command = "X" if (
    $self->{model} eq EZO_PH &&
    version->parse ($self->{firmware}) < version->parse ("1.07")
  );
  $command = "X" if (
    $self->{model} eq EZO_EC &&
    version->parse ($self->{firmware}) < version->parse ("1.08")
  );
  $command = "X" if (
    $self->{model} eq EZO_ORP &&
    version->parse ($self->{firmware}) < version->parse ("1.07")
  );
  $command = "X" if (
    $self->{model} eq EZO_DO &&
    version->parse ($self->{firmware}) < version->parse ("1.07")
  );
  # Send the factory reset command.
  $self->$_sendCommand ($command);
  # Give the device a moment to reboot.
  usleep 1000000;
}

sub find {
  my $self = shift;
  # Make sure the firmware supports this feature on this device.
  $self->$_require_firmware (EZO_RTD, "2.10");
  $self->$_require_firmware (EZO_PH, "2.10");
  $self->$_require_firmware (EZO_EC, "2.10");
  $self->$_require_firmware (EZO_ORP, "2.10");
  $self->$_require_firmware (EZO_DO, "2.10");
  # Send the find command.
  $self->$_sendCommand ("Find");
}

sub flowRateUnit {
  my $self = shift;
  my ($unit) = @_;
  # Make sure this feature is supported on this device.
  die "Feature not available on " . $self->{model} unless (
    $self->{model} eq EZO_FLOW
  );
  if (defined $unit) {
    die "Invalid unit option $unit" unless (
      $unit eq 's' or
      $unit eq 'm' or
      $unit eq 'h'
    );
    $self->$_sendCommand ("Frp," . $unit);
    # Give the device a moment to respond.
    usleep 300000;
  }
  else {
    $self->$_sendCommand ("Frp,?");
    # Give the device a moment to respond.
    usleep 300000;
    (my $frp, $unit) = split /,/, $self->$_getResponse;
    die "Invalid response from device" unless (uc $frp eq "?Frp");
  }
  return $unit;
}

sub i2c {
  my $self = shift;
  my ($address) = @_;
  # Make sure the address is numeric instead of a string.
  $address = hex $address if ($address & ~$address);
  # Make sure the address is within range.
  die "Invalid I2C address $address" unless ($address >= 1 && $address <= 127);
  # Set the address for the device.
  $self->{address} = $address;
  $self->$_sendCommand ("I2C," . $address);
  # Give the device a moment to reboot.
  usleep 1000000;
}

sub information {
  my $self = shift;
  return ($self->{model}, $self->{firmware});
}

sub ledIndicator {
  my $self = shift;
  my ($led) = @_;
  my $command = "L";
  $command = "iL" if ($self->{model} eq EZO_RGB);
  if (defined $led) {
    die "Invalid LED option $led" unless ($led == 0 || $led == 1);
    $self->$_sendCommand ($command . "," . $led);
    # Give the device a moment to respond.
    usleep 300000;
  }
  else {
    $self->$_sendCommand ($command . ",?");
    # Give the device a moment to respond.
    usleep 300000;
    (my $l, $led) = split /,/, $self->$_getResponse;
    die "Invalid response from device" unless (uc $l eq "?L" or uc $l eq "?IL");
  }
  return $led;
}

sub name {
  my $self = shift;
  my ($name) = @_;
  if (defined $name) {
    die "Name cannot be longer than 16 characters" if (length $name > 16);
    die "Name can only include printable characters, excluding spaces" unless (
      $name =~ /^[[:graph:]]*$/
    );
    $self->$_sendCommand ("Name," . $name);
    # Give the device a moment to respond.
    usleep 300000;
  }
  else {
    $self->$_sendCommand ("Name,?");
    # Give the device a moment to respond.
    usleep 300000;
    (my $n, $name) = split /,/, $self->$_getResponse;
    die "Invalid response from device" unless (uc $n eq "?NAME");
  }
  return $name;
}

sub options {
  my $self = shift;
  my ($param, $value) = @_;
  # Make sure this feature is supported on this device.
  return if (
    $self->{model} eq EZO_RTD or
    $self->{model} eq EZO_PH or
    $self->{model} eq EZO_ORP or
    $self->{model} eq EZO_PRS
  );
  if (defined $param && defined $value) {
    $param = uc $param;
    # Validate parameter usage by model.
    die "Invalid parameter '$param'\n" unless (
      ($self->{model} eq EZO_EC and
        ($param eq 'EC' or $param eq 'TDS' or $param eq 'S' or $param eq 'SG')
      ) or
      ($self->{model} eq EZO_DO and
        ($param eq 'MG' or $param eq '%')
      ) or
      ($self->{model} eq EZO_CO2 and
        ($param eq 'T')) or
      ($self->{model} eq EZO_O2 and
        ($param eq 'PPT' or $param eq '%')
      ) or
      ($self->{model} eq EZO_HUM and
        ($param eq 'HUM' or $param eq 'T' or $param eq 'DEW')
      ) or
      ($self->{model} eq EZO_PMP and
        ($param eq 'V' or $param eq 'TV' or $param eq 'ATV')
      ) or
      ($self->{model} eq EZO_PMPL and
        ($param eq 'V' or $param eq 'TV' or $param eq 'ATV')
      ) or
      ($self->{model} eq EZO_RGB and
        ($param eq 'RGB' or $param eq 'LUX' or $param eq 'CIE')
      ) or
      ($self->{model} eq EZO_FLOW and
        ($param eq 'TV' or $param eq 'FR')
      )
    );
    die "Invalid parameter value" unless ($value == 0 or $value == 1);
    $self->$_sendCommand ("O," . $param . "," . $value);
    # Give the device a moment to respond.
    usleep 300000;
  }
  else {
    $self->$_sendCommand ("O,?");
    # Give the device a moment to respond.
    usleep 300000;
    (my $o, $param) = split /,/, $self->$_getResponse, 2;
    die "Invalid response from device" unless (uc $o eq "?O");
  }
  return split ",", $param;
}

sub pressureUnit {
  my $self = shift;
  my ($unit) = @_;
  # Make sure this feature is supported on this device.
  die "Feature not available on " . $self->{model} unless (
    $self->{model} eq EZO_PRS
  );
  if (defined $unit) {
    die "Invalid unit option $unit" unless (
      $unit == 0 or $unit == 1 or
      $unit eq 'psi' or
      $unit eq 'atm' or
      $unit eq 'bar' or
      $unit eq 'kPa' or
      $unit eq 'in h2o' or
      $unit eq 'cm h20'
    );
    $self->$_sendCommand ("U," . $unit);
    # Give the device a moment to respond.
    usleep 300000;
  }
  else {
    $self->$_sendCommand ("U,?");
    # Give the device a moment to respond.
    usleep 300000;
    (my $u, $unit) = split /,/, $self->$_getResponse;
    die "Invalid response from device" unless (uc $u eq "?U");
  }
  return $unit;
}

sub plock {
  my $self = shift;
  my ($plock) = @_;
  # Make sure the firmware supports this feature on this device.
  $self->$_require_firmware (EZO_RTD, "1.02");
  $self->$_require_firmware (EZO_PH, "1.95");
  $self->$_require_firmware (EZO_EC, "1.95");
  $self->$_require_firmware (EZO_ORP, "1.95");
  $self->$_require_firmware (EZO_DO, "1.95");
  if (defined $plock) {
    die "Invalid plock option $plock" unless ($plock == 0 || $plock == 1);
    $self->$_sendCommand ("Plock," . $plock);
    # Give the device a moment to respond.
    usleep 300000;
  }
  else {
    $self->$_sendCommand ("Plock,?");
    # Give the device a moment to respond.
    usleep 300000;
    (my $p, $plock) = split /,/, $self->$_getResponse;
    die "Invalid response from device" unless (uc $p eq "?PLOCK");
  }
  return $plock;
}

sub sleep {
  my $self = shift;
  $self->$_sendCommand ("Sleep");
}

sub status {
  my $self = shift;
  $self->$_sendCommand ("Status");
  # Give the device a moment to respond.
  usleep 300000;
  my ($s, $p, $voltage) = split /,/, $self->$_getResponse;
  die "Invalid response from device" unless (uc $s eq "?STATUS");
  my $reason;
  $reason = EZO_RESTART_REASON_POWEROFF if ($p eq EZO_RESTART_REASON_POWEROFF);
  $reason = EZO_RESTART_REASON_RESET if ($p eq EZO_RESTART_REASON_RESET);
  $reason = EZO_RESTART_REASON_BROWNOUT if ($p eq EZO_RESTART_REASON_BROWNOUT);
  $reason = EZO_RESTART_REASON_WATCHDOG if ($p eq EZO_RESTART_REASON_WATCHDOG);
  $reason = EZO_RESTART_REASON_UNKNOWN if ($p eq EZO_RESTART_REASON_UNKNOWN);
  die "Error detecting reason $p" unless (defined $reason);
  return ($reason, $voltage);
}

## Private methods.

$_sendCommand = sub {
  my $self = shift;
  my ($command) = @_;
  # Send the command to the device.
  my @bytes = unpack 'C*', $command;
  my $comm = shift @bytes;
  $self->{io}->writeBlockData ($comm, \@bytes);
};

$_getResponse = sub {
  my $self = shift;
  my @response = $self->{io}->readBlockData (
    EZO_RESPONSE_LOCATION, EZO_RESPONSE_LENGTH
  );
  # Get the device response code, wait for it to not be busy.
  my $code = shift @response;
  while ($code == EZO_RESPONSE_BUSY) {
    usleep 1000;
    @response = $self->{io}->readBlockData (
      EZO_RESPONSE_LOCATION, EZO_RESPONSE_LENGTH
    );
    $code = shift @response;
  }
  # Check for syntax error in the command.
  die "Syntax error" if ($code == EZO_RESPONSE_ERROR);
  # Check for valid response.
  if ($code == EZO_RESPONSE_SUCCESS) {
    my $response;
    foreach my $byte (@response) {
      last if ($byte == 0x00);
      $response .= pack 'C*', $byte;
    }
    return $response;
  }
};

$_getInformation = sub {
  my $self = shift;
  $self->$_sendCommand ("I");
  # Give the device a moment to respond.
  usleep 300000;
  my ($i, $m, $firmware) = split /,/, $self->$_getResponse;
  die "Invalid response from device" unless (uc $i eq "?I");
  my $model;
  $model = EZO_RTD if (uc $m eq EZO_RTD);
  $model = EZO_PH if (uc $m eq EZO_PH);
  $model = EZO_EC if (uc $m eq EZO_EC);
  $model = EZO_ORP if (uc $m eq EZO_ORP);
  $model = EZO_DO if (uc $m eq EZO_DO);
  $model = EZO_PMP if (uc $m eq EZO_PMP);
  $model = EZO_PMPL if (uc $m eq EZO_PMPL);
  $model = EZO_CO2 if (uc $m eq EZO_CO2);
  $model = EZO_O2 if (uc $m eq EZO_O2);
  $model = EZO_HUM if (uc $m eq EZO_HUM);
  $model = EZO_PRS if (uc $m eq EZO_PRS);
  $model = EZO_FLOW if (uc $m eq EZO_FLOW);
  $model = EZO_RGB if (uc $m eq EZO_RGB);
  die "Unsupported device $m" unless (defined $model);
  return ($model, $firmware);
};

$_is_number = sub {
  my $self = shift;
  return shift =~ /^[-]?\d*\.?\d*$/;
};

$_require_firmware = sub {
  my $self = shift;
  my ($model, $version) = @_;
  die "Feature not available on firmware < $version for $model" if (
    $self->{model} eq $model &&
    version->parse ($self->{firmware}) < version->parse ($version)
  );
};

1;
