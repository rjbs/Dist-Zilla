use strict;
use warnings;
use Test::More 0.88;

use Test::DZil;

sub test_this {
  my ($plugins, $add_files, $assertion) = @_;

  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          'GatherDir',
          @$plugins,
          [ Prereqs => { 'Foo::Bar' => '1.20' } ],
          [ Prereqs => BuildRequires => { 'Builder::Bob' => '9.901' } ],
          [ Prereqs => TestRequires  => { 'Test::Deet'   => '7'     } ],
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
    unlike($makefile, qr/install_share dist => .share./, "not going to install share");
  },
);

test_this(
  [ qw(MakeMaker ShareDir) ],
  { },
  sub {
    my $tzil = shift;
    my $makefile = $tzil->slurp_file('build/Makefile.PL');
    unlike($makefile, qr/install_share dist => .share./, "not going to install share");
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
      qr/install_share dist => .share./,
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
      qr/install_share dist => .share./,
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
      $modulebuild->__module_build_args->{share_dir}{dist},
      'share',
      "files in ./share, ShareDir, so we have a Build.PL share_dir"
    );
  },
);

# ModuleShareDirs

test_this(
  [ qw(MakeMaker) ],
  { },
  sub {
    my $tzil = shift;
    my $makefile = $tzil->slurp_file('build/Makefile.PL');
    unlike($makefile, qr/install_share module => .DZT::Simple., .share./,
      "not going to install module-based share"
    );
  },
);

test_this(
  [ qw(MakeMaker ModuleShareDirs) ],
  { },
  sub {
    my $tzil = shift;
    my $makefile = $tzil->slurp_file('build/Makefile.PL');
    unlike($makefile, qr/install_share module => .DZT::Simple., .share./,
      "not going to install module-based share"
    );
  },
);

test_this(
  [ qw(MakeMaker ModuleShareDirs) ],
  { 'source/share/stupid-share.txt' => "This is a sharedir file.\n" },
  sub {
    my $tzil = shift;
    my $makefile = $tzil->slurp_file('build/Makefile.PL');
    unlike($makefile, qr/install_share module => .DZT::Simple., .share./,
      "files in ./share, empty ModuleShareDirs, so we will not install_share"
    );
  },
);

test_this(
  [
    'MakeMaker',
    ['ModuleShareDirs' => { 'DZT::Simple' => 'share' } ],
  ],
  { 'source/share/stupid-share.txt' => "This is a sharedir file.\n" },
  sub {
    my $tzil = shift;
    my $makefile = $tzil->slurp_file('build/Makefile.PL');
    like($makefile, qr/install_share module => .DZT::Simple., .share./,
      "files in ./share, ModuleShareDirs given, so we will install_share"
    );
  },
);

test_this(
  [
    'MakeMaker',
    ['ModuleShareDirs' => { 'DZT::Simple' => 'share', 'DZT::Other' => 'other' } ],
  ],
  {
    'source/share/stupid-share.txt' => "This is a sharedir file.\n",
    'source/other/stupid-other.txt' => "This is another sharedir file.\n",
  },
  sub {
    my $tzil = shift;
    my $makefile = $tzil->slurp_file('build/Makefile.PL');
    like($makefile, qr/install_share module => .DZT::Simple., .share./,
      "files in ./share, ModuleShareDirs given, so we will install_share"
    );
    like($makefile, qr/install_share module => .DZT::Other., .other./,
      "files in ./other, another ModuleShareDirs given, so we will install_share"
    );
  },
);

test_this(
  [
    'MakeMaker', 'ShareDir',
    ['ModuleShareDirs' => { 'DZT::Simple' => 'simple', 'DZT::Other' => 'other' } ],
  ],
  {
    'source/share/stupid-share.txt' => "This is a sharedir file.\n",
    'source/other/stupid-other.txt' => "This is another sharedir file.\n",
    'source/simple/stupid-other.txt' => "This is another simple sharedir file.\n",
  },
  sub {
    my $tzil = shift;
    my $makefile = $tzil->slurp_file('build/Makefile.PL');
    like($makefile, qr/install_share dist => .share./,
      "ShareDir and ModuleShareDirs: dist share"
    );
    like($makefile, qr/install_share module => .DZT::Simple., .simple./,
      "ShareDir and ModuleShareDirs: first module share",
    );
    like($makefile, qr/install_share module => .DZT::Other., .other./,
      "ShareDir and ModuleShareDirs: other module share"
    );
  },
);

test_this(
  [
    'ModuleBuild',
    ['ModuleShareDirs' => { 'DZT::Simple' => 'share' } ],
  ],
  { 'source/share/stupid-share.txt' => "This is a sharedir file.\n" },
  sub {
    my $tzil = shift;
    my $modulebuild = $tzil->plugin_named('ModuleBuild');
    is(
      $modulebuild->__module_build_args->{share_dir}{module}{'DZT::Simple'},
      'share',
      "files in ./share, ModuleShareDirs given, so we have a Build.PL share_dir"
    );
  },
);

test_this(
  [
    'ModuleBuild', 'ShareDir',
    ['ModuleShareDirs' => { 'DZT::Simple' => 'simple', 'DZT::Other' => 'other' } ],
  ],
  {
    'source/share/stupid-share.txt' => "This is a sharedir file.\n",
    'source/other/stupid-other.txt' => "This is another sharedir file.\n",
    'source/simple/stupid-other.txt' => "This is another simple sharedir file.\n",
  },
  sub {
    my $tzil = shift;
    my $modulebuild = $tzil->plugin_named('ModuleBuild');
    is_deeply(
      $modulebuild->__module_build_args->{share_dir},
      {
        dist => 'share',
        module => {
          'DZT::Simple' => 'simple',
          'DZT::Other' => 'other',
        },
      },
      "ModuleBuild with ShareDir and ModuleShareDirs"
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

    ok(
      !exists $makemaker->__write_makefile_args->{EXE_FILES},
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
    ok(
      !exists $makemaker->__write_makefile_args->{EXE_FILES},
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
