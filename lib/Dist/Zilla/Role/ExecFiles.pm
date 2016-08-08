package Dist::Zilla::Role::ExecFiles;
# ABSTRACT: something that finds files to install as executables

use Moose::Role;
with 'Dist::Zilla::Role::FileFinder';

use namespace::autoclean;

requires 'dir';

sub find_files {
  my ($self) = @_;

  my $dir = $self->dir;
  my $files = [
    grep { index($_->name, "$dir/") == 0 }
      @{ $self->zilla->files }
  ];
}

1;
__END__

=head1 SEE ALSO

Core Dist::Zilla plugins that implement this role:
L<ExecDir|Dist::Zilla::Plugin::ExecDir>.

Core Dist::Zilla plugins that consume this role:
L<FileFinder::Filter|Dist::Zilla::Plugin::FileFinder::Filter>,
L<AutoPrereqs|Dist::Zilla::Plugin::AutoPrereqs>,
L<MakeMaker|Dist::Zilla::Plugin::MakeMaker>,
L<ModuleBuild|Dist::Zilla::Plugin::ModuleBuild>,
L<PkgDist|Dist::Zilla::Plugin::PkgDist>,
L<PkgVersion|Dist::Zilla::Plugin::PkgVersion>,
L<PodVersion|Dist::Zilla::Plugin::PodVersion>.

=cut
