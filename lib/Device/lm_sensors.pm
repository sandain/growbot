=encoding utf8

=head1 NAME

Device::lm_sensors - Driver for sensors supported by lm-sensors.

=head1 SYNOPSIS

  use strict;
  use warnings;
  use utf8;
  use v5.10;

  use Device::lm_sensors;

  # Setup lm-sensors to read the CPU temperature on a Raspberry Pi.
  my $chip = 'cpu_thermal-virtual-0';
  my $device = 'temp1';
  my $value = 'temp1_input';
  my $lm_sensors = Device::lm_sensors->new ($chip, $device, $value);

  # Measure and print the CPU temperature.
  printf "CPU temperature: %s °C\n\n", $lm_sensors->measure;

  # Close the device.
  $lm_sensors->close;

=head1 DESCRIPTION

Device::lm_sensors is a driver for sensors supported by lm-sensors.

=head2 Methods

=over 12

=item C<new>

Returns a new Device::lm_sensors object.

=item C<close>

Closes input/output to the device.

=item C<measure>

Get a measurement from the device.

=back

=head1 DEPENDENCIES

Device::lm_sensors requires Perl version 5.10 or later, lm-sensors version
3.6.0 or later, and Mojo::JSON (or any other JSON::XS compatible parser).

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

package Device::lm_sensors;

use strict;
use warnings;
use utf8;
use version;
use v5.10;
use Mojo::JSON qw(decode_json);

my $DEFAULT_BIN = '/usr/bin/sensors';
my $MIN_VERSION = '3.6.0';

sub new {
  my $class = shift;
  die "Usage: $class->new (chip, device, value)" unless (@_ == 3);
  my ($chip, $device, $value) = @_;
  # Make sure we can find the lm-sensors program.
  my $bin = `which sensors || echo $DEFAULT_BIN`;
  $bin =~ s/[\r\n]+//g;
  die "Error: Unable to find lm-sensors" unless (-e $bin);
  # Bless ourselves with our class.
  my $self = bless {
    chip   => $chip,
    device => $device,
    value  => $value,
    bin    => $bin
  }, $class;
  # Make sure lm-sensors is recent enough.
  my $version_string = `$self->{bin} -v 2>/dev/null`;
  ($_, $_, my $version, $_) = split / /, $version_string, 4;
  die "Error: lm-sensors version $version is too old, $MIN_VERSION is required."
    unless (version->parse ($version) >= version->parse ($MIN_VERSION));
  return $self;
}

sub close {
  my $self = shift;
}

sub measure {
  my $self = shift;
  my $sensors = `$self->{bin} $self->{chip} -A -j 2>/dev/null`;
  my $json = decode_json $sensors;
  # Make sure the chip, device, and value are found fields are found.
  unless (defined $json->{$self->{chip}}) {
    die "Error: Chip not found " . $self->{chip};
  }
  unless (defined $json->{$self->{chip}}->{$self->{device}}) {
    die "Error: Device not found " . $self->{device};
  }
  unless (defined $json->{$self->{chip}}->{$self->{device}}->{$self->{value}}) {
    die "Error: Value not found " . $self->{value};
  }
  # Return the measured value.
  return {
    temperature => $json->{$self->{chip}}->{$self->{device}}->{$self->{value}}
  };
}

1;
