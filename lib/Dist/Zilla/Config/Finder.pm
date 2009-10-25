package Dist::Zilla::Config::Finder;
use Moose;
with 'Config::MVP::Reader::Finder';
# ABSTRACT: the reader for dist.ini files

use Dist::Zilla::Util::MVPAssembler;

has '+assembler' => (
  default => sub {
    my $assembler = Dist::Zilla::Util::MVPAssembler->new;

    my $root = $assembler->section_class->new({
      name => '_',
      aliases => { author => 'authors' },
      multivalue_args => [ qw(authors) ],
    });

    $assembler->sequence->add_section($root);

    return $assembler;
  }
);

sub default_search {
  return qw(Dist::Zilla::Config Config::MVP::Reader);
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
