=encoding utf8

=head1 NAME

SVGPainter

=head1 SYNOPSIS



=head1 DESCRIPTION



=head2 Methods

=over 12

=item C<new>

Returns a new SVGPainter.

=item C<close>

Closes the SVGPainter input/output.

=back

=head1 DEPENDENCIES

Device requires Perl version 5.10 or later.

=head1 FEEDBACK

=head2 Reporting Bugs

Report bugs to the GitHub issue tracker at:

L<https://github.com/sandain/growbot/issues>

=head1 AUTHOR

Jason M. Wood L<sandain@hotmail.com|mailto:sandain@hotmail.com>

=head1 COPYRIGHT AND LICENSE

  Copyright (c) 2022 Jason M. Wood

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

package SVGPainter;

use v5.14;
use strict;
use warnings;
use utf8;
use open qw (:std :utf8);
use Exporter qw (import);
use DateTime;
use DateTime::Duration;
use DateTime::Format::ISO8601;
use SVG;
use POSIX qw (ceil floor);
use constant DEFAULT_WIDTH  => 1000;
use constant DEFAULT_HEIGHT => 500;

our @EXPORT_OK = qw ();

# Private methods. Defined below.
my $_loadData;
my $_xCoordinate;
my $_yCoordinate;
my $_xTics;
my $_yTics;
my $_paintBackground;
my $_paintTitle;
my $_paintXAxis;
my $_paintYAxis;
my $_paintXAxisLabel;
my $_paintYAxisLabel;
my $_paintData;

## Public methods.

sub new {
  my $class = shift;
  my %options = @_;
  # Bless ourselves with our class.
  my $self = bless {
    svg => undef,
    data => undef,
    device => (defined $options{device} ? $options{device} : undef),
    type => (defined $options{type} ? $options{type} : undef),
    folder => (defined $options{folder} ? $options{folder} : undef),
    timeZone => (defined $options{timeZone} ? $options{timeZone} : "UTC"),
    title => (defined $options{title} ? $options{title} : undef),
    xlabel => (defined $options{xlabel} ? $options{xlabel} : undef),
    ylabel => (defined $options{ylabel} ? $options{ylabel} : undef),
    width => (defined $options{width} ? $options{width} : DEFAULT_WIDTH),
    height => (defined $options{height} ? $options{height} : DEFAULT_HEIGHT),
    xlim => (defined $options{xlim} ? $options{xlim} : undef),
    ylim => (defined $options{ylim} ? $options{ylim} : undef)
  }, $class;
  # Quit if device, type, or folder not defined.
  my $usage = sprintf
    'Usage: %s->new(device=>$device, type=>$type, folder=>$folder, ...)',
    $class;
  die $usage unless (
    defined $self->{device} &&
    defined $self->{type} &&
    defined $self->{folder}
  );
  # Initialize the SVG document.
  $self->{svg} = SVG->new (
    "width" => $self->{width},
    "height" => $self->{height},
    "font-family" => "Liberation Sans, sans-serif",
    "font-size" => 20,
    -indent => '  '
  );
  # Load measurement data to be plotted.
  $self->$_loadData;
  return $self;
}

sub paint {
  my $self = shift;
  # Calculate the location of the plot area.
  my $plotLeft = int ($self->{width} * 0.08);
  my $plotRight = int ($self->{width} * 0.99);
  my $plotTop = int ($self->{height} * 0.01);
  my $plotBottom = int ($self->{height} * 0.8);
  # Paint the background.
  $self->$_paintBackground;
  # Paint the Title.
  if (defined $self->{title}) {
    $self->$_paintTitle;
    $plotTop = int ($self->{height} * 0.1);
  }
  # Paint the labels for the X and Y axes.
  if (defined $self->{xlabel}) {
    $self->$_paintXAxisLabel (
      int (($plotRight - $plotLeft) / 2) + $plotLeft,
      int ($self->{height} * 0.99),
      $self->{xlabel}
    );
  }
  if (defined $self->{ylabel}) {
    $self->$_paintYAxisLabel (
      int ($self->{width} * 0.02),
      int (($plotBottom - $plotTop) / 2) + $plotTop,
      $self->{ylabel}
    );
    $plotBottom = int ($self->{height} * 0.77);
  }
  # Paint the X and Y axes.
  $self->$_paintXAxis ($plotLeft, $plotBottom, $plotRight, $plotTop);
  $self->$_paintYAxis ($plotLeft, $plotBottom, $plotRight, $plotTop);
  # Paint the data.
  $self->$_paintData ($plotLeft, $plotBottom, $plotRight, $plotTop);
  # Convert the plot to svg.
  my $svg = $self->{svg}->xmlify (@_);
  # Remove comments.
  $svg =~ s/\s+<!--.*?-->\s+/\n/sg;
  return $svg;
}

## Private methods.

$_loadData = sub {
  my $self = shift;
  my $start = $self->{xlim}[0];
  my $end = $self->{xlim}[1];
  die "Unable to calculate start and end dates"
    unless (defined $start && defined $end);
  # Load the data.
  my $folder = sprintf "%s/%s", $self->{folder}, $self->{device};
  opendir my $dh, $folder or die "Unable to open data directory: $!";
  while (my $file = readdir ($dh)) {
    next unless (-f "$folder/$file");
    my $type = $self->{type};
    if ($file =~ /^$type-(\d\d\d\d)-(\d\d)-(\d\d)\.txt/) {
      my $date = DateTime->new (
        year => $1,
        month => $2,
        day => $3,
        time_zone => $self->{timeZone}
      );
      next if (DateTime->compare ($date, $start) == -1);
      next if (DateTime->compare ($date, $end) == 1);
      open my $fh, '<', "$folder/$file" or die "Unable to open data file $file: $!";
      while (my $line = <$fh>) {
        $line =~ s/[\r\n]+//;
        my ($time, $measure, $unit) = split /\t/, $line, 3;
        # Add the measurement to the data.
        $self->{data}{$time} = $measure;
      }
      close $fh;
    }
  }
  close $dh;
};

$_xCoordinate = sub {
  my $self = shift;
  my ($x, $left, $right) = @_;
  my $start = $self->{xlim}[0];
  my $end = $self->{xlim}[1];
  my $xFactor = ($right - $left) / abs ($end->epoch - $start->epoch);
  return ($x->epoch - $start->epoch) * $xFactor + $left;
};

$_yCoordinate = sub {
  my $self = shift;
  my ($y, $top, $bottom) = @_;
  my $yFactor = ($bottom - $top) / abs ($self->{ylim}[1] - $self->{ylim}[0]);
  $bottom - ($y - $self->{ylim}[0]) * $yFactor;
};

$_xTics = sub {
  my $self = shift;
  my ($left, $right) = @_;
  my $start = $self->{xlim}[0];
  my $end = $self->{xlim}[1];
  my $duration = $end - $start;
  my $interval = DateTime::Duration->new (seconds => 1);
  my $format = "%S";
  my $labelSkip = 10;
  my $longSkip = 5;
  if ($duration->years > 1) {
    $interval = DateTime::Duration->new (months => 6);
    $format = "%F";
    $labelSkip = 1;
    $longSkip = 1;
  }
  elsif ($duration->years > 0) {
    $interval = DateTime::Duration->new (months => 1);
    $format = "%F";
    $labelSkip = 1;
    $longSkip = 1;
  }
  elsif ($duration->months > 1) {
    $interval = DateTime::Duration->new (weeks => 1);
    $format = "%F";
    $labelSkip = 1;
    $longSkip = 1;
  }
  elsif ($duration->months > 0) {
    $interval = DateTime::Duration->new (hours => 12);
    $format = "%F";
    $labelSkip = 2;
    $longSkip = 2;
  }
  elsif ($duration->weeks > 1) {
    $interval = DateTime::Duration->new (hours => 6);
    $format = "%F";
    $labelSkip = 4;
    $longSkip = 2;
  }
  elsif ($duration->weeks > 0) {
    $interval = DateTime::Duration->new (hours => 1);
    $format = "%F";
    $labelSkip = 24;
    $longSkip = 12;
  }
  elsif ($duration->days > 1) {
    $interval = DateTime::Duration->new (hours => 1);
    $format = "%F %H:%M";
    $labelSkip = 12;
    $longSkip = 6;
  }
  elsif ($duration->days > 0) {
    $interval = DateTime::Duration->new (minutes => 30);
    $format = "%F %H:%M";
    $labelSkip = 2;
    $longSkip = 2;
  }
  elsif ($duration->hours > 0) {
    $interval = DateTime::Duration->new (minutes => 1);
    $format = "%H:%M:%S";
    $labelSkip = 2;
    $longSkip = 2;
  }
  elsif ($duration->minutes > 0) {
    $interval = DateTime::Duration->new (seconds => 10);
    $format = "%M:%S";
    $labelSkip = 2;
    $longSkip = 2;
  }
  my @times;
  for (my $t = $start; DateTime->compare ($t, $end) <= 0; $t += $interval) {
    push @times, $t;
  }
  my @xtics;
  for (my $i = 0; $i < @times; $i ++) {
    my $loc = $self->$_xCoordinate ($times[$i], $left, $right);
    if ($i % $labelSkip == 0) {
      push @xtics, {
        loc => $loc,
        length => 15,
        label => $times[$i]->strftime ($format),
        background => 1
      };
    }
    elsif ($i % $longSkip == 0) {
      push @xtics, {
        loc => $loc,
        length => 15,
        background => 1
      };
    }
    else {
      push @xtics, {
        loc => $loc,
        length => 10,
        background => 0
      };
    }
  }
  return @xtics;
};

$_yTics = sub {
  my $self = shift;
  my ($top, $bottom) = @_;
  my $distance = abs $self->{ylim}[1] - $self->{ylim}[0];
  my $interval = 1;
  my $labelSkip = 2;
  my $longSkip = 2;
  if ($distance > 500000) {
    $interval = 50000;
    $labelSkip = 100000;
    $longSkip = 50000;
  }
  elsif ($distance > 100000) {
    $interval = 10000;
    $labelSkip = 100000;
    $longSkip = 50000;
  }
  elsif ($distance > 50000) {
    $interval = 5000;
    $labelSkip = 10000;
    $longSkip = 5000;
  }
  elsif ($distance > 10000) {
    $interval = 1000;
    $labelSkip = 10000;
    $longSkip = 5000;
  }
  elsif ($distance > 5000) {
    $interval = 500;
    $labelSkip = 1000;
    $longSkip = 500;
  }
  elsif ($distance > 1000) {
    $interval = 100;
    $labelSkip = 1000;
    $longSkip = 500;
  }
  elsif ($distance > 500) {
    $interval = 50;
    $labelSkip = 100;
    $longSkip = 50;
  }
  elsif ($distance > 100) {
    $interval = 10;
    $labelSkip = 100;
    $longSkip = 50;
  }
  elsif ($distance > 50) {
    $interval = 5;
    $labelSkip = 10;
    $longSkip = 5;
  }
  elsif ($distance > 10) {
    $interval = 1;
    $labelSkip = 10;
    $longSkip = 5;
  }
  my $start = $self->{ylim}[0];
  $start = ceil ($start / $interval) * $interval unless ($start % $interval == 0);
  my $end = $self->{ylim}[1];
  $end = floor ($end / $interval) * $interval unless ($end % $interval == 0);
  my @ytics;
  for (my $i = $start; $i <= $end; $i += $interval) {
    my $loc = $self->$_yCoordinate ($i, $top, $bottom);
    if ($i % $labelSkip == 0) {
      push @ytics, {
        loc => $loc,
        length => 15,
        label => $i,
        background => 1
      };
    }
    elsif ($i % $longSkip == 0) {
      push @ytics, {
        loc => $loc,
        length => 15,
        background => 1
      };
    }
    else {
      push @ytics, {
        loc => $loc,
        length => 10,
        background => 0
      };
    }
  }
  return @ytics;
};

$_paintBackground = sub {
  my $self = shift;
  my $group = $self->{svg}->group (
    "id" => "background",
    "fill" => "#ffffff"
  );
  $group->path (%{$self->{svg}->get_path (
    "x" => [ 0, $self->{width}, $self->{width},                0 ],
    "y" => [ 0,              0, $self->{height}, $self->{height} ],
    -type => "path",
    -closed => 1
  )});
};

$_paintTitle = sub {
  my $self = shift;
  my $title = $self->{svg}->group (
    "id" => "Title",
    "stroke" => "#000000",
    "font-weight" => "bold"
  );
  $title->text (
    "x" => int ($self->{width} * 0.5),
    "y" => int ($self->{height} * 0.05),
    "text-anchor" => "middle",
    -cdata => $self->{title}
  );
};

$_paintXAxis = sub {
  my $self = shift;
  my ($left, $bottom, $right, $top) = @_;
  my @tics = $self->$_xTics ($left, $right);
  my $xAxis = $self->{svg}->group (
    "id" => "xAxis"
  );
  my $lineGroup = $xAxis->group (
    "stroke" => "#000000",
    "stroke-width" => "2"
  );
  my $labelGroup = $xAxis->group (
    "stroke" => "#000000",
    "text-anchor" => "end",
    "dominant-baseline" => "central"
  );
  my $plotGroup = $xAxis->group (
    "stroke" => "#b7b7b7",
    "stroke-width" => "2"
  );
  $lineGroup->path (%{$self->{svg}->get_path (
    "x" => [ $left, $right ],
    "y" => [ $bottom + 5, $bottom + 5 ],
    -type => "path",
    -closed => 0
  )});
  foreach my $tic (@tics) {
    $lineGroup->path (%{$self->{svg}->get_path (
      "x" => [ $tic->{loc}, $tic->{loc} ],
      "y" => [ $bottom + 5, $bottom + 5 + $tic->{length} ], 
      -type => "path",
      -closed => 0
    )});
    $plotGroup->path (%{$self->{svg}->get_path (
      "x" => [ $tic->{loc}, $tic->{loc} ],
      "y" => [ $bottom, $top ], 
      -type => "path",
      -closed => 0
    )}) if ($tic->{background});
    next unless (defined $tic->{label});
    $labelGroup->text (
      "x" => $tic->{loc}, "y" => $bottom + 25,
      "transform" => sprintf ("rotate(-90 %s,%s)", $tic->{loc}, $bottom + 25),
      -cdata => $tic->{label}
    );
  }
};

$_paintYAxis = sub {
  my $self = shift;
  my ($left, $bottom, $right, $top) = @_;
  my @tics = $self->$_yTics ($top, $bottom);
  my $yAxis = $self->{svg}->group (
    "id" => "yAxis"
  );
  my $lineGroup = $yAxis->group (
    "stroke" => "#000000",
    "stroke-width" => "2"
  );
  my $labelGroup = $yAxis->group (
    "stroke" => "#000000",
  );
  my $plotGroup = $yAxis->group (
    "stroke" => "#b7b7b7",
    "stroke-width" => "2"
  );
  $lineGroup->path (%{$self->{svg}->get_path (
    "x" => [ $left - 5, $left - 5 ],
    "y" => [ $top, $bottom ],
    -type => "path",
    -closed => 0
  )});
  foreach my $tic (@tics) {
    $lineGroup->path (%{$self->{svg}->get_path (
      "x" => [ $left - 5 - $tic->{length}, $left - 5 ],
      "y" => [ $tic->{loc}, $tic->{loc} ],
      -type => "path",
      -closed => 0
    )});
    $plotGroup->path (%{$self->{svg}->get_path (
      "x" => [ $left, $right ],
      "y" => [ $tic->{loc}, $tic->{loc} ],
      -type => "path",
      -closed => 0
    )}) if ($tic->{background});
    next unless (defined $tic->{label});
    $labelGroup->text (
      "x" => $left - 25, "y" => $tic->{loc},
      "text-anchor" => "end",
      "dominant-baseline" => "central",
      -cdata => $tic->{label}
    );
  }
};

$_paintXAxisLabel = sub {
  my $self = shift;
  my ($x, $y, $label) = @_;
  my $labelGroup = $self->{svg}->group (
    "stroke" => "#000000",
  );
  $labelGroup->text (
    "x" => $x, "y" => $y,
    "text-anchor" => "middle",
    -cdata => $label
  );
};

$_paintYAxisLabel = sub {
  my $self = shift;
  my ($x, $y, $label) = @_;
  my $labelGroup = $self->{svg}->group (
    "stroke" => "#000000",
  );
  $labelGroup->text (
    "x" => $x, "y" => $y,
    "text-anchor" => "middle",
    "transform" => sprintf ("rotate(-90 %s,%s)", $x, $y),
    -cdata => $label
  );
};

$_paintData = sub {
  my $self = shift;
  my ($left, $bottom, $right, $top) = @_;
  my $data = $self->{svg}->group (
    "id" => "Data",
    "fill" => "#ff0000"
  );
  foreach my $time (keys %{$self->{data}}) {
    my $xtime = DateTime::Format::ISO8601->parse_datetime ($time);
    $data->circle (
      cx => $self->$_xCoordinate ($xtime, $left, $right),
      cy => $self->$_yCoordinate ($self->{data}{$time}, $top, $bottom),
      r => 2
    );
  }
};

1;
