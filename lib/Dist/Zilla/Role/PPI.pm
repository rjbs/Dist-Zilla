package Dist::Zilla::Role::PPI;
# ABSTRACT: a role for plugins which use PPI

use Moose::Role;

use Moose::Util::TypeConstraints;

use namespace::autoclean;

use Digest::MD5 qw(md5);
use Storable qw(dclone);

=head1 DESCRIPTION

This role provides some common utilities for plugins which use PPI

=method ppi_document_for_file

  my $document = $self->ppi_document_for_file($file);

Given a dzil file object (anything that does L<Dist::Zilla::Role::File>), this
method returns a new L<PPI::Document> for that file's content.

Internally, this method caches these documents. If multiple plugins want a
document for the same file, this avoids reparsing it.

=cut

my %CACHE;

sub ppi_document_for_file {
  my ($self, $file) = @_;

  my $encoded_content = $file->encoded_content;

  # We cache on the MD5 checksum to detect if the document has been modified
  # by some other plugin since it was last parsed, our document is invalid.
  my $md5 = md5($encoded_content);
  return $CACHE{$md5}->clone if $CACHE{$md5};

  require PPI::Document;
  my $document = PPI::Document->new(\$encoded_content)
    or Carp::croak(PPI::Document->errstr);

  return ($CACHE{$md5} = $document)->clone;
}

=method save_ppi_document_to_file

  my $document = $self->save_ppi_document_to_file($document,$file);

Given a L<PPI::Document> and a dzil file object (anything that does
L<Dist::Zilla::Role::File>), this method saves the serialized document in the
file.

It also updates the internal PPI document cache with the new document.

=cut

sub save_ppi_document_to_file {
  my ($self, $document, $file) = @_;

  my $new_content = $document->serialize;

  $file->encoded_content($new_content);

  $CACHE{ md5($new_content) } = $document->clone;
}

=method document_assigns_to_variable

  if( $self->ppi_document_for_file($document, '$FOO')) { ... }

This method returns true if the document assigns to the given variable (the
sigil must be included).

=cut

sub document_assigns_to_variable {
  my ($self, $document, $variable) = @_;

  my $package_stmts = $document->find('PPI::Statement::Package');
  my @namespaces = map { $_->namespace } @{ $package_stmts || []};

  my ($sigil, $varname) = ($variable =~ m'^([$@%*])(.+)$');

  my $package;
  my $finder = sub {
    my $node = $_[1];

    if ($node->isa('PPI::Statement')
      && !$node->isa('PPI::Statement::End')
      && !$node->isa('PPI::Statement::Data')) {

      if ($node->isa('PPI::Statement::Variable')) {
        return (grep { $_ eq $variable } $node->variables) ? 1 : undef;
      }

      return 1 if grep {
        my $child = $_;
        $child->isa('PPI::Token::Symbol')
          and grep {
            $child->canonical eq "${sigil}${_}::${varname}"
                and $node->content =~ /\Q${sigil}${_}::${varname}\E.*=/
          } @namespaces
      } $node->children;
    }
    return 0;   # not found
  };

  my $rv = $document->find_any($finder);
  Carp::croak($document->errstr) unless defined $rv;

  return $rv;
}

1;
