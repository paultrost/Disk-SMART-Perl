use warnings;
use strict;
use Test::More 'tests' => 15;
use Test::Fatal;
use Disk::SMART;


$ENV{'MOCK_TEST_DATA'} =
'smartctl 5.41 2011-06-09 r3365 [x86_64-linux-2.6.32-32-pve] (local build)
Copyright (C) 2002-11 by Bruce Allen, http://smartmontools.sourceforge.net

=== START OF INFORMATION SECTION ===
Model Family:     Seagate Barracuda 7200.10
Device Model:     ST3250410AS
Serial Number:    6RYBDDDQ
Firmware Version: 3.AAF
User Capacity:    250,059,350,016 bytes [250 GB]
Sector Size:      512 bytes logical/physical
Device is:        In smartctl database [for details use: -P show]
ATA Version is:   7
ATA Standard is:  Exact ATA specification draft version not indicated
Local Time is:    Wed Oct 15 17:16:35 2014 CDT
SMART support is: Available - device has SMART capability.
SMART support is: Enabled

=== START OF READ SMART DATA SECTION ===
SMART overall-health self-assessment test result: PASSED

General SMART Values:
Offline data collection status:  (0x82) Offline data collection activity
                    was completed without error.
                    Auto Offline Data Collection: Enabled.
Self-test execution status:      (   0) The previous self-test routine completed
                    without error or no self-test has ever 
                    been run.
Total time to complete Offline 
data collection:        (  430) seconds.
Offline data collection
capabilities:            (0x5b) SMART execute Offline immediate.
                    Auto Offline data collection on/off support.
                    Suspend Offline collection upon new
                    command.
                    Offline surface scan supported.
                    Self-test supported.
                    No Conveyance Self-test supported.
                    Selective Self-test supported.
SMART capabilities:            (0x0003) Saves SMART data before entering
                    power-saving mode.
                    Supports SMART auto save timer.
Error logging capability:        (0x01) Error logging supported.
                    General Purpose Logging supported.
Short self-test routine 
recommended polling time:    (   1) minutes.
Extended self-test routine
recommended polling time:    (  64) minutes.
SCT capabilities:          (0x0001) SCT Status supported.

SMART Attributes Data Structure revision number: 10
Vendor Specific SMART Attributes with Thresholds:
ID# ATTRIBUTE_NAME          FLAG     VALUE WORST THRESH TYPE      UPDATED  WHEN_FAILED RAW_VALUE
  1 Raw_Read_Error_Rate     0x000f   100   253   006    Pre-fail  Always       -       0
  3 Spin_Up_Time            0x0003   098   098   000    Pre-fail  Always       -       0
  4 Start_Stop_Count        0x0032   100   100   020    Old_age   Always       -       19
  5 Reallocated_Sector_Ct   0x0033   100   100   036    Pre-fail  Always       -       0
  7 Seek_Error_Rate         0x000f   070   060   030    Pre-fail  Always       -       10571330
  9 Power_On_Hours          0x0032   099   099   000    Old_age   Always       -       1100
 10 Spin_Retry_Count        0x0013   100   100   097    Pre-fail  Always       -       0
 12 Power_Cycle_Count       0x0032   100   100   020    Old_age   Always       -       19
187 Reported_Uncorrect      0x0032   100   100   000    Old_age   Always       -       0
189 High_Fly_Writes         0x003a   100   100   000    Old_age   Always       -       0
190 Airflow_Temperature_Cel 0x0022   065   050   045    Old_age   Always       -       35 (Min/Max 13/50)
194 Temperature_Celsius     0x0022   035   050   000    Old_age   Always       -       35 (0 13 0 0)
195 Hardware_ECC_Recovered  0x001a   066   060   000    Old_age   Always       -       59046455
197 Current_Pending_Sector  0x0012   100   100   000    Old_age   Always       -       0
198 Offline_Uncorrectable   0x0010   100   100   000    Old_age   Offline      -       0
199 UDMA_CRC_Error_Count    0x003e   200   200   000    Old_age   Always       -       0
200 Multi_Zone_Error_Rate   0x0000   100   253   000    Old_age   Offline      -       0
202 Data_Address_Mark_Errs  0x0032   100   253   000    Old_age   Always       -       0

SMART Error Log Version: 1
No Errors Logged

SMART Self-test log structure revision number 1
Num  Test_Description    Status                  Remaining  LifeTime(hours)  LBA_of_first_error
# 1  Short offline       Completed without error       00%      1100         -
# 2  Short offline       Completed without error       00%      1100         -
# 3  Extended offline    Aborted by host               90%      1100         -
# 4  Short offline       Completed without error       00%      1100         -
# 5  Short offline       Completed without error       00%      1100         -
# 6  Short offline       Completed without error       00%      1099         -

SMART Selective self-test log data structure revision number 1
 SPAN  MIN_LBA  MAX_LBA  CURRENT_TEST_STATUS
    1        0        0  Not_testing
    2        0        0  Not_testing
    3        0        0  Not_testing
    4        0        0  Not_testing
    5        0        0  Not_testing
Selective self-test flags (0x0):
  After scanning selected spans, do NOT read-scan remainder of disk.
If Selective self-test is pending on power-up, resume after 0 minute delay.';

my $disk  = '/dev/test_good';
my $smart = Disk::SMART->new($disk);

#Positive testing
is( $smart->get_disk_temp($disk), 2, 'get_disk_temp() returns device temperature' );
is( $smart->get_disk_health($disk), 'PASSED', 'get_disk_health() returns health status' );
is( $smart->get_disk_model($disk), 'ST3250410AS', 'get_disk_model() returns device model' );
is( $smart->get_disk_errors($disk), 'No Errors Logged', 'get_disk_errors() returns proper string' );
is( scalar( keys $smart->get_disk_attributes($disk) ), 18, 'get_disk_attributes() returns hash of device attributes' );
is( $smart->run_short_test($disk), 'Completed without error', 'run_short_test() returns proper string' );

$ENV{'MOCK_TEST_DATA'} =~ s/ST3250410AS//;
is( $smart->update_data($disk), 1, 'update_data() updated object with changed device data' );
is( $smart->get_disk_model($disk), 'N/A', 'get_disk_model() returns N/A with changed device data' );

#Negative testing
$disk  = '/dev/test_bad';
like( exception { $smart->get_disk_temp($disk); },       qr/$disk not found in object/, 'get_disk_temp() returns failure when passed invalid device' );
like( exception { $smart->get_disk_health($disk); },     qr/$disk not found in object/, 'get_disk_health() returns failure when passed invalid device' );
like( exception { $smart->get_disk_errors($disk); },     qr/$disk not found in object/, 'get_disk_model() returns failure when passed invalid device' );
like( exception { $smart->get_disk_errors($disk); },     qr/$disk not found in object/, 'get_disk_errors() returns failure when passed invalid device' );
like( exception { $smart->get_disk_attributes($disk); }, qr/$disk not found in object/, 'get_disk_attributes() returns failure when passed invalid device' );
like( exception { $smart->run_short_test($disk); },      qr/$disk not found in object/, 'run_short_test() returns failure when passed invalid device' );

$ENV{'MOCK_TEST_DATA'} = undef;
like( exception { $smart->update_data($disk); }, qr/couldn't poll/, 'update_data() returns falure when passed invalid device' );

