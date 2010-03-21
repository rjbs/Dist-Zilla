package Dist::Zilla::Plugin::FinderCode;
use Moose;
with 'Dist::Zilla::Role::FileFinder';

use Moose::Autobox;

has code => (
  is  => 'ro',
  isa => 'CodeRef',
  required => 1,
);

has style => (
  is  => 'ro',
  isa => 'Str',
  default => 'grep',
);

sub find_files {
  my ($self) = @_;

  my $style = $self->style;
  confess "unknown FinderCode style '$style'" unless $style eq 'grep';

  $self->zilla->files->grep($self->code);
}

1;
