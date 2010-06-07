use strict;
use warnings;
package Test::DZil;

use Dist::Zilla::Tester;
use Params::Util qw(_HASH0);
use JSON 2;
use Test::Deep ();
use YAML::Tiny;

use Sub::Exporter -setup => {
  exports => [
    is_filelist =>
    is_yaml     =>
    is_json     =>
    dist_ini    => \'_dist_ini',
    simple_ini  => \'_simple_ini',
  ],
  groups  => [ default => [ qw(dist_ini simple_ini is_filelist is_yaml is_json) ] ],
};

sub is_filelist {
  my ($have, $want, $comment) = @_;

  my @want = sort @$want;
  my @have = sort map { my $str = $_; $str =~ s{\\}{/}g; $str } @$have;

  Test::More::is_deeply(\@have, \@want, $comment);
}

sub is_yaml {
  my ($yaml, $want, $comment) = @_;

  my $have = YAML::Tiny->read_string($yaml)
    or die "Cannot decode YAML";

  Test::Deep::cmp_deeply($have->[0], $want, $comment);
}

sub is_json {
  my ($json, $want, $comment) = @_;

  my $have = JSON->new->ascii(1)->decode($json)
    or die "Cannot decode JSON";

  Test::Deep::cmp_deeply($have, $want, $comment);
}

sub _build_ini_builder {
  my ($starting_core) = @_;
  $starting_core ||= {};

  sub {
    my (@arg) = @_;
    my $new_core = _HASH0($arg[0]) ? shift(@arg) : {};

    my $core_config = { %$starting_core, %$new_core };

    my $config = '';

    for my $key (keys %$core_config) {
      my @values = ref $core_config->{ $key }
                 ? @{ $core_config->{ $key } }
                 : $core_config->{ $key };

      $config .= "$key = $_\n" for grep {defined} @values;
    }

    $config .= "\n" if length $config;

    for my $line (@arg) {
      my @plugin = ref $line ? @$line : ($line, {});
      my $moniker = shift @plugin;
      my $name    = _HASH0($plugin[0]) ? undef : shift @plugin;
      my $payload = shift(@plugin) || {};

      die "TOO MANY ARGS TO PLUGIN GAHLGHALAGH" if @plugin;

      $config .= '[' . $moniker;
      $config .= ' / ' . $name if defined $name;
      $config .= "]\n";

      for my $key (keys %$payload) {
        my @values = ref $payload->{ $key }
                   ? @{ $payload->{ $key } }
                   : $payload->{ $key };

        $config .= "$key = $_\n" for @values;
      }

      $config .= "\n";
    }

    return $config;
  }
}

sub _dist_ini {
  _build_ini_builder;
}

sub _simple_ini {
  _build_ini_builder({
    name     => 'DZT-Sample',
    abstract => 'Sample DZ Dist',
    version  => '0.001',
    author   => 'E. Xavier Ample <example@example.org>',
    license  => 'Perl_5',
    copyright_holder => 'E. Xavier Ample',
  });
}

1;
