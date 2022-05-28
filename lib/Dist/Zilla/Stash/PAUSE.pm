package Dist::Zilla::Stash::PAUSE;
# ABSTRACT: a stash of your PAUSE credentials

use Moose;

use Dist::Zilla::Pragmas;

use namespace::autoclean;

=head1 OVERVIEW

The PAUSE stash is a L<Login|Dist::Zilla::Role::Stash::Login> stash generally
used for uploading to PAUSE.

=cut

sub mvp_aliases {
  return { user => 'username' };
}

has username => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

has password => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

with 'Dist::Zilla::Role::Stash::Login';
__PACKAGE__->meta->make_immutable;
1;
