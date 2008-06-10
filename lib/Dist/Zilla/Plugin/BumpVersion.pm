package Dist::Zilla::Plugin::BumpVersion;
# ABSTRACT: bump the configured version number by one before building
use Moose;
with 'Dist::Zilla::Role::BeforeBuild';

=head1 SYNOPSIS

If loaded, this plugin will ensure that the distribution's version number is
bumped up by one (in the smallest already-defined version units) before
building begins.  In other words, if F<dist.ini>'s version reads C<0.002> then
the newly built dist will be C<0.003>.

=cut

sub before_build {
  my ($self) = @_;

  require Perl::Version;

  my $version = Perl::Version->new( $self->zilla->version );

  my ($r, $v, $s, $a) = map { scalar $version->$_ }
                        qw(revision version subversion alpha);

  my $method = $a > 0     ? 'inc_alpha'
             : defined $s ? 'inc_subversion'
             : defined $v ? 'inc_version'
             :              'inc_reversion';

  $version->$method;

  $self->zilla->version("$version");
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
