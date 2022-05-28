package Test::DZil;
# ABSTRACT: tools for testing Dist::Zilla plugins

use Dist::Zilla::Pragmas;

use Params::Util qw(_HASH0);
use JSON::MaybeXS;
use Scalar::Util qw(blessed);
use Test::Deep ();
use YAML::Tiny;

use Sub::Exporter -setup => {
  exports => [
    is_filelist =>
    is_yaml     =>
    is_json     =>
    dist_ini    => \'_dist_ini',
    simple_ini  => \'_simple_ini',
    Builder     =>
    Minter      =>
  ],
  groups  => [ default => [ qw(-all) ] ],
};

use namespace::autoclean -except => 'import';

=head1 DESCRIPTION

Test::DZil provides routines for writing tests for Dist::Zilla plugins.

=cut

=func Builder

=func Minter

  my $tzil = Builder->from_config(...);

These return class names that subclass L<Dist::Zilla::Dist::Builder> or
L<Dist::Zilla::Dist::Minter>, respectively, with the L<Dist::Zilla::Tester>
behavior added.

=cut

sub Builder {
  require Dist::Zilla::Tester;
  Dist::Zilla::Tester::builder();
}

sub Minter {
  require Dist::Zilla::Tester;
  Dist::Zilla::Tester::minter();
}

=func is_filelist

  is_filelist( \@files_we_have, \@files_we_want, $desc );

This test assertion compares two arrayrefs of filenames, taking care of slash
normalization and sorting.  C<@files_we_have> may also contain objects that
do L<Dist::Zilla::Role::File>.

=cut

sub is_filelist {
  my ($have, $want, $comment) = @_;

  my @want = @$want;
  my @have = map { my $str = (blessed $_ and
                              $_->DOES('Dist::Zilla::Role::File'))
                       ? $_->name
                       : $_;
                   $str =~ s{\\}{/}g; $str } @$have;

  local $Test::Builder::Level = $Test::Builder::Level + 1;
  Test::Deep::cmp_bag(\@have, \@want, $comment);
}

=func is_yaml

  is_yaml( $yaml_string, $want_struct, $comment );

This test assertion deserializes the given YAML string and does a
C<L<cmp_deeply|Test::Deep/cmp_deeply>>.

=cut

sub is_yaml {
  my ($yaml, $want, $comment) = @_;

  my $have = YAML::Tiny->read_string($yaml)
    or die "Cannot decode YAML";

  local $Test::Builder::Level = $Test::Builder::Level + 1;
  Test::Deep::cmp_deeply($have->[0], $want, $comment);
}

=func is_json

  is_json( $json_string, $want_struct, $comment );

This test assertion deserializes the given JSON string and does a
C<L<cmp_deeply|Test::Deep/cmp_deeply>>.

=cut

sub is_json {
  my ($json, $want, $comment) = @_;

  my $have = JSON::MaybeXS->new(ascii => 1)->decode($json)
    or die "Cannot decode JSON";

  local $Test::Builder::Level = $Test::Builder::Level + 1;
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

    for my $key (sort keys %$core_config) {
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

      Carp::confess("bogus plugin configuration: too many args") if @plugin;

      $config .= '[' . $moniker;
      $config .= ' / ' . $name if defined $name;
      $config .= "]\n";

      for my $key (sort keys %$payload) {
        my @values = ref $payload->{ $key }
                   ? @{ $payload->{ $key } }
                   : $payload->{ $key };

        $config .= "$key = $_\n" for grep {defined} @values;
      }

      $config .= "\n";
    }

    return $config;
  }
}

=func dist_ini

  my $ini_text = dist_ini(\%root_config, @plugins);

This routine returns a string that could be used to populate a simple
F<dist.ini> file.  The C<%root_config> gives data for the "root" section of the
configuration.  To provide a line multiple times, provide an arrayref.  For
example, the root section could read:

  {
    name   => 'Dist-Sample',
    author => [
      'J. Smith <jsmith@example.com>',
      'Q. Smith <qsmith@example.com>',
    ],
  }

The root section is optional.

Plugins can be given in a few ways:

=begin :list

= C<"PluginMoniker">

= C<[ "PluginMoniker" ]>

These become C<[PluginMoniker]>

= C<[ "PluginMoniker", "PluginName" ]>

This becomes C<[PluginMoniker / PluginName]>

= C<[ "PluginMoniker", { ... } ]>

= C<[ "PluginMoniker", "PluginName", { ... } ]>

These use the given hashref as the parameters inside the section, with the same
semantics as the root section.

=end :list

=cut

sub _dist_ini {
  _build_ini_builder;
}

=func simple_ini

This behaves exactly like C<dist_ini>, but it merges any given root config into
a starter config, which means that you can often skip any explicit root config.
The starter config may change slightly over time, but is something like this:

  {
    name     => 'DZT-Sample',
    abstract => 'Sample DZ Dist',
    version  => '0.001',
    author   => 'E. Xavier Ample <example@example.org>',
    license  => 'Perl_5',
    copyright_holder => 'E. Xavier Ample',
  }

=cut

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
