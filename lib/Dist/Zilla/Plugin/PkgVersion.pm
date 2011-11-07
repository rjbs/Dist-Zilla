package Dist::Zilla::Plugin::PkgVersion;
# ABSTRACT: add a $VERSION to your packages
use Moose;
with(
  'Dist::Zilla::Role::FileMunger',
  'Dist::Zilla::Role::FileFinderUser' => {
    default_finders => [ ':InstallModules', ':ExecFiles' ],
  },
  'Dist::Zilla::Role::PPI',
);

use PPI;
use MooseX::Types::Perl qw(LaxVersionStr);

use namespace::autoclean;

=head1 SYNOPSIS

in dist.ini

  [PkgVersion]

=head1 DESCRIPTION

This plugin will add lines like the following to each package in each Perl
module or program (more or less) within the distribution:

  {
    $MyModule::VERSION = 0.001;
  }

...where 0.001 is the version of the dist, and MyModule is the name of the
package being given a version.  (In other words, it always uses fully-qualified
names to assign versions.)

It will skip any package declaration that includes a newline between the
C<package> keyword and the package name, like:

  package
    Foo::Bar;

This sort of declaration is also ignored by the CPAN toolchain, and is
typically used when doing monkey patching or other tricky things.

=head2 PERL CRITIC WORKAROUND

Since this plugin adds the version declaration right after the package
declaration and before any other code, the version will probably
declared before <use strict;>. This will cause Perl::Critic to
complain. If this happens to you, you can set the <no_critic> option
to tell Critic to ignore the version declaration:

  [PkgVersion]
  no_critic = 1

=cut

has no_critic => (
  is   => 'ro',
  isa  => 'Bool',
  lazy => 1,
  default => 0,
);

sub munge_files {
  my ($self) = @_;

  $self->munge_file($_) for @{ $self->found_files };
}

sub munge_file {
  my ($self, $file) = @_;

  # XXX: for test purposes, for now! evil! -- rjbs, 2010-03-17
  return                          if $file->name    =~ /^corpus\//;

  return                          if $file->name    =~ /\.t$/i;
  return $self->munge_perl($file) if $file->name    =~ /\.(?:pm|pl)$/i;
  return $self->munge_perl($file) if $file->content =~ /^#!(?:.*)perl(?:$|\s)/;
  return;
}

sub munge_perl {
  my ($self, $file) = @_;

  my $version = $self->zilla->version;

  Carp::croak("invalid characters in version")
    unless LaxVersionStr->check($version);

  my $document = $self->ppi_document_for_file($file);

  if ($self->document_assigns_to_variable($document, '$VERSION')) {
    $self->log([ 'skipping %s: assigns to $VERSION', $file->name ]);
    return;
  }

  return unless my $package_stmts = $document->find('PPI::Statement::Package');

  my %seen_pkg;

  for my $stmt (@$package_stmts) {
    my $package = $stmt->namespace;

    if ($seen_pkg{ $package }++) {
      $self->log([ 'skipping package re-declaration for %s', $package ]);
      next;
    }

    if ($stmt->content =~ /package\s*(?:#.*)?\n\s*\Q$package/) {
      $self->log([ 'skipping private package %s in %s', $package, $file->name ]);
      next;
    }

    # the \x20 hack is here so that when we scan *this* document we don't find
    # an assignment to version; it shouldn't be needed, but it's been annoying
    # enough in the past that I'm keeping it here until tests are better
    my $trial = $self->zilla->is_trial ? ' # TRIAL' : '';
    my $perl = "{\n  \$$package\::VERSION\x20=\x20'$version';$trial\n}\n";

    if ($self->no_critic) {
        # Surround the version declaration in special comments that
        # prevent perl critic from complaining. Without these,
        # Perl::Critic will complain if the package declaration comes
        # before "use strict".
        $perl = "## no critic\n" . $perl . "## use critic\n";
    }

    my $version_doc = PPI::Document->new(\$perl);
    my @children = $version_doc->schildren;

    $self->log_debug([
      'adding $VERSION assignment to %s in %s',
      $package,
      $file->name,
    ]);

    Carp::carp("error inserting version in " . $file->name)
      unless $stmt->insert_after($children[0]->clone)
      and    $stmt->insert_after( PPI::Token::Whitespace->new("\n") );
  }

  $self->save_ppi_document_to_file($document, $file);
}

__PACKAGE__->meta->make_immutable;
1;
