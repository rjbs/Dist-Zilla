package Dist::Zilla::Plugin::PodCoverageTests;
use Moose;
extends 'Dist::Zilla::Plugin::Test::Pod::Coverage';
# ABSTRACT: (DEPRECATED) the old name for Dist::Zilla::Plugin::Test::Pod::Coverage

before register_component => sub {
  die "[PodCoverageTests] will be removed in Dist::Zilla v6; replace it with [Test::Pod::Coverage]\n"
    if Dist::Zilla->VERSION >= 6;

  warn "!!! [PodCoverageTests] will be removed in Dist::Zilla v6; replace it with [Test::Pod::Coverage]\n";
};

no Moose;
__PACKAGE__->meta->make_immutable;
1;
