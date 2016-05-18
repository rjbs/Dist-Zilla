package Dist::Zilla::PluginBundle::Basic;
# ABSTRACT: the basic plugins to maintain and release CPAN dists

use Moose;
with 'Dist::Zilla::Role::PluginBundle::Easy';

use Dist::Zilla::Dialect;

use namespace::autoclean;

sub configure ($self) {
  $self->add_plugins(qw(
    GatherDir
    PruneCruft
    ManifestSkip
    MetaYAML
    MetaJSON
    License
    Readme
    ExtraTests
    ExecDir
    ShareDir

    MakeMaker
    Manifest

    TestRelease
    ConfirmRelease
    UploadToCPAN
  ));
}

__PACKAGE__->meta->make_immutable;
1;

=head1 DESCRIPTION

This plugin is meant to be a basic "first step" bundle for using Dist::Zilla.
It won't munge any of your code, but will generate a F<Makefile.PL> and allows
easy, reliable releasing of distributions.

It includes the following plugins with their default configuration:

=for :list
* L<Dist::Zilla::Plugin::GatherDir>
* L<Dist::Zilla::Plugin::PruneCruft>
* L<Dist::Zilla::Plugin::ManifestSkip>
* L<Dist::Zilla::Plugin::MetaYAML>
* L<Dist::Zilla::Plugin::MetaJSON>
* L<Dist::Zilla::Plugin::License>
* L<Dist::Zilla::Plugin::Readme>
* L<Dist::Zilla::Plugin::ExtraTests>
* L<Dist::Zilla::Plugin::ExecDir>
* L<Dist::Zilla::Plugin::ShareDir>
* L<Dist::Zilla::Plugin::MakeMaker>
* L<Dist::Zilla::Plugin::Manifest>
* L<Dist::Zilla::Plugin::TestRelease>
* L<Dist::Zilla::Plugin::ConfirmRelease>
* L<Dist::Zilla::Plugin::UploadToCPAN>

=head1 SEE ALSO

Core Dist::Zilla plugins: L<@Filter|Dist::Zilla::PluginBundle::Filter>.

Dist::Zilla roles:
L<PluginBundle|Dist::Zilla::Role::PluginBundle>,
L<PluginBundle::Easy|Dist::Zilla::Role::PluginBundle::Easy>.

=cut

