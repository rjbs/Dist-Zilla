use strict;
use warnings;
use utf8;
use Test::More;
binmode(Test::More->builder->$_, ":utf8") for qw/output failure_output todo_output/;

use Path::Tiny;

use Dist::Zilla::File::InMemory;
use Dist::Zilla::File::OnDisk;
use Dist::Zilla::File::FromCode;

my %sample = (
  dolmen  => "Olivier Mengué",
  keedi   =>"김도형 - Keedi Kim",
);

my $sample = join("\n", values %sample);
my $tempfile = Path::Tiny->tempfile->spew_utf8($sample);

my %cases = (

  'OnDisk' => [
    {
      label => 'UTF-8',
      attr => [ name => "$tempfile" ],
    },
  ],

  InMemory => [
    {
      label => 'UTF-8',
      attr => [ name => 'foo.txt', content => $sample ],
    }
  ],

  FromCode => [
    {
      label => 'UTF-8',
      attr => [ name => 'foo.txt', code => sub { $sample } ],
    },
  ],

);

while ( my ($k, $v) = each %cases ) {
  my $class = "Dist::Zilla::File::$k";
  my @cases = @$v;
  for my $c ( @cases ) {
    my $label = "$k: $c->{label}";
    my $obj = new_ok( $class, $c->{attr} );
  }
}

done_testing;
