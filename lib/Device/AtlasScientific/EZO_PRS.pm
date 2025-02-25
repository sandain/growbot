package Device::AtlasScientific::EZO_PRS;

use strict;
use warnings;
use utf8;
use v5.14;
use Time::HiRes qw(usleep);

use parent 'Device::AtlasScientific';

sub measure {
  my $self = shift;
  $self->_sendCommand ('R');
  usleep 900000;
  my @response = split ",", $self->_getResponse;
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
  # Format the measurement.
  my $measure = {};
  $measure->{pressure} = {
    value => $response[0],
    unit  => $unit,
    minimum => 0,
    maximum => $max
  };
  return $measure;
}

sub pressureUnit {
  my $self = shift;
  my ($unit) = @_;
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
    $self->_sendCommand ("U," . $unit);
    # Give the device a moment to respond.
    usleep 300000;
  }
  else {
    $self->_sendCommand ("U,?");
    # Give the device a moment to respond.
    usleep 300000;
    (my $u, $unit) = split /,/, $self->_getResponse;
    die "Invalid response from device" unless (uc $u eq "?U");
  }
  return $unit;
}

1;