package Dist::Zilla::Chrome::Test;
use Moose;
# ABSTRACT: the chrome used by Dist::Zilla::Tester

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

with 'Dist::Zilla::Role::Chrome';
1;
