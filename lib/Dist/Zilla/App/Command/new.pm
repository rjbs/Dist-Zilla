use strict;
use warnings;
package Dist::Zilla::App::Command::new;
# ABSTRACT: start a new dist
use Dist::Zilla::App -command;

# I wouldn't need this if I properly moosified my commands. -- rjbs, 2008-10-12
use Mixin::ExtraFields -fields => {
  driver  => 'HashGuts',
  id      => undef,
};
use Moose::Autobox;
use Path::Class;

sub abstract { 'start a new dist' }

sub multivalue_args { qw(author) }

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

sub run {
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

    # for those 'The getpwuid function is unimplemented
    eval {
        my @pw = getpwuid $>;
        $config->{author} ||= [ (split /,/, $pw[6])[0] ];
    };
    $config->{author} ||= [ getlogin || 'YourNameHere' ] if $@;

    printf $fh "name    = $dist\n";
    printf $fh "version = %s\n", ($config->{initial_version} || '1.000');
    printf $fh "author  = %s\n", $_ for $config->{author}->flatten;
    printf $fh "license = %s\n", ($config->{default_license} || 'Perl_5');
    printf $fh "copyright_holder = %s\n", $config->{author}->[0];
    printf $fh "\n";
    printf $fh "[\@Classic]\n";

    close $fh or die "error closing $file: $!";
  }
}

1;
