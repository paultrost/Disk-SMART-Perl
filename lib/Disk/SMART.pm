package Disk::SMART;

use warnings;
use strict;
use Carp;
use Math::Round;

=head1 NAME

Disk::SMART - Provides an interface to smartctl

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Disk::SMART is an object ooriented module that provides an interface to get SMART disk info from a device as well as initiate testing.

    use Disk::SMART;

    my $smart = Disk::SMART->new('/dev/sda');


=cut

=head1 METHODS

=head2 B<new (DEVICE)>

Instantiates the Disk::SMART object

C<DEVICE> - Device identifier of SSD / Hard Drive

    my $smart = Disk::SMART->new( 'dev/sda', '/dev/sdb' );

=cut

sub new {
    my ( $class, @devices ) = @_;
    confess "Valid device identifier not supplied to constructor.\n" if ( !@devices );

    my $smartctl = '/usr/sbin/smartctl';
    if ( !-f $smartctl ) {
        confess "smartctl binary was not found on your system, are you running as root?\n";
    }

    my $self = bless {}, $class;

    foreach my $device (@devices) {
        $self->{'devices'}->{$device}->{'SMART_OUTPUT'} = qx($smartctl -a $device);
    }

    return $self;
}

=head1 Getting information from smartctl

=cut

=head2 B<get_disk_temp (DEVICE)>

Returns an array with the temperature of the device in Celsius and Farenheit, or N/A.

C<DEVICE> - Device identifier of SSD / Hard Drive

    my ($temp_c, $temp_f) = $smart->get_disk_temp('/dev/sda');

=cut

sub get_disk_temp {
    my ( $self, $device ) = @_;
    my $smart_output = $self->{'devices'}->{$device}->{'SMART_OUTPUT'};
    my ($temp_c) = $smart_output =~ /(Temperature_Celsius.*\n)/;

    if ( defined $temp_c ) {
        chomp $temp_c;
        $temp_c =~ s/ //g;
        $temp_c =~ s/.*-//;
        $temp_c =~ s/\(.*\)//;
    }

    if ( !$temp_c || $smart_output =~ qr/S.M.A.R.T. not available/x ) {
        return 'N/A';
    }
    else {
        my $temp_f = round( ( $temp_c * 9 ) / 5 + 32 );
        return ( $temp_c, $temp_f );
    }
    return undef;
}

=head2 B<get_disk_health (DEVICE)>

Returns the health of the disk. Output is "PASSED", "FAILED", or "N/A".

C<DEVICE> - Device identifier of SSD / Hard Drive

    my $disk_health = $smart->get_disk_health('/dev/sda');

=cut

sub get_disk_health {
    my ( $self, $device ) = @_;
    my $smart_output = $self->{'devices'}->{$device}->{'SMART_OUTPUT'};
    my ($health) = $smart_output =~ /(SMART overall-health self-assessment.*\n)/;

    if ( defined $health and $health =~ /PASSED|FAILED/x ) {
        $health =~ s/.*: //;
        chomp $health;
        return $health;
    }
    else {
        return 'N/A';
    }
}

=head2 B<get_disk_model (DEVICE)>

Returns the model of the device. Output is "<device>: <model>" or "N/A". eg. "/dev/sda: ST3250410AS"

C<DEVICE> - Device identifier of SSD / Hard Drive

    my $disk_model = $smart->get_disk_model('/dev/sda');

=cut

sub get_disk_model {
    my ( $self, $device ) = @_;
    my $smart_output = $self->{'devices'}->{$device}->{'SMART_OUTPUT'};
    my ($model) = $smart_output =~ /(Device\ Model.*\n)/;

    if ( defined $model ) {
        $model =~ s/.*:\ //;
        $model =~ s/^\s+|\s+$//g;    #trim beginning and ending whitepace
    }
    return ($model) ? "$device: $model" : "$device: N/A";
}

1;

__END__

=head1 AUTHOR

 Paul Trost <paul.trost@trostfamily.org>

=head1 LICENSE AND COPYRIGHT

 Copyright 2014.
 This script is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License v2, or at your option any later version.
 <http://gnu.org/licenses/gpl.html>

=cut
