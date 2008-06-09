package Dist::Zilla::PluginBundle::Classic;
# ABSTRACT: build something more or less like a "classic" CPAN dist
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::PluginBundle';

sub bundle_config {
  my ($self) = @_;
  my $class = ref $self;

  my @classes = qw(
    Dist::Zilla::Plugin::AllFiles
    Dist::Zilla::Plugin::BumpVersion
    Dist::Zilla::Plugin::ManifestSkip
    Dist::Zilla::Plugin::MetaYaml
    Dist::Zilla::Plugin::License
    Dist::Zilla::Plugin::Readme
    Dist::Zilla::Plugin::PkgVersion
    Dist::Zilla::Plugin::PodVersion
    Dist::Zilla::Plugin::PodTests
    Dist::Zilla::Plugin::ExtraTests
    Dist::Zilla::Plugin::InstallDirs

    Dist::Zilla::Plugin::MakeMaker
    Dist::Zilla::Plugin::Manifest
  );

  eval "require $_; 1" or die for @classes; ## no critic Carp

  return @classes->map(sub { [ $_ => { '=name' => "$class/$_" } ] })->flatten;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
