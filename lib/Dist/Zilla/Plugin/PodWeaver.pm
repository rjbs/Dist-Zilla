package Dist::Zilla::Plugin::PodWeaver;
# ABSTRACT: do horrible things to POD, producing better docs
use Moose;
use Moose::Autobox;
use List::MoreUtils qw(any);
use Pod::Weaver;
with 'Dist::Zilla::Role::FileMunger';

=head1 WARNING

This code is really, really sketchy.  It's crude and brutal and will probably
break whatever it is you were trying to do.

Eventually, this code will be really awesome.  I hope.  It will probably
provide an interface to something more cool and sophisticated.  Until then,
don't expect it to do anything but bring sorrow to you and your people.

=head1 DESCRIPTION

PodWeaver is a work in progress, which rips apart your kinda-POD and
reconstructs it as boring old real POD.

=cut

sub munge_file {
  my ($self, $file) = @_;

  return
    unless $file->name =~ /\.(?:pm|pod)$/i
    and ($file->name !~ m{/} or $file->name =~ m{^lib/});

  $self->munge_pod($file);
  return;
}

sub munge_pod {
  my ($self, $file) = @_;

  my $new_content = Pod::Weaver->munge_pod_string(
    $file->content,
    {
      filename => $file->name,
      version  => $self->zilla->version,
      license  => $self->zilla->license,
      authors  => $self->zilla->authors,
    },
  );

  $file->content($new_content) if $new_content;
  return;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
