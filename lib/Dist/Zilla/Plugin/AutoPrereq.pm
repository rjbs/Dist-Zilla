package Dist::Zilla::Plugin::AutoPrereq;
use Moose;
extends 'Dist::Zilla::Plugin::AutoPrereqs';
# ABSTRACT: (DEPRECATED) the old name for Dist::Zilla::Plugin::AutoPrereqs

use namespace::autoclean;

before register_component => sub {
  die "[AutoPrereq] will be removed in Dist::Zilla v5; replace it with [AutoPrereqs] (note the 's')\n"
    if Dist::Zilla->VERSION >= 5;

  warn "!!! [AutoPrereq] will be removed in Dist::Zilla v5; replace it with [AutoPrereqs] (note the 's')\n";
};

__PACKAGE__->meta->make_immutable;
1;
