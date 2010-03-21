use strict;
use warnings;
package Test::DZil;

use Dist::Zilla::Tester;
use Params::Util qw(_HASH0);

use Sub::Exporter -setup => {
  exports => [
    dist_ini   => \'_dist_ini',
    simple_ini => \'_simple_ini',
  ],
  groups  => [ default => [ qw(dist_ini simple_ini) ] ],
};

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
