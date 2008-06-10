package Dist::Zilla::Plugin::Manifest;
# ABSTRACT: build a MANIFEST file
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::InstallTool';

=head1 DESCRIPTION

If included, this plugin will produce a F<MANIFEST> file for the distribution,
listing all of the files it contains.  For obvious reasons, it should be
included as close to last as possible.

=cut

sub setup_installer {
  my ($self, $arg) = @_;

  my $file = Dist::Zilla::File::InMemory->new({
    name    => 'MANIFEST',
    content => $self->zilla->files->map(sub{$_->name})->push('MANIFEST')
               ->sort->join("\n"),
  });

  $self->add_file($file);
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
