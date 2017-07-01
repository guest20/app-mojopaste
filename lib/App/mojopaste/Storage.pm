package App::mojopaste::Storage;
#ABSTRACT: paste storage
use Mojo::Base 'Mojolicious::Plugin';

use App::mojopaste::Storage::YamlShas;
has storage => sub {
    App::mojopaste::Storage::YamlShas->new;
};

has 'app';
sub register { my ($plugin,$app,$conf) = @_;

  die "Only 'YamlShas' is supported for use"
    if $conf->{storage} ne 'YamlShas';


  # make sure we're nice and leaky:
  $plugin->app($app);
  $plugin->storage(
    App::mojopaste::Storage::YamlShas->new(
      plugin        => $plugin,
      storage_root  => $conf->{paste_dir},
  ));

  # something something config something ->storage
  $app->helper( store => sub { 
    $plugin->storage
  });
}

# add_from_path   ( $path, $cb )
# add_from_url    ( \@urls, \%options, $cb )
# add_from_string ( $path, $cb )
# fetch_by_id     ( $id,   $cb )


# if_modified_since for urls?

# some kind of blind iterator.

# some kind of matching thinger.
1
