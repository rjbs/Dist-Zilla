package Dist::Zilla::ConfigRole::Findable;
use Moose::Role;
# ABSTRACT: a config class that Dist::Zilla::Config::Finder can find

requires 'can_be_found';
requires 'default_extension';

sub can_be_found {
  my ($self, $arg) = @_;

  my $config_file = $self->filename_from_args($arg);
  return -r "$config_file" and -f _;
}

sub filename_from_args {
  my ($self, $arg) = @_;

  # XXX: maybe we should detect conflicting cases -- rjbs, 2009-08-18
  return $arg->{filename} if $arg->{filename};
  
  my $basename = $arg->{basename};
  confess "no filename or basename supplied"
    unless defined $arg->{basename} and length $arg->{basename};

  my $extension = $self->default_extension;
  my $filename = $basename;
  $filename .= ".$extension" if defined $extension;

  return $filename;
}

no Moose::Role;
1;
