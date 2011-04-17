package Dist::Zilla::Plugin::PodSyntaxTests;
use Moose;
extends 'Dist::Zilla::Plugin::Test::Pod';
# ABSTRACT: (DEPRECATED) the old name for Dist::Zilla::Plugin::Test::Pod

before register_component => sub {
  die "[PodSyntaxTests] will be removed in Dist::Zilla v6; replace it with [Test::Pod]\n"
    if Dist::Zilla->VERSION >= 6;

  warn "!!! [PodSyntaxTests] will be removed in Dist::Zilla v6; replace it with [Test::Pod]\n";
};

no Moose;
__PACKAGE__->meta->make_immutable;
1;
