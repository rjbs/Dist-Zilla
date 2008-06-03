package Dist::Zilla::Plugin::BumpVersion;
use Moose;
with 'Dist::Zilla::Role::BeforeBuild';

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
