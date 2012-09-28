package Dist::Zilla::Plugin::TestAutoName;

use Moose;
with(
  'Dist::Zilla::Role::NameProvider',
);

sub provide_name {
  my ($self) = @_;
  return 'FooBar';
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
