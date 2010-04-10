package Dist::Zilla::Plugin::GatherDir;
# ABSTRACT: gather all the files in a directory
use Moose;
use Moose::Autobox;
use MooseX::Types::Path::Class qw(Dir File);
with 'Dist::Zilla::Role::FileGatherer';

=head1 DESCRIPTION

This is a very, very simple L<FileGatherer|Dist::Zilla::FileGatherer> plugin.
It looks in the directory named in the L</root> attribute and adds all the
files it finds there.  If the root begins with a tilde, the tilde is replaced
with the current user's home directory according to L<File::HomeDir>.

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

# Total hack to work around adding 234249018 files in .git only to remove them
# later.  Will fix more elegantly later. -- rjbs, 2010-04-09
sub __log_inject { 0 }

sub gather_files {
  my ($self) = @_;

  my $root = "" . $self->root;
  $root =~ s{^~([\\/])}{File::HomeDir->my_home . $1}e;
  $root = Path::Class::dir($root);

  my @files;
  for my $filename (File::Find::Rule->file->in($root)) {
    next if ! $self->include_dotfiles and file($filename)->basename =~ qr/^\./;
    push @files, Dist::Zilla::File::OnDisk->new({
      name => $filename,
      mode => (stat $filename)[2] & 0755, # kill world-writeability
    });
  }

  for my $file (@files) {
    (my $newname = $file->name) =~ s{\A\Q$root\E[\\/]}{}g;
    $newname = File::Spec->catdir($self->prefix, $newname) if $self->prefix;

    $file->name($newname);
    $self->add_file($file);
  }

  return;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
