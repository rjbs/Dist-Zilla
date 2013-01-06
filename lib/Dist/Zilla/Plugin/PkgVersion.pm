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

  $MyModule::VERSION = 0.001;

...where 0.001 is the version of the dist, and MyModule is the name of the
package being given a version.  (In other words, it always uses fully-qualified
names to assign versions.)

It will skip any package declaration that includes a newline between the
C<package> keyword and the package name, like:

  package
    Foo::Bar;

This sort of declaration is also ignored by the CPAN toolchain, and is
typically used when doing monkey patching or other tricky things.

=attr die_on_existing_version

If true, then when PkgVersion sees an existing C<$VERSION> assignment, it will
throw an exception rather than skip the file.  This attribute defaults to
false.

=cut

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

has die_on_existing_version => (
  is  => 'ro',
  isa => 'Bool',
  default => 0,
);

sub _make_version_declaration {
  my ($self,$package) = @_;
  my $version = $self->zilla->version;
  # the \x20 hack is here so that when we scan *this* document we don't find
  # an assignment to version; it shouldn't be needed, but it's been annoying
  # enough in the past that I'm keeping it here until tests are better
  my $trial = $self->zilla->is_trial ? ' # TRIAL' : '';
  my $perl = "\n\$$package\::VERSION\x20=\x20'$version';$trial\n";

  $self->log("non-ASCII package name is likely to cause problems")
    if $package =~ /\P{ASCII}/;

  $self->log("non-ASCII version is likely to cause problems")
    if $version =~ /\P{ASCII}/;

  # Why can't I use PPI::Token::Unknown? -- rjbs, 2014-01-11
  my $bogus_token = PPI::Token::Comment->new($perl);
  return $bogus_token;
}
sub munge_perl {
  my ($self, $file) = @_;

  my $version = $self->zilla->version;

  Carp::croak("invalid characters in version")
    unless LaxVersionStr->check($version);

  my $document = $self->ppi_document_for_file($file);

  if ($self->document_assigns_to_variable($document, '$VERSION')) {
    if ($self->die_on_existing_version) {
      $self->log_fatal([ 'existing assignment to $VERSION in %s', $file->name ]);
    }

    $self->log([ 'skipping %s: assigns to $VERSION', $file->name ]);
    return;
  }

  return unless my $package_stmts = $document->find('PPI::Statement::Package');

  my %seen_pkg;

  my $munged = 0;
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

    if ( my $block = $stmt->find_first('PPI::Structure::Block' ) ) {
      # 5.14+ package <version> BLOCK;
      $self->log_debug([
        'adding version to a package NAME BLOCK: package %s in %s',
          $package,
          $file->name
      ]);
      unshift @{$block->{children}},
              PPI::Token::Whitespace->new("\n"),
              $self->_make_version_declaration($package);
      next;
    }
    Carp::carp("error inserting version in " . $file->name)
      unless $stmt->insert_after($self->_make_version_declaration($package));
    $munged = 1;
  }

  $self->save_ppi_document_to_file($document, $file) if $munged;
}

__PACKAGE__->meta->make_immutable;
1;

=head1 SEE ALSO

Core Dist::Zilla plugins:
L<PodVersion|Dist::Zilla::Plugin::PodVersion>,
L<AutoVersion|Dist::Zilla::Plugin::AutoVersion>,
L<NextRelease|Dist::Zilla::Plugin::NextRelease>.

Other Dist::Zilla plugins:
L<OurPkgVersion|Dist::Zilla::Plugin::OurPkgVersion> inserts version
numbers using C<our $VERSION = '...';> and without changing line numbers

=cut
