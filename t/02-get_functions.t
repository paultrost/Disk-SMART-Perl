use warnings;
use strict;
use Test::More 'tests' => 12;
use Disk::SMART;

my $disk  = '/dev/sda';
my $smart = Disk::SMART->new($disk);

ok( $smart->get_disk_temp($disk), 'get_disk_temp() returns drive temperature or N/A' );
is( eval{$smart->get_disk_temp('/dev/sdz')}, undef, 'get_disk_temp() returns failure when passed invalid device' );

like( $smart->get_disk_health($disk), qr/PASSED|FAILED|N\/A/, 'get_disk_health() returns health status or N/A' );
is( eval{$smart->get_disk_health('/dev/sdz')}, undef, 'get_disk_health() returns failure when passed invalid device' );

cmp_ok( length $smart->get_disk_model($disk), '>=', 3, 'get_disk_model() returns disk model or N/A' );
is( eval{$smart->get_disk_errors('/dev/sdz')}, undef, 'get_disk_model() returns failure when passed invalid device' );

like( $smart->get_disk_errors($disk), qr/\w+/, 'get_disk_errors() returns proper string' );
is( eval{$smart->get_disk_errors('/dev/sdz')}, undef, 'get_disk_errors() returns failure when passed invalid device' );

cmp_ok( scalar( keys $smart->get_disk_attributes($disk) ), '>', 1, 'get_disk_attributes() returns hash of device attributes' );
is( eval{$smart->get_disk_attributes('/dev/sdz')}, undef, 'get_disk_attributes() returns failure when passed invalid device' );

is( $smart->update_data($disk), 1, 'update_data() updated object with current device data' );
is( eval{$smart->update_data('/dev/sdz')}, undef, 'update_data() returns falure when passed invalid device' );

