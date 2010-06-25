package Dist::Zilla::Chrome::Test;
use Moose;
# ABSTRACT: the chrome used by Dist::Zilla::Tester

use Dist::Zilla::Types qw(OneZero);
use Log::Dispatchouli;

has logger => (
  is => 'ro',
  default => sub {
    Log::Dispatchouli->new({
      ident   => 'Dist::Zilla::Tester',
      log_pid => 0,
      to_self => 1,
    });
  }
);

sub prompt_str {
  my ($self, $prompt, $arg) = @_;
  $arg ||= {};
  my $default = $arg->{default};

  $self->logger->log_fatal("no default response for test prompt_yn")
    unless defined $default;

  return $default;
}

sub prompt_yn {
  my ($self, $prompt, $arg) = @_;
  $arg ||= {};
  my $default = $arg->{default};

  $self->logger->log_fatal("no default response for test prompt_yn")
    unless defined $default;

  return OneZero->coerce($default);
}

sub prompt_any_key { return }

with 'Dist::Zilla::Role::Chrome';
1;
