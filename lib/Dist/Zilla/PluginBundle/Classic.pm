package Dist::Zilla::PluginBundle::Classic;
# ABSTRACT: the classic (old) default configuration for Dist::Zilla
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::PluginBundle';

sub bundle_config {
  my ($self, $arg) = @_;

  my @plugins = qw(
    GatherDir
    PruneCruft
    ManifestSkip
    MetaYAML
    License
    Readme
    PkgVersion
    PodVersion
    PodCoverageTests
    PodSyntaxTests
    ExtraTests
    ExecDir
    ShareDir

    MakeMaker
    Manifest

    ConfirmRelease
    UploadToCPAN
  );

  my @config;
  for (@plugins) {
    my $class = "Dist::Zilla::Plugin::$_";
    Class::MOP::load_class($class);

    push @config, [ "$arg->{name}/$_" => $class => {} ];
  }

  return @config;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
__END__

=head1 DESCRIPTION

This bundle is more or less the original configuration bundled with
Dist::Zilla.  More than likely, you'd rather be using
L<@Basic|Dist::Zilla::PluginBundle::Basic> or a more complex bundle.  This one
will muck around with your code by adding C<$VERSION> declarations and will
mess with you Pod by adding a C<=head1 VERSION> section, but it won't get you a
lot of more useful features like autoversioning, autoprereqs, or Pod::Weaver.

It includes the following plugins with their default configuration:

* L<Dist::Zilla::Plugin::GatherDir>
* L<Dist::Zilla::Plugin::PruneCruft>
* L<Dist::Zilla::Plugin::ManifestSkip>
* L<Dist::Zilla::Plugin::MetaYAML>
* L<Dist::Zilla::Plugin::License>
* L<Dist::Zilla::Plugin::Readme>
* L<Dist::Zilla::Plugin::PkgVersion>
* L<Dist::Zilla::Plugin::PodVersion>
* L<Dist::Zilla::Plugin::PodCoverageTests>
* L<Dist::Zilla::Plugin::PodSyntaxTests>
* L<Dist::Zilla::Plugin::ExtraTests>
* L<Dist::Zilla::Plugin::ExecDir>
* L<Dist::Zilla::Plugin::ShareDir>
* L<Dist::Zilla::Plugin::MakeMaker>
* L<Dist::Zilla::Plugin::Manifest>
* L<Dist::Zilla::Plugin::ConfirmRelease>
* L<Dist::Zilla::Plugin::UploadToCPAN>

=cut

