package Dist::Zilla::Config::Finder;
use Moose;
use Config::MVP::Reader 2;
extends 'Config::MVP::Reader::Finder';
with 'Dist::Zilla::Config';
# ABSTRACT: the reader for dist.ini files

use Dist::Zilla::Util::MVPAssembler;

sub default_search_path {
  return qw(Dist::Zilla::Config Config::MVP::Reader);
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
