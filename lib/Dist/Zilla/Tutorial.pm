use strict;
use warnings;
package Dist::Zilla::Tutorial;
# ABSTRACT: how to use this "Dist::Zilla" thing
use Carp ();
Carp::confess "you're not meant to use the tutorial, just read it!";
1;
__END__

=head1 SYNOPSIS

Dist::Zilla builds distributions to be uploaded to the CPAN.  That means that
the first thing you'll need is some code.

Once you've got that, you'll need to configure Dist::Zilla.  Here's a simple
F<dist.ini>:

  name    = Carbon-Dating
  version = 0.003
  author  = Alan Smithee <asmithee@example.org>
  license = Perl_5
  copyright_holder = Alan Smithee

  [@Classic]

  [Prereq]
  App::Cmd          = 0.013
  Number::Nary      = 0
  Sub::Exporter     = 0.981

The topmost section configures Dist::Zilla itself.  Here are some of the
entries it expects:

  name    - (required) the name of the dist being built
  version - (required) the version of the dist
  author  - (required) the dist author (you may have multiple entries for this)
  license - (required) the dist license; must be a Software::License::* name

  copyright_holder - the name of the entity holding copyright on the dist

Named sections load plugins, with the following rules:

If a section name begins with an equals sign, the rest of the section name is
left intact and not expanded.  If the section name begins with an at sign, it
is prepended with 'Dist::Zilla::PluginBundle::'.  Otherwise, it is prepended
with 'Dist::Zilla::Plugin::'.

The values inside a section are given as configuration to the plugin.  Consult
each plugin's documentation for more information.

The "Classic" bundle, seen above, builds a fairly normal distribution.  It
bumps up the version number, rewrites tests from F<./xt>, adds some information
to POD, and builds a F<Makefile.PL>
