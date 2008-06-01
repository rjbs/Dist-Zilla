package Dist::Zilla::Role::Plugin;
use Moose::Role;

has plugin_name => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

no Moose::Role;
1;
