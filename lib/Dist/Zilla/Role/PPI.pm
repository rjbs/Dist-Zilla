package Dist::Zilla::Role::PPI;
# ABSTRACT: a role for plugins which use PPI
use Moose::Role;

use Moose::Util::TypeConstraints;

use namespace::autoclean;

=head1 DESCRIPTION

This role provides some common utilities for plugins which use PPI

=method ppi_document_for_file

  my $document = $self->ppi_document_for_file($file);

Given a dzil file object (anything that does L<Dist::Zilla::Role::File>), this
method returns a new L<PPI::Document> for that file's content.

=cut

sub ppi_document_for_file {
  my ($self, $file) = @_;

  my $content = $file->content;

  my $document = PPI::Document->new(\$content)
    or Carp::croak(PPI::Document->errstr);

  return $document;
}

sub document_assigns_to_variable {
  my ($self, $document, $variable) = @_;

  my $finder = sub {
    my $node = $_[1];
    return 1 if $node->isa('PPI::Statement') && $node->content =~ /\Q$variable\E\s*=/sm;
    return 0;
  };

  my $rv = $document->find_any($finder);
  Carp::croak($document->errstr) unless defined $rv;

  return $rv;
}

1;
