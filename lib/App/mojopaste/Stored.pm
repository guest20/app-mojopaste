package App::mojopaste::Stored;
#ABSTRACT: a paste stored by YamlShas
use Mojo::Base -base;

has [
  id      => # usable in urls

  hold_path  => # directory all the bits go in 
  blob_path  => # the file name for the blob
  meta_path  => # path to the meta file

];

has [qw[ created_date created_by ]];
has [qw[ encoding ]];

has blob_stat =>  sub { [stat $_[0]->blob_path] };
#  7 size     total size of file, in bytes
#  8 atime    last access time in seconds since the epoch
#  9 mtime    last modify time in seconds since the epoch
# 10 ctime    inode change time in seconds since the epoch (*)

has size => sub { $_[0]->blob_stat->[7] };

sub path { $_[0]->blob_path }

has 'storage';

has 'meta' => sub {
    use YAML qw[ LoadFile ];
    # use Mojo::Util qw(encode decode);
    LoadFile $_[0]->meta_path
};


sub raw_content {
    $_[0]->blob_path->slurp;
} # slurp

;1
