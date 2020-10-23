=encoding utf8

=head1 NAME

Device::AtlasScientific - Driver for Atlas Scientific series of environmental
robotic devices.

=head1 SYNOPSIS

  use strict;
  use warnings;
  use utf8;
  use v5.10;

  use Device::AtlasScientific;

  # The I2C device file.
  my $device = '/dev/i2c-1';

  # The address of the Atlas Scientific pH sensor device.
  my $address = 0x63;

  # Load this driver for the pH sensor.
  my $pH = Device::AtlasScientific->new ($device, $address);

  # Print out a pH measurement.
  printf "ph: %0.2f\n", $ph->measure;

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

=item C<information>

Returns the device model and firmware version.

=item C<status>

Returns the reason for the last restart and the voltage at the Vcc pin.

=back

=head1 DEPENDENCIES

Device::AtlasScientific requires Perl version 5.10 or later.

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

package Device::AtlasScientific;

use strict;
use warnings;
use utf8;
use v5.10;

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
use constant EZO_CO2  => 'CO2';  # Carbon dioxide (gas)
use constant EZO_O2   => 'O2';   # Oxygen (gas)
use constant EZO_HUM  => 'HUM';  # Humidity
use constant EZO_PRS  => 'PRS';  # Pressure
use constant EZO_FLOW => 'FLOW'; # Flow
use constant EZO_RGB  => 'RGB';  # RGB

# Restart reason from status command.
use constant EZO_RESTART_REASON_POWEROFF => 'P';
use constant EZO_RESTART_REASON_RESET    => 'S';
use constant EZO_RESTART_REASON_BROWNOUT => 'B';
use constant EZO_RESTART_REASON_WATCHDOG => 'W';
use constant EZO_RESTART_REASON_UNKOWN   => 'U';

## Private constants.

# Maximum response length.
use constant EZO_RESPONSE_LENGTH => 40;

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
  EZO_RESTART_REASON_UNKOWN
);

## Private methods.

my $_sendCommand = sub {
  my $self = shift;
  my ($command) = @_;
  # Send the command to the device.
  my @bytes = unpack 'C*', $command;
  my $comm = shift @bytes;
  $self->{io}->writeBlockData ($comm, \@bytes);
};

my $_getResponse = sub {
  my $self = shift;
  my $comm = 0x00; # Undocumented, but this works.
  my @response = $self->{io}->readBlockData ($comm, EZO_RESPONSE_LENGTH);
  # Get the device response code, wait for it to not be busy.
  my $code = shift @response;
  while ($code == EZO_RESPONSE_BUSY) {
    usleep 1000;
    @response = $self->{io}->readBlockData ($comm, EZO_RESPONSE_LENGTH);
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

my $_getInformation = sub {
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
  $model = EZO_CO2 if (uc $m eq EZO_CO2);
  $model = EZO_O2 if (uc $m eq EZO_O2);
  $model = EZO_HUM if (uc $m eq EZO_HUM);
  $model = EZO_PRS if (uc $m eq EZO_PRS);
  $model = EZO_FLOW if (uc $m eq EZO_FLOW);
  $model = EZO_RGB if (uc $m eq EZO_RGB);
  die "Unsupported device $m" unless (defined $model);
  return ($model, $firmware);
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
  # Make sure we can open the Atlas Scientific device.
  die "Error: Unable to access device at $address"
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

sub information {
  my $self = shift;
  return ($self->{model}, $self->{firmware});
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
  $reason = EZO_RESTART_REASON_UNKOWN if ($p eq EZO_RESTART_REASON_UNKOWN);
  die "Error detecting reason $p" unless (defined $reason);
  return ($reason, $voltage);
}

1;
