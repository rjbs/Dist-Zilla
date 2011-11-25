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

sub abstract { "list your distribution's author dependencies" }

sub opt_spec {
  return (
    [ 'root=s' => 'the root of the dist; defaults to .' ],
    [ 'missing' => 'list only the missing dependencies' ],
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
      ),
    ),
  );

  return;
}

sub format_author_deps {
  my ($self, @deps) = @_;
  return join qq{\n} => @deps;
}

sub extract_author_deps {
  my ($self, $root, $missing) = @_;

  my $ini = $root->file('dist.ini');

  die "dzil authordeps only works on dist.ini files, and you don't have one\n"
    unless -e $ini;

  my $fh = $ini->openr;

  require Config::INI::Reader;
  my $config = Config::INI::Reader->read_handle($fh);

  my @packages =
    map  {; Dist::Zilla::Util->expand_config_package_name($_) }
    map  { s/\s.*//; $_ }
    grep { $_ ne '_' }
    keys %$config;

  seek $fh, 0, 0;

  my $in_filter = 0;
  while (<$fh>) {
    next unless $in_filter or /^\[\s*\@Filter/;
    $in_filter = 0, next if /^\[/ and ! /^\[\s*\@Filter/;
    $in_filter = 1;

    next unless /\A-bundle\s*=\s*([^;]+)/;
    push @packages, Dist::Zilla::Util->expand_config_package_name($1);
  }

  seek $fh, 0, 0;
  my @manual;

  while (<$fh>) {
    chomp;
    next unless /\A\s*;\s*authordep\s*(\S+)\s*\z/;
    push @manual, $1;
  }

  # Any "; authordep " is inserted at the beginning of the list
  # in the file order so the user can control the order of at least a part of
  # the plugin list
  splice(@packages, 0, 0, @manual);

  # Move inc:: first in list as they may impact the loading of other
  # plugins (in particular local ones).
  # Also order inc:: so that thoses that want to hack @INC with inc:: plugins
  # can have a consistant playground.
  # We don't sort the others packages to preserve the same (random) ordering
  # for the common case (no inc::, no '; authordep') as in previous dzil
  # releases.
  @packages = ((sort grep /^inc::/, @packages), (grep !/^inc::/, @packages));

  require List::MoreUtils;

  return
    grep { !/^inc::/ }
    grep { $missing ? (! eval "require $_; 1;") : 1 }
    List::MoreUtils::uniq
    @packages;
}

1;
