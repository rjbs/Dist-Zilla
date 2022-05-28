package Dist::Zilla::Role::TestRunner;
# ABSTRACT: something used as a delegating agent to 'dzil test'

use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

use Dist::Zilla::Pragmas;

use namespace::autoclean;

=head1 DESCRIPTION

Plugins implementing this role have their C<test> method called when
testing.  It's passed the root directory of the build test dir and an
optional hash reference of arguments.  Valid arguments include:

=for :list
* jobs -- if parallel testing is supported, this indicates how many to run at once

=method test

This method should throw an exception on failure.

=cut

requires 'test';

=attr default_jobs

This attribute is the default value that should be used as the C<jobs> argument
to the C<test> method.

=cut

has default_jobs => (
  is      => 'ro',
  isa     => 'Int', # non-negative
  lazy    => 1,
  default => sub {
    return ($ENV{HARNESS_OPTIONS} // '') =~ / \b j(\d+) \b /x ? $1 : 1;
  },
);

around dump_config => sub {
  my ($orig, $self) = @_;
  my $config = $self->$orig;

  $config->{'' . __PACKAGE__} = { default_jobs => $self->default_jobs };

  return $config;
};

1;
