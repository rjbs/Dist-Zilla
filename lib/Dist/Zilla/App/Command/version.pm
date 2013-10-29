use strict;
use warnings;

package Dist::Zilla::App::Command::version;
use Dist::Zilla::App -command;
use Moose;
extends 'App::Cmd::Command::version';

# ABSTRACT: display dzil's version

=head1 SYNOPSIS

Print dzil version

  $ dzil --version or $dzil version

=cut

sub version_for_display {
  my $version_pkg = $_[0]->version_package;
  my $version = ( $version_pkg->VERSION ?
                  $version_pkg->VERSION :
                 'dev' );
}

1;
