package Dist::Zilla::Plugin::TestAutoAbstract;

use Moose;
with(
  'Dist::Zilla::Role::AbstractProvider',
);

sub provide_abstract {
  my ($self) = @_;
  return 'Blah blah blah';
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
