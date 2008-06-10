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

=head1 BUILDING YOUR DIST

Maybe we're getting ahead of ourselves, here.  Configuring a bunch of plugins
won't do you a lot of good unless you know how to use them to build your dist.

Dist::Zilla ships with a command called F<dzil> that will get installed by
default.  While it can be extended to offer more commands, there are two really
useful ones:

  $ dzil build

The C<build> command will build the distribution.  Say you're using the
configuration in the SYNOPSIS above.  You'll end up with a file called
F<Carbon-Dating-0.004.tar.gz>.  As long as you've done everything right, it
will be suitable for uploading to the CPAN.

Of course, you should really test it out first.  You can test the dist you'd be
building by running another F<dzil> command:

  $ dzil test

This will build a new copy of your distribution and run its tests, so you'll
know whether the dist that C<build> would build is worth releasing!

=head1 HOW BUILDS GET BUILT

This is really more of a sketchy overview than a spec.

First, all the plugins that perform the
L<BeforeBuild|Dist::Zilla::Role::BeforeBuild> perform their C<before_build>
tasks.

The build root (where the dist is being built) is made.

The L<FileGatherer|Dist::Zilla::Role::FileGatherer>s gather and inject files
into the distribution, then the L<FilePrinter|Dist::Zilla::Role::FilePrinter>s
remove some of them.

All the L<FileMunger|Dist::Zilla::Role::FileMunger>s get a chance to muck about
with each file, possibly changing its name, content, or installability.

Now that the distribution is basically set up, it needs an install tool, like a
F<Makefile.PL>.  All the
L<InstallTool|Dist::Zilla::Role::InstallTool>-performing plugins are used to
do whatever is needed to make the dist installable.

Everything is just about done.  The files are all written out to disk and the 
L<AfterBuild|Dist::Zilla::Role::AfterBuild> plugins do their thing.

=head1 THE GLORIOUS FUTURE

In the glorious future of Dist::Zilla, another phase in the process will exist:
C<release>.  By running C<dzil release>, you'll be able to test your
distribution, build a tarball of it, and upload it to the CPAN.  Plugins will
be able to do things like check your version control system to make sure you're
releasing a new version and that you tag the version you've just uploaded.  It
will update your Changelog file, too, making sure that you don't need to know
what your next version number will be before releasing.

=cut
