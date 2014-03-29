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

=attr die_on_line_insertion

By default, PkgVersion look for a blank line after each C<package> statement.
If it finds one, it inserts the C<$VERSION> assignment on that line.  If it
doesn't, it will insert a new line, which means the shipped copy of the module
will have different line numbers (off by one) than the source.  If
C<die_on_line_insertion> is true, PkgVersion will raise an exception rather
than insert a new line.

=attr finder

=for stopwords FileFinder

This is the name of a L<FileFinder|Dist::Zilla::Role::FileFinder> for finding
modules to edit.  The default value is C<:InstallModules> and C<:ExecFiles>;
this option can be used more than once.

Other predefined finders are listed in
L<Dist::Zilla::Role::FileFinderUser/default_finders>.
You can define your own with the
L<[FileFinder::ByName]|Dist::Zilla::Plugin::FileFinder::ByName> and
L<[FileFinder::Filter]|Dist::Zilla::Plugin::FileFinder::Filter> plugins.

=cut

sub munge_files {
  my ($self) = @_;

  $self->munge_file($_) for @{ $self->found_files };
}

sub munge_file {
  my ($self, $file) = @_;

  if ($file->is_bytes) {
    $self->log_debug($file->name . " has 'bytes' encoding, skipping...");
    return;
  }

  return $self->munge_perl($file);
}

has die_on_existing_version => (
  is  => 'ro',
  isa => 'Bool',
  default => 0,
);

has die_on_line_insertion => (
  is  => 'ro',
  isa => 'Bool',
  default => 0,
);

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

  my $package_stmts = $document->find('PPI::Statement::Package');
  unless ($package_stmts) {
    $self->log([ 'skipping %s: no package statement found', $file->name ]);
    return;
  }

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

    # the \x20 hack is here so that when we scan *this* document we don't find
    # an assignment to version; it shouldn't be needed, but it's been annoying
    # enough in the past that I'm keeping it here until tests are better
    my $trial = $self->zilla->is_trial ? ' # TRIAL' : '';
    my $perl = "\$$package\::VERSION\x20=\x20'$version';$trial";

    $self->log_debug([
      'adding $VERSION assignment to %s in %s',
      $package,
      $file->name,
    ]);

    my $blank;

    {
      my $curr = $stmt;
      while (1) {
        my $find = $document->find(sub {
          return $_[1]->line_number == $curr->line_number + 1;
          return;
        });

        last unless $find and @$find == 1;

        if ($find->[0]->isa('PPI::Token::Comment')) {
          $curr = $find->[0];
          next;
        }

        if ("$find->[0]" =~ /\A\s*\z/) {
          $blank = $find->[0];
        }

        last;
      }
    }

    $perl = $blank ? "$perl\n" : "\n$perl";

    # Why can't I use PPI::Token::Unknown? -- rjbs, 2014-01-11
    my $bogus_token = PPI::Token::Comment->new($perl);

    if ($blank) {
      Carp::carp("error inserting version in " . $file->name)
        unless $blank->insert_after($bogus_token);
      $blank->delete;
    } else {
      my $method = $self->die_on_line_insertion ? 'log_fatal' : 'log';
      $self->$method([
        'no blank line for $VERSION after package %s statement on line %s',
        $stmt->namespace,
        $stmt->line_number,
      ]);

      Carp::carp("error inserting version in " . $file->name)
        unless $stmt->insert_after($bogus_token);
    }

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
