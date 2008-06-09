package Dist::Zilla::Plugin::InstallDirs;
# ABSTRACT: mark directory contents for installation
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::FileMunger';

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
