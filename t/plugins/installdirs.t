use strict;
use warnings;
use Test::More 0.88;

use lib 't/lib';

use Test::DZil;

sub test_this {
  my ($plugins, $add_files, $assertion) = @_;

  my $tzil = Dist::Zilla::Tester->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          'AllFiles',
          @$plugins,
          [ Prereq => { 'Foo::Bar' => '1.20' } ],
          [ Prereq => BuildRequires => { 'Builder::Bob' => '9.901' } ],
          [ Prereq => TestRequires  => { 'Test::Deet'   => '7'     } ],
        ),
        %$add_files,
      },
    },
  );

  $tzil->build;

  $assertion->($tzil);
}

# ShareDir

test_this(
  [ qw(MakeMaker) ],
  { },
  sub {
    my $tzil = shift;
    my $makefile = $tzil->slurp_file('build/Makefile.PL');
    unlike($makefile, qr/install_share .share./, "not going to install share");
  },
);

test_this(
  [ qw(MakeMaker ShareDir) ],
  { },
  sub {
    my $tzil = shift;
    my $makefile = $tzil->slurp_file('build/Makefile.PL');
    unlike($makefile, qr/install_share .share./, "not going to install share");
  },
);


test_this(
  [ qw(MakeMaker) ],
  { 'source/share/stupid-share.txt' => "This is a sharedir file.\n" },
  sub {
    my $tzil = shift;
    my $makefile = $tzil->slurp_file('build/Makefile.PL');
    unlike(
      $makefile,
      qr/install_share .share./,
      "files in ./share, but no ShareDir, so we will not install_share"
    );
  },
);

test_this(
  [ qw(MakeMaker ShareDir) ],
  { 'source/share/stupid-share.txt' => "This is a sharedir file.\n" },
  sub {
    my $tzil = shift;
    my $makefile = $tzil->slurp_file('build/Makefile.PL');
    like(
      $makefile,
      qr/install_share .share./,
      "files in ./share, ShareDir, so we will install_share"
    );
  },
);

test_this(
  [ qw(ModuleBuild ShareDir) ],
  { 'source/share/stupid-share.txt' => "This is a sharedir file.\n" },
  sub {
    my $tzil = shift;
    my $modulebuild = $tzil->plugin_named('ModuleBuild');
    is(
      $modulebuild->__module_build_args->{share_dir},
      'share',
      "files in ./share, ShareDir, so we have a Build.PL share_dir"
    );
  },
);

# ExecDir

test_this(
  [ qw(MakeMaker) ],
  { },
  sub {
    my $tzil = shift;
    my $makemaker = $tzil->plugin_named('MakeMaker');
    
    is_deeply(
      $makemaker->__write_makefile_args->{EXE_FILES},
      [],
      "not going to install execs",
    );
  },
);

test_this(
  [ qw(MakeMaker) ],
  { 'source/bin/be-stiff' => "#!perl\nuse D::Evo;\nuse B::Stuff;\n" },
  sub {
    my $tzil = shift;
    my $makemaker = $tzil->plugin_named('MakeMaker');
    is_deeply(
      $makemaker->__write_makefile_args->{EXE_FILES},
      [],
      "files in ./bin, but no ExecDir, not going to install execs",
    );
  },
);

test_this(
  [ qw(MakeMaker ExecDir) ],
  { 'source/bin/be-stiff' => "#!perl\nuse D::Evo;\nuse B::Stuff;\n" },
  sub {
    my $tzil = shift;
    my $makemaker = $tzil->plugin_named('MakeMaker');
    is_deeply(
      $makemaker->__write_makefile_args->{EXE_FILES},
      [ 'bin/be-stiff' ],
      "files in ./bin, ExecDir, going to install execs",
    );
  },
);

test_this(
  [ qw(ModuleBuild ExecDir) ],
  { 'source/bin/be-stiff' => "#!perl\nuse D::Evo;\nuse B::Stuff;\n" },
  sub {
    my $tzil = shift;
    my $modulebuild = $tzil->plugin_named('ModuleBuild');
    is_deeply(
      $modulebuild->__module_build_args->{script_files},
      [ 'bin/be-stiff' ],
      "files in ./bin, ExecDir, going to install execs in Build.PL",
    );
  },
);

done_testing;
