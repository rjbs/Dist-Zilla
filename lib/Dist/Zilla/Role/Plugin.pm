package Dist::Zilla::Role::Plugin;
use Moose::Role;

has plugin_name => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

has zilla => (
  is  => 'ro',
  isa => 'Dist::Zilla',
  required => 1,
  weak_ref => 1,
);

no Moose::Role;
1;
