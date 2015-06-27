package Dist::Zilla::Prereqs;
# ABSTRACT: the prerequisites of a Dist::Zilla distribution

use Moose;
use MooseX::Types::Moose qw(Bool HashRef);

use CPAN::Meta::Prereqs 2.120630; # add_string_requirement
use Path::Class ();
use String::RewritePrefix;
use CPAN::Meta::Requirements 2.121; # requirements_for_module

use namespace::autoclean;

=head1 DESCRIPTION

Dist::Zilla::Prereqs is a subcomponent of Dist::Zilla.  The C<prereqs>
attribute on your Dist::Zilla object is a Dist::Zilla::Prereqs object, and is
responsible for keeping track of the distribution's prerequisites.

In fact, a Dist::Zilla::Prereqs object is just a thin layer over a
L<CPAN::Meta::Prereqs> object, stored in the C<cpan_meta_prereqs> attribute.

Almost everything this object does is proxied to the CPAN::Meta::Prereqs
object, so you should really read how I<that> works.

Dist::Zilla::Prereqs proxies the following methods to the CPAN::Meta::Prereqs
object:

=for :list
* finalize
* is_finalized
* requirements_for
* as_string_hash

=cut

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

# storing this is sort of gross, but MakeMaker winds up needing the same data
# anyway. -- xdg, 2013-10-22
# This does *not* contain configure requires, as MakeMaker explicitly should
# not have it in its fallback prereqs.
has merged_requires => (
  is => 'ro',
  isa => 'CPAN::Meta::Requirements',
  init_arg => undef,
  default => sub { CPAN::Meta::Requirements->new },
);

=method register_prereqs

  $prereqs->register_prereqs(%prereqs);

  $prereqs->register_prereqs(\%arg, %prereqs);

This method adds new minimums to the prereqs object.  If a hashref is the first
arg, it may have entries for C<phase> and C<type> to indicate what kind of
prereqs are being registered.  (For more information on phase and type, see
L<CPAN::Meta::Spec>.)  For example, you might say:

  $prereqs->register_prereqs(
    { phase => 'test', type => 'recommends' },
    'Test::Foo' => '1.23',
    'XML::YZZY' => '2.01',
  );

If not given, phase and type default to runtime and requires, respectively.

=cut

sub register_prereqs {
  my $self = shift;
  my $arg  = ref($_[0]) ? shift(@_) : {};
  my %prereq = @_;

  my $phase = $arg->{phase} || 'runtime';
  my $type  = $arg->{type}  || 'requires';

  my $req = $self->requirements_for($phase, $type);

  while (my ($package, $version) = each %prereq) {
    $req->add_string_requirement($package, $version || 0);
  }

  return;
}

before 'finalize' => sub {
  my ($self) = @_;
  $self->sync_runtime_build_test_requires;
};


# this avoids a long-standing CPAN.pm bug that incorrectly merges runtime and
# "build" (build+test) requirements by ensuring requirements stay unified
# across all three phases
sub sync_runtime_build_test_requires {
  my $self = shift;

  # first pass: generated merged requirements
  for my $phase ( qw/runtime build test/ ) {
    my $req = $self->requirements_for($phase, 'requires');
    $self->merged_requires->add_requirements( $req );
  };

  # second pass: update from merged requirements
  for my $phase ( qw/runtime build test/ ) {
    my $req = $self->requirements_for($phase, 'requires');
    for my $mod ( $req->required_modules ) {
      $req->clear_requirement( $mod );
      $req->add_string_requirement(
        $mod => $self->merged_requires->requirements_for_module($mod)
      );
    }
  }

  return;
}

__PACKAGE__->meta->make_immutable;
1;
