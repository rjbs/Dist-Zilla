package Dist::Zilla::Plugin::MetaResources;
# ABSTRACT: provide arbitrary "resources" for distribution metadata
use Moose;
with 'Dist::Zilla::Role::MetaProvider';

=head1 DESCRIPTION

This plugin adds resources entries to the distribution's metadata.

  [MetaResources]
  homepage: http://example.com/~dude/project.asp

=cut

has resources => (
  is       => 'ro',
  isa      => 'HashRef',
  required => 1,
);

sub new {
  my ($class, $arg) = @_;

  my $self = $class->SUPER::new({
    '=name'   => delete $arg->{'=name'},
    zilla     => delete $arg->{zilla},
    resources => $arg,
  });
}

sub metadata {
  my ($self) = @_;

  return { resources => $self->resources };
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
