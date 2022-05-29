package Dist::Zilla::Plugin::FinderCode;
# ABSTRACT: a callback-based FileFinder plugin

use Moose;
with 'Dist::Zilla::Role::FileFinder';

use Dist::Zilla::Pragmas;

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

sub find_files ($self) {
  my $method = '_find_via_' . $self->style;

  $self->$method;
}

sub _find_via_grep ($self) {
  my @files = grep { $self->code->($_, $self) } @{ $self->zilla->files };
  return \@files;
}

sub _find_via_list ($self) {
  my $code = $self->code;
  $self->$code;
}

__PACKAGE__->meta->make_immutable;
1;
