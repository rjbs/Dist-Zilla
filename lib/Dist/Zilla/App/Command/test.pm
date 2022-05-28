package Dist::Zilla::App::Command::test;
# ABSTRACT: test your dist

use Dist::Zilla::Pragmas;

use Dist::Zilla::App -command;

=head1 SYNOPSIS

  dzil test [ --release ] [ --no-author ] [ --automated ] [ --extended ] [ --all ]

=head1 DESCRIPTION

This command is a thin wrapper around the L<test|Dist::Zilla::Dist::Builder/test> method in
Dist::Zilla.  It builds your dist and runs the tests with the AUTHOR_TESTING
environment variable turned on, so it's like doing this:

  export AUTHOR_TESTING=1
  dzil build --no-tgz
  cd $BUILD_DIRECTORY
  perl Makefile.PL
  make
  make test

A build that fails tests will be left behind for analysis, and F<dzil> will
exit a non-zero value.  If the tests are successful, the build directory will
be removed and F<dzil> will exit with status 0.

=cut

sub opt_spec {
  [ 'release'   => 'enables the RELEASE_TESTING env variable', { default => 0 } ],
  [ 'automated' => 'enables the AUTOMATED_TESTING env variable', { default => 0 } ],
  [ 'extended' => 'enables the EXTENDED_TESTING env variable', { default => 0 } ],
  [ 'author!' => 'enables the AUTHOR_TESTING env variable (default behavior)', { default => 1 } ],
  [ 'all' => 'enables the RELEASE_TESTING, AUTOMATED_TESTING, EXTENDED_TESTING and AUTHOR_TESTING env variables', { default => 0 } ],
  [ 'keep-build-dir|keep' => 'keep the build directory even after a success' ],
  [ 'jobs|j=i' => 'number of parallel test jobs to run' ],
  [ 'test-verbose' => 'enables verbose testing (TEST_VERBOSE env variable on Makefile.PL, --verbose on Build.PL', { default => 0 } ],
}

=head1 OPTIONS

=head2 --release

This will run the test suite with RELEASE_TESTING=1

=head2 --automated

This will run the test suite with AUTOMATED_TESTING=1

=head2 --extended

This will run the test suite with EXTENDED_TESTING=1

=head2 --no-author

This will run the test suite without setting AUTHOR_TESTING

=head2 --all

Equivalent to --release --automated --extended --author

=cut

sub abstract { 'test your dist' }

sub execute {
  my ($self, $opt, $arg) = @_;

  local $ENV{RELEASE_TESTING} = 1 if $opt->release or $opt->all;
  local $ENV{AUTHOR_TESTING} = 1 if $opt->author or $opt->all;
  local $ENV{AUTOMATED_TESTING} = 1 if $opt->automated or $opt->all;
  local $ENV{EXTENDED_TESTING} = 1 if $opt->extended or $opt->all;

  $self->zilla->test({
    $opt->keep_build_dir
      ? (keep_build_dir => 1)
      : (),
    $opt->jobs
      ? (jobs => $opt->jobs)
      : (),
    $opt->test_verbose
      ? (test_verbose => $opt->test_verbose)
      : (),
  });
}

1;
