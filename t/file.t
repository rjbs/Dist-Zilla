use strict;
use warnings;
use utf8;
use Test::More;
use Test::Fatal;
binmode(Test::More->builder->$_, ":utf8") for qw/output failure_output todo_output/;

use Encode;
use Path::Tiny;

use Dist::Zilla::File::InMemory;
use Dist::Zilla::File::OnDisk;
use Dist::Zilla::File::FromCode;

my %sample = (
  dolmen  => "Olivier Mengué",
  keedi   =>"김도형 - Keedi Kim",
);

my $sample = join("\n", values %sample);
my $encoded_sample = encode("UTF-8", $sample);
my $tempfile = Path::Tiny->tempfile;
$tempfile->spew_utf8($sample);

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
    my $label = "$k $c->{label}";
    my $obj = new_ok( $class, $c->{attr}, "$label: new object" );
    is( $obj->content, $sample, "$label: content" );
    is( $obj->encoded_content, $encoded_sample, "$label: encoded_content" );
    if ( $obj->DOES("Dist::Zilla::Role::MutableFile") ) {

    }
    else {
      like(
        exception { $obj->content($sample) },
        qr/cannot set content/,
        "$label: changing content should throw error"
      );
      like(
        exception { $obj->encoded_content($encoded_sample) },
        qr/cannot set encoded_content/,
        "$label: changing encoded_content should throw error"
      );
    }
  }
}

done_testing;
