package Dist::Zilla::Plugin::AllFiles;
# ABSTRACT: gather all the files in your dist's root
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

sub gather_files {
  my ($self) = @_;

  my $root = "" . $self->root;
  $root =~ s{^~([\\/])}{File::HomeDir->my_home . $1}e;
  $root = Path::Class::dir($root);

  my @files =
    map { Dist::Zilla::File::OnDisk->new({ name => $_ }) }
    File::Find::Rule
    ->not( File::Find::Rule->name(qr/^\./) )
    ->file
    ->in($root);

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
