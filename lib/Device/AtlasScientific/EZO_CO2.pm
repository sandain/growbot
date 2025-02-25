package Device::AtlasScientific::EZO_CO2;

use strict;
use warnings;
use utf8;
use v5.14;
use Time::HiRes qw(usleep);

use parent 'Device::AtlasScientific';

sub calibration {
  my $self = shift;
  my ($arg, $value) = @_;
  # If no argument was provided, check if the device is calibrated.
  if (not defined $arg) {
    # Check if the device is calibrated.
    $self->_sendCommand ("Cal,?");
    # Give the device a moment to respond.
    usleep 300000;
    my ($c, $num) = split /,/, $self->_getResponse;
    die "Invalid response from device" unless (uc $c eq "?CAL");
    # Return with the current state of calibration.
    return $num;
  }
  # Handle the clear calibration option.
  if (uc $arg eq "CLEAR") {
    # Send the clear command.
    $self->_sendCommand ("Cal,clear");
    # Give the device a moment to respond.
    usleep 300000;
    # Return indicating that the device is not calibrated.
    return 0;
  }
  die "Invalid calibration point: $arg" unless (
    defined $arg and $self->_is_number ($arg)
  );
  # Send the desired calibration command.
  $self->_sendCommand ("Cal," . $arg);
  # Give the device a moment to respond.
  usleep 900000;
  # Return indicating that the device is calibrated.
  return 1;
}

sub measure {
  my $self = shift;
  $self->_sendCommand ('R');
  usleep 900000;
  my @response = split ",", $self->_getResponse;
  # Read the device options.
  my @options = $self->options;
   # Format the measurement.
  my $measure = {};
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
  return $measure;
}

sub options {
  my $self = shift;
  my ($param, $value) = @_;
  if (defined $param && defined $value) {
    $param = uc $param;
    # Validate parameter usage by model.
    die "Invalid parameter '$param'\n" unless ($param eq 'T');
    die "Invalid parameter value" unless ($value == 0 or $value == 1);
    $self->_sendCommand ("O," . $param . "," . $value);
    # Give the device a moment to respond.
    usleep 300000;
  }
  else {
    $self->_sendCommand ("O,?");
    # Give the device a moment to respond.
    usleep 300000;
    (my $o, $param) = split /,/, $self->_getResponse, 2;
    die "Invalid response from device" unless (uc $o eq "?O");
  }
  return split ",", $param;
}

1;