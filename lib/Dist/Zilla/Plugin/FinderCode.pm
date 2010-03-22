package Dist::Zilla::Plugin::FinderCode;
use Moose;
with 'Dist::Zilla::Role::FileFinder';

use Moose::Autobox;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

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

  $self->zilla->files->grep($self->code);
}

sub _find_via_list {
  my ($self) = @_;

  my $code = $self->code;
  $self->$code;
}

1;
