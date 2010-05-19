package Dist::Zilla::Prereqs;
# ABSTRACT: the prerequisites of a Dist::Zilla distribution
use Moose;
use Moose::Autobox;
use MooseX::Types::Moose qw(Bool HashRef);

use CPAN::Meta::Prereqs;
use Hash::Merge::Simple ();
use Path::Class ();
use String::RewritePrefix;
use Version::Requirements;

use namespace::autoclean;

has cpan_meta_prereqs => (
  is  => 'ro',
  isa => 'CPAN::Meta::Prereqs',
  init_arg => undef,
  default  => sub { CPAN::Meta::Prereqs->new },
  handles  => [ qw(
    finalize
    is_finalized
    requirements_for
    as_string_hash
  ) ],
);

sub as_distmeta {
  my ($self) = @_;

  my %distmeta = (
    requires           => $self->requirements_for(qw(runtime requires)),
    recommends         => $self->requirements_for(qw(runtime recommends)),
    configure_requires => $self->requirements_for(qw(configure requires)),
  );

  my $build = $self->requirements_for(qw(build requires))->clone;
  $build->add_requirements( $self->requirements_for(qw(test requires)) );
  $distmeta{build_requires} = $build;

  return { map {; $_ => $distmeta{$_}->as_string_hash } keys %distmeta };
}

sub register_prereqs {
  my $self = shift;
  my $arg  = ref($_[0]) ? shift(@_) : {};
  my %prereq = @_;

  my $phase = $arg->{phase} || 'runtime';
  my $type  = $arg->{type}  || 'requires';

  my $req = $self->requirements_for($phase, $type);

  while (my ($package, $version) = each %prereq) {
    $req->add_minimum($package, $version);
  }

  return;
}

1;
