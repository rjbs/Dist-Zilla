use strict;
use warnings;
package Dist::Zilla::App::Command::new;
# ABSTRACT: start a new dist
use Dist::Zilla::App -command;

=head1 SYNOPSIS

Creates a new Dist-Zilla based distribution in the current directory.

    dzil new NAME

=head1 EXAMPLE

    $ dzil new My::Module::Name
    $ dzil new .

=head1 ARGUMENTS

  NAME = PACKAGE | DOTDIR
  DOTDIR  = "."
  PACKAGE = "Your-Package-Name" | "Your::Module::Name"

=head2 NAME

Can be either the value '.' , or a main-module name ( ie: C<Foo::Bar> )

=head3 DOTDIR

If the name given for the C<name> is C<< . >> it will assume the parent
directory is the module name, ie:

  $ cd /tmp/foo-bar/
  $ dist new .

This will create F</tmp/foo-bar/dist.ini>

=head3 PACKAGE

C<::> tokens will be replaced with '-''s and a respective directory created.

ie:

  $ cd /tmp
  $ dist new Foo::Bar

creates

  $ /tmp/Foo-Bar/dist.ini

=cut

# I wouldn't need this if I properly moosified my commands. -- rjbs, 2008-10-12
use Mixin::ExtraFields -fields => {
  driver  => 'HashGuts',
  id      => undef,
};
use Moose::Autobox;
use Path::Class;

sub abstract { 'start a new dist' }

sub mvp_aliases         { { author => 'authors' } }
sub mvp_multivalue_args { qw(authors) }

sub validate_args {
  my ($self, $opt, $args) = @_;

  $self->usage_error('dzil new takes exactly one argument') if @$args != 1;

  my $name = $args->[0];

  if ($name eq '.') {
    $self->set_extra(dir   => dir('.')->absolute);

    my @dir_list = $self->get_extra('dir')->dir_list;
    $name = $dir_list[-1];
  } else {
    $name =~ s/::/-/g;
    $self->set_extra(dir  => dir('.')->subdir($name)->absolute);
    $self->set_extra(mkdir => 1);
  }

  $self->usage_error('given dist name is invalid') if $name =~ m{[./\\]};

  $self->set_extra(dist => $name);

  $self->log([
    'will create new dist %s in %s',
    $self->get_extra('dist'),
    $self->get_extra('dir'),
  ]);
}

sub opt_spec {
}

=head1 GENERATED FILE

The main purpose of the 'new' command is to generate a model C<dist.ini> file that will do just the basics.

    name = <DIST-NAME>
    version = <DIST-VERSION>
    author  = <DIST-AUTHOR1>
    author  = <DIST-AUTHOR2>
    license = <DIST-LICENSE>
    copyright_holder = <DIST-AUTHOR1>

    [@Classic]

=head1 GENERATED FIELDS

=head2 DIST-NAME

This is the detected / provided name of the distribution. See L</NAME> for how this is provided.

=head2 DIST-VERSION

This is loaded from your L<configuration|/CONFIGURATION>, or 1.000 if not configured.

=head2 DIST-AUTHOR[n]

This is loaded from your L<configuration/CONFIGURATION>, or attempted to be detected from the environment/uid if not configured.

=head2 DIST-LICENSE

This is loaded from your L<configuration/CONFIGURATION>, or set to "Perl_5" if not configured.

=cut

sub execute {
  my ($self, $opt, $arg) = @_;

  my $dist = $self->get_extra('dist');
  my $dir  = $self->get_extra('dir');

  if ($self->get_extra('mkdir')) {
    mkdir($dir) or Carp::croak("couldn't create new dist dir $dir: $!");
  }

  # XXX: This needs to all be handled by roles. -- rjbs, 2008-10-12
  {
    my $file = $dir->file('dist.ini');
    open my $fh, '>', $file or die "can't open $file for output: $!";

    my $config = { $self->config->flatten };

    # for those 'The getpwuid function is unimplemented'
    unless ($config->{authors} and @{ $config->{authors} }) {
      local $@;
      eval {
          my @pw = getpwuid $>;
          $config->{authors} ||= [ (split /,/, $pw[6])[0] ];
      };
    }

    Carp::croak("no 'author' set in config and cannot be determined by OS")
      unless $config->{authors} and @{ $config->{authors} };

    printf $fh "name    = $dist\n";
    printf $fh "version = %s\n", ($config->{initial_version} || '1.000');
    printf $fh "author  = %s\n", $_ for $config->{authors}->flatten;
    printf $fh "license = %s\n", ($config->{default_license} || 'Perl_5');
    printf $fh "copyright_holder = %s\n",
      $config->{copyright_holder} || $config->{authors}->[0];
    printf $fh "\n";
    printf $fh "[\@Classic]\n";

    close $fh or die "error closing $file: $!";
  }
}

=head1 CONFIGURATION

In C<~/.dzil> or C<~/.dzil/config.ini>

  [=Dist::Zilla::App::Command::new]
  author = authorname  # used for copyright owner
  author = author2name
  initial_version = 3.1415
  default_license = BSD

=cut

1;
