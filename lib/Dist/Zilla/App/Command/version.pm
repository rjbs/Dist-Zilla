use strict;
use warnings;
package Dist::Zilla::App::Command::version;
# ABSTRACT: display dzil's version

use Dist::Zilla::App -command;
use App::Cmd::Command::version;
BEGIN {
  ## parent and base dont work here. ??? -- kentnl 2014-10-31
  our @ISA;
  unshift @ISA, 'App::Cmd::Command::version';
}

use Dist::Zilla::Dialect;

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
