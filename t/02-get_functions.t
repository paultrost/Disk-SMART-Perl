use warnings;
use strict;
use Test::More 'tests' => 3;
use Disk::SMART;

my $disk = '/dev/sda';
my $smart = Disk::SMART->new($disk);

ok( $smart->get_disk_temp($disk), 'get_disk_temp() returns drive temperature or N/A');
like( $smart->get_disk_health('/dev/sda'), qr/PASSED|FAILED|N\/A/, 'get_disk_health() returns health status or N/A');
like( $smart->get_disk_model('/dev/sda'), qr/(\w+: \w+)|N\/A/, 'get_disk_model() returned disk model or N/A');
