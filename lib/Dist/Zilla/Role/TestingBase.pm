package Dist::Zilla::Role::TestingBase;
# ABSTRACT: Common ground for automated test suites commands
use Moose::Role;

use namespace::autoclean;

=attr testing_command

This attribute specifies the testing command to use instead of the "test"
in "./Build test" or "make test". It is an array reference of arguments.

So for example, one can set it to C<runtest> to test using L<Test::Run::CmdLine>.

Defaults to "test".
=cut

# XXX: Later, add a way to set this in config. -- rjbs, 2008-06-02
has testing_command => (
  is   => 'rw',
  isa  => 'ArrayRef',
  lazy => 1,
  init_arg => undef,
  default  => sub { [ qw( test ) ] },
);

1;

=head1 DESCRIPTION

This role is a helper for all installers that make use of test suite commands,
and allows one to specify the L<testing_command> as an arrayref of command-line
arguments.

=cut

