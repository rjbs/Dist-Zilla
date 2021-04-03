package Dist::Zilla::Role::FileInjector;
# ABSTRACT: something that can add files to the distribution

use Moose::Role;

# BEGIN BOILERPLATE
use v5.20.0;
use warnings;
use utf8;
no feature 'switch';
use experimental qw(postderef postderef_qq); # This experiment gets mainlined.
# END BOILERPLATE

use namespace::autoclean;

=head1 DESCRIPTION

This role should be implemented by any plugin that plans to add files into the
distribution.  It provides one method (C<L</add_file>>, documented below),
which adds a file to the distribution, noting the place of addition.

=method add_file

  $plugin->add_file($dzil_file);

This adds a file to the distribution, setting the file's C<added_by> attribute
as it does so.

=cut

sub add_file {
  my ($self, $file) = @_;
  my ($pkg, undef, $line) = caller;

  $file->_set_added_by(
    sprintf("%s (%s line %s)", $self->plugin_name, $pkg, $line),
  );

  $self->log_debug([ 'adding file %s', $file->name ]);
  push @{ $self->zilla->files }, $file;
}

1;
