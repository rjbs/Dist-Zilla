package Dist::Zilla::Plugin::Manifest;
# ABSTRACT: build a MANIFEST file
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::FileGatherer';

use namespace::autoclean;

use Dist::Zilla::File::FromCode;

=head1 DESCRIPTION

If included, this plugin will produce a F<MANIFEST> file for the distribution,
listing all of the files it contains.  For obvious reasons, it should be
included as close to last as possible.

This plugin is included in the L<@Basic|Dist::Zilla::PluginBundle::Basic>
bundle.

=head1 SEE ALSO

Dist::Zilla core plugins:
L<@Basic|Dist::Zilla::PluginBundle::Manifest>,
L<ManifestSkip|Dist::Zilla::Plugin::ManifestSkip>.

Other modules: L<ExtUtils::Manifest>.

=cut

sub __fix_filename {
  my ($name) = @_;
  return $name unless $name =~ /[ '\\]/;
  $name =~ s/\\/\\\\/g;
  $name =~ s/'/\\'/g;
  return qq{'$name'};
}

sub gather_files {
  my ($self, $arg) = @_;

  my $zilla = $self->zilla;

  my $file = Dist::Zilla::File::FromCode->new({
    name => 'MANIFEST',
    code => sub {
      $zilla->files->map(sub { $_->name })
            ->sort->map( sub { __fix_filename($_) } )->join("\n")
      . "\n",
    },
  });

  $self->add_file($file);
}

__PACKAGE__->meta->make_immutable;
1;
