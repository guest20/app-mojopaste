package App::mojopaste::Storage::YamlShas;
#ABSTRACT: store pastes in sha1'ed blobs, along with a yaml index file
use Mojo::Base -base;


has [qw[ plugin storage_root ]] => sub {
    die "plugin/storage_root should be set when I'm created"
};

use Mojo::File 'path';

has paste_dir => sub {
    my $paste_dir = path($_[0]->storage_root);
    -d $paste_dir or $paste_dir->make_path
                  or die "mkpath $paste_dir: $!";
    $paste_dir;
};



sub parse_ids { my $store=shift;
  map { my ($first_two,$the_next);
       (($first_two,$the_next) = /^([0-9a-f]{2})([0-9a-f]{38})$/)
    ? +{
      hold_path => path($store->paste_dir, $first_two, $the_next,),
      blob_path => path($store->paste_dir, $first_two, $the_next,'raw'),
      meta_path => path($store->paste_dir, $first_two, $the_next,'meta.yaml'),
      id => $_ }
    : ()
  } @_
}

use App::mojopaste::Stored;
use YAML qw[ LoadFile ];
sub fetch_by_id {
    my $cb = (@_ and 'CODE' eq ref $_[-1]) ? pop : ();
    my ($store,$id) = @_;

    my @pastes =  map { 
        (-e $_->{hold_path})
          ?  App::mojopaste::Stored->new(
            %$_,
            ( -e $_->{meta_path} )
              ?  ( meta =>  LoadFile $_->{meta_path} )
              : ()
          )
          : undef
    }
    $store->parse_ids($id);

  $cb ? $cb->(@pastes) : @pastes
    
}

use YAML qw[ Dump ];
use Mojo::Util qw(encode decode);

use Time::HiRes qw[ time ];
sub _wait_dequeue {my ($store) = @_;

}
sub _enqueue {my ($store,$blob) = @_;
  my $queue = path($store->paste_dir, 'new/');
  $queue->make_path unless -d $queue;

  # link OLDFILE,NEWFILE
    symlink $blob->hold_path, $queue->child(time . "-$$");
  # add a meta entry that says "still in processing queue"

  
}


sub add_from_string { 
  my $cb = (@_ and 'CODE' eq ref $_[-1]) ? pop : ();
  my ($store,$content,$meta) = @_;

  my $encoded =  $content;# encode 'UTF-8', $paste;

  my $id = Mojo::Util::sha1_sum( $encoded );
  
  my $blob = App::mojopaste::Stored->new( $store->parse_ids($id) );
  $blob->hold_path->make_path;

  $blob->blob_path->spurt($encoded);
  $blob->meta({
    %{$meta||{}},
    source => { method => '_from_string' }
  });
  $blob->meta_path->spurt( Dump $blob->meta );
  $store->_enqueue($blob);

  $cb ? $cb->($blob) : $blob

}

sub add_from_file {
  my $cb = (@_ and 'CODE' eq ref $_[-1]) ? pop : ();
  my ($store,$up,$meta) = @_;


  my $id = Mojo::Util::sha1_sum($up->slurp);

  my $blob = App::mojopaste::Stored->new( $store->parse_ids($id) );
  $blob->hold_path->make_path;

  $up->move_to( $blob->blob_path );
  $blob->meta({
    %{$meta||{}},
    source => { method => '_from_file' },
    upload => {
              $up->can('size')     ? ( size => $up->size ) : (),
              $up->can('filename') ? ( name => $up->filename ) : (),
              }, 
  });
  $blob->meta_path->spurt( Dump $blob->meta );
  $store->_enqueue($blob);


  $cb ? $cb->($blob) : $blob

}

sub fetch_in_groups {
  my ($store, $size, $cb) = @_;

  # 42 hex chars, but olol
  my @h=(0..9,'a'..'f');
  my @partitions = map { my $f=$_; map { "$f$_" } @h } @h;
 
  #something forky
  for (@partitions) { 
      s{/}{} for my @ids =
      map path($_)->to_rel($store->paste_dir),
        my @blobs =
            glob path($store->paste_dir, $_, "*"); 
      #warn $_, @ids;
      $store->fetch_by_id( @ids, $cb );
  }

}

1
