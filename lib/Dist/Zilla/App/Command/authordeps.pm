use strict;
use warnings;
package Dist::Zilla::App::Command::authordeps;
# ABSTRACT: List your distribution's author dependencies
use Dist::Zilla::App -command;

use Dist::Zilla::Util ();
use Moose;
use Path::Class qw(dir);
use List::MoreUtils qw(uniq);
use Config::INI::Reader;

use namespace::autoclean;

=head1 SYNOPSIS

  dzil authordeps [ --missing ] [ --root=/path/to/dist ]

=head1 DESCRIPTION

This command prints the dependencies to build your distribution. You could
pipe that list to a CPAN client like L<cpan> to install all of the dependecies
in one quick go.

=head1 EXAMPLE

  $ dzil authordeps
  $ dzil authordeps | cpan
  $ dzil authordeps --missing
  $ dzil authordeps --root=/home/rjbs/acme-foobar

=head1 OPTIONS

=head2 --missing

List only the missing dependencies on your system.

=head2 --root=/path/to/dist

Specify the path of the dist to introspect.

Defaults to the current path.

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

  my @sections = uniq map  { s/\s.*//; $_ }
                      grep { $_ ne '_' }
                      keys %{$config};

  return
    grep { $missing ? (! eval "require $_; 1;") : 1 }
    map {; Dist::Zilla::Util->expand_config_package_name($_) } @sections;
}

1;
