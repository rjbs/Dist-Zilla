use strict;
use warnings;

use Test::More;
use Test::DZil;
use Test::Deep;
use Test::Fatal;
use Path::Tiny;
use List::Util 'first';

my $tzil = Builder->from_config(
  { dist_root => 't/does_not_exist' },
  {
    add_files => {
      path(qw(source dist.ini)) => simple_ini(
        'GatherDir',       # a file gatherer (adds OnDisk file)
        'PodSyntaxTests',  # a file gatherer (adds InMemory file)
        'Manifest',        # a file gatherer (adds FromCode file)

        # a file munger that changes content
        [ PkgVersion => { finder => ':AllFiles' } ],

        'ExtraTests',      # a file munger that changes filename
      ),
      path(qw(source lib DZT Sample.pm)) => "package DZT::Sample;\n\n1",
    },
  },
);

$tzil->chrome->logger->set_debug(1);
is(
  exception { $tzil->build },
  undef,
  'build proceeds normally',
) or diag 'saw log messages: ', explain $tzil->log_messages;

my $module = first { $_->name eq path(qw(lib DZT Sample.pm)) }
             @{ $tzil->files };

cmp_deeply(
  $module,
  methods(
    added_by => all(
      re(qr/\bencoded_content added by GatherDir \(Dist::Zilla::Plugin::GatherDir line \d+\)(;|$)/),
      re(qr/\bcontent set by PkgVersion \(Dist::Zilla::Plugin::PkgVersion line \d+\)(;|$)/),
    ),
  ),
  'OnDisk file added by GatherDir, set by PkgVersion has correct properties',
);

my $test = first { $_->name eq path(qw(t author-pod-syntax.t)) }
           @{ $tzil->files };

cmp_deeply(
  $test,
  methods(
    added_by => all(
      re(qr/^content added by PodSyntaxTests \(Dist::Zilla::Plugin::InlineFiles line \d+\)(;|$)/),
      re(qr/\bcontent set by ExtraTests \(Dist::Zilla::Plugin::ExtraTests line \d+\)(;|$)/),
      re(qr/\bfilename set by ExtraTests \(Dist::Zilla::Plugin::ExtraTests line \d+\)(;|$)/),
    ),
  ),
  'InMemory file altered by all of PodSyntaxTests, PkgVersion and ExtraTests has correct properties',
);

my $manifest = first { $_->name eq path('MANIFEST') } @{ $tzil->files };
cmp_deeply(
  $manifest,
  methods(
    added_by => re(qr/^bytes from coderef added by Manifest \(Dist::Zilla::Plugin::Manifest line \d+\)$/),
  ),
  'FromCode file added by Manifest has correct properties',
);

done_testing;
