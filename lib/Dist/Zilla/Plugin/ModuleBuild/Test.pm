package Dist::Zilla::Plugin::ModuleBuild::Test;

# ABSTRACT: TestRunner for ModuleBuild based Dists

# $Id:$
use Moose;
use namespace::autoclean;
with 'Dist::Zilla::Role::TestRunner';

=head1 DESCRIPTION

If you're using C<[ModuleBuild]>, this is likely the test-runner you want to use.

=cut

=head1 METHODS

=head2 test

  perl Build.PL
  ./Build
  ./Build test

Is more or less what this plugin does.

=cut

sub test {
  my ( $self, $target ) = @_;
  ## no critic Punctuation
  system($^X => 'Build.PL') and die "error with Makefile.PL\n";
  system('./Build') and die "error running make\n";
  system('./Build test') and die "error running make test\n";
  return;
}

1;

