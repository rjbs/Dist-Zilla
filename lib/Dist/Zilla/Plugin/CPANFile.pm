package Dist::Zilla::Plugin::CPANFile;
# ABSTRACT: produce a cpanfile prereqs file
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::FileGatherer';

use namespace::autoclean;

use Dist::Zilla::File::FromCode;
use Dist::Zilla::Util::CPANFile;

=head1 DESCRIPTION

This plugin will add a F<cpanfile> file to the distribution.

=attr filename

If given, parameter allows you to specify an alternate name for the generated
file.  It defaults, of course, to F<cpanfile>.

=cut

has filename => (
  is  => 'ro',
  isa => 'Str',
  default => 'cpanfile',
);

sub gather_files {
  my ($self, $arg) = @_;

  my $zilla = $self->zilla;

  my $file  = Dist::Zilla::File::FromCode->new({
    name => $self->filename,
    code => sub {
      my $prereqs = $zilla->prereqs;
      my $str = Dist::Zilla::Util::CPANFile::str_from_prereqs($prereqs);
      return $str;
    },
  });

  $self->add_file($file);
  return;
}

__PACKAGE__->meta->make_immutable;
1;
