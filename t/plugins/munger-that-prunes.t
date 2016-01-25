use strict;
use warnings;
use Test::More 0.88;

use lib 't/lib';

use Test::DZil;
use YAML::Tiny;

{
   my $tzil = Builder->from_config(
      { dist_root => 'corpus/dist/DZT' },
      {
         add_files => {
            'source/Build.pod'  => "This file is cruft.\n",
            'source/Build2.pod' => "This other file is cruft.\n",
            'source/Build3.pod' => "This third file is cruft.\n",
            'source/dist.ini'   => simple_ini(
               'GatherDir',
               'MungerThatPrunesPodFiles',
            ),
         },
      },
   );
   
   $tzil->build;
   
   my @files = map {; $_->name } @{ $tzil->files };
   is_filelist(
      [ @files ],
      [ qw(lib/DZT/Sample.pm t/basic.t dist.ini) ],
      'munge_file that call prunes does not mangle $self->zilla->files',
   );
}

done_testing;
