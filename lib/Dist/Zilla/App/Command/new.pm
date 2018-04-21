use strict;
use warnings;
package Dist::Zilla::App::Command::new;
# ABSTRACT: mint a new dist

use Dist::Zilla::App -command;

use Dist::Zilla::Dialect;

=head1 SYNOPSIS

Creates a new Dist-Zilla based distribution under the current directory.

  $ dzil new Main::Module::Name

There are two arguments, C<-p> and C<-P>. C<-P> specify the minting profile
provider and C<-p> - the profile name.

The default profile provider first looks in the
F<~/.dzil/profiles/$profile_name> and then among standard profiles, shipped
with Dist::Zilla. For example:

  $ dzil new -p work Corporate::Library

This command would instruct C<dzil> to look in F<~/.dzil/profiles/work> for a
F<profile.ini> (or other "profile" config file).  If no profile name is given,
C<dzil> will look for the C<default> profile.  If no F<default> directory
exists, it will use a very simple configuration shipped with Dist::Zilla.

  $ dzil new -P Foo Corporate::Library

This command would instruct C<dzil> to consult the Foo provider about the
directory of 'default' profile.

Furthermore, it is possible to specify the default minting provider and profile
in the F<~/.dzil/config.ini> file, for example:

  [%Mint]
  provider = FooCorp
  profile = work

=cut

sub abstract { 'mint a new dist' }

sub usage_desc { '%c new %o <ModuleName>' }

sub opt_spec {
  [ 'profile|p=s',  'name of the profile to use',
    { default => 'default' }  ],

  [ 'provider|P=s', 'name of the profile provider to use',
    { default => 'Default' }  ],

  # [ 'module|m=s@', 'module(s) to create; may be given many times'         ],
}

sub validate_args {
  my ($self, $opt, $args) = @_;

  require MooseX::Types::Perl;

  $self->usage_error('dzil new takes exactly one argument') if @$args != 1;

  my $name = $args->[0];

  $name =~ s/::/-/g if MooseX::Types::Perl::is_ModuleName($name)
               and not MooseX::Types::Perl::is_DistName($name);

  $self->usage_error("$name is not a valid distribution name")
    unless MooseX::Types::Perl::is_DistName($name);

  $args->[0] = $name;
}

sub execute {
  my ($self, $opt, $arg) = @_;

  my $dist = $arg->[0];

  require Dist::Zilla::Dist::Minter;
  my $stash = $self->app->_build_global_stashes;
  my $minter = Dist::Zilla::Dist::Minter->_new_from_profile(
    ( exists $stash->{'%Mint'} ?
      [ $stash->{'%Mint'}->provider, $stash->{'%Mint'}->profile ] :
      [ $opt->provider, $opt->profile ]
    ),
    {
      chrome  => $self->app->chrome,
      name    => $dist,
      _global_stashes => $stash,
    },
  );

  $minter->mint_dist({
    # modules => $opt->module,
  });
}

1;
