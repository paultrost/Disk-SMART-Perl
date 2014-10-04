use warnings;
use strict;
use Test::More 'tests' => 8;
use Disk::SMART;

my $disk  = '/dev/sda';
my $smart = Disk::SMART->new($disk);

ok( $smart->get_disk_temp($disk), 'get_disk_temp() returns drive temperature or N/A' );
is( eval{$smart->get_disk_temp('/dev/sdz')}, undef, 'get_disk_temp() returns failure when passed invalid device' );
like( $smart->get_disk_health($disk), qr/PASSED|FAILED|N\/A/, 'get_disk_health() returns health status or N/A' );
is( eval{$smart->get_disk_health('/dev/sdz')}, undef, 'get_disk_health() returns failure when passed invalid device' );
like( $smart->get_disk_model($disk),  qr/\w+/,    'get_disk_model() returns disk model or N/A' );
is( eval{$smart->get_disk_errors('/dev/sdz')}, undef, 'get_disk_model() returns failure when passed invalid device' );
like( $smart->get_disk_errors($disk), qr/\w+/, 'get_disk_errors() returns proper string' );
is( eval{$smart->get_disk_errors('/dev/sdz')}, undef, 'get_disk_errors() returns failure when passed invalid device' );
