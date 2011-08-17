package Dist::Zilla::Plugin::MetaTests;
use Moose;
extends 'Dist::Zilla::Plugin::Test::CPAN::Meta';
# ABSTRACT: (DEPRECATED) the old name for Dist::Zilla::Plugin::Test::CPAN::Meta

before register_component => sub {
  die "[MetaTests] will be removed in Dist::Zilla v6; replace it with [Test::CPAN::Meta]\n"
    if Dist::Zilla->VERSION >= 6;

  warn "!!! [MetaTests] will be removed in Dist::Zilla v6; replace it with [Test::CPAN::Meta]\n";
};

no Moose;
__PACKAGE__->meta->make_immutable;
1;
