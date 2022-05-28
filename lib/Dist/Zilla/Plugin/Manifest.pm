package Dist::Zilla::Plugin::Manifest;
# ABSTRACT: build a MANIFEST file

use Moose;
with 'Dist::Zilla::Role::FileGatherer';

use Dist::Zilla::Pragmas;

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

sub __fix_filename ($name) {
  return $name unless $name =~ /[ '\\]/;
  $name =~ s/\\/\\\\/g;
  $name =~ s/'/\\'/g;
  return qq{'$name'};
}

sub gather_files ($self, $arg = {}) {
  my $zilla = $self->zilla;

  my $file = Dist::Zilla::File::FromCode->new({
    name => 'MANIFEST',
    code_return_type => 'bytes',
    code => sub {
      my $generated_by = sprintf "%s v%s", ref($self), $self->VERSION || '(dev)';

      return "# This file was automatically generated by $generated_by.\n"
           . join("\n", map { __fix_filename($_) } sort map { $_->name } @{ $zilla->files })
           . "\n",
    },
  });

  $self->add_file($file);
}

__PACKAGE__->meta->make_immutable;
1;
