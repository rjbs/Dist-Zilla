package Dist::Zilla::App::Tester;
use base 'App::Cmd::Tester';
use App::Cmd::Tester 0.306 (); # result_class, ->app

use Dist::Zilla::App;
use File::chdir;
use File::Spec;

use Sub::Exporter::Util ();
use Sub::Exporter -setup => {
  exports => [ test_dzil => Sub::Exporter::Util::curry_method() ],
  groups  => [ default   => [ qw(test_dzil) ] ],
};

sub result_class { 'Dist::Zilla::App::Tester::Result' }

sub test_dzil {
  my ($self, $root, $argv) = @_;

  local @INC = map {; File::Spec->rel2abs($_) } @INC;
  local $CWD = $root;

  return $self->test_app('Dist::Zilla::App' => $argv);
}

{
  package Dist::Zilla::App::Tester::Result;
  BEGIN { our @ISA = qw(App::Cmd::Tester::Result); }

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
}


1;
