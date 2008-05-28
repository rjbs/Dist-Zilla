package Dist::Zilla::Plugin::Manifest;
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::AfterBuild';

sub after_build {
  my ($self, $arg) = @_;

  my $file = $arg->{build_root}->file('MANIFEST');
  open my $fh, '>', $file or die "can't open $file for writing: $!";

  my $files = [ $arg->{files}->map(sub{$_->name})->flatten, 'MANIFEST' ]->sort;
  print { $fh } "$_\n" for $files->flatten;

  close $fh or die "can't close $file: $!";
}

no Moose;
1;
