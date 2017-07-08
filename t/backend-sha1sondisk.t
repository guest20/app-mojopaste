use lib '.';
use t::Helper;

die "I need to be run from the root of the repo."
    unless -f './README';

my $t   = t::Helper->t;

use_ok 'App::mojopaste::Storage';

my $store= App::mojopaste::Storage::Sha1sOnDisk->new( {
  storage_root=> my $PASTE_DIR=$ENV{PASTE_DIR},
});

use Mojo::Util;
use Mojo::File 'path';

FROM_STRING: {

    my $raw = "$$ stole my $!";
    my $id = Mojo::Util::sha1_sum( $raw );

    diag "$id - $raw";
    my $path_on_disk = path($PASTE_DIR, (split /^(..)/, $id, ), 'raw');


    ok( ! -f $path_on_disk, "$path_on_disk should be missing")
        or diag "Instead it contains: " . $path_on_disk->slurp;;

    my $first = $store->add_from_string($raw);
    ok( -f $path_on_disk, "$path_on_disk should exist")
        or die "Instead: $!";

    # use Data::Dumper; diag Dumper($first);
    is_deeply( $first->id, $id, "Id" );
    is_deeply( $path_on_disk->slurp, $first->raw_content, "Same on disk" );

    # If I had implemented ->remove on $blob, I'd test it here.
    # instead we just clean up after ourselves:
    $first->hold_path->remove_tree;
}

FROM_FILE:{

    my $source = path( './README' )->copy_to("./README-$$"); # will be moved
    my $raw = $source->slurp;
    my $id = Mojo::Util::sha1_sum( $raw );

    diag "$id - $source";
    my $path_on_disk = path($PASTE_DIR, (split /^(..)/, $id, ), 'raw');

    ok( ! -f $path_on_disk, "$path_on_disk should be missing")
        or die "Instead it contains: " . $path_on_disk->slurp;

    my $first = $store->add_from_file( $source );
    ok( -f $path_on_disk, "$path_on_disk should exist")
        or diag "Instead: $!";

    # use Data::Dumper; diag Dumper($first);
    is_deeply( $first->id, $id, "Id" );
    is_deeply( $path_on_disk->slurp, $first->raw_content, "Same on disk" );

    # If I had implemented ->remove on $blob, I'd test it here.
    # instead we just clean up after ourselves:
    $first->hold_path->remove_tree;
}


done_testing;
