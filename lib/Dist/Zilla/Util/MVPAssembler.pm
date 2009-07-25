package Dist::Zilla::Util::MVPAssembler;
use Moose;
extends 'Config::MVP::Assembler';
# ABSTRACT: Dist::Zilla-specific subclass of Config::MVP::Assembler

sub expand_package {
  my $str = Dist::Zilla::Util->expand_config_package_name($_[1]);
  return $str;
}

no Moose;
1;
