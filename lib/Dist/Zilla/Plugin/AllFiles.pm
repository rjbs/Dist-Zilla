package Dist::Zilla::Plugin::AllFiles;
# ABSTRACT: gather all the files in your dist's root
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::FileGatherer';

use File::Find::Rule;

sub gather_files {
  my ($self) = @_;
  my $root = $self->zilla->root;

  my @files = File::Find::Rule
            ->not( File::Find::Rule->name(qr/^\./) )
            ->file
            ->in($root);

  $self->add_file(Dist::Zilla::File::OnDisk->new({ name => $_ })) for @files;
  return;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
