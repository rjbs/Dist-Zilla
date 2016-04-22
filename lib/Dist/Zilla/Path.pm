use strict;
use warnings;
use utf8;

package Dist::Zilla::Path;
# ABSTRACT: a helper to get Path::Tiny objects

use parent 'Path::Tiny';

use Path::Tiny 0.052 qw();  # issue 427
use Scalar::Util qw( blessed );
use Sub::Exporter -setup => {
  exports => [ qw( path ) ],
  groups  => { default => [ qw( path ) ] },
};

sub path {
  my ($thing, @rest) = @_;

  if (@rest == 0 && blessed $thing) {
    return $thing if $thing->isa(__PACKAGE__);

    return bless(Path::Tiny::path("$thing"), __PACKAGE__)
      if $thing->isa('Path::Class::Entity') || $thing->isa('Path::Tiny');
  }

  return bless(Path::Tiny::path($thing, @rest), __PACKAGE__);
}

sub file {
  my ($self, @file) = @_;
  require Path::Class;
  Path::Class::dir($self)->file(@file);
}

sub subdir {
  my ($self, @subdir) = @_;
  require Path::Class;
  Path::Class::dir($self)->file(@subdir);
}

1;
