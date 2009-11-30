package Dist::Zilla::Plugin::MakeMaker::Test;

# ABSTRACT: TestRunner for MakeMaker based Dists

# $Id:$
use Moose;
use namespace::autoclean;
with 'Dist::Zilla::Role::TestRunner';

=head1 DESCRIPTION

If you're using C<[MakeMaker]>, this is likely the test-runner you want to use.

=cut

=head1 METHODS

=head2 test

  perl Makefile.PL
  make
  make test

Is more or less what this plugin does.

=cut

sub test {
  my ( $self, $target ) = @_;
  ## no critic Punctuation
  system($^X => 'Makefile.PL') and die "error with Makefile.PL\n";
  system('make') and die "error running make\n";
  system('make test') and die "error running make test\n";
  return;
}

1;

