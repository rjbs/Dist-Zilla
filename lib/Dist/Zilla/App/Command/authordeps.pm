use strict;
use warnings;
package Dist::Zilla::App::Command::authordeps;
use Dist::Zilla::App -command;
# ABSTRACT: List your distribution's author dependencies

use Dist::Zilla::Util ();
use Moose;
use Path::Class qw(dir);
use List::MoreUtils qw(uniq);
use Config::INI::Reader;

use namespace::autoclean;

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

  $self->log(
    $self->format_author_deps(
      $self->extract_author_deps(
        dir(defined $opt->root ? $opt->root : '.'),
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

  my $fh     = $ini->openr;
  my $config = Config::INI::Reader->read_handle($fh);

  my @packages =
    uniq
    map  {; Dist::Zilla::Util->expand_config_package_name($_) }
    map  { s/\s.*//; $_ }
    grep { $_ ne '_' }
    keys %{$config};

  seek $fh, 0, 0;

  while (<$fh>) {
    chomp;
    next unless /\A\s*;\s*authordep\s*(\S+)\s*\z/;
    push @packages, $1;
  }

  return
    grep { !/^inc::/ }
    grep { $missing ? (! eval "require $_; 1;") : 1 }
    @packages;
}

1;
