use strict;
use warnings;
use Test::More 0.88;

use Dist::Zilla::PluginBundle::Classic;
use Dist::Zilla::PluginBundle::Filter;

my @classic = Dist::Zilla::PluginBundle::Classic->bundle_config({
  name    => '@Classic',
  package => 'Dist::Zilla::PluginBundle::Classic',
  payload => { },
});

my @filtered = Dist::Zilla::PluginBundle::Filter->bundle_config({
  name    => '@CF',
  package => 'Dist::Zilla::PluginBundle::Filter',
  payload => {
    bundle => '@Classic',
    remove => [ qw(ManifestSkip PkgVersion) ],
  },
});

is(@filtered, @classic - 2, "filtering 2 plugins gets us 2 fewer plugins!");

my $before_count =
  grep { $_->[1] =~ /\ADist::Zilla::Plugin::(?:ManifestSkip|PkgVersion)\z/ }
  @classic;

is($before_count, 2, "we started with the 2 we wanted to remove");

my $after_count =
  grep { $_->[1] =~ /\ADist::Zilla::Plugin::(?:ManifestSkip|PkgVersion)\z/ }
  @filtered;

is($after_count, 0, "...then we removed them");

done_testing;
