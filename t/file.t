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

my $sample              = join("\n", values %sample);
my $encoded_sample      = encode("UTF-8", $sample);
my $db_sample          = $sample x 2;
my $db_encoded_sample  = $encoded_sample x 2;

sub test_mutable_roundtrip {
  my ($obj, $label) = @_;

  ok( $obj->DOES("Dist::Zilla::Role::MutableFile"), "does MutableFile role" );

  # assumes object content starts as $sample
  is( $obj->content, $sample, "get content" );
  is( $obj->encoded_content, $encoded_sample, "get encoded_content" );

  # set content, check content & encoded_content
  ok( $obj->content($db_sample), "set content");
  is( $obj->content, $db_sample, "get content");
  is( $obj->encoded_content, $db_encoded_sample, "get encoded_content");

  # set encoded_content, check encoded_content & content
  ok( $obj->encoded_content($encoded_sample), "set encoded_content");
  is( $obj->encoded_content, $encoded_sample, "get encoded_content");
  is( $obj->content, $sample, "get content");
}

subtest "OnDisk" => sub {
  my $class = "Dist::Zilla::File::OnDisk";

  subtest "UTF-8 file" => sub {
    my $tempfile = Path::Tiny->tempfile;

    ok( $tempfile->spew_utf8($sample), "create UTF-8 encoded tempfile" );
    my $obj = new_ok( $class, [name => "$tempfile"] );
    test_mutable_roundtrip($obj);
  };

};

subtest "InMemory" => sub {
  my $class = "Dist::Zilla::File::InMemory";

  subtest "UTF-8 string" => sub {
    my $obj = new_ok( $class, [name => "foo.txt", content => $sample] );
    test_mutable_roundtrip($obj);
  };
};

subtest "FromCode" => sub {
  my $class = "Dist::Zilla::File::FromCode";

  subtest "UTF-8 string" => sub {
    my $obj = new_ok( $class, [name => "foo.txt", code => sub { $sample } ]);
    is( $obj->content, $sample, "content" );
    is( $obj->encoded_content, $encoded_sample, "encoded_content" );
  };

  subtest "content immutable" => sub {
    my $obj = new_ok( $class, [name => "foo.txt", code => sub { $sample } ]);
    like(
      exception { $obj->content($sample) },
      qr/cannot set content/,
      "changing content should throw error"
    );
    like(
      exception { $obj->encoded_content($encoded_sample) },
      qr/cannot set encoded_content/,
      "changing encoded_content should throw error"
    );
  };
};

done_testing;
