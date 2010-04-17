package Dist::Zilla::Chrome::Term;
use Moose;
# ABSTRACT: chrome used for terminal-based interaction

use Log::Dispatchouli;

has logger => (
  is  => 'ro',
  isa => 'Log::Dispatchouli',
  init_arg => undef,
  default  => sub {
    Log::Dispatchouli->new({
      ident     => 'Dist::Zilla',
      to_stdout => 1,
      log_pid   => 0,
      to_self   => ($ENV{DZIL_TESTING} ? 1 : 0),
      quiet_fatal => 'stdout',
    });
  }
);

with 'Dist::Zilla::Role::Chrome';
1;
