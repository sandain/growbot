=encoding utf8

=head1 NAME

GaugePlot

=head1 SYNOPSIS



=head1 DESCRIPTION



=head2 Methods

=over 12

=item C<new>

Returns a new GaugePlot.

=item C<paint>

Paints the GaugePlot and returns it as SVG.

=back

=head1 DEPENDENCIES

GaugePlot requires Perl version 5.14 or later.

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

package GaugePlot;

use v5.14;
use strict;
use warnings;
use utf8;
use open qw (:std :utf8);
use Exporter qw (import);
use POSIX qw (ceil floor);

use constant DEFAULT_WIDTH  => 1000;
use constant DEFAULT_HEIGHT => 600;
use constant DEFAULT_FONT_FAMILY => "Liberation Sans, Arial, sans-serif";
use constant DEFAULT_FONT_SIZE => 90;
use constant DEFAULT_ERROR_COLOR => "#d3212c";
use constant DEFAULT_WARN_COLOR => "#ff980e";
use constant DEFAULT_GOOD_COLOR => "#069c56";
use constant DEFAULT_TEXT_COLOR => "#000000";
use constant DEFAULT_DECORATION_COLOR => "#000000";
use constant DEFAULT_BACKGROUND_COLOR => "#ffffff";
use constant PI => 3.14159265359;

our @EXPORT_OK = qw ();

# Private methods. Defined below.
my $_paintXMLTag;
my $_paintSVGOpenTag;
my $_paintSVGCloseTag;
my $_paintTitleTag;
my $_paintDescTag;
my $_paintBackground;
my $_paintGauge;
my $_scalePath;
my $_calculateRotation;
my $_calculateXY;

## Public methods.

sub new {
  my $class = shift;
  my %options = @_;
  # Bless ourselves with our class.
  my $self = bless {
    svg => undef,
    xmlTag => (defined $options{xmlTag} ? $options{xmlTag} : 1),
    title => (defined $options{title} ? $options{title} : undef),
    desc => (defined $options{desc} ? $options{desc} : undef),
    width => (defined $options{width} ? $options{width} : DEFAULT_WIDTH),
    height => (defined $options{height} ? $options{height} : DEFAULT_HEIGHT),
    fontFamily => (defined $options{fontFamily} ? $options{fontFamily} : DEFAULT_FONT_FAMILY),
    fontSize => (defined $options{fontSize} ? $options{fontSize} : DEFAULT_FONT_SIZE),
    value => (defined $options{value} ? $options{value} : undef),
    unit => (defined $options{unit} ? $options{unit} : undef),
    lim => (defined $options{lim} ? $options{lim} : []),
    errorLim => (defined $options{errorLim} ? $options{errorLim} : []),
    warnLim => (defined $options{warnLim} ? $options{warnLim} : []),
    errorColor => (defined $options{errorColor} ? $options{errorColor} : DEFAULT_ERROR_COLOR),
    warnColor => (defined $options{warnColor} ? $options{warnColor} : DEFAULT_WARN_COLOR),
    goodColor => (defined $options{goodColor} ? $options{goodColor} : DEFAULT_GOOD_COLOR),
    textColor => (defined $options{textColor} ? $options{textColor} : DEFAULT_TEXT_COLOR),
    decorationColor => (defined $options{decorationColor} ? $options{decorationColor} : DEFAULT_DECORATION_COLOR),
    backgroundColor => (defined $options{backgroundColor} ? $options{backgroundColor} : DEFAULT_BACKGROUND_COLOR)
  }, $class;
  # Quit if value or lim not defined.
  my $usage = sprintf
    'Usage: %s->new(value=>23, lim=>[0,100], ...)',
    $class;
  warn sprintf "Value undefined\n%s", $usage
    unless (defined $self->{value});
  warn sprintf "Limits undefined\n%s", $usage
    unless (defined $self->{lim}[0] && defined $self->{lim}[1]);
  warn sprintf "Limits malformed: (%s, %s)\n%s",
    $self->{lim}[0], $self->{lim}[1],
    $usage
    unless ($self->{lim}[0] < $self->{lim}[1]);
#  warn sprintf "Value less than minimum\n%s", $usage
#    unless ($self->{value} >= $self->{lim}[0]);
#  warn sprintf "Value more than maximum\n%s", $usage
#    unless ($self->{value} <= $self->{lim}[1]);
  if (defined $self->{warnLim}[0] || defined $self->{warnLim}[1]) {
    warn sprintf "Warn limits missing\n%s", $usage
      unless (defined $self->{warnLim}[0]);
    warn sprintf "Warn limits missing\n%s", $usage
      unless (defined $self->{warnLim}[1]);
    warn sprintf "Warn limits malformed: (%s, %s)\n%s",
      $self->{warnLim}[0], $self->{warnLim}[1],
      $usage
      unless ($self->{warnLim}[0] < $self->{warnLim}[1]);
    warn sprintf "Warn limits outside limits range (%s, %s): (%s, %s)\n%s",
      $self->{lim}[0], $self->{lim}[1],
      $self->{warnLim}[0], $self->{warnLim}[1],
      $usage
      unless ($self->{warnLim}[0] >= $self->{lim}[0]);
    warn sprintf "Warn limits outside limits range (%s, %s): (%s, %s)\n%s",
      $self->{lim}[0], $self->{lim}[1],
      $self->{warnLim}[0], $self->{warnLim}[1],
      $usage
      unless ($self->{warnLim}[0] < $self->{lim}[1]);
    warn sprintf "Warn limits outside limits range (%s, %s): (%s, %s)\n%s",
      $self->{lim}[0], $self->{lim}[1],
      $self->{warnLim}[0], $self->{warnLim}[1],
      $usage
      unless ($self->{warnLim}[1] > $self->{lim}[0]);
    warn sprintf "Warn limits outside limits range (%s, %s): (%s, %s)\n%s",
      $self->{lim}[0], $self->{lim}[1],
      $self->{warnLim}[0], $self->{warnLim}[1],
      $usage
      unless ($self->{warnLim}[1] <= $self->{lim}[1]);
  }
  if (defined $self->{errorLim}[0] || defined $self->{errorLim}[1]) {
    warn sprintf "Error limits missing\n%s", $usage
      unless (defined $self->{errorLim}[0]);
    warn sprintf "Error limits missing\n%s", $usage
      unless (defined $self->{errorLim}[1]);
    warn sprintf "Error limits malformed: (%s, %s)\n%s",
      $self->{errorLim}[0], $self->{errorLim}[1],
      $usage
      unless ($self->{errorLim}[0] < $self->{errorLim}[1]);
    warn sprintf "Error limits outside limits range (%s, %s): (%s, %s)\n%s",
      $self->{lim}[0], $self->{lim}[1],
      $self->{errorLim}[0], $self->{errorLim}[1],
      $usage
      unless ($self->{errorLim}[0] >= $self->{lim}[0]);
    warn sprintf "Error limits outside limits range (%s, %s): (%s, %s)\n%s",
      $self->{lim}[0], $self->{lim}[1],
      $self->{errorLim}[0], $self->{errorLim}[1],
      unless ($self->{errorLim}[0] < $self->{lim}[1]);
    warn sprintf "Error limits outside limits range (%s, %s): (%s, %s)\n%s",
      $self->{lim}[0], $self->{lim}[1],
      $self->{errorLim}[0], $self->{errorLim}[1],
      unless ($self->{errorLim}[1] > $self->{lim}[0]);
    warn sprintf "Error limits outside limits range (%s, %s): (%s, %s)\n%s",
      $self->{lim}[0], $self->{lim}[1],
      $self->{errorLim}[0], $self->{errorLim}[1],
      unless ($self->{errorLim}[1] <= $self->{lim}[1]);
  }
  return $self;
}

sub paint {
  my $self = shift;
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
  # Paint the gauge.
  $self->$_paintGauge;
  # Close the svg tag.
  $self->$_paintSVGCloseTag;
  return $self->{svg};
}

## Private methods.

$_paintXMLTag = sub {
  my $self = shift;
  $self->{svg} .= "<?xml";
  $self->{svg} .= " version=\"1.0\"";
  $self->{svg} .= " encoding=\"UTF-8\"";
  $self->{svg} .= " standalone=\"yes\"";
  $self->{svg} .= "?>\n";
};

$_paintSVGOpenTag = sub {
  my $self = shift;
  $self->{svg} .= "<svg";
  $self->{svg} .= sprintf " font-family=\"%s\"", $self->{fontFamily};
  $self->{svg} .= sprintf " font-size=\"%s\"", $self->{fontSize};
  $self->{svg} .= " xmlns=\"http://www.w3.org/2000/svg\"";
  $self->{svg} .= " width=\"100%\"";
  $self->{svg} .= " height=\"100%\"";
  $self->{svg} .= sprintf " viewBox=\"0 0 %s %s\"",
    $self->{width}, $self->{height};
  $self->{svg} .= ">\n";
};

$_paintSVGCloseTag = sub {
  my $self = shift;
  $self->{svg} .= "</svg>";
};

$_paintTitleTag = sub {
  my $self = shift;
  $self->{svg} .= " " x 2;
  $self->{svg} .= "<title id=\"document-title\">";
  $self->{svg} .= $self->{title};
  $self->{svg} .= "</title>\n";
};

$_paintDescTag = sub {
  my $self = shift;
  $self->{svg} .= " " x 2;
  $self->{svg} .= "<desc id=\"document-description\">";
  $self->{svg} .= $self->{desc};
  $self->{svg} .= "</desc>\n";
};

$_paintBackground = sub {
  my $self = shift;
  $self->{svg} .= " " x 2;
  $self->{svg} .= sprintf "<g fill=\"%s\">\n", $self->{backgroundColor};
  $self->{svg} .= " " x 4;
  $self->{svg} .= "<path id=\"background\"";
  $self->{svg} .= sprintf " d=\"M 0,0 L 0,%s %s,%s %s,0 Z\"",
    $self->{height}, $self->{width}, $self->{height}, $self->{width};
  $self->{svg} .= "/>\n";
  $self->{svg} .= " " x 2;
  $self->{svg} .= "</g>\n";
};

$_paintGauge = sub {
  my $self = shift;
  my $r = floor $self->{width} * 0.475;  # outline radius 475
  my $cx = floor $self->{width} * 0.5;   # center x 500
  my $cy = ceil $self->{height} * 0.833; # center y 500
  my $d = floor $self->{height} * 0.125; # delta 75
  my $gr = floor $self->{width} * 0.02; # gauge radius 20
  # Start the gauge group.
  $self->{svg} .= " " x 2;
  $self->{svg} .= sprintf "<g stroke=\"%s\">\n", $self->{decorationColor};
  # Add the gauge outline.
  $self->{svg} .= " " x 4;
  $self->{svg} .= "<g";
  $self->{svg} .= " fill=\"none\"";
  $self->{svg} .= " stroke-width=\"20\"";
  $self->{svg} .= ">\n";
  $self->{svg} .= " " x 6;
  $self->{svg} .= "<path id=\"gauge-outline\"";
  $self->{svg} .= sprintf " d=\"M %s,%s A %s %s 0 0 1 %s,%s L %s,%s L %s,%s Z\"",
    $cx - $r, $cy, $r, $r, $cx + $r, $cy, $cx + $r, $cy + $d, $cx - $r, $cy + $d;
  $self->{svg} .= "/>\n";
  $self->{svg} .= " " x 4;
  $self->{svg} .= "</g>\n";
  # Add the gauge scale.
  $self->{svg} .= " " x 4;
  $self->{svg} .= "<g";
  $self->{svg} .= " stroke-width=\"10\"";
  $self->{svg} .= ">\n";
  # Draw the scale.
  my $wl = $self->{lim}[0];
  my $wh = $self->{lim}[1];
  my $el = $self->{lim}[0];
  my $eh = $self->{lim}[1];
  $wl = $self->{warnLim}[0] if (defined $self->{warnLim}[0]);
  $wh = $self->{warnLim}[1] if (defined $self->{warnLim}[1]);
  $el = $self->{errorLim}[0] if (defined $self->{errorLim}[0]);
  $eh = $self->{errorLim}[1] if (defined $self->{errorLim}[1]);
  $wl = $el if ($wl < $el);
  $wh = $eh if ($wh > $eh);
  $self->{svg} .= " " x 6;
  $self->{svg} .= "<path id=\"gauge-scale-good\"";
  $self->{svg} .= sprintf " d=\"%s\"", $self->$_scalePath ($wl, $wh, $cx, $cy);
  $self->{svg} .= sprintf " fill=\"%s\"", $self->{goodColor};
  $self->{svg} .= "/>\n";
  if (defined $self->{warnLim}[0]) {
    $self->{svg} .= " " x 6;
    $self->{svg} .= "<path id=\"gauge-scale-warn\"";
    $self->{svg} .= sprintf " d=\"%s\"", join " ",
      $self->$_scalePath ($el, $wl, $cx, $cy),
      $self->$_scalePath ($wh, $eh, $cx, $cy);
    $self->{svg} .= sprintf " fill=\"%s\"", $self->{warnColor};
    $self->{svg} .= "/>\n";
  }
  if (defined $self->{errorLim}[0]) {
    $self->{svg} .= " " x 6;
    $self->{svg} .= "<path id=\"gauge-scale-error\"";
    $self->{svg} .= sprintf " d=\"%s\"", join " ",
      $self->$_scalePath ($self->{lim}[0], $el, $cx, $cy),
      $self->$_scalePath ($eh, $self->{lim}[1], $cx, $cy);
    $self->{svg} .= sprintf " fill=\"%s\"", $self->{errorColor};
    $self->{svg} .= "/>\n";
  }
  $self->{svg} .= " " x 4;
  $self->{svg} .= "</g>\n";
  # Add the gauge.
  $self->{svg} .= " " x 4;
  $self->{svg} .= "<g";
  $self->{svg} .= sprintf " fill=\"%s\"", $self->{decorationColor};
  $self->{svg} .= " stroke-width=\"10\"";
  $self->{svg} .= " stroke-linejoin=\"round\"";
  $self->{svg} .= ">\n";
  $self->{svg} .= " " x 6;
  $self->{svg} .= "<path id=\"gauge\"";
  $self->{svg} .= sprintf " d=\"M %s,%s A %s %s 0 0 1 %s,%s L %s,%s Z\"",
    $cx - $gr, $cy - $r, $gr, $gr, $cx + $gr, $cy - $r, $cx, ceil 0.463 * $r;
  $self->{svg} .= sprintf " transform=\"rotate(%s %s,%s)\"", 
    90 - $self->$_calculateRotation ($self->{value}), $cx, $cy;
  $self->{svg} .= "/>\n";
  $self->{svg} .= " " x 4;
  $self->{svg} .= "</g>\n";
  # Add text labels for the gauge value and title.
  $self->{svg} .= " " x 4;
  $self->{svg} .= "<g";
  $self->{svg} .= " text-anchor=\"middle\"";
  $self->{svg} .= sprintf " fill=\"%s\"", $self->{textColor};
  $self->{svg} .= ">\n";
  $self->{svg} .= " " x 6;
  $self->{svg} .= "<text id=\"gauge-value\"";
  $self->{svg} .= sprintf " x=\"%s\"", $cx;
  $self->{svg} .= sprintf " y=\"%s\"", $cy - 100;
  $self->{svg} .= ">";
  $self->{svg} .= sprintf "%s", $self->{value};
  $self->{svg} .= sprintf " %s", $self->{unit} if (defined $self->{unit});
  $self->{svg} .= "</text>\n";
  if (defined $self->{title}) {
    $self->{svg} .= " " x 6;
    $self->{svg} .= "<text id=\"gauge-title\"";
    $self->{svg} .= sprintf " x=\"%s\"", $cx;
    $self->{svg} .= sprintf " y=\"%s\"", $cy;
    $self->{svg} .= ">";
    $self->{svg} .= $self->{title};
    $self->{svg} .= "</text>\n";
    $self->{svg} .= " " x 4;
    $self->{svg} .= "</g>\n";
  }
  # End the gauge group.
  $self->{svg} .= " " x 2;
  $self->{svg} .= "</g>\n";
};

$_scalePath = sub {
  my $self = shift;
  my ($start, $end, $cx, $cy) = @_;
  my @a = $self->$_calculateXY ($cx, $cy, $start, 400);
  my @b = $self->$_calculateXY ($cx, $cy, $end, 400);
  my @c = $self->$_calculateXY ($cx, $cy, $end, 300);
  my @d = $self->$_calculateXY ($cx, $cy, $start, 300);
  return sprintf "M %s,%s A 400 400 0 0 1 %s,%s L %s,%s A 300 300 0 0 0 %s,%s Z",
    @a, @b, @c, @d;
};

$_calculateRotation = sub {
  my $self = shift;
  my ($value) = @_;
  return 180 - ($value - $self->{lim}[0]) * 180 / 
    abs ($self->{lim}[1] - $self->{lim}[0]);
};

$_calculateXY = sub {
  my $self = shift;
  my ($cx, $cy, $value, $r) = @_;
  my $theta = $self->$_calculateRotation ($value) * PI / 180;
  my $x = $cx + $r * cos $theta;
  my $y = $cy - $r * sin $theta;
  return ($x, $y);
};

1;
