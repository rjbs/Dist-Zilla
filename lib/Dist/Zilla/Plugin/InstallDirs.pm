package Dist::Zilla::Plugin::InstallDirs;
# ABSTRACT: mark directory contents for installation
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::FileMunger';

=head1 SYNOPSIS

In your F<dist.ini>:

  [InstallDirs]
  bin = scripts
  bin = extra_scripts

=head1 DESCRIPTION

This plugin marks the contents of certain directories as files to be installed
under special locations.

The only implemented attribute is C<bin>, which indicates directories that
contain executable files to install.  If no value is given, the directory
C<bin> will be considered.

=head1 TODO

Add support for ShareDir-style C<dist_dir> files.

=cut

# XXX: implement share
sub multivalue_args { qw(bin share) }

has mark_as_bin => (
  is   => 'ro',
  isa  => 'ArrayRef[Str]',
  default  => sub { [ qw(bin) ] },
  init_arg => 'bin'
);

sub munge_file {
  my ($self, $file) = @_;

  for my $dir ($self->mark_as_bin->flatten) {
    next unless $file->name =~ qr{^\Q$dir\E[\\/]};
    $file->install_type('bin');
  }
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
