package Dist::Zilla::App::Tester;
use base 'App::Cmd::Tester';
use App::Cmd::Tester 0.306; # result_class, ->app

sub result_class { 'Dist::Zilla::App::Tester::Result' }

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
