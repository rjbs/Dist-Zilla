package Dist::Zilla::Dist::Minter;
# ABSTRACT: distribution builder; installer not included!

use Moose 0.92; # role composition fixes
extends 'Dist::Zilla';

use Dist::Zilla::Pragmas;

use File::pushd ();
use Dist::Zilla::Path;
use Module::Runtime 'require_module';

use namespace::autoclean;

sub _setup_default_plugins ($self) {
  unless ($self->plugin_named(':DefaultModuleMaker')) {
    require Dist::Zilla::Plugin::TemplateModule;
    my $plugin = Dist::Zilla::Plugin::TemplateModule->new({
      plugin_name => ':DefaultModuleMaker',
      zilla       => $self,
    });

    push @{ $self->plugins }, $plugin;
  }
}

sub _new_from_profile ($class, $profile_data, $arg) {
  $arg ||= {};

  my $config_class =
    $arg->{config_class} ||= 'Dist::Zilla::MVP::Reader::Finder';
  require_module($config_class);

  $arg->{chrome}->logger->log_debug(
    { prefix => '[DZ] ' },
    "reading configuration using $config_class"
  );

  require Dist::Zilla::MVP::Assembler::Zilla;
  require Dist::Zilla::MVP::Section;
  my $assembler = Dist::Zilla::MVP::Assembler::Zilla->new({
    chrome        => $arg->{chrome},
    zilla_class   => $class,
    section_class => 'Dist::Zilla::MVP::Section', # make this DZMA default
  });

  for ($assembler->sequence->section_named('_')) {
    $_->add_value(name   => $arg->{name});
    $_->add_value(chrome => $arg->{chrome});
    $_->add_value(_global_stashes => $arg->{_global_stashes})
      if $arg->{_global_stashes};
  }

  my $module = String::RewritePrefix->rewrite(
    { '' => 'Dist::Zilla::MintingProfile::', '=', => '' },
    $profile_data->[0],
  );
  require_module($module);

  my $profile_dir = $module->profile_dir($profile_data->[1]);

  warn "expected a string or Path::Tiny but got a Path::Class from $module\n"
    if ref $profile_dir && $profile_dir->isa('Path::Class');

  $profile_dir = path($profile_dir);

  $assembler->sequence->section_named('_')->add_value(root => $profile_dir);

  my $seq = $config_class->read_config(
    $profile_dir->child('profile'),
    {
      assembler => $assembler
    },
  );

  my $self = $seq->section_named('_')->zilla;

  $self->_setup_default_plugins;

  return $self;
}

sub _mint_target_dir ($self) {
  my $name = $self->name;
  my $dir  = path($name);
  $self->log_fatal("./$name already exists") if -e $dir;

  return $dir = $dir->absolute;
}

sub mint_dist ($self, $arg = {}) {
  my $name = $self->name;
  my $dir  = $self->_mint_target_dir;

  # XXX: We should have a way to get more than one module name in, and to
  # supply plugin names for the minter to use. -- rjbs, 2010-05-03
  my @modules = (
    { name => $name =~ s/-/::/gr }
  );

  $self->log("making target dir $dir");
  $dir->mkpath;

  my $wd = File::pushd::pushd($self->root);

  $_->before_mint  for @{ $self->plugins_with(-BeforeMint) };

  for my $module (@modules) {
    my $minter = $self->plugin_named(
      $module->{minter_name} || ':DefaultModuleMaker'
    );

    $minter->make_module({ name => $module->{name} })
  }

  $_->gather_files       for @{ $self->plugins_with(-FileGatherer) };
  $_->set_file_encodings for @{ $self->plugins_with(-EncodingProvider) };
  $_->prune_files        for @{ $self->plugins_with(-FilePruner) };
  $_->munge_files        for @{ $self->plugins_with(-FileMunger) };

  $self->_check_dupe_files;

  $self->log("writing files to $dir");

  for my $file (@{ $self->files }) {
    $self->_write_out_file($file, $dir);
  }

  $_->after_mint({ mint_root => $dir })
    for @{ $self->plugins_with(-AfterMint) };

  $self->log("dist minted in ./$name");
}

__PACKAGE__->meta->make_immutable;
1;
