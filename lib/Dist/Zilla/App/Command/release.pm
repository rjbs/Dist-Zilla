use strict;
use warnings;
package Dist::Zilla::App::Command::release;
# ABSTRACT: release your dist to the CPAN
use Dist::Zilla::App -command;

=head1 SYNOPSIS

Use ReleasePlugin(s) to release your distribution in many ways.

    dzil release

Put some plugins in your F<dist.ini> that perform
L<Dist::Zilla::Role::Releaser>, such as L<Dist::Zilla::Plugin::UploadToCPAN>

=cut

sub abstract { 'release your dist' }

sub execute {
  my ($self, $opt, $arg) = @_;
  $self->zilla->release;
}

1;
