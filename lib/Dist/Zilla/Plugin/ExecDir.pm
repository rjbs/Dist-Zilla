package Dist::Zilla::Plugin::ExecDir;
# ABSTRACT: install a directory's contents as executables

use Moose;

use Dist::Zilla::Pragmas;

use namespace::autoclean;

=head1 SYNOPSIS

In your F<dist.ini>:

  [ExecDir]
  dir = scripts

If no C<dir> is provided, the default is F<bin>.

=cut

has dir => (
  is   => 'ro',
  isa  => 'Str',
  default => 'bin',
);

with 'Dist::Zilla::Role::ExecFiles';
__PACKAGE__->meta->make_immutable;
1;
