package Dist::Zilla::Role::FileWriter;
use Moose::Role;

with 'Dist::Zilla::Role::Plugin';
requires 'write_files';

sub write_content_to {
  my ($self, $content, $file) = @_;

  open my $out_fh, '>', "$file" or die "can't open $file for writing: $!";

  print { $out_fh  } (ref $content ? $$content : $content)
    or die "error printing to $file: $!";
  
  close $out_fh or die "error closing $file: $!";
}

no Moose::Role;
1;
