package Dist::Zilla::PluginBundle::FakeClassic;
# ABSTRACT: build something more or less like a "classic" CPAN dist

use Moose;
extends 'Dist::Zilla::PluginBundle::Classic';

# BEGIN BOILERPLATE
use v5.20.0;
use warnings;
use utf8;
no feature 'switch';
use experimental qw(postderef postderef_qq); # This experiment gets mainlined.
# END BOILERPLATE

use namespace::autoclean;

around bundle_config => sub {
  my ($orig, $self, $arg) = @_;

  my @config = $self->$orig($arg);

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
