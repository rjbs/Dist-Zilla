# Temporay fix
# This is a hard-coded version of Test::EOL.

use Test::More;
use File::Spec;
use FindBin qw( $Bin );
use File::Find;

my $updir = File::Spec->updir();

my @skipfiles;

if ($^O eq 'MSWin32') {
  push @skipfiles,
    [ qr/^.*\/Makefile$/, "Makefile is outside our control on win32" ],
    [ qr/^.*\.bat$/, "Bat files are uncontrollable, need \\r codes to work" ];
}

sub _all_files {
  my @base_dirs = @_ ? @_ : File::Spec->catdir($Bin, $updir);
  my @found;
  my $want_sub = sub {
    return unless (-f $File::Find::name && -r _);
    push @found, File::Spec->no_upwards($File::Find::name);
  };

  my $find_arg = {
    ($] <= 5.006) ? () : (
      untaint         => 1,
      untaint_pattern => qr|^([-+@\w./:\\]+)$|,
      untaint_skip    => 1,
    ),
    wanted   => $want_sub,
    no_chdir => 1,
  };
  find($find_arg, @base_dirs);
  return @found;

}

sub _find_rn {
  my $file = shift;
  open my $fh, '<', $file or die $!;
  binmode($fh, ':raw');

  # just in case somebody makes this \r\n -_-
  local $/ = "\n";
  my $lineno = 0;
  while (defined(my $line = <$fh>)) {
    $lineno++;
    if ($line =~ /\r$/) {
      return $lineno;
    }
  }
  return undef;
}

sub _real_test_file {
  my $file = shift;
  my $line = _find_rn($file);
  return ok(1, "$file is free from \\r ") if not defined $line;
  return ok(0, "$file has \\r on line $line");
}

sub _todo_test_file {
  my ($file, $reason) = @_;
  my $line = _find_rn($file);
  TODO: {
    local $TODO = $reason;
    return _real_test_file($file);
  }
}

sub _test_file {
  my $file = shift;
  for (@skipfiles) {
    if ($file =~ $_->[0]) {
      return _todo_test_file($file, $_->[1]);
    }
  }
  return _real_test_file($file);
}

my (@files) = _all_files();

plan tests => (0 + @files);

_test_file($_) for @files;
