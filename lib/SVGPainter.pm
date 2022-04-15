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

Device requires Perl version 5.14 or later.

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
use POSIX qw (ceil floor fmod);
use constant DEFAULT_WIDTH  => 1000;
use constant DEFAULT_HEIGHT => 500;
use constant EPSILON => 1e-14;

our @EXPORT_OK = qw ();

# Private methods. Defined below.
my $_loadData;
my $_xCoordinate;
my $_yCoordinate;
my $_xTics;
my $_yTics;
my $_paintXMLTag;
my $_paintSVGOpenTag;
my $_paintSVGCloseTag;
my $_paintTitleTag;
my $_paintDescTag;
my $_paintBackground;
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
    xmlTag => (defined $options{xmlTag} ? $options{xmlTag} : 1),
    indent => (defined $options{indent} ? $options{indent} : 0),
    title => (defined $options{title} ? $options{title} : undef),
    desc => (defined $options{desc} ? $options{desc} : undef),
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
  # Clear any old paint jobs.
  $self->{svg} = "";
  # Start with the xml tag if requested.
  $self->$_paintXMLTag if ($self->{xmlTag});
  # Paint the opening svg tag.
  $self->$_paintSVGOpenTag;
  # Paint the title tag if the title was provided.
  $self->$_paintTitleTag if (defined $self->{title});
  # Paint the desc tag if the desc was provided.
  $self->$_paintDescTag if (defined $self->{desc});
  # Paint the background.
  $self->$_paintBackground;
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
  # Close the svg tag.
  $self->$_paintSVGCloseTag;
  return $self->{svg};
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
      open my $fh, '<', "$folder/$file" or
        die "Unable to open data file $file: $!";
      while (my $line = <$fh>) {
        $line =~ s/[\0\r\n]+//;
        my ($datetime, $measure, $unit) = split /\t/, $line, 3;
        my $measurement;
        eval {
          $measurement = {
            datetime => DateTime::Format::ISO8601->parse_datetime ($datetime),
            measure => $measure,
            unit => $unit
          };
        } or printf STDERR "Error: Unable to parse datetime '%s' for %s.\n%s",
          $datetime, $self->{device}, $@;
        # Add the measurement to the data.
        push @{$self->{data}}, $measurement if (defined $measurement);
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
  my $dst = $start->is_dst;
  for (my $t = $start; DateTime->compare ($t, $end) <= 0; $t += $interval) {
    # Account for Daylight Savings Time if it happened during this interval.
    $t += DateTime::Duration->new (hours => 1) if ($dst and ! $t->is_dst);
    $t -= DateTime::Duration->new (hours => 1) if (! $dst and $t->is_dst);
    # Add the time to the list.
    push @times, $t;
    # Keep track of where the switch to Daylight Savings Time occurs.
    $dst = $t->is_dst;
  }
  my @xtics;
  for (my $i = 0; $i < @times; $i ++) {
    my $loc = $self->$_xCoordinate ($times[$i], $left, $right);
    if (abs (fmod ($i, $labelSkip)) < EPSILON) {
      push @xtics, {
        loc => $loc,
        length => 15,
        label => $times[$i]->strftime ($format),
        background => 1
      };
    }
    elsif (abs (fmod ($i, $longSkip)) < EPSILON) {
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
  my $interval;
  my $labelSkip;
  my $longSkip;
  my @distances = (
    5e6, 1e6,
    5e5, 1e5,
    5e4, 1e4,
    5e3, 1e3,
    5e2, 1e2,
    5e1, 1e1,
    5e0, 1e0,
    5e-1, 1e-1,
    5e-2, 1e-2,
    5e-3, 1e-3,
    5e-4, 1e-4,
    5e-5, 1e-5,
    5e-6, 1e-6
  );
  my $i;
  for ($i = 0; $i < @distances; $i ++) {
    if ($distance >= $distances[$i]) {
      if ($i % 2 == 0) {
        $interval = $distances[$i] / 50;
        $longSkip = $distances[$i] / 10;
        $labelSkip = $distances[$i] / 5;
      }
      else {
        $interval = $distances[$i] / 20;
        $longSkip = $distances[$i] / 10;
        $labelSkip = $distances[$i] / 5;
      }
      last;
    }
  }
  my $start = $self->{ylim}[0];
  $start = ceil ($start / $interval) * $interval
    if (abs fmod ($start, $interval) > EPSILON);
  my $end = $self->{ylim}[1];
  $end = floor ($end / $interval) * $interval
    if (abs fmod ($end, $interval) > EPSILON);
  my @ytics;
  for (my $i = $start; $i <= $end; $i += $interval) {
    my $loc = $self->$_yCoordinate ($i, $top, $bottom);
    my $label = abs (fmod ($i, $labelSkip));
    my $long = abs (fmod ($i, $longSkip));
    if ($label < EPSILON or $labelSkip - $label < EPSILON) {
      push @ytics, {
        loc => $loc,
        length => 15,
        label => $i,
        background => 1
      };
    }
    elsif ($long < EPSILON or $longSkip - $long < EPSILON) {
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

$_paintXMLTag = sub {
  my $self = shift;
  $self->{svg} .= " " x $self->{indent};
  $self->{svg} .= "<?xml";
  $self->{svg} .= " version=\"1.0\"";
  $self->{svg} .= " encoding=\"UTF-8\"";
  $self->{svg} .= " standalone=\"yes\"";
  $self->{svg} .= "?>\n";
};

$_paintSVGOpenTag = sub {
  my $self = shift;
  $self->{svg} .= " " x $self->{indent};
  $self->{svg} .= "<svg";
  $self->{svg} .= " font-family=\"Liberation Sans, sans-serif\"";
  $self->{svg} .= " font-size=\"20\"";
  $self->{svg} .= " xmlns=\"http://www.w3.org/2000/svg\"";
  $self->{svg} .= " width=\"100%%\"";
  $self->{svg} .= " height=\"100%%\"";
  $self->{svg} .= sprintf " viewBox=\"0 0 %s %s\"",
    $self->{width}, $self->{height};
  $self->{svg} .= ">\n";
};

$_paintSVGCloseTag = sub {
  my $self = shift;
  $self->{svg} .= " " x $self->{indent};
  $self->{svg} .= "</svg>";
};

$_paintTitleTag = sub {
  my $self = shift;
  $self->{svg} .= " " x ($self->{indent} + 2);
  $self->{svg} .= "<title id=\"document-title\">";
  $self->{svg} .= $self->{title};
  $self->{svg} .= "</title>\n";
};

$_paintDescTag = sub {
  my $self = shift;
  $self->{svg} .= " " x ($self->{indent} + 2);
  $self->{svg} .= "<desc id=\"document-description\">";
  $self->{svg} .= $self->{desc};
  $self->{svg} .= "</desc>\n";

};

$_paintBackground = sub {
  my $self = shift;
  $self->{svg} .= " " x ($self->{indent} + 2);
  $self->{svg} .= "<g id=\"background\" fill=\"#ffffff\">\n";
  $self->{svg} .= " " x ($self->{indent} + 4);
  $self->{svg} .= sprintf "<path d=\"M 0,0 L 0,%s %s,%s, %s,0 Z\"/>\n",
    $self->{width}, $self->{width}, $self->{height}, $self->{height};
  $self->{svg} .= " " x ($self->{indent} + 2);
  $self->{svg} .= "</g>\n";
};

$_paintXAxis = sub {
  my $self = shift;
  my ($left, $bottom, $right, $top) = @_;
  my @tics = $self->$_xTics ($left, $right);
  $self->{svg} .= " " x ($self->{indent} + 2);
  $self->{svg} .= "<g id=\"x-axis\">\n";
  $self->{svg} .= " " x ($self->{indent} + 4);
  $self->{svg} .= "<g stroke=\"#000000\" stroke-width=\"2\">\n";
  $self->{svg} .= " " x ($self->{indent} + 6);
  $self->{svg} .= sprintf "<path d=\"M %s,%s L %s,%s\"/>\n",
    $left, $bottom + 5, $right, $bottom + 5;
  foreach my $tic (@tics) {
    $self->{svg} .= " " x ($self->{indent} + 6);
    $self->{svg} .= sprintf "<path d=\"M %s,%s L %s,%s\"/>\n",
      $tic->{loc}, $bottom + 5, $tic->{loc}, $bottom + 5 + $tic->{length};
  }
  $self->{svg} .= " " x ($self->{indent} + 4);
  $self->{svg} .= "</g>\n";
  $self->{svg} .= " " x ($self->{indent} + 4);
  $self->{svg} .= "<g";
  $self->{svg} .= " stroke=\"#000000\"";
  $self->{svg} .= " text-anchor=\"end\"";
  $self->{svg} .= " dominant-baseline=\"central\"";
  $self->{svg} .= ">\n";
  foreach my $tic (@tics) {
    next unless (defined $tic->{label});
    $self->{svg} .= " " x ($self->{indent} + 6);
    $self->{svg} .= "<text";
    $self->{svg} .= sprintf " x=\"%s\"", $tic->{loc};
    $self->{svg} .= sprintf " y=\"%s\"", $bottom + 25;
    $self->{svg} .= sprintf " transform=\"rotate(-90 %s,%s)\"",
      $tic->{loc}, $bottom + 25;
    $self->{svg} .= ">";
    $self->{svg} .= $tic->{label};
    $self->{svg} .= "</text>\n";
  }
  $self->{svg} .= " " x ($self->{indent} + 4);
  $self->{svg} .= "</g>\n";
  $self->{svg} .= " " x ($self->{indent} + 4);
  $self->{svg} .= "<g stroke=\"#b7b7b7\" stroke-width=\"2\">\n";
  foreach my $tic (@tics) {
    next unless ($tic->{background});
    $self->{svg} .= " " x ($self->{indent} + 6);
    $self->{svg} .= sprintf "<path d=\"M %s,%s L %s,%s\"/>\n",
      $tic->{loc}, $bottom, $tic->{loc}, $top;
  }
  $self->{svg} .= " " x ($self->{indent} + 4);
  $self->{svg} .= "</g>\n";
  $self->{svg} .= " " x ($self->{indent} + 2);
  $self->{svg} .= "</g>\n";
};

$_paintYAxis = sub {
  my $self = shift;
  my ($left, $bottom, $right, $top) = @_;
  my @tics = $self->$_yTics ($top, $bottom);
  $self->{svg} .= " " x ($self->{indent} + 2);
  $self->{svg} .= "<g id=\"y-axis\">\n";
  $self->{svg} .= " " x ($self->{indent} + 4);
  $self->{svg} .= "<g stroke=\"#000000\" stroke-width=\"2\">\n";
  $self->{svg} .= " " x ($self->{indent} + 6);
  $self->{svg} .= sprintf "<path d=\"M %s,%s L %s,%s\"/>\n",
    $left - 5, $top, $left - 5, $bottom;
  foreach my $tic (@tics) {
    $self->{svg} .= " " x ($self->{indent} + 6);
    $self->{svg} .= sprintf "<path d=\"M %s,%s L %s,%s\"/>\n",
      $left - 5 - $tic->{length}, $tic->{loc}, $left - 5, $tic->{loc};
  }
  $self->{svg} .= " " x ($self->{indent} + 4);
  $self->{svg} .= "</g>\n";
  $self->{svg} .= " " x ($self->{indent} + 4);
  $self->{svg} .= "<g";
  $self->{svg} .= " stroke=\"#000000\"";
  $self->{svg} .= " text-anchor=\"end\"";
  $self->{svg} .= " dominant-baseline=\"central\"";
  $self->{svg} .= ">\n";
  foreach my $tic (@tics) {
    next unless (defined $tic->{label});
    $self->{svg} .= " " x ($self->{indent} + 6);
    $self->{svg} .= sprintf "<text x=\"%s\" y=\"%s\">%s</text>\n",
      $left - 25, $tic->{loc}, $tic->{label};
  }
  $self->{svg} .= " " x ($self->{indent} + 4);
  $self->{svg} .= "</g>\n";
  $self->{svg} .= " " x ($self->{indent} + 4);
  $self->{svg} .= "<g stroke=\"#b7b7b7\" stroke-width=\"2\">\n";
  foreach my $tic (@tics) {
    next unless ($tic->{background});
    $self->{svg} .= " " x ($self->{indent} + 6);
    $self->{svg} .= sprintf "<path d=\"M %s,%s L %s,%s\"/>\n",
      $left, $tic->{loc}, $right, $tic->{loc};
  }
  $self->{svg} .= " " x ($self->{indent} + 4);
  $self->{svg} .= "</g>\n";
  $self->{svg} .= " " x ($self->{indent} + 2);
  $self->{svg} .= "</g>\n";
};

$_paintXAxisLabel = sub {
  my $self = shift;
  my ($x, $y, $label) = @_;
  $self->{svg} .= " " x ($self->{indent} + 2);
  $self->{svg} .= "<g";
  $self->{svg} .= " id=\"x-axis-label\"";
  $self->{svg} .= " stroke=\"#000000\"";
  $self->{svg} .= " text-anchor=\"middle\"";
  $self->{svg} .= ">\n";
  $self->{svg} .= " " x ($self->{indent} + 4);
  $self->{svg} .= sprintf "<text x=\"%s\" y=\"%s\">%s</text>\n",
    $x, $y, $label;
  $self->{svg} .= " " x ($self->{indent} + 2);
  $self->{svg} .= "</g>\n";
};

$_paintYAxisLabel = sub {
  my $self = shift;
  my ($x, $y, $label) = @_;
  $self->{svg} .= " " x ($self->{indent} + 2);
  $self->{svg} .= "<g";
  $self->{svg} .= " id=\"y-axis-label\"";
  $self->{svg} .= " stroke=\"#000000\"";
  $self->{svg} .= " text-anchor=\"middle\"";
  $self->{svg} .= ">\n";
  $self->{svg} .= " " x ($self->{indent} + 4);
  $self->{svg} .=  "<text";
  $self->{svg} .= sprintf " x=\"%s\"", $x;
  $self->{svg} .= sprintf " y=\"%s\"", $y;
  $self->{svg} .= sprintf " transform=\"rotate(-90 %s,%s)\"", $x, $y;
  $self->{svg} .= ">";
  $self->{svg} .= $label;
  $self->{svg} .= "</text>\n";
  $self->{svg} .= " " x ($self->{indent} + 2);
  $self->{svg} .= "</g>\n";
};

$_paintData = sub {
  my $self = shift;
  my ($left, $bottom, $right, $top) = @_;
  $self->{svg} .= " " x ($self->{indent} + 2);
  $self->{svg} .= "<g id=\"data\" fill=\"#ff0000\">\n";
  foreach my $measure (@{$self->{data}}) {
    $self->{svg} .= " " x ($self->{indent} + 4);
    $self->{svg} .= sprintf "<circle cx=\"%s\" cy=\"%s\" r=\"2\"/>\n",
      $self->$_xCoordinate ($measure->{datetime}, $left, $right),
      $self->$_yCoordinate ($measure->{measure}, $top, $bottom);
  }
  $self->{svg} .= " " x ($self->{indent} + 2);
  $self->{svg} .= "</g>\n";
};

1;
