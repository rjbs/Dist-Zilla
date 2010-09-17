package Dist::Zilla::Plugin::BumpVersion;
# ABSTRACT: (DEPRECATED) bump the version number by one before building
use Moose;
with 'Dist::Zilla::Role::BeforeBuild';

=head1 SYNOPSIS

B<WARNING>  This plugin is deprecated and will be removed.  It is generally
useless.  It does not do what you think it does.

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
             :              'inc_revision';

  $version->$method;

  $self->zilla->version("$version");
}

before register_component => sub {
  die "Dist::Zilla::Plugin::BumpVersion is incompatible with Dist::Zilla >= v5"
    if Dist::Zilla->VERSION >= 5;

  warn "!!! $_[0] will be removed in Dist::Zilla v5; remove it from your config\n";
};

__PACKAGE__->meta->make_immutable;
no Moose;
1;
