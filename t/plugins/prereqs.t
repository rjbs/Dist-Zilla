use strict;
use warnings;
use Test::More 0.88;

use lib 't/lib';

use JSON 2;
use Test::DZil;

{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          [ GatherDir => ],
          [ MetaJSON  => ],
          [ Prereq =>                 => { A => 1 }         ],
          [ Prereq => RuntimeRequires => { A => 2, B => 3 } ],
          [ Prereq => DevelopSuggests => { C => 4 }         ],
          [ Prereq => TestConflicts   => { C => 5, D => 6 } ],
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
      runtime => { requires  => { A => 2, B => 3 } },
      test    => { conflicts => { C => 5, D => 6 } },
    },
    "prereqs merged",
  );
}

{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          [ GatherDir => ],
          [ MetaJSON  => ],
          [ Prereq =>                 => { A => 1 }         ],
          [ Prereq => RuntimeRequires => { A => 2, B => 3 } ],
          [ Prereq => DevelopSuggests => { C => 4 }         ],
          [ Prereq => TestConflicts   => { C => 5, D => 6 } ],
          [ ClearPrereqs => { clear => [ qw(B C) ] } ],
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
