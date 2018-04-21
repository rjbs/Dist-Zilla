package Dist::Zilla::Role::FileFinderUser;
# ABSTRACT: something that uses FileFinder plugins

use MooseX::Role::Parameterized 1.01;

use Dist::Zilla::Dialect;

use namespace::autoclean;

=head1 DESCRIPTION

This role enables you to search for files in the dist. This makes it easy to find specific
files and have the code factored out to common methods.

Here's an example of a finder: ( taken from AutoPrereqs )

  with 'Dist::Zilla::Role::FileFinderUser' => {
      default_finders  => [ ':InstallModules', ':ExecFiles' ],
  };

Then you use it in your code like this:

  foreach my $file ( @{ $self->found_files }) {
    # $file is an object! Look at L<Dist::Zilla::Role::File>
  }

=cut

=attr finder_arg_names

Define the name of the attribute which will hold this finder. Be sure to specify different names
if you have multiple finders!

This is an ArrayRef.

Default: [ qw( finder ) ]

=cut

parameter finder_arg_names => (
  isa => 'ArrayRef',
  default => sub { [ 'finder' ] },
);

=attr default_finders

This attribute is an arrayref of plugin names for the default plugins the
consuming plugin will use as finders.

Example: C<< [ qw( :InstallModules :ExecFiles ) ] >>

The default finders are:

=begin :list

= :InstallModules

Searches your lib/ directory for pm/pod files

= :IncModules

Searches your inc/ directory for pm files

= :MainModule

Finds the C<main_module> of your dist

= :TestFiles

Searches your t/ directory and lists the files in it.

= :ExtraTestFiles

Searches your xt/ directory and lists the files in it.

= :ExecFiles

Searches your distribution for executable files.  Hint: Use the
L<Dist::Zilla::Plugin::ExecDir> plugin to mark those files as executables.

= :PerlExecFiles

A subset of C<:ExecFiles> limited just to perl scripts (those ending with
F<.pl>, or with a recognizable perl shebang).

= :ShareFiles

Searches your ShareDir directory and lists the files in it.
Hint: Use the L<Dist::Zilla::Plugin::ShareDir> plugin to set up the sharedir.

= :AllFiles

Returns all files in the distribution.

= :NoFiles

Returns nothing.

=end :list

=cut

parameter default_finders => (
  isa => 'ArrayRef',
  required => 1,
);

=attr method

This will be the name of the subroutine installed in your package for this
finder.  Be sure to specify different names if you have multiple finders!

Default: found_files

=cut

parameter method => (
  isa     => 'Str',
  default => 'found_files',
);

role {
  my ($p) = @_;

  my ($finder_arg, @finder_arg_aliases) = @{ $p->finder_arg_names };
  confess "no finder arg names given!" unless $finder_arg;

  around mvp_multivalue_args => sub {
    my ($orig, $self) = @_;

    my @start = $self->$orig;
    return (@start, $finder_arg);
  };

  if (@finder_arg_aliases) {
    around mvp_aliases => sub {
      my ($orig, $self) = @_;

      my $start = $self->$orig;

      for my $alias (@finder_arg_aliases) {
        confess "$alias is already an alias to $start->{$alias}"
          if exists $start->{$alias} and $orig->{$alias} ne $finder_arg;
        $start->{ $alias } = $finder_arg;
      }

      return $start;
    };
  }

  has $finder_arg => (
    is  => 'ro',
    isa => 'ArrayRef[Str]',
    default => sub { [ @{ $p->default_finders } ] },
  );

  method $p->method => sub {
    my ($self) = @_;

    my @filesets = map {; $self->zilla->find_files($_) }
                   @{ $self->$finder_arg };

    my %by_name = map {; $_->name, $_ } map { @$_ } @filesets;

    return [ map {; $by_name{$_} } sort keys %by_name ];
  };
};

1;
