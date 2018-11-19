package Dist::Zilla::Plugin::FinderCode;
# ABSTRACT: a callback-based FileFinder plugin

use Moose;
with 'Dist::Zilla::Role::FileFinder';

use Dist::Zilla::Dialect;

use namespace::autoclean;

use Moose::Util::TypeConstraints;

has code => (
  is  => 'ro',
  isa => 'CodeRef',
  required => 1,
);

has style => (
  is  => 'ro',
  isa => enum([ qw(grep list) ]),
  required => 1,
);

sub find_files {
  my ($self) = @_;

  my $method = '_find_via_' . $self->style;

  $self->$method;
}

sub _find_via_grep {
  my ($self) = @_;

  my @files = grep { $self->code->($_, $self) } @{ $self->zilla->files };
  return \@files;
}

sub _find_via_list {
  my ($self) = @_;

  my $code = $self->code;
  $self->$code;
}

__PACKAGE__->meta->make_immutable;
1;
