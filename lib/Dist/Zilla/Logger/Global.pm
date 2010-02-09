package Dist::Zilla::Logger::Global;
use MooseX::Singleton;

use Log::Dispatchouli;

use namespace::autoclean;

has ident  => (
  is => 'ro',
  default => 'Dist::Zilla',
);

has logger => (
  is   => 'ro',
  isa  => 'Log::Dispatchouli',
  lazy => 1,
  handles => [ qw(log log_debug) ],
  default => sub {
    return Log::Dispatchouli->new({
      ident => $_[0]->ident,
    });
  },
);

with 'Dist::Zilla::Role::Logger';
1;
