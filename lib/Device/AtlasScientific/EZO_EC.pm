package Device::AtlasScientific::EZO_EC;

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
    defined $arg and
    uc $arg eq 'LOW' or uc $arg eq 'HIGH' or $arg eq 'DRY' or
    $self->_is_number ($arg)
  );
  die "Invalid calibration point: $value" if (
    (uc $arg eq 'LOW' or uc $arg eq 'HIGH') and
    defined $value and $self->_is_number ($value)
  );
  # Send the desired calibration command.
  $self->_sendCommand ("Cal,dry") if (uc $arg eq 'DRY');
  $self->_sendCommand ("Cal,low," . $value) if (uc $arg eq 'LOW');
  $self->_sendCommand ("Cal,high," . $value) if (uc $arg eq 'HIGH');
  $self->_sendCommand ("Cal," . $arg) if ($self->_is_number ($arg));
  # Give the device a moment to respond.
  usleep 600000;
  # Return indicating that the device is calibrated.
  return 1;
}

sub calibrationExport {
  my $self = shift;
  # Make sure the firmware supports this feature on this device.
  $self->_require_firmware ("2.10");
  # First ask for the calibration string info.
  $self->_sendCommand ("Export,?");
  # Give the device a moment to respond.
  usleep 300000;
  my ($e, $num, $bytes) = split /,/, $self->_getResponse;
  # The number of calibration strings is off by one when the number of bytes is
  # divisible by 12.
  $num -- if ($bytes % 12 == 0);
  die "Invalid response from device" unless (uc $e eq "?EXPORT");
  # Ask for each calibration string.
  my @calibration;
  for (my $i = 0; $i < $num; $i ++) {
    $self->_sendCommand ("Export");
    # Give the device a moment to respond.
    usleep 300000;
    my $response = $self->_getResponse;
    push @calibration, $response;
  }
  $self->_sendCommand ("Export");
  # Give the device a moment to respond.
  usleep 300000;
  die "Error exporting calibration" unless (uc $self->_getResponse eq "*DONE");
  my $b = eval join '+', map { length $_ } @calibration;
  die "Invalid calibration" unless ($bytes == $b);
  return @calibration;
}

sub calibrationImport {
  my $self = shift;
  my @calibration = @_;
  # Make sure the firmware supports this feature on this device.
  $self->_require_firmware ("2.10");
  # Import the calibration.
  foreach my $cal (@calibration) {
    $self->_sendCommand ("Import," . $cal);
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
  $command = "X" if ($self->_test_version ("1.08"));
  # Send the factory reset command.
  $self->_sendCommand ($command);
  # Give the device a moment to reboot.
  usleep 1000000;
}

sub find {
  my $self = shift;
  # Make sure the firmware supports this feature on this device.
  $self->_require_firmware ("2.10");
  # Send the find command.
  $self->_sendCommand ("Find");
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
  return $measure;
}

sub options {
  my $self = shift;
  my ($param, $value) = @_;
  if (defined $param && defined $value) {
    $param = uc $param;
    # Validate parameter usage by model.
    die "Invalid parameter '$param'\n"      
      unless ($param eq 'EC' or $param eq 'TDS' or $param eq 'S' or $param eq 'SG');
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

sub plock {
  my $self = shift;
  my ($plock) = @_;
  # Make sure the firmware supports this feature on this device.
  $self->_require_firmware ("1.95");
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

1;