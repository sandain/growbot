=encoding utf8

=head1 NAME

GrowBot::Controller::Device

=head1 SYNOPSIS

  # Called automatically by Mojolicious routing.

=head1 DESCRIPTION

Controller for GrowBot device pages, providing views of current readings
and historical data for each device.

=head2 Actions

=over 12

=item C<show>

Renders the device page.

=item C<current>

Renders the current status of a device.

=item C<current_type>

Renders the current status of a specific device action type.

=item C<history>

Renders the history for a device.

=item C<history_type>

Renders the history for a specific device action type.

=back

=head1 DEPENDENCIES

GrowBot::Controller::Device requires Perl version 5.14 or later, in addition
to Mojolicious.

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

package GrowBot::Controller::Device;

use Mojo::Base 'Mojolicious::Controller';

=head2 Actions

=head3 show

  Renders the device page.

=cut

sub show {
  my $self = shift;
  $self->render (template => 'device');
}

=head3 current

  Renders the current status of the device.

=cut

sub current {
  my $self = shift;
  $self->render (template => 'device_current');
}

=head3 current_type

  Renders the current status of the device action type.

=cut

sub current_type {
  my $self = shift;
  $self->render (template => 'device_current_type');
}

=head3 history

  Renders the history for the device.

=cut

sub history {
  my $self = shift;
  $self->render (template => 'device_history');
}

=head3 history_type

  Renders the history for the device action type.

=cut

sub history_type {
  my $self = shift;
  $self->render (template => 'device_history_type');
}

1;
