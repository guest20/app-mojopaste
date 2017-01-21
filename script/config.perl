{                                        
  paste_dir     => '/tmp/lols',
  enable_charts => 1, # default is 0     
  hypnotoad => {                         
    listen => ['http://*:12345'],         
  },                                     
  paste_peers => [qw[ http://localhost:12345 http://localhost:12346 http://localhost:12347 http://localhost:31337]]
}                                        
