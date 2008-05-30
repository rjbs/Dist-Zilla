package Dist::Zilla::Plugin::SmokeTests;
use Moose;
with 'Dist::Zilla::Role::FileMunger';

sub munge_file {
  my ($self, $file) = @_;

  warn "NAME: >> " . $file->name . "\n";
  return unless $file->name =~ m{\Axt/smoke/.+\.t\z};

  (my $name = $file->name) =~ s{^xt/smoke/}{t/smoke-};

  $file->name($name);

  my @lines = split /\n/, $file->content;
  my $after = $lines[0] =~ /\A#!/ ? 1 : 0;
  splice @lines, $after, 0, <<'END_SKIPPER';
BEGIN {
  unless ($ENV{AUTOMATED_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for automated tests');
  }
}
END_SKIPPER

  $file->content(join "\n", @lines);
}

1;
