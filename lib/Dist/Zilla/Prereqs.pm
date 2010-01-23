package Dist::Zilla::Prereqs;
# ABSTRACT: the prerequisites of a Dist::Zilla distribution
use Moose;
use Moose::Autobox;
use MooseX::Types::Moose qw(Bool HashRef);

use Hash::Merge::Simple ();
use Path::Class ();
use String::RewritePrefix;
use version 0.79 ();

use namespace::autoclean;

has is_finalized => (
  is  => 'ro',
  isa => Bool,
  traits  => [ qw(Bool) ],
  default => 0,
  handles => {
    finalize => 'set',
  },
);

has _guts => (
  is  => 'ro',
  isa => HashRef,
  default  => sub { {} },
  init_arg => undef,
);

sub as_distmeta {
  my ($self) = @_;

  my $distmeta = {
    requires           => { %{ $self->_guts->{runtime}{requires}   || {} } },
    build_requires     => { %{ $self->_guts->{build}{requires}     || {} } },
    configure_requires => { %{ $self->_guts->{configure}{requires} || {} } },
  };

  for my $set (values %$distmeta) {
    for my $key (keys %$set) {
      $set->{ $key } = $set->{ $key }->stringify;
    }
  }

  return $distmeta;
}

sub register_prereqs {
  my $self = shift;
  my $arg  = ref($_[0]) ? shift(@_) : {};
  my %prereq = @_;

  confess "too late to register a prereq" if $self->is_finalized;

  my $phase = $arg->{phase} || 'runtime';
  my $type  = $arg->{type}  || 'requires';

  $phase = 'build' if $phase eq 'test';

  my $prereq = ($self->_guts->{ $phase }{ $type } ||= {});

  while (my ($package, $version) = each %prereq) {
    $version = blessed($version) ? $version : version->parse($version);

    my $slot = \$prereq->{ $package };
    $$slot ||= $version;
    $$slot = $version if $version > $$slot;
  }

  return;
}

1;
