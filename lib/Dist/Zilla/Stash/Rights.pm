package Dist::Zilla::Stash::Rights;
# ABSTRACT: a stash of your default licensing terms

use Moose;
with 'Dist::Zilla::Role::Stash';

use Dist::Zilla::Dialect;

use namespace::autoclean;

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

__PACKAGE__->meta->make_immutable;
1;
