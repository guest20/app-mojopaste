package App::mojopaste::Storage::Sha1sOnDisk;
#ABSTRACT: store pastes in sha1'ed blobs on disk
use Mojo::Base -base;

# You get back these to represent the stored file:
use App::mojopaste::Stored;


has [qw[ plugin storage_root ]] => sub {
    die "plugin/storage_root should be set when I'm created"
};

has paste_dir => sub {
    my $paste_dir = path($_[0]->storage_root);
    -d $paste_dir or $paste_dir->make_path
                  or die "mkpath $paste_dir: $!";
    $paste_dir;
};

use Mojo::File 'path';
sub parse_ids { my $store=shift;
  map { my ($first_two,$the_next) = /(..)(.*)/;
    +{
      hold_path => path($store->paste_dir, $first_two, $the_next,),
      blob_path => path($store->paste_dir, $first_two, $the_next,'raw'),
      id => $_ }
  } @_
}

sub fetch_by_id {
    my $cb = (@_ and 'CODE' eq ref $_[-1]) ? pop : ();
    my ($store,$id) = @_;

    use YAML qw[ LoadFile ];

    my @pastes =  map { 
        (-e $_->{hold_path})
          ?  App::mojopaste::Stored->new( %$_ )
          : undef
    }
    $store->parse_ids($id);

  $cb ? $cb->(@pastes) : @pastes
    
}


# links to each pastes hold_dir can be found in new/date-pid
# you can do something with the links from cron (expire or something)
use Time::HiRes qw[ time ];
sub _wait_dequeue {my ($store) = @_;

}
sub _enqueue {my ($store,$blob) = @_;
  my $queue = path($store->paste_dir, 'new/');
  $queue->make_path unless -d $queue;

  # link OLDFILE,NEWFILE
    symlink $blob->hold_path, $queue->child(time . "-$$");
}

sub add_from_string { 
  my $cb = (@_ and 'CODE' eq ref $_[-1]) ? pop : ();
  my ($store,$content) = @_;

  my $encoded =  $content;

  my $id = Mojo::Util::sha1_sum( $encoded );
  
  my $blob = App::mojopaste::Stored->new( $store->parse_ids($id) );
  $blob->hold_path->make_path;

  $blob->blob_path->spurt($encoded);
  $store->_enqueue($blob);

  $cb ? $cb->($blob) : $blob

}

sub add_from_file {
  my $cb = (@_ and 'CODE' eq ref $_[-1]) ? pop : ();
  my ($store,$up) = @_;


  my $id = Mojo::Util::sha1_sum($up->slurp);

  my $blob = App::mojopaste::Stored->new( $store->parse_ids($id) );
  $blob->hold_path->make_path;

  $up->move_to( $blob->blob_path );
  $store->_enqueue($blob);


  $cb ? $cb->($blob) : $blob

}

1
