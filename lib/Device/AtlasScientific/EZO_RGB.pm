package Device::AtlasScientific::EZO_RGB;

use strict;
use warnings;
use utf8;
use v5.14;
use Time::HiRes qw(usleep);

use parent 'Device::AtlasScientific';

sub calibration {
  my $self = shift;
  my ($arg, $value) = @_;
  # Send the calibration command.
  $self->_sendCommand ("Cal");
  # Give the device a moment to respond.
  usleep 300000;
  # Return indicating that the device is calibrated.
  return 1;
}

sub ledIndicator {
  my $self = shift;
  my ($led) = @_;
  my $command = "L";
  $command = "iL" if ($self->{model} eq EZO_RGB);
  if (defined $led) {
    die "Invalid LED option $led" unless ($led == 0 || $led == 1);
    $self->_sendCommand ($command . "," . $led);
    # Give the device a moment to respond.
    usleep 300000;
  }
  else {
    $self->_sendCommand ($command . ",?");
    # Give the device a moment to respond.
    usleep 300000;
    (my $l, $led) = split /,/, $self->_getResponse;
    die "Invalid response from device" unless (uc $l eq "?L" or uc $l eq "?IL");
  }
  return $led;
}

sub measure {
  my $self = shift;
  $self->_sendCommand ('R');
  usleep 600000;
  my @response = split ",", $self->_getResponse;
  # Read the device options.
  my @options = $self->options;
  # Format the measurement.
  my $measure = {};
  for (my $i = 0; $i < @options; $i ++) {
    $measure->{rgb} = {
      value => $response[$i],
      unit  => "RGB",
      minimum => 0,
      maximum => 255
    } if ($options[$i] eq 'RGB');
    $measure->{lux} = {
      value => $response[$i],
      unit  => "LUX",
      minimum => 0,
      maximum => 65535
    } if ($options[$i] eq 'LUX');
    $measure->{cie} = {
      value => $response[$i],
      unit  => "CIE",
      minimum => 0,
      maximum => 100
    } if ($options[$i] eq 'CIE');
  }
  return $measure;
}

sub options {
  my $self = shift;
  my ($param, $value) = @_;
  if (defined $param && defined $value) {
    $param = uc $param;
    # Validate parameter usage by model.
    die "Invalid parameter '$param'\n" unless ($param eq 'RGB' or $param eq 'LUX' or $param eq 'CIE');
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