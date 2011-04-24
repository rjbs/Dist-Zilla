use strict;
use warnings;
use Test::More 0.88;

use lib 't/lib';

use JSON 2;
use Test::DZil;

{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          [ GatherDir => ],
          [ MetaJSON  => ],
          [ Prereqs =>                 => { A => 1 }         ],
          [ Prereqs => RuntimeRequires => { A => 2, B => 3 } ],
          [ Prereqs => DevelopSuggests => { C => 4 }         ],
          [ Prereqs => TestConflicts   => { C => 5, D => 6 } ],
          [ Prereqs => Recommends      => { E => 7 }         ],
        ),
      },
    },
  );

  $tzil->build;

  my $json = $tzil->slurp_file('build/META.json');

  my $meta = JSON->new->decode($json);

  is_deeply(
    $meta->{prereqs},
    {
      develop => { suggests  => { C => 4 } },
      runtime => {
        requires   => { A => 2, B => 3 },
        recommends => { E => 7 },
      },
      test    => { conflicts => { C => 5, D => 6 } },
    },
    "prereqs merged",
  );
}

{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          [ GatherDir => ],
          [ MetaJSON  => ],
          [ Prereqs =>                 => { A => 1 }         ],
          [ Prereqs => RuntimeRequires => { A => 2, B => 3 } ],
          [ Prereqs => DevelopSuggests => { C => 4 }         ],
          [ Prereqs => TestConflicts   => { C => 5, D => 6 } ],
          [ RemovePrereqs => { remove => [ qw(B C) ] } ],
        ),
      },
    },
  );

  $tzil->build;

  my $json = $tzil->slurp_file('build/META.json');

  my $meta = JSON->new->decode($json);

  is_deeply(
    $meta->{prereqs},
    {
      runtime => { requires  => { A => 2 } },
      test    => { conflicts => { D => 6 } },
    },
    "prereqs merged and pruned",
  );
}

done_testing;
