use strict;
use warnings;
use Test::More 0.88;

use Test::DZil;
use Test::Deep;

{
  package Keywords; # see also Dist::Zilla::Plugin::Keywords ;)
  use Moose;
  with 'Dist::Zilla::Role::MetaProvider';

  sub mvp_multivalue_args { qw(keywords) }

  has keywords => (
    is => 'ro', isa => 'ArrayRef[Str]',
    lazy => 1,
    default => sub { [] },
  );

  sub metadata
  {
    my $self = shift;
    my $keywords = $self->keywords;
    return { @$keywords ? ( keywords => $keywords ) : () };
  }
}

{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          [ '=Keywords' => 'plugin 1' => { keywords => [ qw(foo bar) ] } ],
          [ '=Keywords' => 'plugin 2' => { keywords => [ qw(dog cat) ] } ],
        ),
      },
    },
  );


  cmp_deeply(
    $tzil->distmeta,
    {
      abstract       => 'Sample DZ Dist',
      author         => ['E. Xavier Ample <example@example.org>'],
      dynamic_config => 0,
      generated_by   => ignore,
      license        => [ 'perl_5' ],
      'meta-spec'    => {
        url     => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec',
        version => 2
      },
      name      => 'DZT-Sample',
      release_status => 'stable',
      version => '0.001',
      keywords => [ qw(foo bar dog cat) ],
      x_generated_by_perl => "$^V",
      x_spdx_expression => 'Artistic-1.0-Perl OR GPL-1.0-or-later',
    },
    'metadata is correctly merged together',
  );
}

done_testing;
