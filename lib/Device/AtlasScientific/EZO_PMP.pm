package Device::AtlasScientific::EZO_PMP;

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
  usleep 300000;
  # Return indicating that the device is calibrated.
  return 1;
}

sub dispense {
  my $self = shift;
  my ($amount, $time) = @_;
  # Send the dispense command.
  if (defined $amount && defined $time) {
    die "Invalid amount to dispense" unless ($self->_is_number ($amount));
    die "Invalid time to dispense" unless ($self->_is_number ($time));
    $self->_sendCommand ("D," . $amount . "," . $time);
    # Give the device a moment to respond.
    usleep 300000;
  }
  elsif (defined $amount) {
    die "Invalid amount to dispense" unless (
      $amount eq '*'  || $amount eq '-*' || $self->_is_number ($amount)
    );
    $self->_sendCommand ("D," . $amount);
    # Give the device a moment to respond.
    usleep 300000;
  }
  else {
    $self->_sendCommand ("D,?");
    # Give the device a moment to respond.
    usleep 300000;
    (my $d, $amount, my $status) = split /,/, $self->_getResponse;
    die "Invalid response from device" unless (uc $d eq "?D");
    return ($amount, $status);
  }
}

sub dispenseConstant {
  my $self = shift;
  my ($rate, $time) = @_;
  # Send the dispense constant command.
  if (defined $rate && defined $time) {
    die "Invalid rate to dispense" unless ($self->_is_number ($rate));
    die "Invalid time to dispense" unless (
      $time eq '*' || $self->_is_number ($time)
    );
    $self->_sendCommand ("DC," . $rate . "," . $time);
    # Give the device a moment to respond.
    usleep 300000;
  }
  else {
    $self->_sendCommand ("DC,?");
    # Give the device a moment to respond.
    usleep 300000;
    (my $dc, $rate) = split /,/, $self->_getResponse;
    die "Invalid response from device" unless (uc $dc eq "?maxrate");
    return $rate;
  }
}

sub dispensePause {
  my $self = shift;
  # Send the dispense pause command.
  $self->_sendCommand ("P");
  # Give the device a moment to respond.
  usleep 300000;
}

sub dispensePauseStatus {
  my $self = shift;
  # Send the dispense pause status command.
  $self->_sendCommand ("P,?");
  # Give the device a moment to respond.
  usleep 300000;
  my ($p, $status) = split /,/, $self->_getResponse;
  die "Invalid response from device" unless (uc $p eq "?P");
  return $status;
}

sub dispenseStartup {
  my $self = shift;
  my ($arg) = @_;
  # Send the dispense startup command.
  if (defined $arg) {
    die "Invalid argument to dispense startup" unless (
      $arg eq 'off' || $self->_is_number ($arg)
    );
    $self->_sendCommand ("Dstart," . $arg);
    # Give the device a moment to respond.
    usleep 300000;
  }
  else {
    $self->_sendCommand ("Dstart,?");
    # Give the device a moment to respond.
    usleep 300000;
    my ($dstart, $rate) = split /,/, $self->_getResponse;
    die "Invalid response from device" unless (uc $dstart eq "?Dstart");
    return $rate;
  }
}

sub dispenseStop {
  my $self = shift;
  # Send the dispense stop command.
  $self->_sendCommand ("X");
  # Give the device a moment to respond.
  usleep 300000;
}

sub dispensedAbsoluteTotalVolume {
  my $self = shift;
  # Send the absolute total volume dispensed command.
  $self->_sendCommand ("ATV,?");
  # Give the device a moment to respond.
  usleep 300000;
  my ($tv, $volume) = split /,/, $self->_getResponse;
  die "Invalid response from device" unless (uc $tv eq "?ATV");
  return $volume;
}

sub dispensedTotalVolume {
  my $self = shift;
  # Send the total volume dispensed command.
  $self->_sendCommand ("TV,?");
  # Give the device a moment to respond.
  usleep 300000;
  my ($tv, $volume) = split /,/, $self->_getResponse;
  die "Invalid response from device" unless (uc $tv eq "?TV");
  return $volume;
}

sub dispensedVolumeClear {
  my $self = shift;
  # Send the total volume dispensed clear command.
  $self->_sendCommand ("clear");
  # Give the device a moment to respond.
  usleep 300000;
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
  return $measure;
}

sub options {
  my $self = shift;
  my ($param, $value) = @_;
  if (defined $param && defined $value) {
    $param = uc $param;
    # Validate parameter usage by model.
    die "Invalid parameter '$param'\n" unless ($param eq 'V' or $param eq 'TV' or $param eq 'ATV');
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

sub pumpVoltage {
  my $self = shift;
  # Send the pump voltage command.
  $self->_sendCommand ("PV,?");
  # Give the device a moment to respond.
  usleep 300000;
  my ($pv, $voltage) = split /,/, $self->_getResponse;
  die "Invalid response from device" unless (uc $pv eq "?PV");
  return $voltage;
}

1;