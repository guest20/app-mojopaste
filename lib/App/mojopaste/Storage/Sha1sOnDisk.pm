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
  map { my ($first_two,$the_next);
       (($first_two,$the_next) = /^([0-9a-f]{2})([0-9a-f]{38})$/)
    ? +{
      hold_path => path($store->paste_dir, $first_two, $the_next,),
      blob_path => path($store->paste_dir, $first_two, $the_next,'raw'),
      id => $_ }
    : ()
  } @_
}

sub fetch_by_id {
    my $cb = (@_ and 'CODE' eq ref $_[-1]) ? pop : ();
    my ($store,@id) = @_;

    use YAML qw[ LoadFile ];

    my @pastes =  map { 
        (-e $_->{hold_path})
          ?  App::mojopaste::Stored->new( %$_ )
          : undef
    }
    $store->parse_ids(@id);

  $cb ? $cb->(@pastes) : @pastes
    
}

sub add_from_string { 
  my $cb = (@_ and 'CODE' eq ref $_[-1]) ? pop : ();
  my ($store,$content) = @_;

  my $encoded =  $content;

  my $id = Mojo::Util::sha1_sum( $encoded );
  
  my $blob = App::mojopaste::Stored->new( $store->parse_ids($id) );
  $blob->hold_path->make_path;

  $blob->blob_path->spurt($encoded);

  $cb ? $cb->($blob) : $blob

}

sub add_from_file {
  my $cb = (@_ and 'CODE' eq ref $_[-1]) ? pop : ();
  my ($store,$up) = @_;


  my $id = Mojo::Util::sha1_sum($up->slurp);

  my $blob = App::mojopaste::Stored->new( $store->parse_ids($id) );
  $blob->hold_path->make_path;

  $up->move_to( $blob->blob_path );


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
