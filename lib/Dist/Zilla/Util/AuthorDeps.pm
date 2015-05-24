use strict;
use warnings;
package Dist::Zilla::Util::AuthorDeps;
# ABSTRACT: Utils for listing your distribution's author dependencies

use Dist::Zilla::Util;
use Path::Tiny;

sub format_author_deps {
  my ($reqs, $versions) = @_;

  my $formatted = '';
  foreach my $rec (@{ $reqs }) {
    my ($mod, $ver) = each(%{ $rec });
    $formatted .= $versions ? "$mod = $ver\n" : "$mod\n";
  }
  chomp($formatted);
  return $formatted;
}

sub extract_author_deps {
  my ($root, $missing) = @_;

  my $ini = path($root, 'dist.ini');

  die "dzil authordeps only works on dist.ini files, and you don't have one\n"
    unless -e $ini;

  my $fh = $ini->openr_utf8;

  require Config::INI::Reader;
  my $config = Config::INI::Reader->read_handle($fh);

  require CPAN::Meta::Requirements;
  my $reqs = CPAN::Meta::Requirements->new;

  for my $section ( sort keys %$config ) {
    next if q[_] eq $section;
    my $pack = $section;
    $pack =~ s{\s*/.*$}{}; # trim optional space and slash-delimited suffix

    my $version = 0;
    $version = $config->{$section}->{':version'} if exists $config->{$section}->{':version'};

    my $realname = Dist::Zilla::Util->expand_config_package_name($pack);
    $reqs->add_minimum($realname => $version);
  }

  seek $fh, 0, 0;

  my $in_filter = 0;
  while (<$fh>) {
    next unless $in_filter or /^\[\s*\@Filter/;
    $in_filter = 0, next if /^\[/ and ! /^\[\s*\@Filter/;
    $in_filter = 1;

    next unless /\A-bundle\s*=\s*([^;\s]+)/;
    my $pname = $1;
    chomp($pname);
    $reqs->add_minimum(Dist::Zilla::Util->expand_config_package_name($1) => 0)
  }

  seek $fh, 0, 0;

  my @packages;
  while (<$fh>) {
    chomp;
    next unless /\A\s*;\s*authordep\s*(\S+)\s*(=\s*(\S+))?\s*\z/;
    my $ver = defined $3 ? $3 : "0";
    # Any "; authordep " is inserted at the beginning of the list
    # in the file order so the user can control the order of at least a part of
    # the plugin list
    push @packages, $1;
    # And added to the requirements so we can use it later
    $reqs->add_minimum($1 => $ver);
  }

  my $vermap = $reqs->as_string_hash;
  # Add the other requirements
  push(@packages, sort keys %{ $vermap });

  # Move inc:: first in list as they may impact the loading of other
  # plugins (in particular local ones).
  # Also order inc:: so that those that want to hack @INC with inc:: plugins
  # can have a consistent playground.
  # We don't sort the others packages to preserve the same (random) ordering
  # for the common case (no inc::, no '; authordep') as in previous dzil
  # releases.
  @packages = ((sort grep /^inc::/, @packages), (grep !/^inc::/, @packages));

  # Now that we have a sorted list of packages, use that to build an array of
  # hashrefs for display.
  require Class::Load;
  require List::UtilsBy;    # uniq_by

  my @final =
    map { { $_ => $vermap->{$_} } }
    grep {
      $missing
        ? $_ eq 'perl'
          ? ($vermap->{perl} ? !eval "use $vermap->{perl}; 1" : ())
          : (! Class::Load::try_load_class($_, ($vermap->{$_} ? {-version => $vermap->{$_}} : ())))
        : 1
      }
    List::UtilsBy::uniq_by(sub {$_}, @packages);

  return \@final;
}

1;
