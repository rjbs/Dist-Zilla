use strict;
use warnings;
package Dist::Zilla::App::Command::run;
# ABSTRACT: run stuff in a dir where your dist is built

use Dist::Zilla::App -command;

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

If no run command is provided, a new default shell is invoked. This can be
useful for testing your distribution as if it were installed.

=cut

sub abstract { 'run stuff in a dir where your dist is built' }

sub opt_spec {
  [ 'build!' => 'do the Build actions before running the command; done by default',
                { default => 1 } ],
}

sub description {
  "This will build your dist and run the given 'command' in the build dir.\n" .
  "If no command was specified, your shell will be run there instead."
}

sub usage_desc {
  return '%c run %o [ command [ arg1 arg2 ... ] ]';
}

sub execute {
  my ($self, $opt, $args) = @_;

  unless (@$args) {
    my $envname = $^O eq 'MSWin32' ? 'COMSPEC' : 'SHELL';
    unless ($ENV{$envname}) {
      $self->usage_error("no command supplied to run and no \$$envname set");
    }
    $args = [ $ENV{$envname} ];
    $self->log("no command supplied to run so using \$$envname: $args->[0]");
  }

  $self->zilla->run_in_build($args, { build => $opt->build });
}

1;
