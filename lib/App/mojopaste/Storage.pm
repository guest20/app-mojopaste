package App::mojopaste::Storage;
#ABSTRACT: paste storage
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Loader qw[ load_class ];

has storage => sub {
  die "Too late to decide storage, plase pass 'storage' => to the plugin"
};

has 'app';
sub register { my ($plugin,$app,$conf) = @_;

  my ($backend,$e) =  __PACKAGE__ . '::' . ($conf->{storage} // 'Sha1sOnDisk');
  die "'$backend' isn't a very good backend: $e" if $e = load_class $backend;

  # make sure we're nice and leaky:
  $plugin->app($app);
  $plugin->storage(
    $backend->new(
      plugin        => $plugin,
      storage_root  => $conf->{paste_dir},
  ));

  # something something config something ->storage
  $app->helper( store => sub { 
    $plugin->storage
  });
}

1
