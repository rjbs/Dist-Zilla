package Dist::Zilla::Plugin::AllFiles;
# ABSTRACT: gather all the files in your dist's root
use Moose;
use Moose::Autobox;
use MooseX::Types::Path::Class qw(Dir File);
with 'Dist::Zilla::Role::FileGatherer';

use File::Find::Rule;
use File::HomeDir;

has root => (
  is   => 'ro',
  isa  => Dir,
  lazy => 1,
  coerce   => 1,
  required => 1,
  default  => sub { shift->zilla->root },
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
    $file->name($newname);
    $self->add_file($file);
  }

  return;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
