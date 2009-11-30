package Dist::Zilla::Plugin::PkgVersion;
# ABSTRACT: add a $VERSION to your packages
use Moose;
with 'Dist::Zilla::Role::FileMunger';

use PPI;

=head1 DESCRIPTION

This plugin will add a line like the following to each package in each Perl
module or program (more or less) within the distribution:

  our $VERSION = 0.001; # where 0.001 is the version of the dist

=cut

sub munge_file {
  my ($self, $file) = @_;

  return                          if $file->name    =~ /\.t$/i;
  return $self->munge_perl($file) if $file->name    =~ /\.(?:pm|pl)$/i;
  return $self->munge_perl($file) if $file->content =~ /^#!(?:.*)perl(?:$|\s)/;
  return;
}

sub munge_perl {
  my ($self, $file) = @_;

  my $version = $self->zilla->version;
  Carp::croak("invalid characters in version") if $version !~ /\A[.0-9_]+\z/;

  my $content = $file->content;

  my $document = PPI::Document->new(\$content)
    or Carp::croak( PPI::Document->errstr );

  {
    # This is sort of stupid.  We want to see if we assign to $VERSION already.
    # I'm sure there's got to be a better way to do this, but what the heck --
    # this should work and isn't too slow for me. -- rjbs, 2009-11-29
    my $code_only = $document->clone;
    $code_only->prune("PPI::Token::$_") for qw(Comment Pod Quote Regexp);
    if ($code_only->serialize =~ /\$VERSION\s*=/sm) {
      $self->log(sprintf('skipping %s: assigns to $VERSION', $file->name));
      return;
    }
  }

  return unless my $package_stmts = $document->find('PPI::Statement::Package');

  # $hack is here so that when we scan *this* document we
  my $version_doc = PPI::Document->new(\qq{our \$VERSION = '$version';\n});
  my @children = $version_doc->schildren;

  for my $stmt (@$package_stmts) {
    Carp::carp("error inserting version in " . $file->name)
      unless $stmt->insert_after($children[0]->clone)
      and    $stmt->insert_after( PPI::Token::Whitespace->new("\n") );
  }

  $file->content($document->serialize);
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
