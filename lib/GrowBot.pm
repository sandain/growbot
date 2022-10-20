=encoding utf8

=head1 NAME

GrowBot

=head1 SYNOPSIS



=head1 DESCRIPTION



=head2 Methods

=over 12

=item C<new>

Returns a new GrowBot.

=item C<close>

Closes the GrowBot device input/output.

=back

=head1 DEPENDENCIES

Device requires Perl version 5.14 or later.

=head1 FEEDBACK

=head2 Reporting Bugs

Report bugs to the GitHub issue tracker at:

L<https://github.com/sandain/growbot/issues>

=head1 AUTHOR

Jason M. Wood L<sandain@hotmail.com|mailto:sandain@hotmail.com>

=head1 COPYRIGHT AND LICENSE

  Copyright (c) 2020-2022 Jason M. Wood

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

package GrowBot;

use v5.14;
use strict;
use warnings;
use utf8;
use open qw (:std :utf8);
use Exporter qw (import);
use Mojo::JSON qw (from_json);
use Child;
use Cwd;
use DateTime;
use File::Path qw (make_path);
use File::Spec;

use Device::Bosch280;
use Device::AtlasScientific;
use Device::lm_sensors;
use ScatterPlot;

my %SUPPORTED_DEVICES = (
  "EZO_RTD" => {
    "Driver" => "AtlasScientific",
    "Actions" => {
      "Measure" => {
        "temperature" => {
          "Name" => "Temperature",
          "Unit" => "°C",
          "Minimum" => 0,
          "Maximum" => 50
        }
      }
    },
    "Dashboard" => [
      "temperature"
    ],
    "DefaultAction" => "Measure",
    "Interval" => 30
  },
  "EZO_PH" => {
    "Driver" => "AtlasScientific",
    "Actions" => {
      "Measure" => {
        "ph" => {
          "Name" => "pH",
          "Unit" => "",
          "Minimum" => 0.001,
          "Maximum" => 14
        }
      }
    },
    "Dashboard" => [
      "ph"
    ],
    "DefaultAction" => "Measure",
    "Interval" => 30
  },
  "EZO_EC" => {
    "Driver" => "AtlasScientific",
    "Actions" => {
      "Measure" => {
        "conductivity" => {
          "Name" => "Electrical Conductivity",
          "Unit" => "μS/cm",
          "Minimum" => 0.07,
          "Maximum" => 500000
        },
        "total_dissolved_solids" => {
          "Name" => "Total Dissolved Solids",
          "Unit" => "PPM",
          "Minimum" => 0,
          "Maximum" => 500000
        },
        "salinity" => {
          "Name" => "Salinity",
          "Unit" => "PSU",
          "Minimum" => 0.00,
          "Maximum" => 42.00
        },
        "specific_gravity" => {
          "Name" => "Specific Gravity",
          "Unit" => "",
          "Minimum" => 1.00,
          "Maximum" => 1.30
        },
      }
    },
    "Dashboard" => [
      "conductivity", "total_dissolved_solids", "salinity", "specific_gravity"
    ],
    "DefaultAction" => "Measure",
    "Interval" => 30
  },
  "EZO_ORP" => {
    "Driver" => "AtlasScientific",
    "Actions" => {
      "Measure" => {
        "oxidation_reduction_potential" => {
          "Name" => "Oxidation-reduction potential",
          "Unit" => "mV",
          "Minimum" => -1019.9,
          "Maximum" => 1019.9
        }
      }
    },
    "Dashboard" => [
      "oxidation_reduction_potential"
    ],
    "DefaultAction" => "Measure",
    "Interval" => 30
  },
  "EZO_DO" => {
    "Driver" => "AtlasScientific",
    "Actions" => {
      "Measure" => {
        "dissolved_oxygen" => {
          "Name" => "Dissolved Oxygen",
          "Unit" => "mg/L",
          "Minimum" => 0.01,
          "Maximum" => 100
        },
        "saturation" => {
          "Name" => "Saturation",
          "Unit" => "%",
          "Minimum" => 0.1,
          "Maximum" => 400
        }
      }
    },
    "Dashboard" => [
      "dissolved_oxygen", "saturation"
    ],
    "DefaultAction" => "Measure",
    "Interval" => 30
  },
  "BME280" => {
    "Driver" => "Bosch280",
    "Actions" => {
      "Measure" => {
        "temperature" => {
          "Name" => "Temperature",
          "Unit" => "°C",
          "Minimum" => 0,
          "Maximum" => 50
        },
        "pressure" => {
          "Name" => "Pressure",
          "Unit" => "hPa",
          "Minimum" => 300,
          "Maximum" => 1100
        },
        "humidity" => {
          "Name" => "Humidity",
          "Unit" => "%",
          "Minimum" => 0,
          "Maximum" => 100
        }
      }
    },
    "Dashboard" => [
      "temperature", "pressure", "humidity"
    ],
    "DefaultAction" => "Measure",
    "Interval" => 30
  },
  "BMP280" => {
    "Driver" => "Bosch280",
    "Actions" => {
      "Measure" => {
        "temperature" => {
          "Name" => "Temperature",
          "Unit" => "°C",
          "Minimum" => 0,
          "Maximum" => 50
        },
        "pressure" => {
          "Name" => "Pressure",
          "Unit" => "hPa",
          "Minimum" => 300,
          "Maximum" => 1100
        }
      }
    },
    "Dashboard" => [
      "temperature", "pressure"
    ],
    "DefaultAction" => "Measure",
    "Interval" => 30
  },
  "CPU" => {
    "Driver" => "lm_sensors",
    "Actions" => {
      "Measure" => {
        "temperature" => {
          "Name" => "Temperature",
          "Unit" => "°C",
          "Minimum" => 0,
          "Maximum" => 100
        }
      }
    },
    "Dashboard" => [
      "temperature"
    ],
    "DefaultAction" => "Measure",
    "Interval" => 30
  }
);

my $default_config = {
  "AppName"    => "GrowBot",
  "Version"    => 0.2,
  "TimeZone"   => "UTC",
  "DataFolder" => getcwd . "/data",
  "Devices"    => { }
};

our @EXPORT_OK = qw ();

# Private methods. Defined below.
my $_deviceCalibrate;
my $_deviceMeasure;
my $_loadConfig;
my $_startDevice;


## Public methods.

sub new {
  my $class = shift;
  die "Usage: $class->new ('config.json')" unless (@_ == 1);
  my ($configFile) = @_;
  # Bless ourselves with our class.
  my $self = bless {
    config => undef,
    devices => undef,
    threads => undef,
    queue => undef
  }, $class;
  # Load the configuration file.
  $self->{configFile} = $configFile;
  $self->{config} = $self->$_loadConfig ();
  return $self;
}

sub close {
  my $self = shift;
  foreach my $device (keys %{$self->{devices}}) {
    $self->{devices}{$device}->close;
    unlink $self->{queue}{$device};
  }
}

sub wait {
  my $self = shift;
  foreach my $device (keys %{$self->{devices}}) {
    $self->{threads}{$device}->wait;
  }
}

sub start {
  my $self = shift;
  foreach my $device (keys %{$self->{config}{Devices}}) {
    my $config = $self->{config}{Devices}{$device};
    # Load the device driver.
    eval {
      my $type = sprintf "Device::%s", $config->{Driver};
      $self->{devices}{$device} = $type->new (@{$config->{Options}});
    } or printf STDERR "Error: Unable to initialize device %s.\n%s",
      $device, $@;
    # Setup the action queue for the device.
    $self->{queue}{$device} =
      sprintf "%s/growbot_%s", File::Spec->tmpdir, $device;
    open my $fh, '>', $self->{queue}{$device} or
      die "Unable to write to $device queue: $!";
    printf $fh "";
    $fh->close;
    # Create the worker thread for the device.
    eval {
      $self->{threads}{$device} = $self->$_startDevice ($device);
    } or printf STDERR "Error: Unable to start child process for %s.\n%s",
      $device, $@;
  }



  # Each device gets its own thread
  # Each device has an action queue
  # If the action queue is empty, the default action is run
  # The default action could be nothing.



}

sub name {
  my $self = shift;
  return $self->{config}{AppName};
}

sub version {
  my $self = shift;
  return $self->{config}{Version};
}

sub dataFolder {
  my $self = shift;
  return $self->{config}{DataFolder};
}

sub timeZone {
  my $self = shift;
  return $self->{config}{TimeZone};
}

sub devices {
  my $self = shift;
  return keys %{$self->{config}->{Devices}};
}

sub enqueueCommand {
  my $self = shift;
  my ($device, $command, $datetime, $priority) = @_;
  open my $queueFH, '>>', $self->{queue}{$device} or
      die "Unable to write to $device queue: $!";
  printf $queueFH "%s\t%s\t%d\n", $command, $datetime->rfc3339, $priority;
  $queueFH->close;
}

## Private methods.

$_deviceCalibrate = sub {
  my $self = shift;
  my ($device) = @_;

};

$_deviceMeasure = sub {
  my $self = shift;
  my ($device, $action) = @_;
  my $config = $self->{config}{Devices}{$device};
  my $folder = $self->{config}{DataFolder} . '/' . $device;
  my $measure = $self->{devices}{$device}->measure;
  my $now = DateTime->now (time_zone => $self->{config}{TimeZone});
  foreach my $type (sort keys %{$measure}) {
    my $fh;
    my $file;
    # Append the measurement to the current day's file.
    $file = sprintf "%s/%s-%s.txt", $folder, $type, $now->date;
    open $fh, '>>', $file or die "Can't output sensor data: $!\n";
    printf $fh "%s\t%s\t%s\n", 
      $now->rfc3339, $measure->{$type}{value}, $measure->{$type}{unit};
    $fh->close;
    # Write the measurement to the most recent measure file.
    $file = sprintf "%s/%s.txt", $folder, $type;
    open $fh, '>', $file or die "Can't output sensor data: $!\n";
    printf $fh "%s\t%s\t%s\n", 
      $now->rfc3339, $measure->{$type}{value}, $measure->{$type}{unit};
    $fh->close;

    # Determine the default limits for the X axis.
    my $start = $now - DateTime::Duration->new (months => 1);
#    my $start = $now - DateTime::Duration->new (weeks => 1);
#    my $start = $now - DateTime::Duration->new (days => 1);
    my $end = $now + DateTime::Duration->new (days => 1);
    $start->set (hour => 0, minute => 0, second => 0, nanosecond => 0);
    $end->set (hour => 0, minute => 0, second => 0, nanosecond => 0);
    # Determine the default limits for the Y axis.
    my $min = $measure->{$type}{minimum};
    my $max = $measure->{$type}{maximum};
    # Determine the unit used for the Y axis.
    my $unit = $measure->{$type}{unit};
    # Determine the default name to be used for the title.
    my $name = $type;
    # Override defaults with configuration options.
    $min = $config->{Actions}{Measure}{$type}{Minimum}
      if (defined $config->{Actions}{Measure}{$type}{Minimum});
    $max = $config->{Actions}{Measure}{$type}{Maximum}
      if (defined $config->{Actions}{Measure}{$type}{Maximum});
    $unit = $config->{Actions}{Measure}{$type}{Unit}
      if (defined $config->{Actions}{Measure}{$type}{Unit});
    $name = $config->{Actions}{Measure}{$type}{Name}
      if (defined $config->{Actions}{Measure}{$type}{Name});
    # Create the y axis label
    my $ylabel = $name;
    $ylabel .= sprintf " (%s)", $unit if (defined $unit && $unit ne "");
    # Create a description for the figure.
    my $desc = sprintf "%s data from device %s", $name, $device;
    # Create a SVG containing all of the measurement data.
    my $painter = ScatterPlot->new (
      width => 1500,
      height => 750,
      title => $name,
      desc => $desc,
      ylabel => $ylabel,
      xlabel => "Date",
      folder => $self->{config}{DataFolder},
      device => $device,
      type => $type,
      timeZone => $self->{config}{TimeZone},
      xmlTag => 0,
      xlim => [ $start, $end ],
      ylim => [ $min, $max ]
    );
    $file = sprintf "%s/%s", $folder, $type;
    # Write the svg data to a temporary file.
    open $fh, '>', $file . ".tmp" or die "Can't output sensor data: $!\n";
    print $fh $painter->paint;
    $fh->close;
    # Rename the temporary file.
    unlink $file . ".svg" if (-e $file . ".svg");
    rename $file . ".tmp", $file . ".svg";
  }
};

$_loadConfig = sub {
  my $self = shift;
  # Load the default configuration from the DATA section.
  my $config = $default_config;
  # Load the configuration in the provided file.
  open my $configIO, '<', $self->{configFile} or
    die "Error: Unable to open configuration file: $!";
  my $c = from_json (join "", <$configIO>);
  $configIO->close;
  # Copy values from the provided configuration.
  $config->{AppName} = $c->{AppName} if (defined $c->{AppName});
  $config->{Version} = $c->{Version} if (defined $c->{Version});
  $config->{TimeZone} = $c->{TimeZone} if (defined $c->{TimeZone});
  $config->{DataFolder} = $c->{DataFolder} if (defined $c->{DataFolder});
  if (defined $c->{Devices}) {
    foreach my $device (keys %{$c->{Devices}}) {
      my $d = $c->{Devices}{$device};
      die sprintf "Error: Unsupported device type %s", $d->{Type}
        unless (defined $d->{Type} && defined $SUPPORTED_DEVICES{$d->{Type}});
        $config->{Devices}{$device} = $SUPPORTED_DEVICES{$d->{Type}};
        $config->{Devices}{$device}{Type} = $d->{Type};
        $config->{Devices}{$device}{Options} = $d->{Options}
          if (defined $d->{Options});
        $config->{Devices}{$device}{Dashboard} = $d->{Dashboard}
          if (defined $d->{Dashboard} && ref $d->{Dashboard} eq 'ARRAY');
    }
  }
  return $config;
};

$_startDevice = sub {
  my $self = shift;
  my ($device) = @_;
  my $config = $self->{config}{Devices}{$device};
  make_path ($self->{config}{DataFolder} . '/' . $device);
  my $child = Child->new (sub {
    open my $queueFH, '<', $self->{queue}{$device} or
      die "Unable to read from $device queue: $!";
    my @queue;
    my $running = 1;
    while ($running) {
      # Load the queue.
      while (my $line = <$queueFH>) {
        $line =~ s/[\r\n]+//;
        my ($command, $datetime, $priority) = split "\t", $line;
        my $action;
        eval {
          $action = {
            command => $command,
            datetime => DateTime::Format::ISO8601->parse_datetime ($datetime),
            priority => $priority
          };
        } or printf STDERR "Error: Unable to parse datetime '%s' for %s.\n%s",
          $datetime, $device, $@;
        # Enqueue the action.
        push @queue, $action if (defined $action);
      }
      # Make sure the queue has actions.
      if (@queue > 0) {
        # Sort the queue based on priority then time.
        @queue = sort {
          $b->{priority} <=> $a->{priority} ||
          DateTime->compare ($a->{datetime}, $b->{datetime})
        } @queue;
        # Get the current time.
        my $now = DateTime->now (time_zone => $self->{config}{TimeZone});
        # Check if it is time to run the first action in the queue.
        if (DateTime->compare ($now, $queue[0]->{datetime}) >= 0) {
          # Pop off an action from the queue.
          my $action = shift @queue;
          # Respond to the close action.
          if ($action->{command} eq 'Close') {
            $running = 0;
            last;
          }
          # Make sure the action exists in the configuration.
          die "Unknown action $action->{command}"
            unless (defined $config->{Actions}{$action->{command}});
          # Respond to the action based on its type.
          if ($action->{command} eq 'Measure') {
            $self->$_deviceMeasure ($device, $action->{command});
          }
          if ($action->{command} eq 'Calibrate') {
            $self->$_deviceCalibrate ($device);
          }
          # Enqueue the action again if needed.
          if (defined $config->{Interval}) {
            my $interval = DateTime::Duration->new (
              seconds => $config->{Interval}
            );
            $self->enqueueCommand (
              $device,
              $action->{command},
              $now + $interval,
              0
            );
          }
        }
      }
    }
    $queueFH->close;
  });
  return $child->start;
};

1;
