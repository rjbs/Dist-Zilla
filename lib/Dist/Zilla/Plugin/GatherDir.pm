package Dist::Zilla::Plugin::GatherDir;
# ABSTRACT: gather all the files in a directory
use Moose;
use Moose::Autobox;
use MooseX::Types::Path::Class qw(Dir File);
with 'Dist::Zilla::Role::FileGatherer';

=head1 DESCRIPTION

This is a very, very simple L<FileGatherer|Dist::Zilla::Role::FileGatherer>
plugin.  It looks in the directory named in the L</root> attribute and adds all
the files it finds there.  If the root begins with a tilde, the tilde is
replaced with the current user's home directory according to L<File::HomeDir>.

=cut

use File::Find::Rule;
use File::HomeDir;
use File::Spec;
use Path::Class;

use namespace::autoclean;

has root => (
  is   => 'ro',
  isa  => Dir,
  lazy => 1,
  coerce   => 1,
  required => 1,
  default  => sub { shift->zilla->root },
);

has prefix => (
  is  => 'ro',
  isa => 'Str',
  default => '',
);

has include_dotfiles => (
  is  => 'ro',
  isa => 'Bool',
  default => 0,
);

sub gather_files {
  my ($self) = @_;

  my $root = "" . $self->root;
  $root =~ s{^~([\\/])}{File::HomeDir->my_home . $1}e;
  $root = Path::Class::dir($root);

  my @files;
  FILE: for my $filename (File::Find::Rule->file->in($root)) {
    unless ($self->include_dotfiles) {
      my $file = file($filename)->relative($root);
      next FILE if $file->basename =~ qr/^\./;
      next FILE if grep { /^\.[^.]/ } $file->dir->dir_list;
    }

    push @files, $self->_file_from_filename($filename);
  }

  for my $file (@files) {
    (my $newname = $file->name) =~ s{\A\Q$root\E[\\/]}{}g;
    $newname = File::Spec->catdir($self->prefix, $newname) if $self->prefix;

    $file->name($newname);
    $self->add_file($file);
  }

  return;
}

sub _file_from_filename {
  my ($self, $filename) = @_;

  return Dist::Zilla::File::OnDisk->new({
    name => $filename,
    mode => (stat $filename)[2] & 0755, # kill world-writeability
  });
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
