package Dist::Zilla::File::InMemory;
# ABSTRACT: a file that you build entirely in memory
use Moose;

use namespace::autoclean;

=head1 DESCRIPTION

This represents a file created in memory -- it's not much more than a glorified
string.

See L<Dist::Zilla::Role::MutableFile> for details.

=cut

with 'Dist::Zilla::Role::MutableFile', 'Dist::Zilla::Role::StubBuild';

after 'BUILD' => sub {
  my ($self,$opts) = @_;
  my @sources = qw/encoded_content content/;
  my @given = grep { exists $opts->{$_} } @sources;
  unless ( @given == 1 ) {
    $self->log_fatal(__PACKAGE__ . " requires have one and only one of: @sources");
  }
  my $source = $given[0];
  my $setter = "_$source";
  $self->_content_source($source);
  $self->$setter( $opts->{$source} );
};

# these should never be called since we ensure one of _content or
# _encoded_content content is set in BUILD and set the source accordingly

sub _build_content { die "shouldn't reach here" }
sub _build_encoded_content { die "shouldn't reach here" }
sub _build_content_source { die "shouldn't reach here" }

__PACKAGE__->meta->make_immutable;
1;
