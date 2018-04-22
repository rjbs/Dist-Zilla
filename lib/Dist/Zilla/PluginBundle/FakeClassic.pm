package Dist::Zilla::PluginBundle::FakeClassic;
# ABSTRACT: build something more or less like a "classic" CPAN dist

use Moose;
extends 'Dist::Zilla::PluginBundle::Classic';

use Dist::Zilla::Dialect;

use namespace::autoclean;

around bundle_config => sub ($orig, $self, $arg, @rest) {
  my @config = $self->$orig($arg, @rest);

  for my $i (0 .. $#config) {
    if ($config[ $i ][1] eq 'Dist::Zilla::Plugin::UploadToCPAN') {
      require Dist::Zilla::Plugin::FakeRelease;
      $config[ $i ] = [
        "$arg->{name}/FakeRelease",
        'Dist::Zilla::Plugin::FakeRelease',
        $config[ $i ][2]
      ];
    }
  }

  return @config;
};

__PACKAGE__->meta->make_immutable;
1;
