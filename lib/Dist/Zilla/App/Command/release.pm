package Dist::Zilla::App::Command::release;
# ABSTRACT: release your dist to the CPAN

use Dist::Zilla::Pragmas;

use Dist::Zilla::App -command;

=head1 SYNOPSIS

  dzil release

  dzil release --trial

  dzil release --trial-num 3

  # long form, jobs takes an integer
  dzil release --jobs 9

  # short form, same as above
  dzil release -j 9

This command is a very, very thin wrapper around the
C<L<release|Dist::Zilla/release>> method on the Dist::Zilla object.  It will
build, archive, and release your distribution using your Releaser plugins.

Available options are:

=over

=item C<--trial>, will cause it to build a trial build.

=item C<--trial-num=i>, optional trial release number (implies --trial).

=item C<--jobs|-j=i>, number of test jobs run in parallel using L<Test::Harness|Test::Harness>.

=back

The default for L<Test::Harness|Test::Harness> is C<9>. The number of parallel jobs can also be specified setting C<HARNESS_OPTIONS>.

    HARNESS_OPTIONS=j9

See L<Test::Harness|Test::Harness> for more details.

=cut

sub abstract { 'release your dist' }

sub opt_spec {
  [ 'trial' => 'build a trial release that PAUSE will not index' ],
  [ 'trial-num=i' => 'optional trial release number (implies --trial)' ],
  [ 'jobs|j=i' => 'number of parallel test jobs to run' ],
}

sub execute {
  my ($self, $opt, $arg) = @_;

  my $zilla;
  {
    # isolate changes to RELEASE_STATUS to zilla construction
    local $ENV{RELEASE_STATUS} = $ENV{RELEASE_STATUS};
    $ENV{RELEASE_STATUS} = 'testing' if $opt->trial or defined $opt->trial_num;
    $zilla = $self->zilla;
  }

  $self->zilla->trial_num($opt->trial_num) if defined $opt->trial_num;
  local $ENV{HARNESS_OPTIONS} = join ':', split(':', $ENV{HARNESS_OPTIONS} // ''), 'j'.$opt->jobs if $opt->jobs;
  $self->zilla->release;
}

1;
