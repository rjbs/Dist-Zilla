use strict;
use warnings;
package Dist::Zilla::App::Command::build;
# ABSTRACT: build your dist
use Dist::Zilla::App -command;

=head1 SYNOPSIS

Builds your distribution and emits tar.gz files / directories.

    dzil build [--tgz|--notgz]

=cut

sub abstract { 'build your dist' }

=head1 EXAMPLE

    $ dzil build
    $ dzil build --tgz
    $ dzil build --notgz

=cut

sub opt_spec {
  [ 'tgz!', 'build a tarball (default behavior)', { default => 1 } ]
}

=head1 OPTIONS

=head2 --tgz | --notgz

Builds a .tar.gz in your project directory after building the distribution.

--tgz behaviour is by default, use --notgz to disable building an archive.

=cut

sub execute {
  my ($self, $opt, $arg) = @_;

  my $method = $opt->{tgz} ? 'build_archive' : 'build_in';
  $self->zilla->$method;
}

1;
