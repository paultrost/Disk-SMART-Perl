use warnings;
use strict;
use Test::More 'tests' => 1;
use Disk::SMART;

my $smart = Disk::SMART->new('/dev/sda');

pass('instantiation of object successful') if ( defined($smart) );
