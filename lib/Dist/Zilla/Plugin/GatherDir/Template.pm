package Dist::Zilla::Plugin::GatherDir::Template;
# ABSTRACT: gather all the files in a directory and use them as templates
use Moose;
extends 'Dist::Zilla::Plugin::GatherDir';
with 'Dist::Zilla::Role::TextTemplate';

use autodie;
use Moose::Autobox;
use Dist::Zilla::File::FromCode;
use namespace::autoclean;

=head1 DESCRIPTION

This is a very, very simple L<FileGatherer|Dist::Zilla::FileGatherer> plugin.
It looks in the directory named in the L</root> attribute and adds all the
files it finds there.  If the root begins with a tilde, the tilde is replaced
with the current user's home directory according to L<File::HomeDir>.

It is meant to be used when minting dists with C<dzil new>, but could be used
in building existing dists, too.

=cut

sub _file_from_filename {
  my ($self, $filename) = @_;

  my $template = do {
    open my $fh, '<', $filename;
    local $/;
    <$fh>;
  };

  return Dist::Zilla::File::FromCode->new({
    name => $filename,
    mode => (stat $filename)[2] & 0755, # kill world-writeability
    code => sub {
      my ($file_obj) = @_;
      $self->fill_in_string(
        $template,
        {
          dist   => \($self->zilla),
          plugin => \($self),
        },
      );
    },
  });
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
