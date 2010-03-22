package Dist::Zilla::Plugin::PodVersion;
# ABSTRACT: add a VERSION head1 to each Perl document
use Moose;
with(
  'Dist::Zilla::Role::FileMunger',
  'Dist::Zilla::Role::FileFinderUser' => {
    default_finders => [ ':InstallModules' ],
  },
);

=head1 DESCRIPTION

This plugin adds a C<=head1 VERSION> section to most perl files in the
distribution, indicating the version of the dist being build (and, thus, the
version of the module, assuming L<PkgVersion|Dist::Zilla::Plugin::PkgVersion>
is also loaded.

=cut

sub munge_files {
  my ($self) = @_;

  $self->munge_file($_) for @{ $self->found_files };
}

sub munge_file {
  my ($self, $file) = @_;

  return $self->munge_pod($file);
}

sub munge_pod {
  my ($self, $file) = @_;

  my @content = split /\n/, $file->content;
  
  require List::MoreUtils;
  if (List::MoreUtils::any(sub { $_ =~ /^=head1 VERSION\b/ }, @content)) {
    $self->log($file->name . ' already has a VERSION section in POD');
    return;
  }

  for (0 .. $#content) {
    next until $content[$_] =~ /^=head1 NAME/;

    $_++; # move past the =head1 line itself
    $_++ while $content[$_] =~ /^\s*$/;

    $_++; # move past the line with the abstract
    $_++ while $content[$_] =~ /^\s*$/;

    splice @content, $_ - 1, 0, (
      q{},
      "=head1 VERSION",
      q{},
      "version " . $self->zilla->version . q{},
    );

    $file->content(join "\n", @content);
    return;
  }

  $self->log(
    "couldn't find a place to insert VERSION section to "
    . $file->name,
  );
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
