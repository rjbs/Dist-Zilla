use strict;
use warnings;
package Dist::Zilla::Util::CPANFile;
# ABSTRACT: Utils for working with cpanfiles

sub _hunkify_hunky_hunk_hunks {
  my ($indent, $type, $req) = @_;

  my $str = '';
  for my $module (sort $req->required_modules) {
    my $vstr = $req->requirements_for_module($module);
    $str .= qq{$type "$module" => "$vstr";\n};
  }
  $str =~ s/^/'  ' x $indent/egm;
  return $str;
}

=pod cpanfile_str_from_prereqs

=cut

sub str_from_prereqs {
  my ($prereqs) = @_;

  my @types  = qw(requires recommends suggests conflicts);
  my @phases = qw(runtime build test configure develop);
  
  my $str = '';
  for my $phase (@phases) {
    for my $type (@types) {
      my $req = $prereqs->requirements_for($phase, $type);
      next unless $req->required_modules;
      $str .= qq[\non '$phase' => sub {\n] unless $phase eq 'runtime';
      $str .= _hunkify_hunky_hunk_hunks(
                                        ($phase eq 'runtime' ? 0 : 1),
                                        $type,
                                        $req,
                                       );
      $str .= qq[};\n]                     unless $phase eq 'runtime';
    }
  }
  return $str;
}

sub write_file {
  my ($prereqs, $filename) = @_;

  my $str = str_from_prereqs($prereqs);
  open my $fh, ">", $filename or die $@;
  print $fh $str;
  close $fh or die $@;
}

1;
