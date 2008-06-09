package Dist::Zilla::Plugin::Manifest;
# ABSTRACT: build a MANIFEST file
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::InstallTool';

sub setup_installer {
  my ($self, $arg) = @_;

  my $file = Dist::Zilla::File::InMemory->new({
    name    => 'MANIFEST',
    content => $self->zilla->files->map(sub{$_->name})->push('MANIFEST')
               ->sort->flatten->join("\n"),
  });

  $self->add_file($file);
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
