use strict;
use warnings;
use utf8;

package Dist::Zilla::Types::Path;

# ABSTRACT: Workalike for MooseX::Types::Path::Class for Dist::Zilla::Path
use namespace::autoclean;

use MooseX::Types -declare => [qw( Dir File )];

use MooseX::Types::Moose qw(Str ArrayRef);

require Dist::Zilla::Path;

# Because loading MX:Types:Path:Class
# loads Path::Class itself and we want to avoid that so we can apply Devel::Hide
# we avoid using MX:Types:Path:Class
#
# Also, we don't really need the Dir and File types from it,
# only coercions for the respective classes ::Dir and ::File

class_type('Dist::Zilla::Path');
my $pc_dir = class_type('Path::Class::Dir');
my $pc_file = class_type('Path::Class::File');

class_type('Path::Tiny');
subtype Dir,  as 'Dist::Zilla::Path';
subtype File, as 'Dist::Zilla::Path';

coerce 'Dist::Zilla::Path',
  from Str,      via { Dist::Zilla::Path::path($_) },
  from ArrayRef, via { Dist::Zilla::Path::path(@$_) },
  from $pc_dir,   via { Dist::Zilla::Path::path($_) },
  from $pc_file,  via { Dist::Zilla::Path::path($_) },
  from 'Path::Tiny',        via { Dist::Zilla::Path::path($_) };

coerce Dir,
  from Str,      via { Dist::Zilla::Path::path($_) },
  from ArrayRef, via { Dist::Zilla::Path::path(@$_) },
  from $pc_dir,   via { Dist::Zilla::Path::path($_) },
  from 'Path::Tiny',        via { Dist::Zilla::Path::path($_) };


coerce File,
  from Str,      via { Dist::Zilla::Path::path($_) },
  from ArrayRef, via { Dist::Zilla::Path::path(@$_) },
  from $pc_file,  via { Dist::Zilla::Path::path($_) },
  from 'Path::Tiny',        via { Dist::Zilla::Path::path($_) };

1;

