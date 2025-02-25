package Device::AtlasScientific::EZO_FLOW;

use strict;
use warnings;
use utf8;
use v5.14;
use Time::HiRes qw(usleep);

use parent 'Device::AtlasScientific';

sub flowRateUnit {
  my $self = shift;
  my ($unit) = @_;
  if (defined $unit) {
    die "Invalid unit option $unit" unless (
      $unit eq 's' or
      $unit eq 'm' or
      $unit eq 'h'
    );
    $self->_sendCommand ("Frp," . $unit);
    # Give the device a moment to respond.
    usleep 300000;
  }
  else {
    $self->_sendCommand ("Frp,?");
    # Give the device a moment to respond.
    usleep 300000;
    (my $frp, $unit) = split /,/, $self->_getResponse;
    die "Invalid response from device" unless (uc $frp eq "?Frp");
  }
  return $unit;
}

sub measure {
  my $self = shift;
  $self->_sendCommand ('R');
  usleep 300000;
  my @response = split ",", $self->_getResponse;
  # Read the device options.
  my @options = $self->options;
  # Format the measurement.
  my $measure = {};
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
  return $measure;
}

sub options {
  my $self = shift;
  my ($param, $value) = @_;
  if (defined $param && defined $value) {
    $param = uc $param;
    # Validate parameter usage by model.
    die "Invalid parameter '$param'\n" unless ($param eq 'TV' or $param eq 'FR');
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