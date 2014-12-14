use strict;
use warnings;
use Test::More 0.88;
use Test::Fatal qw(exception);
use Test::Deep;

use Test::DZil;

{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          [ GatherDir => ],
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

  cmp_deeply(
    $tzil->distmeta,,
    superhashof({
      prereqs => {
        develop => { suggests  => { C => 4 } },
        runtime => {
          requires   => { A => 2, B => 3 },
          recommends => { E => 7 },
        },
        test    => { conflicts => { C => 5, D => 6 } },
      }
    }),
    "prereqs merged",
  );
}

# test that we avoid a CPAN.pm bug by synchronizing Runtime|Build|Test requires
{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          [ GatherDir => ],
          [ Prereqs => RuntimeRequires  => { A => 2, B => 0, C => 2 } ],
          [ RemovePrereqs => { remove => [ qw(C) ] } ],
          [ Prereqs => TestRequires     => { A => 1, B => 1, C => 1 } ],
          [ Prereqs => BuildRequires    => { A => 0, B => 2, C => 0 } ],
        ),
      },
    },
  );

  $tzil->build;

  is_deeply(
    $tzil->distmeta->{prereqs},
    {
      runtime => {
        requires   => { A => 2, B => 2 },
      },
      test => {
        requires   => { A => 2, B => 2, C => 1 },
      },
      build => {
        requires   => { A => 2, B => 2, C => 1 },
      },
    },
    "prereqs synchronized across runtime, build & test phases",
  );
}

{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          [ GatherDir => ],
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

  cmp_deeply(
    $tzil->distmeta,
    superhashof(
      {
        prereqs =>
        {
          runtime => { requires  => { A => 2 } },
          test    => { conflicts => { D => 6 } },
        },
      }
    ),
    "prereqs merged and pruned",
  );
}

{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          [ GatherDir => ],
          [ Prereqs => { A => 1 } ],
          [ Prereqs => P1
            => { qw(-phase runtime -type requires), A => 2, B => 3 } ],
          [ Prereqs => P2
            => { qw(-phase develop -type suggests), C => 4 }         ],
          [ Prereqs => P3
            => { qw(-phase test -relationship conflicts), C => 5, D => 6 } ],
          [ Prereqs => P4
            => { qw(-type recommends),              E => 7 }         ],
        ),
      },
    },
  );

  $tzil->build;

  cmp_deeply(
    $tzil->distmeta,
    superhashof(
      {
        prereqs =>
        {
          develop => { suggests  => { C => 4 } },
          runtime => {
            requires   => { A => 2, B => 3 },
            recommends => { E => 7 },
          },
          test    => { conflicts => { C => 5, D => 6 } },
        },
      }
    ),
    "-phase, -type, & -relationship",
  );
}

{
  like( exception {
    Builder->from_config(
      { dist_root => 'corpus/dist/DZT' },
      {
        add_files => {
          'source/dist.ini' => simple_ini(
            [ Prereqs => { A => 1 } ],
            [ Prereqs => NotMagic => { B => 3 } ],
          ),
        },
      },
    );
  },
        qr/No -phase or -relationship specified/,
        "non-magic name dies");
}

{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          [ Prereqs => 'Bundle/Prereqs' => { A => 1 } ],
          [ Prereqs => 'Other/Prereq'   => { B => 1 } ],
          [ Prereqs => P1 => { qw(-phase runtime), C => 2 } ],
          [ Prereqs => P2 => { qw(-relationship requires), D => 2 } ],
          [ Prereqs => P3 => { qw(-phase configure), E => 2 } ],
          [ Prereqs => P4 => { qw(-phase build -type suggests), F => 2 } ],
          # Mixing a magic name with -phase or -type is *NOT RECOMMENDED*
          # but it does work (at least for now)
          [ Prereqs => Recommends => { qw(-phase test), G => 2 } ],
        ),
      },
    },
  );

  my @expected = qw(
    Bundle/Prereqs runtime requires
    Other/Prereq   runtime requires
    P1             runtime requires
    P2             runtime requires
    P3             configure requires
    P4             build suggests
    Recommends     test recommends
  );

  while (@expected) {
    my $name = shift @expected;
    my $p = $tzil->plugin_named($name);
    is($p->prereq_phase, shift @expected, "$name phase");
    is($p->prereq_type,  shift @expected, "$name relationship");
  }
}

done_testing;
