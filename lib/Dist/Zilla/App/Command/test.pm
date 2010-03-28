use strict;
use warnings;
package Dist::Zilla::App::Command::test;
# ABSTRACT: test your dist
use Dist::Zilla::App -command;

use Moose::Autobox;

=head1 SYNOPSIS

Test your distribution:

  dzil test

This runs with AUTHOR_TESTING and RELEASE_TESTING environment variables turned
on, so it's like doing this:

  export AUTHOR_TESTING=1
  export RELEASE_TESTING=1
  dzil build
  rsync -avp My-Project-Version/ .build/
  cd .build;
  perl Makefile.PL
  make
  make test

Except for the fact it's built directly in a subdir of .build (like
F<.build/ASDF123>).

A build that fails tests will be left behind for analysis, and F<dzil> will
exit a non-zero value.  If the tests are successful, the build directory will
be removed and F<dzil> will exit with status 0.

=head1 SEE ALSO

The heavy lifting of this module is now done by
L<Dist::Zilla::Role::TestRunner> plugins.

=cut

sub abstract { 'test your dist' }

sub execute {
  my ($self, $opt, $arg) = @_;

  $self->zilla->test;
}

1;
