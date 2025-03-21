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

=item * Oxidation-reduction potential meter:
L<https://atlas-scientific.com/files/ORP_EZO_Datasheet.pdf>

=item * Dissolved oxygen meter:
L<https://atlas-scientific.com/files/DO_EZO_Datasheet.pdf>

=item * Peristaltic pump:
L<https://atlas-scientific.com/files/EZO_PMP_Datasheet.pdf>

=item * Large Peristaltic pump:
L<https://atlas-scientific.com/files/EZO_PMP_L_Datasheet.pdf>

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

=item C<dispense>

Dispense a specific volume (mL) from the device. If the volume is provided, that
volume will be dispensed. Negative values for volume will dispense in reverse.
If minutes are provided, this volume will be dispensed over this time period. If
no arguments are provided, the last volume requested and the status (1 if
actively dispensing, 0 if not) will be returned.

Arguments:

=over 12

=item C<volume>

The volume (mL) to dispense.

=item C<minutes>

The number of minutes to dispense the volume requested.

=back

=item C<dispenseConstant>

Dispense at a constant flow rate over a specified length of time. If no
arguments are supplied, the maximum possible flow rate will be returned.

Arguments:

=over 12

=item C<rate>

The rate (mL / minute) to dispense.

=item <minutes>

The number of minutes to dispense. Use '*' to dispense indefinitely (will reset
after 20 days).

=back

=item C<dispenseStartup>

Dispense a specific volume (mL) at device startup. If no arguments are provided,
the volume dispensed at startup is reported (

Arguments:

=over 12

=item C<volume>

The specific volume (mL) to dispense at device startup.

=item C<off>

Disable dispense at device startup.

=back

=item C<dispensePause>

Pause dispensing on the device.

=item C<dispensePauseStatus>

Return the status of the dispense pause (1 paused, 0 unpaused) from the device.

=item C<dispenseStop>

Stop dispensing from the device.

=item C<dispensedTotalVolume>

Return the total volume (mL) dispensed from the device.

=item C<dispensedAbsoluteTotalVolume>

Return the absolute total volume (mL) dispensed from the device.

=item C<dispensedVolumeClear>

Clear the total volume dispensed from the device.

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

=item C<pumpVoltage>

Returns the voltage of the pump.

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

  Copyright (c) 2020-2025 Jason M. Wood

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
use constant SUPPORTED_DEVICES => {
  RTD  => 'EZO_RTD',  # Temperature
  PH   => 'EZO_PH',   # pH
  EC   => 'EZO_EC',   # Electrical conductivity
  ORP  => 'EZO_ORP',  # Oxidation-reduction potential
  DO   => 'EZO_DO',   # Dissolved oxygen
  PMP  => 'EZO_PMP',  # Peristaltic pump
  PMPL => 'EZO_PMP',  # Large Peristaltic pump
  CO2  => 'EZO_CO2',  # Carbon dioxide (gas)
  O2   => 'EZO_O2',   # Oxygen (gas)
  HUM  => 'EZO_HUM',  # Humidity
  PRS  => 'EZO_PRS',  # Pressure
  FLOW => 'EZO_FLO',  # Flow
  RGB  => 'EZO_RGB'   # RGB
};

# Restart reason from status command.
use constant EZO_RESTART_REASON_POWEROFF => 'P';
use constant EZO_RESTART_REASON_RESET    => 'S';
use constant EZO_RESTART_REASON_BROWNOUT => 'B';
use constant EZO_RESTART_REASON_WATCHDOG => 'W';
use constant EZO_RESTART_REASON_UNKNOWN  => 'U';

# Response location and maximum response length.
use constant EZO_RESPONSE_LOCATION => 0x00;
use constant EZO_RESPONSE_LENGTH => 52;

# Response codes.
use constant EZO_RESPONSE_SUCCESS => 0x01;
use constant EZO_RESPONSE_ERROR   => 0x02;
use constant EZO_RESPONSE_BUSY    => 0xfe;
use constant EZO_RESPONSE_NO_DATA => 0xff;

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
  # Temporarily bless ourselves with our class.
  my $self = bless {
    io       => $io
  }, $class;
  # Retrieve the device model and firmware version.
  my ($model, $firmware) = $self->_getInformation;
  # Make sure the device is supported.
  die "Unsupported device $model" unless (defined SUPPORTED_DEVICES->{$model});
  my $device_module = "Device::AtlasScientific::" . SUPPORTED_DEVICES->{$model};
  eval "require $device_module" or die "Error loading $device_module: $@";
  # Bless ourselves with the device module.
  $self = bless {
    io      => $io,
    model   => $model,
    firmware => $firmware,
    options  => []
  }, $device_module;
  return $self;
}

## Generic device methods.

sub baud {
  my $self = shift;
  my ($rate) = @_;
  die "Invalid baud rate" unless (
    $rate == 300 || $rate == 1200 || $rate == 2400 || $rate == 9600 ||
    $rate == 19200 || $rate == 38400 || $rate == 57600 || $rate == 115200
  );
  # Send the command to the device.
  $self->_sendCommand ("Baud" . "," . $rate);
  # Give the device a moment to reboot.
  usleep 1000000;
}

sub close {
  my $self = shift;
  $self->{io}->close;
}

sub factoryReset {
  my $self = shift;
  my $command = "Factory";
  # Send the factory reset command.
  $self->_sendCommand ($command);
  # Give the device a moment to reboot.
  usleep 1000000;
}

sub find {
  my $self = shift;
  # Send the find command.
  $self->_sendCommand ("Find");
}

sub i2c {
  my $self = shift;
  my ($address) = @_;
  # Make sure the address is numeric instead of a string.
  $address = hex $address if ($address & ~$address);
  # Make sure the address is within range.
  die "Invalid I2C address $address" unless ($address >= 1 && $address <= 127);
  # Set the address for the device.
  $self->_sendCommand ("I2C," . $address);
  # Give the device a moment to reboot.
  usleep 1000000;
}

sub information {
  my $self = shift;
  return ($self->{model}, $self->{firmware});
}

sub name {
  my $self = shift;
  my ($name) = @_;
  if (defined $name) {
    die "Name cannot be longer than 16 characters" if (length $name > 16);
    die "Name can only include printable characters, excluding spaces" unless (
      $name =~ /^[[:graph:]]*$/
    );
    $self->_sendCommand ("Name," . $name);
    # Give the device a moment to respond.
    usleep 300000;
  }
  else {
    $self->_sendCommand ("Name,?");
    # Give the device a moment to respond.
    usleep 300000;
    (my $n, $name) = split /,/, $self->_getResponse;
    die "Invalid response from device" unless (uc $n eq "?NAME");
  }
  return $name;
}

sub plock {
  my $self = shift;
  my ($plock) = @_;
  if (defined $plock) {
    die "Invalid plock option $plock" unless ($plock == 0 || $plock == 1);
    $self->_sendCommand ("Plock," . $plock);
    # Give the device a moment to respond.
    usleep 300000;
  }
  else {
    $self->_sendCommand ("Plock,?");
    # Give the device a moment to respond.
    usleep 300000;
    (my $p, $plock) = split /,/, $self->_getResponse;
    die "Invalid response from device" unless (uc $p eq "?PLOCK");
  }
  return $plock;
}

sub status {
  my $self = shift;
  $self->_sendCommand ("Status");
  # Give the device a moment to respond.
  usleep 300000;
  my ($s, $p, $voltage) = split /,/, $self->_getResponse;
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

sub sleep {
  my $self = shift;
  $self->_sendCommand ("Sleep");
}

## Methods not implemented in this base class. They are implemented in the
## device specific classes if supported by that device.

sub calibration {
  my $self = shift;
  die "Calibration feature not available on " . $self->{model};
}

sub calibrationExport {
  my $self = shift;
  die "Calibration export feature not available on " . $self->{model};
}

sub calibrationImport {
  my $self = shift;
  die "Calibration import feature not available on " . $self->{model};
}

sub dispense {
  my $self = shift;
  die "Dispense feature not available on " . $self->{model};
}

sub dispenseConstant {
  my $self = shift;
  die "Dispense constant feature not available on " . $self->{model};
}

sub dispensePause {
  my $self = shift;
   die "Dispense pause feature not available on " . $self->{model};
}

sub dispensePauseStatus {
  my $self = shift;
   die "Dispense pause status feature not available on " . $self->{model};
}

sub dispenseStartup {
  my $self = shift;
  die "Dispense startup feature not available on " . $self->{model};
}

sub dispenseStop {
  my $self = shift;
  die "Dispense stop feature not available on " . $self->{model};
}

sub dispensedAbsoluteTotalVolume {
  my $self = shift;
  die "Dispensed absolute total volume feature not available on " . $self->{model};
}

sub dispensedTotalVolume {
  my $self = shift;
  die "Dispensed total volume feature not available on " . $self->{model};
}

sub dispensedVolumeClear {
  my $self = shift;
  die "Dispensed volume clear feature not available on " . $self->{model};
}

sub flowRateUnit {
  my $self = shift;
  die "Flow rate unit feature not available on " . $self->{model};
}

sub ledIndicator {
  my $self = shift;
  die "LED indicator feature not available on " . $self->{model};
}

sub measure {
  my $self = shift;
  die "Measure feature not available on " . $self->{model};
}

sub options {
  my $self = shift;
  die "Options feature not available on " . $self->{model};
}

sub pressureUnit {
  my $self = shift;
 die "Pressure unit feature not available on " . $self->{model};
}

sub pumpVoltage {
  my $self = shift;
 die "Pump voltage feature not available on " . $self->{model};
}

## Utility methods.

sub _getInformation {
  my $self = shift;
  $self->_sendCommand ("I");
  # Give the device a moment to respond.
  usleep 300000;
  my ($i, $model, $firmware) = split /,/, $self->_getResponse;
  $model = uc $model;
  die "Invalid response from device" unless (uc $i eq "?I");
  die "Unsupported device $model" unless (defined SUPPORTED_DEVICES->{$model});
  return ($model, $firmware);
}

sub _getResponse {
  my $self = shift;
  my @response;
  my $code;
  eval {
    @response = $self->{io}->readBlockData (
      EZO_RESPONSE_LOCATION, EZO_RESPONSE_LENGTH
    );
    # Get the device response code, wait for it to not be busy.
    $code = shift @response;
    while ($code == EZO_RESPONSE_BUSY) {
      usleep 1000;
      @response = $self->{io}->readBlockData (
        EZO_RESPONSE_LOCATION, EZO_RESPONSE_LENGTH
      );
      $code = shift @response;
    }
  } or die "Error reading response from device: $@";
  # Check for syntax error in the command.
  die "Syntax error" if ($code == EZO_RESPONSE_ERROR);
  # Check for valid response.
  if ($code == EZO_RESPONSE_SUCCESS) {
    my $response = '';
    foreach my $byte (@response) {
      last if ($byte == 0x00);
      $response .= pack 'C*', $byte;
    }
    return $response;
  }
}

sub _is_number {
  my $self = shift;
  return shift =~ /^[-]?\d*\.?\d*$/;
}

sub _sendCommand {
  my $self = shift;
  my ($command) = @_;
  # Send the command to the device.
  my @bytes = unpack 'C*', $command;
  my $comm = shift @bytes;
  eval {
    $self->{io}->writeBlockData ($comm, \@bytes);
  } or die "Error sending command to device: $@";
}

sub _require_firmware {
  my $self = shift;
  my ($version) = @_;
  die "Feature not available on firmware < $version for " . $self->{model} if (
    $self->_test_version ($version)
  );
}

sub _test_version {
  my $self = shift;
  my ($version) = @_;
  return version->parse ($self->{firmware}) < version->parse ($version);
}

1;
