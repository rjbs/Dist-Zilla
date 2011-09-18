package Dist::Zilla::Role::PPIMunger;
# ABSTRACT: for plugins that need to munge PPI document
use Moose::Role;

use namespace::autoclean;

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

=method code_only_ppi_document

  my $code_only = $self->code_only_ppi_document($document);

This method takes a L<PPI::Document> and strips out all the non-code nodes,
returning a new L<PPI::Document>.

=cut

sub code_only_ppi_document {
  my ($self, $document) = @_;

  my $code_only = $document->clone;

  # This used to look like this -
  #
  # $code_only->prune("PPI::Token::$_") for qw(Comment Pod Quote Regexp);
  #
  # Every call to ->prune iterates through the _entire document_, so calling
  # it four times in a row is really really really slow. Any time we want to
  # prune a document, we should go to great lengths to call ->prune just once.
  my %prune = map { ("PPI::Token::$_" => 1) } qw(Comment Pod Quote Regexp);
  my $wanted = sub {
    my $node_class = blessed($_[1]);
    return 1 if $prune{$node_class};
    return 0;
  };
  $code_only->prune($wanted);

  return $code_only;
}

1;
