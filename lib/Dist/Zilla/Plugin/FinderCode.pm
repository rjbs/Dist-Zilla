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
  $self->log_fatal("unknown FinderCode style '$style'") if $style ne 'grep';

  $self->zilla->files->grep($self->code);
}

1;
