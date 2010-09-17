package Dist::Zilla::Plugin::AutoPrereq;
use Moose;
extends 'Dist::Zilla::Plugin::AutoPrereqs';
# ABSTRACT: (DEPRECATED) the old name for Dist::Zilla::Plugin::AutoPrereqs

before register_component => sub {
  warn "!!! [AutoPrereq] will be removed in Dist::Zilla v5; replace it with [AutoPrereqs] (note the 's')\n";
};

no Moose;
__PACKAGE__->meta->make_immutable;
1;
