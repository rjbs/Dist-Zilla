use strict;
use warnings;
package Dist::Zilla::App::Tester;
# ABSTRACT: testing library for Dist::Zilla::App

use parent 'App::Cmd::Tester::CaptureExternal';
use App::Cmd::Tester 0.306 (); # result_class, ->app

use Dist::Zilla::App;
use File::Copy::Recursive qw(dircopy);
use File::pushd ();
use File::Spec;
use File::Temp;
use Path::Class;

use Sub::Exporter::Util ();
use Sub::Exporter -setup => {
  exports => [ test_dzil => Sub::Exporter::Util::curry_method() ],
  groups  => [ default   => [ qw(test_dzil) ] ],
};

sub result_class { 'Dist::Zilla::App::Tester::Result' }

sub test_dzil {
  my ($self, $source, $argv, $arg) = @_;
  $arg ||= {};

  local @INC = map {; ref($_) ? $_ : File::Spec->rel2abs($_) } @INC;

  my $tmpdir = $arg->{tempdir} || File::Temp::tempdir(CLEANUP => 1);
  my $root   = dir($tmpdir)->subdir('source');
  $root->mkpath;

  dircopy($source, $root);

  my $wd = File::pushd::pushd($root);

  local $ENV{DZIL_TESTING} = 1;
  my $result = $self->test_app('Dist::Zilla::App' => $argv);
  $result->{tempdir} = $tmpdir;

  return $result;
}

{
  package Dist::Zilla::App::Tester::Result;

  BEGIN { our @ISA = qw(App::Cmd::Tester::Result); }

  sub tempdir {
    my ($self) = @_;
    return $self->{tempdir};
  }

  sub zilla {
    my ($self) = @_;
    return $self->app->zilla;
  }

  sub build_dir {
    my ($self) = @_;
    return $self->zilla->built_in;
  }

  sub clear_log_events {
    my ($self) = @_;
    $self->app->zilla->logger->logger->clear_events;
  }

  sub log_events {
    my ($self) = @_;
    $self->app->zilla->logger->logger->events;
  }

  sub log_messages {
    my ($self) = @_;
    [ map {; $_->{message} } @{ $self->app->zilla->logger->logger->events } ];
  }
}

=head1 DESCRIPTION

This module exports only one function, C<test_dzil>.

=head2 C<test_dzil>

This function is used to test C<Dist::Zilla::App>.
It receives two mandatory options. The first is the path to a Dist::Zilla-based
distribution. The second, an array reference to a list of arguments. 

The third optional argument is a hash reference, with further options. At the moment
the only supported option is c<tempdir>.

It returns a C<Dist::Zilla::App::Tester::Result>, that inherits from 
C<App::Cmd::Tester::Result>. Typical methods called from this result are:

=over 4 

=item C<output>

The output of running dzil;

=item C<tempdir>

The folder used for temporary files.

=item C<build_dir>

The folder where the distribution was built.

=back

=cut

1;
