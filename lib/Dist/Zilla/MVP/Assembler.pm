package Dist::Zilla::MVP::Assembler;
use Moose;
extends 'Config::MVP::Assembler';
with 'Config::MVP::Assembler::WithBundles';
# ABSTRACT: Dist::Zilla-specific subclass of Config::MVP::Assembler

use MooseX::Types::Perl qw(PackageName);

use Moose::Util::TypeConstraints;

use Dist::Zilla::MVP::RootSection;
use Dist::Zilla::Util;

sub BUILD {
  my ($self) = @_;

  my $root = Dist::Zilla::MVP::RootSection->new;
  $self->sequence->add_section($root);
}

has zilla_class => (
  is      => 'ro',
  isa     => PackageName,
  default => 'Dist::Zilla',
);

sub expand_package {
  my $str = Dist::Zilla::Util->expand_config_package_name($_[1]);
  return $str;
}

sub package_bundle_method {
  my ($self, $pkg) = @_;
  return unless $pkg->isa('Moose::Object')
         and    $pkg->does('Dist::Zilla::Role::PluginBundle');
  return 'bundle_config';
}

before replace_bundle_with_contents => sub {
  my ($self, $bundle_sec, $method) = @_;
  # This is where we will want to make note that the bundle was present.
};

sub zilla {
  my ($self) = @_;
  $self->sequence->section_named('_')->zilla;
}

no Moose;
1;
