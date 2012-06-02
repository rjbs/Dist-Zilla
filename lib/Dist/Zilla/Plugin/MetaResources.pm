package Dist::Zilla::Plugin::MetaResources;

# ABSTRACT: provide arbitrary "resources" for distribution metadata
use Moose;
with 'Dist::Zilla::Role::MetaProvider';

use namespace::autoclean;

=head1 DESCRIPTION

This plugin adds resources entries to the distribution's metadata.

  [MetaResources]
  homepage          = http://example.com/~dude/project.asp
  bugtracker.web    = http://rt.cpan.org/NoAuth/Bugs.html?Dist=Project
  bugtracker.mailto = bug-project@rt.cpan.org
  repository.url    = git://github.com/dude/project.git
  repository.web    = http://github.com/dude/project
  repository.type   = git

=cut

has resources => (
  is       => 'ro',
  isa      => 'HashRef',
  required => 1,
);

sub BUILDARGS {
  my ($class, @arg) = @_;
  my %copy = ref $arg[0] ? %{ $arg[0] } : @arg;

  my $zilla = delete $copy{zilla};
  my $name  = delete $copy{plugin_name};

  if (exists $copy{bugtracker}) {
    my $tracker = delete $copy{bugtracker};
    $copy{bugtracker}{web} = $tracker;
  }

  if (exists $copy{repository}) {
    my $repo = delete $copy{repository};
    $copy{repository}{url} = $repo;
  }

  for my $multi (qw( bugtracker repository )) {
    for my $key (grep { /^\Q$multi\E\./ } keys %copy) {
      my $subkey = (split /\./, $key, 2)[1];
      $copy{$multi}{$subkey} = delete $copy{$key};
    }
  }

  return {
    zilla       => $zilla,
    plugin_name => $name,
    resources   => \%copy,
  };
}

sub metadata {
  my ($self) = @_;

  return { resources => $self->resources };
}

__PACKAGE__->meta->make_immutable;
1;

=head1 SEE ALSO

Dist::Zilla roles: L<MetaProvider|Dist::Zilla::Role::MetaProvider>.

Dist::Zilla plugins on the CPAN: L<GithubMeta|Dist::Zilla::Plugin::GithubMeta>.

=cut
