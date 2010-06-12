use strict;
use warnings;
package Dist::Zilla::App::Command::run;
# ABSTRACT: run stuff in a dir where your dist is built

=head1 SYNOPSIS

  $ dzil run ./bin/myscript
  $ dzil run prove -bv t/mytest.t
  $ dzil run bash

=head1 DESCRIPTION

This command will build your dist with Dist::Zilla, then build the
distribution and then run a command in the build directory.  It's something
like doing this:

  dzil build
  rsync -avp My-Project-version/ .build/
  cd .build
  perl Makefile.PL            # or perl Build.PL
  make                        # or ./Build
  export PERL5LIB=$PWD/blib/lib:$PWD/blib/arch
  <your command as defined by rest of params>

Except for the fact it's built directly in a subdir of .build (like
F<.build/69105y2>).

A command returning with an non-zero error code will left the build directory
behind for analysis, and C<dzil> will exit with a non-zero status.  Otherwise,
the build directory will be removed and dzil will exit with status zero.

=cut

use Dist::Zilla::App -command;
use Moose::Autobox;

sub abstract { 'run stuff in a dir where your dist is built' }

sub execute {
  my ($self, $opts, $args) = @_;

  $self->zilla->run_in_build($args);
}

1;
