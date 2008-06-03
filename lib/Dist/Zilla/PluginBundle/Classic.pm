package Dist::Zilla::PluginBundle::Classic;
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::PluginBundle';

sub bundle_config {
  my ($self) = @_;
  my $class = ref $self;

  my @classes = qw(
    Dist::Zilla::Plugin::BumpVersion
    Dist::Zilla::Plugin::ManifestSkip
    Dist::Zilla::Plugin::MakeMaker
    Dist::Zilla::Plugin::MetaYaml
    Dist::Zilla::Plugin::License
    Dist::Zilla::Plugin::PkgVersion
    Dist::Zilla::Plugin::PodVersion
    Dist::Zilla::Plugin::ExtraTests
    Dist::Zilla::Plugin::Manifest
  );

  eval "require $_; 1" or die for @classes;

  return @classes->map(sub { [ $_ => { '=name' => "$self/$_" } ] })->flatten;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
