=encoding utf8

=head1 NAME

Device::V4L2 - Driver for cameras supported by V4L2.

=head1 SYNOPSIS

  use strict;
  use warnings;
  use utf8;
  use v5.14;

  use Device::V4L2;

  # Setup V4L2 to capture an image from a cammera connected to a Raspberry Pi.
  my $device = '/dev/video0';
  my $pixel_format = 'MJPG';
  my $width = 1920;
  my $height= 1080
  my $camera = Device::V4L2->new ($device, $pixel_format, $width, $height);

  # Capture an image from the camera.
  my $camera->capture ('image.jpg');

  # Close the device.
  $camera->close;

=head1 DESCRIPTION

Device::V4L2 is a driver for cameras supported by V4L2.

=head2 Methods

=over 12

=item C<new>

Returns a new Device::V4L2 object.

=item C<close>

Closes the device.

=item C<capture>

Capture an image from the camera.

=back

=head1 DEPENDENCIES

Device::V4L2 requires Perl version 5.14 or later, File::Temp, v4l-utils, and
ImageMagick.

=head1 FEEDBACK

=head2 Reporting Bugs

Report bugs to the GitHub issue tracker at:

L<https://github.com/sandain/growbot/issues>

=head1 AUTHOR

Jason M. Wood L<sandain@hotmail.com|mailto:sandain@hotmail.com>

=head1 COPYRIGHT AND LICENSE

  Copyright (c) 2023 Jason M. Wood

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

package Device::V4L2;

use strict;
use warnings;
use utf8;
use version;
use v5.14;
use File::Temp;

my $DEFAULT_V4L2_CTL_BIN = '/usr/bin/v4l2-ctl';
my $DEFAULT_CONVERT_BIN = '/usr/bin/convert';

sub new {
  my $class = shift;
  die "Usage: $class->new (device, pixel_format, width, height)"
    unless (@_ == 4);
  my ($device, $pixel_format, $width, $height) = @_;
  # Make sure we can find the v4l2-ctl program.
  my $v4l2_ctl_bin = `which v4l2-ctl || echo $DEFAULT_V4L2_CTL_BIN`;
  $v4l2_ctl_bin =~ s/[\r\n]+//g;
  die "Error: Unable to find v4l2-ctl" unless (-e $v4l2_ctl_bin);
  # Make sure we can find the convert program.
  my $convert_bin = `which convert || echo $DEFAULT_CONVERT_BIN`;
  $convert_bin =~ s/[\r\n]+//g;
  die "Error: Unable to find convert" unless (-e $convert_bin);
  # Bless ourselves with our class.
  my $self = bless {
    device       => $device,
    pixel_format => $pixel_format,
    width        => $width,
    height       => $height,
    v4l2_ctl_bin => $v4l2_ctl_bin,
    convert_bin  => $convert_bin
  }, $class;
  return $self;
}

sub close {
  my $self = shift;
}

sub capture {
  my $self = shift;
  my ($file_name) = @_;
  my $v4l2_ctl_bin = $self->{v4l2_ctl_bin};
  my $convert_bin = $self->{convert_bin};
  my $device = $self->{device};
  my $tmp = File::Temp->new (TEMPLATE => 'v4l2XXXXXX');
  my $fmt = sprintf "width=%s,height=%s,pixelformat=%s",
    $self->{width}, $self->{height}, $self->{pixel_format};
  `$v4l2_ctl_bin \\
    --device $device \\
    --stream-mmap \\
    --set-fmt-video=$fmt \\
    --stream-to=$tmp \\
    --stream-count=10 \\
    2>/dev/null`;
  `$convert_bin $tmp $file_name 2>/dev/null`;
}

1;
