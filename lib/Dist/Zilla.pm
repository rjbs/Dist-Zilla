package Dist::Zilla;
# ABSTRACT: distribution builder; installer not included!

use Moose 0.92; # role composition fixes
with 'Dist::Zilla::Role::ConfigDumper';

# This comment has fün̈n̈ÿ characters.

use MooseX::Types::Moose qw(ArrayRef Bool HashRef Object Str);
use MooseX::Types::Perl qw(DistName LaxVersionStr);
use MooseX::Types::Path::Class qw(Dir File);
use Moose::Util::TypeConstraints;

use Dist::Zilla::Types qw(License);

use Log::Dispatchouli 1.100712; # proxy_loggers, quiet_fatal
use Path::Class;
use Path::Tiny;
use List::Util 1.33 qw(first none);
use Software::License 0.101370; # meta2_name
use String::RewritePrefix;
use Try::Tiny;

use Dist::Zilla::Prereqs;
use Dist::Zilla::File::OnDisk;
use Dist::Zilla::Role::Plugin;
use Dist::Zilla::Util;

use namespace::autoclean;

=head1 DESCRIPTION

Dist::Zilla builds distributions of code to be uploaded to the CPAN.  In this
respect, it is like L<ExtUtils::MakeMaker>, L<Module::Build>, or
L<Module::Install>.  Unlike those tools, however, it is not also a system for
installing code that has been downloaded from the CPAN.  Since it's only run by
authors, and is meant to be run on a repository checkout rather than on
published, released code, it can do much more than those tools, and is free to
make much more ludicrous demands in terms of prerequisites.

If you have access to the web, you can learn more and find an interactive
tutorial at B<L<dzil.org|http://dzil.org/>>.  If not, try
L<Dist::Zilla::Tutorial>.

=cut

has chrome => (
  is  => 'rw',
  isa => role_type('Dist::Zilla::Role::Chrome'),
  required => 1,
);

=attr name

The name attribute (which is required) gives the name of the distribution to be
built.  This is usually the name of the distribution's main module, with the
double colons (C<::>) replaced with dashes.  For example: C<Dist-Zilla>.

=cut

has name => (
  is   => 'ro',
  isa  => DistName,
  lazy => 1,
  builder => '_build_name',
);

=attr version

This is the version of the distribution to be created.

=cut

has _version_override => (
  isa => LaxVersionStr,
  is  => 'ro' ,
  init_arg => 'version',
);

# XXX: *clearly* this needs to be really much smarter -- rjbs, 2008-06-01
has version => (
  is   => 'rw',
  isa  => LaxVersionStr,
  lazy => 1,
  init_arg  => undef,
  builder   => '_build_version',
);

sub _build_name {
  my ($self) = @_;

  my $name;
  for my $plugin (@{ $self->plugins_with(-NameProvider) }) {
    next unless defined(my $this_name = $plugin->provide_name);

    $self->log_fatal('attempted to set name twice') if defined $name;

    $name = $this_name;
  }

  $self->log_fatal('no name was ever set') unless defined $name;

  $name;
}

sub _build_version {
  my ($self) = @_;

  my $version = $self->_version_override;

  for my $plugin (@{ $self->plugins_with(-VersionProvider) }) {
    next unless defined(my $this_version = $plugin->provide_version);

    $self->log_fatal('attempted to set version twice') if defined $version;

    $version = $this_version;
  }

  $self->log_fatal('no version was ever set') unless defined $version;

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
  default  => sub {
    my ($self) = @_;

    unless ($self->main_module) {
      die "no abstract given and no main_module found; make sure your main module is in ./lib\n";
    }

    my $file = $self->main_module;
    $self->log_debug("extracting distribution abstract from " . $file->name);
    my $abstract = Dist::Zilla::Util->abstract_from_file($file);

    if (!defined($abstract)) {
        my $filename = $file->name;
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

has _main_module_override => (
  isa => 'Str',
  is  => 'ro' ,
  init_arg  => 'main_module',
  predicate => '_has_main_module_override',
);

has main_module => (
  is   => 'ro',
  isa  => 'Dist::Zilla::Role::File',
  lazy => 1,
  init_arg => undef,
  default  => sub {

    my ($self) = @_;

    my $file;
    my $guess;

    if ( $self->_has_main_module_override ) {
       $file = first { $_->name eq $self->_main_module_override }
               @{ $self->files };
    } else {
       # We're having to guess

       ($guess = $self->name) =~ s{-}{/}g;
       $guess = "lib/$guess.pm";

       $file = (first { $_->name eq $guess } @{ $self->files })
           ||  (sort { length $a->name <=> length $b->name }
                grep { $_->name =~ m{\.pm\z} and $_->name =~ m{\Alib/} }
                @{ $self->files })[0];
       $self->log("guessing dist's main_module is " . ($file ? $file->name : $guess));
    }

    if (not $file) {
        my @errorlines;

        push @errorlines, "Unable to find main_module in the distribution";
        if ( $self->_has_main_module_override ) {
            push @errorlines, "'main_module' was specified in dist.ini but the file '" . $self->_main_module_override . "' is not to be found in our dist. ( Did you add it? )";
        } else {
            push @errorlines,"We tried to guess '$guess' but no file like that existed";
        }
        if ( not @{ $self->files } ) {
            push @errorlines, "Upon further inspection we didn't find any files in your dist, did you add any?";
        } elsif ( none { $_->name =~ m{\.pm\z} } @{ $self->files } ){
            push @errorlines, "We didn't find any .pm files in your dist, this is probably a problem.";
        }
        push @errorlines,"Cannot continue without a main_module";
        $self->log_fatal( join qq{\n}, @errorlines );
    }
    $self->log_debug("dist's main_module is " . $file->name);

    return $file;
  },
);

=attr license

This is the L<Software::License|Software::License> object for this dist's
license and copyright.

It will be created automatically, if possible, with the
C<copyright_holder> and C<copyright_year> attributes.  If necessary, it will
try to guess the license from the POD of the dist's main module.

A better option is to set the C<license> name in the dist's config to something
understandable, like C<Perl_5>.

=cut

has license => (
  is   => 'ro',
  isa  => License,
  lazy => 1,
  init_arg  => 'license_obj',
  predicate => '_has_license',
  builder   => '_build_license',
  handles   => {
    copyright_holder => 'holder',
    copyright_year   => 'year',
  },
);

sub _build_license {
  my ($self) = @_;

  my $license_class    = $self->_license_class;
  my $copyright_holder = $self->_copyright_holder;
  my $copyright_year   = $self->_copyright_year;

  my $provided_license;

  for my $plugin (@{ $self->plugins_with(-LicenseProvider) }) {
    my $this_license = $plugin->provide_license({
      copyright_holder => $copyright_holder,
      copyright_year   => $copyright_year,
    });

    next unless defined $this_license;

    $self->log_fatal('attempted to set license twice')
      if defined $provided_license;

    $provided_license = $this_license;
  }

  return $provided_license if defined $provided_license;

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

    if (@guess != 1) {
      $self->log_fatal(
        "no license data in config, no %Rights stash,",
        "couldn't make a good guess at license from Pod; giving up. ",
        "Perhaps you need to set up a global config file (dzil setup)?"
      );
    }

    my $filename = $self->main_module->name;
    $license_class = $guess[0];
    $self->log("based on POD in $filename, guessing license is $guess[0]");
  }

  Class::Load::load_class($license_class);

  my $license = $license_class->new({
    holder => $self->_copyright_holder,
    year   => $self->_copyright_year,
  });

  $self->_clear_license_class;
  $self->_clear_copyright_holder;
  $self->_clear_copyright_year;

  return $license;
}

has _license_class => (
  is        => 'ro',
  isa       => 'Maybe[Str]',
  lazy      => 1,
  init_arg  => 'license',
  clearer   => '_clear_license_class',
  default   => sub {
    my $stash = $_[0]->stash_named('%Rights');
    $stash && return $stash->license_class;
    return;
  }
);

has _copyright_holder => (
  is        => 'ro',
  isa       => 'Maybe[Str]',
  lazy      => 1,
  init_arg  => 'copyright_holder',
  clearer   => '_clear_copyright_holder',
  default   => sub {
    return unless my $stash = $_[0]->stash_named('%Rights');
    $stash && return $stash->copyright_holder;
    return;
  }
);

has _copyright_year => (
  is        => 'ro',
  isa       => 'Int',
  lazy      => 1,
  init_arg  => 'copyright_year',
  clearer   => '_clear_copyright_year',
  default   => sub {
    # Oh man.  This is a terrible idea!  I mean, what if by the code gets run
    # around like Dec 31, 23:59:59.9 and by the time the default gets called
    # it's the next year but the default was already set up?  Oh man.  That
    # could ruin lives!  I guess we could make this a sub to defer the guess,
    # but think of the performance hit!  I guess we'll have to suffer through
    # this until we can optimize the code to not take .1s to run, right? --
    # rjbs, 2008-06-13
    my $stash = $_[0]->stash_named('%Rights');
    my $year  = $stash && $stash->copyright_year;
    return defined $year ? $year : (localtime)[5] + 1900;
  }
);

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
  isa  => ArrayRef[Str],
  lazy => 1,
  default  => sub {
    my ($self) = @_;

    if (my $stash  = $self->stash_named('%User')) {
      return $stash->authors;
    }

    my $author = try { $self->copyright_holder };
    return [ $author ] if defined $author and length $author;

    $self->log_fatal(
      "No %User stash and no copyright holder;",
      "can't determine dist author; configure author or a %User section",
    );
  },
);

=attr files

This is an arrayref of objects implementing L<Dist::Zilla::Role::File> that
will, if left in this arrayref, be built into the dist.

Non-core code should avoid altering this arrayref, but sometimes there is not
other way to change the list of files.  In the future, the representation used
for storing files B<will be changed>.

=cut

has files => (
  is   => 'ro',
  isa  => ArrayRef[ role_type('Dist::Zilla::Role::File') ],
  lazy => 1,
  init_arg => undef,
  default  => sub { [] },
);

sub prune_file {
  my ($self, $file) = @_;
  my @files = @{ $self->files };

  for my $i (0 .. $#files) {
    next unless $file == $files[ $i ];
    splice @{ $self->files }, $i, 1;
    return;
  }

  return;
}

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

=attr is_trial

This attribute tells us whether or not the dist will be a trial release.

=cut

has is_trial => (
  is => 'rw', # XXX: make SetOnce -- rjbs, 2010-03-23
  isa => Bool,
  default => sub { $ENV{TRIAL} ? 1 : 0 }
);

=attr plugins

This is an arrayref of plugins that have been plugged into this Dist::Zilla
object.

Non-core code B<must not> alter this arrayref.  Public access to this attribute
B<may go away> in the future.

=cut

has plugins => (
  is   => 'ro',
  isa  => 'ArrayRef[Dist::Zilla::Role::Plugin]',
  init_arg => undef,
  default  => sub { [ ] },
);

=attr distmeta

This is a hashref containing the metadata about this distribution that will be
stored in META.yml or META.json.  You should not alter the metadata in this
hash; use a MetaProvider plugin instead.

=cut

has distmeta => (
  is   => 'ro',
  isa  => 'HashRef',
  init_arg  => undef,
  lazy      => 1,
  builder   => '_build_distmeta',
);

sub _build_distmeta {
  my ($self) = @_;

  require CPAN::Meta::Merge;
  my $meta_merge = CPAN::Meta::Merge->new(default_version => 2);
  my $meta = {
    'meta-spec' => {
      version => 2,
      url     => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec',
    },
    name     => $self->name,
    version  => $self->version,
    abstract => $self->abstract,
    author   => $self->authors,
    license  => [ $self->license->meta2_name ],

    # XXX: what about unstable?
    release_status => ($self->is_trial or $self->version =~ /_/)
                    ? 'testing'
                    : 'stable',

    dynamic_config => 0, # problematic, I bet -- rjbs, 2010-06-04
    generated_by   => $self->_metadata_generator_id
                    . ' version '
                    . (defined $self->VERSION ? $self->VERSION : '(undef)')
  };

  for (@{ $self->plugins_with(-MetaProvider) }) {
    $meta = $meta_merge->merge($meta, $_->metadata);
  }

  return $meta;
}

sub _metadata_generator_id { 'Dist::Zilla' }

=attr prereqs

This is a L<Dist::Zilla::Prereqs> object, which is a thin layer atop
L<CPAN::Meta::Prereqs>, and describes the distribution's prerequisites.

=cut

has prereqs => (
  is   => 'ro',
  isa  => 'Dist::Zilla::Prereqs',
  init_arg => undef,
  lazy     => 1,
  default  => sub { Dist::Zilla::Prereqs->new },
  handles  => [ qw(register_prereqs) ],
);

=method plugin_named

  my $plugin = $zilla->plugin_named( $plugin_name );

=cut

sub plugin_named {
  my ($self, $name) = @_;
  my $plugin = first { $_->plugin_name eq $name } @{ $self->plugins };

  return $plugin if $plugin;
  return;
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
  my $plugins = [ grep { $_->does($role) } @{ $self->plugins } ];

  return $plugins;
}

=method find_files

  my $files = $zilla->find_files( $finder_name );

This method will look for a
L<FileFinder|Dist::Zilla::Role::FileFinder>-performing plugin with the given
name and return the result of calling C<find_files> on it.  If no plugin can be
found, an exception will be raised.

=cut

sub find_files {
  my ($self, $finder_name) = @_;

  $self->log_fatal("no plugin named $finder_name found")
    unless my $plugin = $self->plugin_named($finder_name);

  $self->log_fatal("plugin $finder_name is not a FileFinder")
    unless $plugin->does('Dist::Zilla::Role::FileFinder');

  $plugin->find_files;
}

sub _check_dupe_files {
  my ($self) = @_;

  my %files_named;
  for my $file (@{ $self->files }) {
    push @{ $files_named{ $file->name} ||= [] }, $file;
  }

  return unless
    my @dupes = grep { @{ $files_named{$_} } > 1 } keys %files_named;

  for my $name (@dupes) {
    $self->log("attempt to add $name multiple times; added by: "
       . join('; ', map { $_->added_by } @{ $files_named{ $name } })
    );
  }

  Carp::croak("aborting; duplicate files would be produced");
}

sub _write_out_file {
  my ($self, $file, $build_root) = @_;

  # Okay, this is a bit much, until we have ->debug. -- rjbs, 2008-06-13
  # $self->log("writing out " . $file->name);

  my $file_path = file($file->name);

  my $to_dir = $build_root->subdir( $file_path->dir );
  my $to = $to_dir->file( $file_path->basename );
  $to_dir->mkpath unless -e $to_dir;
  die "not a directory: $to_dir" unless -d $to_dir;

  Carp::croak("attempted to write $to multiple times") if -e $to;

  path("$to")->spew_raw( $file->encoded_content );
  chmod $file->mode, "$to" or die "couldn't chmod $to: $!";
}

=attr logger

This attribute stores a L<Log::Dispatchouli::Proxy> object, used to log
messages.  By default, a proxy to the dist's L<Chrome|Dist::Zilla::Chrome> is
taken.

The following methods are delegated from the Dist::Zilla object to the logger:

=for :list
* log
* log_debug
* log_fatal

=cut

has logger => (
  is   => 'ro',
  isa  => 'Log::Dispatchouli::Proxy', # could be duck typed, I guess
  lazy => 1,
  handles => [ qw(log log_debug log_fatal) ],
  default => sub {
    $_[0]->chrome->logger->proxy({ proxy_prefix => '[DZ] ' })
  },
);

around dump_config => sub {
  my ($orig, $self) = @_;
  my $config = $self->$orig;
  $config->{is_trial} = $self->is_trial;
  return $config;
};

has _local_stashes => (
  is   => 'ro',
  isa  => HashRef[ Object ],
  lazy => 1,
  default => sub { {} },
);

has _global_stashes => (
  is   => 'ro',
  isa  => HashRef[ Object ],
  lazy => 1,
  default => sub { {} },
);

=method stash_named

  my $stash = $zilla->stash_named( $name );

This method will return the stash with the given name, or undef if none exists.
It looks for a local stash (for this dist) first, then falls back to a global
stash (from the user's global configuration).

=cut

sub stash_named {
  my ($self, $name) = @_;

  return $self->_local_stashes->{ $name } if $self->_local_stashes->{$name};
  return $self->_global_stashes->{ $name };
}

__PACKAGE__->meta->make_immutable;
1;

=head1 SUPPORT

There are usually people on C<irc.perl.org> in C<#distzilla>, even if they're
idling.

The L<Dist::Zilla website|http://dzil.org/> has several valuable resources for
learning to use Dist::Zilla.

There is a mailing list to discuss Dist::Zilla.  You can L<join the
list|http://www.listbox.com/subscribe/?list_id=139292> or L<browse the
archives|http://listbox.com/member/archive/139292>.

=head1 SEE ALSO

=over 4

=item *

In the Dist::Zilla distribution:

=over 4

=item *

Plugin bundles:
L<@Basic|Dist::Zilla::PluginBundle::Basic>,
L<@Filter|Dist::Zilla::PluginBundle::Filter>.

=item *

Major plugins:
L<GatherDir|Dist::Zilla::Plugin::GatherDir>,
L<Prereqs|Dist::Zilla::Plugin::Prereqs>,
L<AutoPrereqs|Dist::Zilla::Plugin::AutoPrereqs>,
L<MetaYAML|Dist::Zilla::Plugin::MetaYAML>,
L<MetaJSON|Dist::Zilla::Plugin::MetaJSON>,
...

=back

=item *

On the CPAN:

=over 4

=item *

Search for plugins: L<https://metacpan.org/search?q=Dist::Zilla::Plugin::>

=item *

Search for plugin bundles: L<https://metacpan.org/search?q=Dist::Zilla::PluginBundle::>

=back

=back
