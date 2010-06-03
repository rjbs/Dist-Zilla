package Dist::Zilla::Stash::Rights;
use Moose;
with 'Dist::Zilla::Role::Stash';
# ABSTRACT: a stash of your default licensing terms

has license_class => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

has copyright_holder => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

has copyright_year => (
  is  => 'ro',
  isa => 'Int',
);

1;
