package Dist::Zilla::Plugin::FixedPrereqs;
use Moose;
with 'Dist::Zilla::Role::FixedPrereqs';

has _prereq => (
  is   => 'ro',
  isa  => 'HashRef',
  default => sub { {} },
);

sub new {
  my ($class, $arg) = @_;

  my $self = $class->SUPER::new({
    '=name' => delete $arg->{'=name'},
    zilla   => delete $arg->{zilla},
    _prereq => $arg,
  });
}

sub prereq { shift->_prereq }

no Moose;
__PACKAGE__->meta->make_immutable;
1;
