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
use Fcntl qw (:flock);
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
use Device::V4L2;
use GaugePlot;
use ScatterPlot;

my %SUPPORTED_DEVICES = (
  "EZO_RTD" => {
    "Driver" => "AtlasScientific",
    "Actions" => {
      "Measure" => {
        "Type" => {
          "temperature" => {
            "Name" => "Temperature",
            "Unit" => "°C",
            "Format" => "%d",
            "Minimum" => 0,
            "Maximum" => 50
          }
        },
        "Interval" => 30
      },
      "Calibrate" => {
      },
      "HistoryPlot" => {
        "Interval" => 60
      },
      "GaugePlot" => {
        "Interval" => 30
      }
    },
    "Dashboard" => [
      "temperature"
    ],
    "DefaultActions" => [ "Measure", "HistoryPlot", "GaugePlot" ]
  },
  "EZO_PH" => {
    "Driver" => "AtlasScientific",
    "Actions" => {
      "Measure" => {
        "Type" => {
          "ph" => {
            "Name" => "pH",
            "Unit" => "",
            "Format" => "%.2f",
            "Minimum" => 0.001,
            "Maximum" => 14
          }
        },
        "Interval" => 30
      },
      "Calibrate" => {
      },
      "HistoryPlot" => {
        "Interval" => 60
      },
      "GaugePlot" => {
        "Interval" => 30
      }
    },
    "Dashboard" => [
      "ph"
    ],
    "DefaultActions" => [ "Measure", "HistoryPlot", "GaugePlot" ]
  },
  "EZO_EC" => {
    "Driver" => "AtlasScientific",
    "Actions" => {
      "Measure" => {
        "Type" => {
          "conductivity" => {
            "Name" => "EC",
            "Unit" => "μS/cm",
            "Format" => "%d",
            "Minimum" => 0.07,
            "Maximum" => 500000
          },
          "total_dissolved_solids" => {
            "Name" => "Total Dissolved Solids",
            "Unit" => "PPM",
            "Format" => "%d",
            "Minimum" => 0,
            "Maximum" => 500000
          },
          "salinity" => {
            "Name" => "Salinity",
            "Unit" => "PSU",
            "Format" => "%.1f",
            "Minimum" => 0.00,
            "Maximum" => 42.00
          },
          "specific_gravity" => {
            "Name" => "Specific Gravity",
            "Unit" => "",
            "Format" => "%.1f",
            "Minimum" => 1.00,
            "Maximum" => 1.30
          }
        },
        "Interval" => 30
      },
      "Calibrate" => {
      },
      "HistoryPlot" => {
        "Interval" => 60
      },
      "GaugePlot" => {
        "Interval" => 30
      }
    },
    "Dashboard" => [
      "conductivity", "total_dissolved_solids", "salinity", "specific_gravity"
    ],
    "DefaultActions" => [ "Measure", "HistoryPlot", "GaugePlot" ]
  },
  "EZO_ORP" => {
    "Driver" => "AtlasScientific",
    "Actions" => {
      "Measure" => {
        "Type" => {
          "oxidation_reduction_potential" => {
            "Name" => "ORP",
            "Unit" => "mV",
            "Format" => "%.1f",
            "Minimum" => -1019.9,
            "Maximum" => 1019.9
          }
        },
        "Interval" => 30
      },
      "Calibrate" => {
      },
      "HistoryPlot" => {
        "Interval" => 60
      },
      "GaugePlot" => {
        "Interval" => 30
      }
    },
    "Dashboard" => [
      "oxidation_reduction_potential"
    ],
    "DefaultActions" => [ "Measure", "HistoryPlot", "GaugePlot" ]
  },
  "EZO_DO" => {
    "Driver" => "AtlasScientific",
    "Actions" => {
      "Measure" => {
        "Type" => {
          "dissolved_oxygen" => {
            "Name" => "DO",
            "Unit" => "mg/L",
            "Format" => "%.1f",
            "Minimum" => 0.01,
            "Maximum" => 100
          },
          "saturation" => {
            "Name" => "Saturation",
            "Unit" => "%",
            "Format" => "%.1f",
            "Minimum" => 0.1,
            "Maximum" => 400
          }
        },
        "Interval" => 30
      },
      "Calibrate" => {
      },
      "HistoryPlot" => {
        "Interval" => 60
      },
      "GaugePlot" => {
        "Interval" => 30
      }
    },
    "Dashboard" => [
      "dissolved_oxygen", "saturation"
    ],
    "DefaultActions" => [ "Measure", "HistoryPlot", "GaugePlot" ]
  },
  "BME280" => {
    "Driver" => "Bosch280",
    "Actions" => {
      "Measure" => {
        "Type" => {
          "temperature" => {
            "Name" => "Temperature",
            "Unit" => "°C",
            "Format" => "%d",
            "Minimum" => 0,
            "Maximum" => 50
          },
          "pressure" => {
            "Name" => "Pressure",
            "Unit" => "hPa",
            "Format" => "%d",
            "Minimum" => 300,
            "Maximum" => 1100
          },
          "humidity" => {
            "Name" => "Humidity",
            "Unit" => "%",
            "Format" => "%d",
            "Minimum" => 0,
            "Maximum" => 100
          }
        },
        "Interval" => 30
      },
      "HistoryPlot" => {
        "Interval" => 60
      },
      "GaugePlot" => {
        "Interval" => 30
      }
    },
    "Dashboard" => [
      "temperature", "pressure", "humidity"
    ],
    "DefaultActions" => [ "Measure", "HistoryPlot", "GaugePlot" ]
  },
  "BMP280" => {
    "Driver" => "Bosch280",
    "Actions" => {
      "Measure" => {
        "Type" => {
          "temperature" => {
            "Name" => "Temperature",
            "Unit" => "°C",
            "Format" => "%d",
            "Minimum" => 0,
            "Maximum" => 50
          },
          "pressure" => {
            "Name" => "Pressure",
            "Unit" => "hPa",
            "Format" => "%d",
            "Minimum" => 300,
            "Maximum" => 1100
          }
        },
        "Interval" => 30
      },
      "HistoryPlot" => {
        "Interval" => 60
      },
      "GaugePlot" => {
        "Interval" => 30
      }
    },
    "Dashboard" => [
      "temperature", "pressure"
    ],
    "DefaultActions" => [ "Measure", "HistoryPlot", "GaugePlot" ]
  },
  "CPU" => {
    "Driver" => "lm_sensors",
    "Actions" => {
      "Measure" => {
        "Type" => {
          "temperature" => {
            "Name" => "Temperature",
            "Unit" => "°C",
            "Format" => "%d",
            "Minimum" => 0,
            "Maximum" => 100
          }
        },
        "Interval" => 30
      },
      "HistoryPlot" => {
        "Interval" => 60
      },
      "GaugePlot" => {
        "Interval" => 30
      }
    },
    "Dashboard" => [
      "temperature"
    ],
    "DefaultActions" => [ "Measure", "HistoryPlot", "GaugePlot" ]
  },
  "V4L2" => {
    "Driver" => "V4L2",
    "Actions" => {
      "Capture" => {
        "Interval" => 60
      }
    },
    "Dashboard" => [ ],
    "DefaultActions" => [ "Capture" ]
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
my $_deviceCapture;
my $_deviceMeasure;
my $_deviceHistoryPlot;
my $_deviceGaugePlot;
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
    flock $fh, LOCK_EX;
    printf $fh "";
    $fh->close;
    # Create the worker thread for the device.
    eval {
      $self->{threads}{$device} = $self->$_startDevice ($device);
    } or printf STDERR "Error: Unable to start child process for %s.\n%s",
      $device, $@;
  }
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

sub enqueueAction {
  my $self = shift;
  my ($device, $command, $datetime, $priority) = @_;
  open my $fh, '>>', $self->{queue}{$device} or
    die "Unable to write to $device queue: $!";
  flock $fh, LOCK_EX;
  printf $fh "%s\t%s\t%d\n", $command, $datetime->rfc3339, $priority;
  $fh->close;
}

## Private methods.

$_deviceCalibrate = sub {
  my $self = shift;
  my ($device) = @_;

};

$_deviceCapture = sub {
  my $self = shift;
  my ($device) = @_;
  my $folder = $self->{config}{DataFolder} . '/' . $device;
  my $now = DateTime->now (time_zone => $self->{config}{TimeZone});
  my $file = sprintf "%s/%s.jpg", $folder, $now->rfc3339;
  $self->{devices}->{$device}->capture ($file);
};

$_deviceMeasure = sub {
  my $self = shift;
  my ($device) = @_;
  my $folder = $self->{config}{DataFolder} . '/' . $device;
  my $measure = $self->{devices}{$device}->measure;
  my $now = DateTime->now (time_zone => $self->{config}{TimeZone});
  foreach my $type (sort keys %{$measure}) {
    # Append the measurement to the current day's file.
    my $dayfile = sprintf "%s/%s-%s.txt", $folder, $type, $now->date;
    open my $dayfh, '>>', $dayfile or die "Can't output sensor data: $!\n";
    printf $dayfh "%s\t%s\t%s\n",
      $now->rfc3339, $measure->{$type}{value}, $measure->{$type}{unit};
    $dayfh->close;
    # Write the measurement to the most recent measure file.
    my $recentfile = sprintf "%s/%s.txt", $folder, $type;
    open my $recentfh, '>', $recentfile or die "Can't output sensor data: $!\n";
    printf $recentfh "%s\t%s\t%s\n",
      $now->rfc3339, $measure->{$type}{value}, $measure->{$type}{unit};
    $recentfh->close;
  }
};

$_deviceHistoryPlot = sub {
  my $self = shift;
  my ($device) = @_;
  my $config = $self->{config}{Devices}{$device};
  my $folder = $self->{config}{DataFolder} . '/' . $device;
  my $measure = $self->{devices}{$device}->measure;
  my $now = DateTime->now (time_zone => $self->{config}{TimeZone});
  foreach my $type (sort keys %{$measure}) {
    # Determine the default name to be used for the title.
    my $name = $type;
    $name = $config->{Actions}{Measure}{Type}{$type}{Name}
      if (defined $config->{Actions}{Measure}{Type}{$type}{Name});
    # Create a description for the figure.
    my $desc = sprintf "%s data from device %s", $name, $device;
    # Determine the limits for the X axis.
    my $start = $now - DateTime::Duration->new (months => 1);
#    my $start = $now - DateTime::Duration->new (weeks => 1);
#    my $start = $now - DateTime::Duration->new (days => 1);
    my $end = $now + DateTime::Duration->new (days => 1);
    $start->set (hour => 0, minute => 0, second => 0, nanosecond => 0);
    $end->set (hour => 0, minute => 0, second => 0, nanosecond => 0);
    # Determine the limits for the Y axis.
    my $min = $measure->{$type}{minimum};
    my $max = $measure->{$type}{maximum};
    $min = $config->{Actions}{Measure}{Type}{$type}{Minimum}
      if (defined $config->{Actions}{Measure}{Type}{$type}{Minimum});
    $max = $config->{Actions}{Measure}{Type}{$type}{Maximum}
      if (defined $config->{Actions}{Measure}{Type}{$type}{Maximum});
    # Determine the warning limits.
    my $warnMin = $min;
    my $warnMax = $max;
    $warnMin = $config->{Actions}{Measure}{Type}{$type}{WarningMinimum}
      if (defined $config->{Actions}{Measure}{Type}{$type}{WarningMinimum});
    $warnMax = $config->{Actions}{Measure}{Type}{$type}{WarningMaximum}
      if (defined $config->{Actions}{Measure}{Type}{$type}{WarningMaximum});
    # Determine the error limits.
    my $errorMin = $min;
    my $errorMax = $max;
    $errorMin = $config->{Actions}{Measure}{Type}{$type}{ErrorMinimum}
      if (defined $config->{Actions}{Measure}{Type}{$type}{ErrorMinimum});
    $errorMax = $config->{Actions}{Measure}{Type}{$type}{ErrorMaximum}
      if (defined $config->{Actions}{Measure}{Type}{$type}{ErrorMaximum});
    # Determine the unit used for the Y axis.
    my $unit = $measure->{$type}{unit};
    $unit = $config->{Actions}{Measure}{Type}{$type}{Unit}
      if (defined $config->{Actions}{Measure}{Type}{$type}{Unit});
    # Create the y axis label
    my $ylabel = $name;
    $ylabel .= sprintf " (%s)", $unit if (defined $unit && $unit ne "");
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
      ylim => [ $min, $max ],
      warnLim => [ $warnMin, $warnMax ],
      errorLim => [ $errorMin, $errorMax ]
    );
    my $file = sprintf "%s/%s-history", $folder, $type;
    # Write the svg data to a temporary file.
    open my $fh, '>', $file . ".tmp" or die "Can't output sensor data: $!\n";
    print $fh $painter->paint;
    $fh->close;
    # Rename the temporary file.
    unlink $file . ".svg" if (-e $file . ".svg");
    rename $file . ".tmp", $file . ".svg";
  }
};

$_deviceGaugePlot = sub {
  my $self = shift;
  my ($device) = @_;
  my $config = $self->{config}{Devices}{$device};
  my $folder = $self->{config}{DataFolder} . '/' . $device;
  my $measure = $self->{devices}{$device}->measure;
  foreach my $type (sort keys %{$measure}) {
    # Determine the name to be used for the title.
    my $name = $type;
    $name = $config->{Actions}{Measure}{Type}{$type}{Name}
      if (defined $config->{Actions}{Measure}{Type}{$type}{Name});
    # Create a description for the figure.
    my $desc = sprintf "%s data from device %s", $name, $device;
    # Determine the limits.
    my $min = $measure->{$type}{minimum};
    my $max = $measure->{$type}{maximum};
    $min = $config->{Actions}{Measure}{Type}{$type}{Minimum}
      if (defined $config->{Actions}{Measure}{Type}{$type}{Minimum});
    $max = $config->{Actions}{Measure}{Type}{$type}{Maximum}
      if (defined $config->{Actions}{Measure}{Type}{$type}{Maximum});
    # Determine the warning limits.
    my $warnMin = $min;
    my $warnMax = $max;
    $warnMin = $config->{Actions}{Measure}{Type}{$type}{WarningMinimum}
      if (defined $config->{Actions}{Measure}{Type}{$type}{WarningMinimum});
    $warnMax = $config->{Actions}{Measure}{Type}{$type}{WarningMaximum}
      if (defined $config->{Actions}{Measure}{Type}{$type}{WarningMaximum});
    # Determine the error limits.
    my $errorMin = $min;
    my $errorMax = $max;
    $errorMin = $config->{Actions}{Measure}{Type}{$type}{ErrorMinimum}
      if (defined $config->{Actions}{Measure}{Type}{$type}{ErrorMinimum});
    $errorMax = $config->{Actions}{Measure}{Type}{$type}{ErrorMaximum}
      if (defined $config->{Actions}{Measure}{Type}{$type}{ErrorMaximum});
    # Determine the unit.
    my $unit = $measure->{$type}{unit};
    $unit = $config->{Actions}{Measure}{Type}{$type}{Unit}
      if (defined $config->{Actions}{Measure}{Type}{$type}{Unit});
    # Determine the format of the measured value.
    my $format = "%s";
    $format = $config->{Actions}{Measure}{Type}{$type}{Format}
      if (defined $config->{Actions}{Measure}{Type}{$type}{Format});
    my $painter = GaugePlot->new (
      title => $name,
      desc => $desc,
      value => sprintf ($format, $measure->{$type}{value}),
      unit => $unit,
      lim => [$min,$max],
      warnLim => [$warnMin,$warnMax],
      errorLim => [$errorMin,$errorMax]
    );
    my $file = sprintf "%s/%s-gauge", $folder, $type;
    # Write the svg data to a temporary file.
    open my $fh, '>', $file . ".tmp" or die "Can't output sensor data: $!\n";
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
  open my $fh, '<', $self->{configFile} or
    die "Error: Unable to open configuration file: $!";
  my $c = from_json (join "", <$fh>);
  $fh->close;
  # Copy values from the provided configuration.
  $config->{AppName} = $c->{AppName} if (defined $c->{AppName});
  $config->{Version} = $c->{Version} if (defined $c->{Version});
  $config->{TimeZone} = $c->{TimeZone} if (defined $c->{TimeZone});
  $config->{DataFolder} = $c->{DataFolder} if (defined $c->{DataFolder});
  if (defined $c->{Devices}) {
    foreach my $device (keys %{$c->{Devices}}) {
      my $d = $c->{Devices}{$device};
      unless (defined $d->{Type} && defined $SUPPORTED_DEVICES{$d->{Type}}) {
        printf STDERR "Error: Unsupported device type %s\n", $d->{Type};
        next;
      }
      $config->{Devices}{$device} = $SUPPORTED_DEVICES{$d->{Type}};
      $config->{Devices}{$device}{Type} = $d->{Type};
      $config->{Devices}{$device}{Options} = $d->{Options}
        if (defined $d->{Options});
      $config->{Devices}{$device}{Dashboard} = $d->{Dashboard}
        if (defined $d->{Dashboard} && ref $d->{Dashboard} eq 'ARRAY');
      if (defined $d->{Limits}) {
        foreach my $type (keys %{$d->{Limits}}) {
          foreach my $value (keys %{$d->{Limits}{$type}}) {
            $config->{Devices}{$device}{Actions}{Measure}{Type}{$type}{$value} =
              $d->{Limits}{$type}{$value};
          }
        }
      }
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
    my $running = 1;
    while ($running) {
      my @queue;
      # Open the queue file for read and write.
      open my $fh, '+<', $self->{queue}{$device} or
        die "Unable to read from $device queue: $!";
      flock $fh, LOCK_EX;
      while (my $line = <$fh>) {
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
      truncate $fh, 0;
      $fh->close;
      # Make sure there is something in the queue.
      next unless (@queue > 0);
      # Sort the queue based on priority then time.
      @queue = sort {
        $b->{priority} <=> $a->{priority} ||
        DateTime->compare ($a->{datetime}, $b->{datetime})
      } @queue;
      # Get the current time.
      my $now = DateTime->now (time_zone => $self->{config}{TimeZone});
      # Check if it is time to run the first action in the queue.
      if (DateTime->compare ($now, $queue[0]->{datetime}) >= 0) {
        # Grab the next action in the queue.
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
        if ($action->{command} eq 'Calibrate') {
          $self->$_deviceCalibrate ($device);
        }
        if ($action->{command} eq 'Capture') {
          $self->$_deviceCapture ($device);
        }
        if ($action->{command} eq 'Measure') {
          $self->$_deviceMeasure ($device);
        }
        if ($action->{command} eq 'HistoryPlot') {
          $self->$_deviceHistoryPlot ($device);
        }
        if ($action->{command} eq 'GaugePlot') {
          $self->$_deviceGaugePlot ($device);
        }
        # Enqueue the action again if needed.
        if (defined $config->{Actions}{$action->{command}}{Interval}) {
          my $interval = DateTime::Duration->new (
            seconds => $config->{Actions}{$action->{command}}{Interval}
          );
          $action->{datetime} = $now + $interval;
          push @queue, $action;
        }
      }
      # Write any actions in the queue back to the queue file.
      while (@queue > 0) {
        my $action = shift @queue;
        $self->enqueueAction (
          $device,
          $action->{command},
          $action->{datetime},
          $action->{priority}
        );
      }
    }
  });
  return $child->start;
};

1;
