package Dist::Zilla::Plugin::GatherDir::Template;
# ABSTRACT: gather all the files in a directory and use them as templates

use Moose;
extends 'Dist::Zilla::Plugin::GatherDir';
with 'Dist::Zilla::Role::TextTemplate';

use Dist::Zilla::Dialect;

use namespace::autoclean;

use autodie;
use Dist::Zilla::File::FromCode;
use Dist::Zilla::Path;

=head1 DESCRIPTION

This is a subclass of the L<GatherDir|Dist::Zilla::Plugin::GatherDir>
plugin.  It works just like its parent class, except that each
gathered file is processed through L<Text::Template>.

The variables C<$plugin> and C<$dist> will be provided to the
template, set to the GatherDir::Template plugin and the Dist::Zilla
object, respectively.

It is meant to be used when minting dists with C<dzil new>, but could be used
in building existing dists, too.

=head1 ATTRIBUTES

=head2 rename

Use this to rename files while they are being gathered.  This is a list of
key/value pairs, specified thus:

    [GatherDir::Template]
    rename.DISTNAME = $dist->name =~ s/...//r
    rename.DISTVER  = $dist->version

This example will replace the tokens C<DISTNAME> and C<DISTVER> with the
expressions they are associated with. These expressions will be treated as
though they were miniature Text::Template sections, and hence will receive the
same variables that the file itself receives, i.e. C<$dist> and C<$plugin>.

=cut

has _rename => (
  is => 'ro',
  isa => 'HashRef',
  default => sub { +{} },
);

around BUILDARGS => sub ($orig, $class, @rest) {
  my $args = $class->$orig(@rest);
  my %retargs = %$args;

  for my $rename (grep /^rename/, keys %retargs) {
    my $expr = delete $retargs{$rename};
    $rename =~ s/^rename\.//;
    $retargs{_rename}->{$rename} = $expr;
  }

  return \%retargs;
};

sub _file_from_filename ($self, $filename) {
  my $template = path($filename)->slurp_utf8;

  my @stat = stat $filename or $self->log_fatal("$filename does not exist!");

  my $new_filename = $filename;

  for my $token (keys $self->_rename->%*) {
    my $expr = $self->_rename->{$token};
    my $temp_temp = "{{ $expr }}";
    my $replacement = $self->fill_in_string(
      $temp_temp,
      {
        dist   => \($self->zilla),
        plugin => \($self),
      },
    );

    $new_filename =~ s/\Q$token/$replacement/g;
  }

  return Dist::Zilla::File::FromCode->new({
    name => $new_filename,
    mode => ($stat[2] & 0755) | 0200, # kill world-writeability, make sure owner-writable.
    code => sub ($file, @) {
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
1;
