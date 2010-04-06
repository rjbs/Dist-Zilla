package Dist::Zilla::PluginBundle::Basic;
# ABSTRACT: the basic plugins to maintain and release CPAN dists
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
    ExtraTests
    ExecDir
    ShareDir

    MakeMaker
    Manifest

    TestRelease
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

This plugin is meant to be a basic "first step" bundle for using Dist::Zilla.
It won't munge any of your code, but will generate a F<Makefile.PL> and allows
easy, reliable releasing of distributions.

It includes the following plugins with their default configuration:

=for :list
* L<Dist::Zilla::Plugin::GatherDir>
* L<Dist::Zilla::Plugin::PruneCruft>
* L<Dist::Zilla::Plugin::ManifestSkip>
* L<Dist::Zilla::Plugin::MetaYAML>
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

=cut

