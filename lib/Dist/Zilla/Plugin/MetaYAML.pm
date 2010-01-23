package Dist::Zilla::Plugin::MetaYAML;
# ABSTRACT: produce a META.yml
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::FileGatherer';

use Hash::Merge::Simple ();

=head1 DESCRIPTION

This plugin will add a F<META.yml> file to the distribution.

For more information on this file, see L<Module::Build::API> and
L<http://module-build.sourceforge.net/META-spec-v1.3.html>.

=cut

sub gather_files {
  my ($self, $arg) = @_;

  require Dist::Zilla::File::FromCode;
  require YAML::Tiny;

  my $zilla = $self->zilla;
  my $file  = Dist::Zilla::File::FromCode->new({
    name => 'META.yml',
    code => sub {
      YAML::Tiny::Dump($zilla->distmeta);
    },
  });

  $self->add_file($file);
  return;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
