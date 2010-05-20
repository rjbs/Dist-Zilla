package Dist::Zilla::MVP::Assembler;
use Moose;
extends 'Config::MVP::Assembler';
with 'Config::MVP::Assembler::WithBundles';
# ABSTRACT: Dist::Zilla-specific subclass of Config::MVP::Assembler

use Dist::Zilla::Util;

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

  warn sprintf(
    "MAKE NOTE: added bundle %s isa %s\n",
    $bundle_sec->name,
    $bundle_sec->package,
  );
};

no Moose;
1;
