=encoding utf8

=head1 NAME

GrowBot::App

=head1 SYNOPSIS

  use GrowBot::App;
  GrowBot::App->start;

=head1 DESCRIPTION

GrowBot::App is the Mojolicious application class for GrowBot. It initializes
the device manager, registers hooks and helpers, and defines the application
routes.

=head2 Methods

=over 12

=item C<new>

Returns a new GrowBot.

=item C<startup>

Initializes the GrowBot application. Called automatically by Mojolicious.

=back

=head1 DEPENDENCIES

GrowBot::App requires Perl version 5.14 or later, in addition to Mojolicious.

=head1 FEEDBACK

=head2 Reporting Bugs

Report bugs to the GitHub issue tracker at:
  https://github.com/sandain/growbot/issues

=head1 AUTHOR - Jason M. Wood

Email sandain@hotmail.com

=head1 COPYRIGHT AND LICENSE

  Copyright (c) 2026  Jason M. Wood <sandain@hotmail.com>

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

package GrowBot::App;

use open qw (:std :utf8);
use Mojo::Base 'Mojolicious', -signatures;
use Mojo::JSON qw (to_json);
use DateTime;
use DateTime::Format::ISO8601;

use GrowBot::Model::DeviceManager;

has 'device_manager';

# Private methods. Defined below.
my $_registerHelpers;
my $_registerRoutes;

## Public methods.

sub startup {
  my $self = shift;

  # Create a new GrowBot::Model::DeviceManager using the configuration file.
  $self->device_manager (GrowBot::Model::DeviceManager->new ('config.json'));

  # Hook: set the Server response header globally rather than per-route.
  $self->hook (before_dispatch => sub {
    my $c = shift;
    $c->res->headers->server ($self->device_manager->name);
  });

  # Remove the default Mojolicious favicon.
  delete $self->static->extra->{'favicon.ico'};

  # Register helpers.
  $self->$_registerHelpers;

  # Set up routes.
  $self->$_registerRoutes;
}

## Private methods.

=head2 Private Methods

=head3 _registerHelpers

  Register Mojolicious helpers used by templates.

=cut

$_registerHelpers = sub {
  my $self = shift;
  my $dm = $self->device_manager;

  # Helper: gb_config
  # Return configuration information.
  $self->helper ('gb_config' => sub {
    return $dm->{config};
  });

  # Helper: gb_devices
  # Return a sorted list of device names.
  $self->helper ('gb_devices' => sub {
    return sort $dm->devices;
  });

  # Helper: current
  # Return current measurement for a given device and measurement type.
  $self->helper ('current' => sub {
    my ($c, $device, $measurement, $type, $indent) = @_;
    # Sanity check arguments.
    return unless (grep { $_ eq $device } $dm->devices);
    return unless (defined $dm->{config}{Devices}{$device}{Actions}{Measure}{Type}{$measurement});
    return unless (grep { $_ eq $type } ("txt", "json", "html", "svg"));
    my $filepath = sprintf "%s/%s/%s-gauge.%s",
      $dm->dataFolder, $device, $measurement, $type;
    return unless (-s $filepath);
    open my $fh, '<', $filepath or die "Can't load gauge data: $!";
    my $data = join " " x $indent, <$fh>;
    close $fh;
    return $data;
  });

  # Helper: history
  # Return measurement history for a given device and measurement type.
  $self->helper ('history' => sub {
    my ($c, $device, $measurement, $type, $indent) = @_;
    # Sanity check arguments.
    return unless (grep { $_ eq $device } $dm->devices);
    return unless (defined $dm->{config}{Devices}{$device}{Actions}{Measure}{Type}{$measurement});
    return unless (grep { $_ eq $type } ("txt", "json", "html", "svg"));
    my $filepath = sprintf "%s/%s/%s-history.%s",
      $dm->dataFolder, $device, $measurement, $type;
    return unless (-s $filepath);
    open my $fh, '<', $filepath or die "Can't load history data: $!";
    my $data = join " " x $indent, <$fh>;
    close $fh;
    return $data;
  });

  # Helper: device
  # Return device data as a JSON string.
  $self->helper ('device' => sub {
    my ($c, $name) = @_;
    my $config = $dm->{config};
    my $folder  = sprintf "%s/%s", $dm->dataFolder, $name;
    my $data = {
      "name"      => $config->{Devices}{$name}{Name},
      "driver"    => $config->{Devices}{$name}{Driver},
      "type"      => $config->{Devices}{$name}{Type},
      "dashboard" => $config->{Devices}{$name}{Dashboard}
    };
    if (defined $config->{Devices}{$name}{Actions}{Measure}{Type}) {
      foreach my $m (keys %{$config->{Devices}{$name}{Actions}{Measure}{Type}}) {
        open my $fh, '<', "$folder/$m.txt" or
          die "Can't open file $folder/$m.txt: $!";
        my $measure = join "", <$fh>;
        close $fh;
        $measure =~ s/[\r\n]+//;
        my @measure = split /\t/, $measure;
        my ($date, $time);
        eval {
          my $dt = DateTime::Format::ISO8601->parse_datetime ($measure[0]);
          $dt->set_time_zone ($config->{TimeZone});
          $date = $dt->ymd;
          $time = $dt->hms;
        } or printf STDERR "Error: Unable to parse datetime '%s'.\n%s",
          $measure[0], $@;
        $data->{measurements}{$m} = {
          "type"    => $config->{Devices}{$name}{Actions}{Measure}{Type}{$m}{Name},
          "date"    => $date,
          "time"    => $time,
          "measure" => $measure[1],
          "unit"    => ($measure[2] // "")
        };
      }
    }
    return to_json $data;
  });
};

=head3 _registerRoutes

  Set up the application routes.

=cut

$_registerRoutes = sub {
  my $self = shift;
  my $r = $self->routes;
  $r->namespaces (['GrowBot::Controller']);

  # Dashboard.
  $r->get (
    '/',
    [format => ['html']]
  )->to ('Dashboard#index', format => 'html');

  # Device page.
  $r->get (
    '/device/:name',
    [format => ['html', 'json']]
  )->to ('Device#show', format => 'html');

  # Current status of a device.
  $r->get (
    '/device/:name/current',
    [format => ['html', 'json']]
  )->to ('Device#current', format => 'html');

  # Current status of a device action type.
  $r->get (
    '/device/:name/current/:type',
    [format => ['html', 'json', 'svg', 'txt']]
  )->to ('Device#current_type', format => 'html');

  # History for a device.
  $r->get (
    '/device/:name/history',
    [format => ['html', 'json']]
  )->to ('Device#history', format => 'html');

  # History for a device action type.
  $r->get (
    '/device/:name/history/:type',
    [format => ['html', 'json', 'svg', 'txt']]
  )->to ('Device#history_type', format => 'html');
};

1;
