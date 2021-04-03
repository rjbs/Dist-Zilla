package Dist::Zilla::Role::ExecFiles;
# ABSTRACT: something that finds files to install as executables

use Moose::Role;
with 'Dist::Zilla::Role::FileFinder';

# BEGIN BOILERPLATE
use v5.20.0;
use warnings;
use utf8;
no feature 'switch';
use experimental qw(postderef postderef_qq); # This experiment gets mainlined.
# END BOILERPLATE

use namespace::autoclean;

requires 'dir';

sub find_files {
  my ($self) = @_;

  my $dir = $self->dir;
  my $files = [
    grep { index($_->name, "$dir/") == 0 }
      @{ $self->zilla->files }
  ];
}

1;
