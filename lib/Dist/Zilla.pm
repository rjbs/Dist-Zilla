package Dist::Zilla;
# ABSTRACT: distribution builder; installer not included!
use Moose;
use Moose::Autobox;
use Dist::Zilla::Types qw(DistName License);
use MooseX::Types::Path::Class qw(Dir File);
use Moose::Util::TypeConstraints;

use File::Find::Rule;
use Hash::Merge::Simple ();
use Path::Class ();
use Software::License;
use String::RewritePrefix;

use Dist::Zilla::File::OnDisk;
use Dist::Zilla::Role::Plugin;

use namespace::autoclean;

=attr dzil_app

This attribute (which is optional) will provide the Dist::Zilla::App object if
the Dist::Zilla object is being used in the context of the F<dzil> command (or
anything else using it through Dist::Zilla::App).

=cut

has 'dzil_app' => (
  is  => 'rw',
  isa => 'Dist::Zilla::App',
);

=attr name

The name attribute (which is required) gives the name of the distribution to be
built.  This is usually the name of the distribution's main module, with the
double colons (C<::>) replaced with dashes.  For example: C<Dist-Zilla>.

=cut

has name => (
  is   => 'ro',
  isa  => DistName,
  required => 1,
);

=attr version

This is the version of the distribution to be created.

=cut

has version_override => (
  isa => 'Str',
  is  => 'ro' ,
  init_arg => 'version',
);

# XXX: *clearly* this needs to be really much smarter -- rjbs, 2008-06-01
has version => (
  is   => 'rw',
  isa  => 'Str',
  lazy => 1,
  init_arg  => undef,
  required  => 1,
  builder   => '_build_version',
);

sub _build_version {
  my ($self) = @_;

  my $version = $self->version_override;

  for my $plugin ($self->plugins_with(-VersionProvider)->flatten) {
    next unless defined(my $this_version = $plugin->provide_version);

    confess('attempted to set version twice') if defined $version;

    $version = $this_version;
  }

  confess('no version was ever set') unless defined $version;

  $self->log("warning: version number does not look like a number")
    unless $version =~ m{\A\d+(?:\.\d+)\z};

  $version;
}

=attr abstract

This is a one-line summary of the distribution.  If none is given, one will be
looked for in the L</main_module> of the dist.

=cut

has abstract => (
  is   => 'rw',
  isa  => 'Str',
  lazy => 1,
  required => 1,
  default  => sub {
    my ($self) = @_;

    unless ($self->main_module) {
      die "no abstract given and no main_module found; make sure your main module is in ./lib\n";
    }

    require Dist::Zilla::Util;
    my $filename = $self->main_module->name;
    $self->log("extracting distribution abstract from $filename");
    my $abstract = Dist::Zilla::Util->abstract_from_file($filename);

    if (!defined($abstract)) {
        die "Unable to extract an abstract from $filename. Please add the following comment to the file with your abstract:
    # ABSTRACT: turns baubles into trinkets
";
    }

    return $abstract;
  }
);

=attr main_module

This is the module where Dist::Zilla might look for various defaults, like
the distribution abstract.  By default, it's derived from the distribution
name.  If your distribution is Foo-Bar, and F<lib/Foo/Bar.pm> exists,
that's the main_module.  Otherwise, it's the shortest-named module in the
distribution.  This may change!

You can override the default by specifying the file path explicitly,
ie:
    main_module = lib/Foo/Bar.pm

=cut

has main_module_override => (
  isa => 'Str',
  is  => 'ro' ,
  init_arg => 'main_module',
  predicate => 'has_main_module_override',
);

has main_module => (
  is   => 'ro',
  isa  => 'Dist::Zilla::Role::File',
  lazy => 1,
  init_arg => undef,
  required => 1,
  default  => sub {

    my ($self) = @_;

    my $file;
    my $guessing = q{};

    if ( $self->has_main_module_override ) {

       $file = $self->files->grep(sub{ $_->name eq $self->main_module_override })->head;

    } else {
       $guessing = 'guessing '; # We're having to guess

       (my $guess = $self->name) =~ s{-}{/}g;
       $guess = "lib/$guess.pm";

       $file = $self->files->grep(sub{ $_->name eq $guess })->head
           ||  $self->files
             ->grep(sub { $_->name =~ m{\.pm\z} and $_->name =~ m{\Alib/} })
             ->sort(sub { length $_[0]->name <=> length $_[1]->name })
             ->head;
    }

    die "Unable to find main_module in dist\n" unless $file;

    $self->log("${guessing}dist's main_module is " . $file->name);

    return $file;
  },
);


=attr copyright_holder

This is the name of the legal entity who holds the copyright on this code.
This is a required attribute with no default!

=cut

has copyright_holder => (
  is   => 'ro',
  isa  => 'Str',
  required => 1,
);

=attr copyright_year

This is the year of copyright for the dist.  By default, it's this year.

=cut

has copyright_year => (
  is   => 'ro',
  isa  => 'Int',

  # Oh man.  This is a terrible idea!  I mean, what if by the code gets run
  # around like Dec 31, 23:59:59.9 and by the time the default gets called it's
  # the next year but the default was already set up?  Oh man.  That could ruin
  # lives!  I guess we could make this a sub to defer the guess, but think of
  # the performance hit!  I guess we'll have to suffer through this until we
  # can optimize the code to not take .1s to run, right? -- rjbs, 2008-06-13
  default => (localtime)[5] + 1900,
);

=attr license

This is the L<Software::License|Software::License> object for this dist's
license.  It will be created automatically, if possible, with the
C<copyright_holder> and C<copyright_year> attributes.  If necessary, it will
try to guess the license from the POD of the dist's main module.

A better option is to set the C<license> name in the dist's config to something
understandable, like C<Perl_5>.

=cut

has license => (
  reader => 'license',
  writer => '_set_license',
  isa    => License,
  init_arg => undef,
);

sub _initialize_license {
  my ($self, $value) = @_;

  my $license;

  # If it's an object (weird!) we're being handed a pre-created license and
  # we should probably just trust it. -- rjbs, 2009-07-21
  $license = $value if blessed $value;

  unless ($license) {
    my $license_class = $value;

    if ($license_class) {
      $license_class = String::RewritePrefix->rewrite(
        {
          '=' => '',
          ''  => 'Software::License::'
        },
        $license_class,
      );
    } else {
      require Software::LicenseUtils;
      my @guess = Software::LicenseUtils->guess_license_from_pod(
        $self->main_module->content
      );

      Carp::confess("couldn't make a good guess at license") if @guess != 1;

      my $filename = $self->main_module->name;
      $license_class = $guess[0];
      $self->log("based on POD in $filename, guessing license is $guess[0]");
    }

    eval "require $license_class; 1" or die;

    $license = $license_class->new({
      holder => $self->copyright_holder,
      year   => $self->copyright_year,
    });
  }

  confess "$value is not a valid license" if ! License->check($license);

  $self->_set_license($license);
}

=attr authors

This is an arrayref of author strings, like this:

  [
    'Ricardo Signes <rjbs@cpan.org>',
    'X. Ample, Jr <example@example.biz>',
  ]

This is likely to change at some point in the near future.

=cut

has authors => (
  is   => 'ro',
  isa  => 'ArrayRef[Str]',
  lazy => 1,
  required => 1,
  default  => sub { [ $_[0]->copyright_holder ] },
);

=attr files

This is an arrayref of objects implementing L<Dist::Zilla::Role::File> that
will, if left in this arrayref, be built into the dist.

=cut

has files => (
  is   => 'ro',
  isa  => 'ArrayRef[Dist::Zilla::Role::File]',
  lazy => 1,
  init_arg => undef,
  default  => sub { [] },
);

=attr root

This is the root directory of the dist, as a L<Path::Class::Dir>.  It will
nearly always be the current working directory in which C<dzil> was run.

=cut

has root => (
  is   => 'ro',
  isa  => Dir,
  coerce   => 1,
  required => 1,
);

=attr plugins

This is an arrayref of plugins that have been plugged into this Dist::Zilla
object.

=cut

has plugins => (
  is   => 'ro',
  isa  => 'ArrayRef[Dist::Zilla::Role::Plugin]',
  default => sub { [ ] },
);

=attr built_in

This is the L<Path::Class::Dir>, if any, in which the dist has been built.

=cut

has built_in => (
  is   => 'rw',
  isa  => Dir,
  init_arg  => undef,
);

=attr distmeta

This is a hashref containing the metadata about this distribution that
will be stored in META.yml or META.json.  You should not alter the
metadata in this hash; use a MetaProvider plugin instead.

=cut

has distmeta => (
  is   => 'ro',
  isa  => 'HashRef',
  init_arg  => undef,
  lazy      => 1,
  default => sub {
    my ($self) = @_;

    my $meta = {
      'meta-spec' => {
        version => 1.4,
        url     => 'http://module-build.sourceforge.net/META-spec-v1.4.html',
      },
      name     => $self->name,
      version  => $self->version,
      abstract => $self->abstract,
      author   => $self->authors,
      license  => $self->license->meta_yml_name,
      requires => $self->prereq,
      generated_by => (ref $self) . ' version ' . $self->VERSION,
    };

    $meta = Hash::Merge::Simple::merge($meta, $_->metadata)
      for $self->plugins_with(-MetaProvider)->flatten;

    $meta;
  } # end default for distmeta
);

=attr prereq

This is a hashref of module prerequisites.  This attribute is likely to get
greatly overhauled, or possibly replaced with a method based on other
(private?) attributes.

=cut

sub prereq {
  my ($self) = @_;

  # XXX: This needs to always include the highest version. -- rjbs, 2008-06-01
  my $prereq = {};
  $prereq = $prereq->merge( $_->prereq )
    for $self->plugins_with(-FixedPrereqs)->flatten;

  return $prereq;
}

=method from_config

  my $zilla = Dist::Zilla->from_config(\%arg);

This routine returns a new Zilla from the configuration in the current working
directory.

Valid arguments are:

  config_class - the class to use to read the config
                 default: Dist::Zilla::Config::INI

=cut

sub from_config {
  my ($class, $arg) = @_;
  $arg ||= {};

  my $root = Path::Class::dir($arg->{dist_root} || '.');

  my ($seq) = $class->_load_config(
    $arg->{config_class},
    $root,
  );

  my $core_config = $seq->section_named('_')->payload;

  my $self = $class->new($core_config);

  for my $section ($seq->sections) {
    next if $section->name eq '_';

    my ($name, $plugin_class, $arg) = (
      $section->name,
      $section->package,
      $section->payload,
    );

    $self->log("initializing plugin $name ($plugin_class)");

    confess "arguments attempted to override plugin name"
      if defined $arg->{plugin_name};

    confess "arguments attempted to override plugin name"
      if defined $arg->{zilla};

    $self->plugins->push(
      $plugin_class->new( $arg->merge({
        plugin_name => $name,
        zilla       => $self,
      }) )
    );
  }

  return $self;
}

sub _load_config {
  my ($self, $config_class, $root) = @_;

  $config_class ||= 'Dist::Zilla::Config::Finder';
  unless (eval "require $config_class; 1") {
    die "couldn't load $config_class: $@"; ## no critic Carp
  }

  $self->log("reading configuration using $config_class");

  my ($sequence) = $config_class->new->read_config({
    root     => $root,
    basename => 'dist',
  });

  # I wonder if the root should be named '' or something, but that's probably
  # sort of a ridiculous thing to worry about. -- rjbs, 2009-08-24
  $sequence->section_named('_')->add_value(root => $root);

  return $sequence;
}

=method plugins_with

  my $roles = $zilla->plugins_with( -SomeRole );

This method returns an arrayref containing all the Dist::Zilla object's plugins
that perform a the named role.  If the given role name begins with a dash, the
dash is replaced with "Dist::Zilla::Role::"

=cut

sub plugins_with {
  my ($self, $role) = @_;

  $role =~ s/^-/Dist::Zilla::Role::/;
  my $plugins = $self->plugins->grep(sub { $_->does($role) });

  return $plugins;
}

=method build_in

  $zilla->build_in($root);

This method builds the distribution in the given directory.  If no directory
name is given, it defaults to DistName-Version.  If the distribution has
already been built, an exception will be thrown.

=cut

sub build_in {
  my ($self, $root) = @_;

  Carp::confess("attempted to build " . $self->name . " a second time")
    if $self->built_in;

  $_->before_build for $self->plugins_with(-BeforeBuild)->flatten;

  $self->log("beginning to build " . $self->name);

  $_->gather_files    for $self->plugins_with(-FileGatherer)->flatten;
  $_->prune_files     for $self->plugins_with(-FilePruner)->flatten;
  $_->munge_files     for $self->plugins_with(-FileMunger)->flatten;
  $_->setup_installer for $self->plugins_with(-InstallTool)->flatten;

  $self->_check_dupe_files;

  my $build_root = $self->_prep_build_root($root);

  $self->log("writing " . $self->name . " in $build_root");

  for my $file ($self->files->flatten) {
    $self->_write_out_file($file, $build_root);
  }

  $_->after_build({ build_root => $build_root })
    for $self->plugins_with(-AfterBuild)->flatten;

  $self->built_in($build_root);
}

=method ensure_built_in

  $zilla->ensure_built_in($root);

This method behaves like C<L</build_in>>, but if the dist is already built in
C<$root> (or the default root, if no root is given), no exception is raised.

=cut

sub ensure_built_in {
  my ($self, $root) = @_;

  # $root ||= $self->name . q{-} . $self->version;
  return if $self->built_in and
    (!$root or ($self->built_in eq $root));

  Carp::croak("dist is already built, but not in $root") if $self->built_in;
  $self->build_in($root);
}

=method build_archive

  $dist->build_archive($root);

This method will ensure that the dist has been built in the given root, and
will then build a tarball of that directory in the current directory.

=cut

sub build_archive {
  my ($self, $root) = @_;

  $self->ensure_built_in($root);

  require Archive::Tar;
  my $archive = Archive::Tar->new;
  my $built_in = $self->built_in;

  my %seen_dir;

  for my $file ($self->files->flatten) {
    my $in = Path::Class::file($file->name)->dir;
    $archive->add_files( $built_in->subdir($in) ) unless $seen_dir{ $in }++;
    $archive->add_files( $built_in->file( $file->name ) );
  }

  ## no critic
  my $file = Path::Class::file($self->name . '-' . $self->version . '.tar.gz');

  $self->log("writing archive to $file");
  $archive->write("$file", 9);

  return $file;
}

sub _check_dupe_files {
  my ($self) = @_;

  my %files_named;
  for my $file ($self->files->flatten) {
    ($files_named{ $file->name} ||= [])->push($file);
  }

  return unless
    my @dupes = grep { $files_named{$_}->length > 1 } keys %files_named;

  for my $name (@dupes) {
    $self->log("attempt to add $name multiple times; added by: "
       . join('; ', map { $_->added_by } @{ $files_named{ $name } })
    );
  }

  Carp::croak("aborting; duplicate files would be produced");
}

sub _prep_build_root {
  my ($self, $build_root) = @_;

  my $default_name = $self->name . q{-} . $self->version;
  $build_root = Path::Class::dir($build_root || $default_name);

  $build_root->mkpath unless -d $build_root;

  my $dist_root = $self->root;

  $build_root->rmtree if -d $build_root;

  return $build_root;
}

sub _write_out_file {
  my ($self, $file, $build_root) = @_;

  # Okay, this is a bit much, until we have ->debug. -- rjbs, 2008-06-13
  # $self->log("writing out " . $file->name);

  my $file_path = Path::Class::file($file->name);

  my $to_dir = $build_root->subdir( $file_path->dir );
  my $to = $to_dir->file( $file_path->basename );
  $to_dir->mkpath unless -e $to_dir;
  die "not a directory: $to_dir" unless -d $to_dir;

  Carp::croak("attempted to write $to multiple times") if -e $to;

  open my $out_fh, '>', "$to" or die "couldn't open $to to write: $!";
  print { $out_fh } $file->content;
  close $out_fh or die "error closing $to: $!";
}

=method test

  $zilla->test;

This method builds a new copy of the distribution and tests it.  If the tests
appear to pass, it returns true.  If something goes wrong, it returns false.

=cut

sub test { die '...' }

=method release

  $zilla->release;

This method releases the distribution, probably by uploading it to the CPAN.
The actual effects of this method (as with most of the methods) is determined
by the loaded plugins.

=cut

sub release { die '...' }

=method log

  $zilla->log($message);

This method logs the given message.  In the future it will be a more useful and
expressive method.  For now, it just prints the string after tacking on a
newline.

=cut

# XXX: yeah, uh, do something more awesome -- rjbs, 2008-06-01
sub log { ## no critic
  my ($self, $msg) = @_;
  require Dist::Zilla::Util;
  Dist::Zilla::Util->_log($msg);
}

sub BUILD {
  my ($self, $arg) = @_;

  $self->_initialize_license($arg->{license});
}

__PACKAGE__->meta->make_immutable;
1;
__END__
=head1 DESCRIPTION

Dist::Zilla builds distributions of code to be uploaded to the CPAN.  In this
respect, it is like L<ExtUtils::MakeMaker>, L<Module::Build>, or
L<Module::Install>.  Unlike those tools, however, it is not also a system for
installing code that has been downloaded from the CPAN.  Since it's only run by
authors, and is meant to be run on a repository checkout rather than on
published, released code, it can do much more than those tools, and is free to
make much more ludicrous demands in terms of prerequisites.

For more information, see L<Dist::Zilla::Tutorial>.

=head1 SUPPORT

There are usually people on C<irc.perl.org> in C<#distzilla>, even if they're
idling.

There is a mailing list to discuss Dist::Zilla, which you can join here:

L<http://www.listbox.com/subscribe/?list_id=139292>

The archive is available here:

L<http://listbox.com/member/archive/139292>

