use strict;
use warnings;
package Dist::Zilla::Util;
# ABSTRACT: random snippets of code that Dist::Zilla wants

use Carp ();
use Encode ();

{
  package
    Dist::Zilla::Util::PEA;
  @Dist::Zilla::Util::PEA::ISA = ('Pod::Simple');

  sub _new  {
    my ($class, @args) = @_;
    # Load Pod::Simple only when used (and not yet loaded)
    unless (exists $INC{'Pod/Simple.pm'}) {
      require Pod::Simple;
    }
    my $parser = $class->new(@args);
    $parser->code_handler(sub {
      my ($line, $line_number, $parser) = @_;
      return if $parser->{abstract};


      return $parser->{abstract} = $1
        if $line =~ /^\s*#+\s*ABSTRACT:[ \t]*(\S.*)$/m;
      return;
    });
    return $parser;
  }

  sub _handle_element_start {
    my ($parser, $ele_name, $attr) = @_;

    if ($ele_name eq 'head1') {
      $parser->{buffer} = "";
    }
    elsif ($ele_name eq 'Para') {
      $parser->{buffer} = "";
    }
    elsif ($ele_name eq 'C') {
      $parser->{in_C} = 1;
    }

    return;
  }

  sub _handle_element_end {
    my ($parser, $ele_name, $attr) = @_;

    return if $parser->{abstract};
    if ($ele_name eq 'head1') {
      $parser->{in_section} = $parser->{buffer};
    }
    elsif ($ele_name eq 'Para' && $parser->{in_section} eq 'NAME' ) {
      if ($parser->{buffer} =~ /^(?:\S+\s+)+?-+\s+(.+)$/s) {
        $parser->{abstract} = $1;
      }
    }
    elsif ($ele_name eq 'C') {
      delete $parser->{in_C};
    }

    return;
  }

  sub _handle_text {
    my ($parser, $text) = @_;

    # The C<...> tags are expected to be preserved. MetaCPAN renders them.
    if ($parser->{in_C}) {
      $parser->{buffer} .= "C<$text>";
    }
    else {
      $parser->{buffer} .= $text;
    }
    return;
  }
}

=method abstract_from_file

This method, I<which is likely to change or go away>, tries to guess the
abstract of a given file, assuming that it's Perl code.  It looks for a POD
C<=head1> section called "NAME" or a comment beginning with C<ABSTRACT:>.

=cut

sub abstract_from_file {
  my ($self, $file) = @_;
  my $e = Dist::Zilla::Util::PEA->_new;

  $e->parse_string_document($file->content);

  return $e->{abstract};
}

=method expand_config_package_name

  my $pkg_name = Dist::Zilla::Util->expand_config_package_name($string);

This method, I<which is likely to change or go away>, rewrites the given string
into a package name.

Prefixes are rewritten as follows:

=for :list
* C<=> becomes nothing
* C<@> becomes C<Dist::Zilla::PluginBundle::>
* C<%> becomes C<Dist::Zilla::Stash::>
* otherwise, C<Dist::Zilla::Plugin::> is prepended

=cut

use String::RewritePrefix 0.006 rewrite => {
  -as => '_expand_config_package_name',
  prefixes => {
    '=' => '',
    '@' => 'Dist::Zilla::PluginBundle::',
    '%' => 'Dist::Zilla::Stash::',
    ''  => 'Dist::Zilla::Plugin::',
  },
};

sub expand_config_package_name {
  shift; goto &_expand_config_package_name
}

sub _global_config_root {
  require Dist::Zilla::Path;
  return Dist::Zilla::Path::path($ENV{DZIL_GLOBAL_CONFIG_ROOT}) if $ENV{DZIL_GLOBAL_CONFIG_ROOT};

  require File::HomeDir;
  my $homedir = File::HomeDir->my_home
    or Carp::croak("couldn't determine home directory");

  return Dist::Zilla::Path::path($homedir)->child('.dzil');
}

sub _assert_loaded_class_version_ok {
  my ($self, $pkg, $version) = @_;

  require CPAN::Meta::Requirements;
  my $req = CPAN::Meta::Requirements->from_string_hash({
    $pkg => $version,
  });

  my $have_version = $pkg->VERSION;
  unless ($req->accepts_module($pkg => $have_version)) {
    die( sprintf
      "%s version (%s) does not match required version: %s\n",
      $pkg,
      $have_version // 'undef',
      $version,
    );
  }
}

1;
