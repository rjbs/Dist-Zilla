use strict;
use warnings;
use utf8;

package Dist::Zilla::Path;
# ABSTRACT: a helper to get Path::Tiny objects

use Dist::Zilla::Dialect;

use Path::Tiny 0.052 qw( path );  # issue 427
use Sub::Exporter -setup => {
  exports => [ qw( path ) ],
  groups  => { default => [ qw( path ) ] },
};

1;
