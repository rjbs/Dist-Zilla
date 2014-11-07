use strict;
use warnings;
use utf8;
use Test::More;
use Test::Fatal;
use Test::FailWarnings -allow_deps => 1;
binmode(Test::More->builder->$_, ":utf8") for qw/output failure_output todo_output/;

use Encode;
use Path::Tiny;
use Test::DZil;
use List::Util 'first';

use Dist::Zilla::File::InMemory;
use Dist::Zilla::File::OnDisk;
use Dist::Zilla::File::FromCode;

my %sample = (
  dolmen  => "Olivier Mengué",
  keedi   =>"김도형 - Keedi Kim",
);

my $sample              = join("\n", values %sample);
my $encoded_sample      = encode("UTF-8", $sample);
my $db_sample           = $sample x 2;
my $db_encoded_sample   = $encoded_sample x 2;
my $latin1_dolmen       = encode("latin1", $sample{dolmen});

my $tzil = Builder->from_config(
    { dist_root => 't/does_not_exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                'GatherDir',
            ),
            path(qw(source lib DZT Sample.pm)) => "package DZT::Sample;\n\n1",
        },
    },
);

{
    # this trickery is so the caller appears to be whatever called new_file()
    my $gatherdir = first { $_->isa('Dist::Zilla::Plugin::GatherDir') } @{ $tzil->plugins };
    my $add_file = $gatherdir->can('add_file');

    my $i = 0;
    sub new_file {
      my ($objref, $class, @args) = @_;
      my $obj = $class->new(
          name => 'foo_' . $i++ . '.txt',
          @args,
      );
      ok($obj, "created a $class");
      $$objref = $obj;

      # equivalent to: $gatherdir->add_file($obj);
      @_ = ($gatherdir, $obj); goto &$add_file;
    }
}

sub test_mutable_roundtrip {
  my ($obj) = @_;

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

sub test_content_from_bytes {
  my ($obj, $source_re) = @_;
  # assumes object encoded_content is encoded sample
  is( $obj->encoded_content, $encoded_sample, "get encoded_content" );
  my $err = exception { $obj->content };
  like(
    $err,
    qr/can't decode text from 'bytes'/i,
    "get content from bytes should throw error"
  );
  # Match only the first line of the stack trace
  like( $err, qr/^[^\n]+$source_re/s, "error shows encoded_content source" );
}

sub test_latin1 {
  my ($obj) = @_;
  # assumes encoded_content is $latin1_dolmen and encoding
  # is already set to 'latin1"
  is( $obj->encoded_content, $latin1_dolmen, "get encoded_content" );
  is( $obj->content, $sample{dolmen}, "get content" );
}

subtest "OnDisk" => sub {
  my $class = "Dist::Zilla::File::OnDisk";

  subtest "UTF-8 file" => sub {
    my $tempfile = Path::Tiny->tempfile;

    ok( $tempfile->spew_utf8($sample), "create UTF-8 encoded tempfile" );
    my $obj;
    new_file(\$obj, $class, name => "$tempfile");
    test_mutable_roundtrip($obj);
  };

  subtest "binary file" => sub {
    my $tempfile = Path::Tiny->tempfile;

    ok( $tempfile->spew_raw($encoded_sample), "create binary tempfile" );
    my $obj;
    new_file(\$obj, $class, name => "$tempfile");
    ok( $obj->encoding("bytes"), "set encoding to 'bytes'");
    test_content_from_bytes($obj, qr/encoded_content added by \S+ \(\S+ line \d+\)/);
  };

  subtest "latin1 file" => sub {
    my $tempfile = Path::Tiny->tempfile;

    ok(
      $tempfile->spew( { binmode => ":encoding(latin1)"}, $sample{dolmen} ),
      "create latin1 tempfile"
    );
    my $obj;
    new_file(\$obj, $class, name => "$tempfile", encoding => 'latin1');
    test_latin1($obj);
  };

};

subtest "InMemory" => sub {
  my $class = "Dist::Zilla::File::InMemory";

  subtest "UTF-8 string" => sub {
    my $obj;
    new_file(\$obj, $class, content => $sample);
    test_mutable_roundtrip($obj);
  };

  subtest "binary string" => sub {
    my ($obj, $line);
    new_file(\$obj, $class, encoded_content => $encoded_sample); $line = __LINE__;
    ok( $obj->encoding("bytes"), "set encoding to 'bytes'");
    test_content_from_bytes($obj, qr/encoded_content added by \S+ \(\S+ line $line\)/);
  };

  subtest "latin1 string" => sub {
    my $obj;
    new_file(\$obj, $class, encoded_content => $latin1_dolmen, encoding => "latin1");
    test_latin1($obj);
  };

};

subtest "FromCode" => sub {
  my $class = "Dist::Zilla::File::FromCode";

  subtest "UTF-8 string" => sub {
    my $obj;
    new_file(\$obj, $class, code => sub { $sample });
    is( $obj->content, $sample, "content" );
    is( $obj->encoded_content, $encoded_sample, "encoded_content" );
  };

  subtest "content immutable" => sub {
    my $obj;
    new_file(\$obj, $class, code => sub { $sample });
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

  subtest "binary string" => sub {
    my ($obj, $line);
    new_file(\$obj, $class, code_return_type => 'bytes', code => sub { $encoded_sample }); $line = __LINE__;
    test_content_from_bytes($obj, qr/bytes from coderef added by \S+ \(main line $line\)/);
  };

  subtest "latin1 string" => sub {
    my $obj;
    new_file(\$obj, $class, (
        code_return_type => 'bytes',
        code => sub { $latin1_dolmen },
        encoding => 'latin1',
      )
    );
    test_latin1($obj);
  };

};

done_testing;
