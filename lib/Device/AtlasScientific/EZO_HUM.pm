package Device::AtlasScientific::EZO_HUM;

use strict;
use warnings;
use utf8;
use v5.14;
use Time::HiRes qw(usleep);

use parent 'Device::AtlasScientific';

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
  return $measure;
}

sub options {
  my $self = shift;
  my ($param, $value) = @_;
  if (defined $param && defined $value) {
    $param = uc $param;
    # Validate parameter usage by model.
    die "Invalid parameter '$param'\n" unless ($param eq 'HUM' or $param eq 'T' or $param eq 'DEW');
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