use strict;
use warnings;
package Dist::Zilla::App::Command::authordeps;
use Dist::Zilla::App -command;
# ABSTRACT: List your distribution's author dependencies

=head1 SYNOPSIS

  $ dzil authordeps

This will scan the F<dist.ini> file and print a list of plugin modules that
probably need to be installed for the dist to be buildable.  This is a very
naive scan, but tends to be pretty accurate.  Modules can be added to its
results by using special comments in the form:

  ; authordep Some::Package

=cut

use CPAN::Meta::Requirements;

sub abstract { "list your distribution's author dependencies" }

sub opt_spec {
  return (
    [ 'root=s' => 'the root of the dist; defaults to .' ],
    [ 'missing' => 'list only the missing dependencies' ],
    [ 'versions', 'include required version numbers in listing' ]
  );
}

sub execute {
  my ($self, $opt, $arg) = @_;

  require Path::Class;
  require Dist::Zilla::Util;

  $self->log(
    $self->format_author_deps(
      $self->extract_author_deps(
        Path::Class::dir(defined $opt->root ? $opt->root : '.'),
        $opt->missing,
      ), $opt->versions
    ),
  );

  return;
}

sub format_author_deps {
  my ($self, $reqs, $versions) = @_;

  my $formatted = '';
  foreach my $rec (@{ $reqs }) {
    my ($mod, $ver) = each(%{ $rec });
    $formatted .= $versions ? "$mod = $ver\n" : "$mod\n";
  }
  chomp($formatted);
  return $formatted;
}

sub extract_author_deps {
  my ($self, $root, $missing) = @_;

  my $ini = $root->file('dist.ini');

  die "dzil authordeps only works on dist.ini files, and you don't have one\n"
    unless -e $ini;

  my $fh = $ini->openr;

  require Config::INI::Reader;
  my $config = Config::INI::Reader->read_handle($fh);

  my $reqs = CPAN::Meta::Requirements->new;

  my @packs =
    map  { s/\s.*//; $_ }
    grep { $_ ne '_' }
    keys %$config;

  foreach my $pack (@packs) {

    my $version = 0;
    if(exists $config->{$pack} && exists $config->{$pack}->{':version'}) {
      $version = $config->{$pack}->{':version'};
    }
    my $realname = Dist::Zilla::Util->expand_config_package_name($pack);
    $reqs->add_minimum($realname => $version);
  }

  seek $fh, 0, 0;

  my $in_filter = 0;
  while (<$fh>) {
    next unless $in_filter or /^\[\s*\@Filter/;
    $in_filter = 0, next if /^\[/ and ! /^\[\s*\@Filter/;
    $in_filter = 1;

    next unless /\A-bundle\s*=\s*([^;]+)/;
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
  # Also order inc:: so that thoses that want to hack @INC with inc:: plugins
  # can have a consistant playground.
  # We don't sort the others packages to preserve the same (random) ordering
  # for the common case (no inc::, no '; authordep') as in previous dzil
  # releases.
  @packages = ((sort grep /^inc::/, @packages), (grep !/^inc::/, @packages));

  # Now that we have a sorted list of packages, use that to build an array of
  # hashrefs for display.
  require List::MoreUtils;
  require Class::Load;
  
  my @final =
    map { { $_ => $vermap->{$_} } }
    grep { $missing ? (! Class::Load::try_load_class($_)) : 1 }
    List::MoreUtils::uniq
    @packages;
    
  return \@final;
}

1;
