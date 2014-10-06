package Disk::SMART;
{
    $Disk::SMART::VERSION = '0.03.1'
}

=head1 NAME

Disk::SMART - Provides an interface to smartctl

=head1 SYNOPSIS

Disk::SMART is an object ooriented module that provides an interface to get SMART disk info from a device as well as initiate testing.

    use Disk::SMART;

    my $smart = Disk::SMART->new('/dev/sda');


=cut

use warnings;
use strict;
use Carp;
use Math::Round;


=head1 CONSTRUCTOR

=head2 B<new (DEVICE)>

Instantiates the Disk::SMART object

C<DEVICE> - Device identifier of SSD / Hard Drive

    my $smart = Disk::SMART->new( 'dev/sda', '/dev/sdb' );

Returns C<Disk::SMART> object if smartctl is available and can poll the given device.

=cut

sub new {
    my ( $class, @devices ) = @_;
    my $smartctl = '/usr/sbin/smartctl';
    my $self = bless {}, $class;

    croak "Valid device identifier not supplied to constructor for $class.\n" if ( !@devices );
    croak "smartctl binary was not found on your system, are you running as root?\n" if !-f $smartctl;

    foreach my $device (@devices) {
        my $out = qx($smartctl -a $device);
        if ( $out =~ /No such device/i ) {
            croak "Smartctl couldn't poll device $device\n";
        }
        $self->{'devices'}->{$device}->{'SMART_OUTPUT'} = $out;
    }

    return $self;
}

=head1 USER METHODS

=head2 B<get_disk_temp (DEVICE)>

Returns an array with the temperature of the device in Celsius and Farenheit, or N/A.

C<DEVICE> - Device identifier of SSD / Hard Drive

    my ($temp_c, $temp_f) = $smart->get_disk_temp('/dev/sda');

=cut

sub get_disk_temp {
    my ( $self, $device ) = @_;
    $self->_validate_param($device);
    my $smart_output = $self->{'devices'}->{$device}->{'SMART_OUTPUT'};
    my ($temp_c) = $smart_output =~ /(Temperature_Celsius.*\n)/;

    if ( !defined $temp_c || $smart_output =~ qr/S.M.A.R.T. not available/x ) {
        return 'N/A';
    }

    chomp $temp_c;
    $temp_c =~ s/ //g;
    $temp_c =~ s/.*-//;
    $temp_c =~ s/\(.*\)//;

    my $temp_f = round( ( $temp_c * 9 ) / 5 + 32 );
    return ( $temp_c, $temp_f );
   
}

=head2 B<get_disk_health (DEVICE)>

Returns the health of the disk. Output is "PASSED", "FAILED", or "N/A".

C<DEVICE> - Device identifier of SSD / Hard Drive

    my $disk_health = $smart->get_disk_health('/dev/sda');

=cut

sub get_disk_health {
    my ( $self, $device ) = @_;
    $self->_validate_param($device);
    my $smart_output = $self->{'devices'}->{$device}->{'SMART_OUTPUT'};
    my ($health) = $smart_output =~ /(SMART overall-health self-assessment.*\n)/;

    if ( (!defined $health) or $health !~ /PASSED|FAILED/x ) {
        return 'N/A';
    }

    $health =~ s/.*: //;
    chomp $health;
    return $health;
}

=head2 B<get_disk_model (DEVICE)>

Returns the model of the device. eg. "ST3250410AS".

C<DEVICE> - Device identifier of SSD / Hard Drive

    my $disk_model = $smart->get_disk_model('/dev/sda');

=cut

sub get_disk_model {
    my ( $self, $device ) = @_;
    $self->_validate_param($device);
    my $smart_output = $self->{'devices'}->{$device}->{'SMART_OUTPUT'};
    my ($model) = $smart_output =~ /(Device\ Model.*\n)/;

    if ( !defined $model ) {
        return 'N/A';
    }
    
    $model =~ s/.*:\ //;
    $model =~ s/^\s+|\s+$//g;    #trim beginning and ending whitepace
    return $model;
}

=head2 B<get_disk_errors (DEVICE)>

Returns any listed errors

C<DEVICE> - DEvice identifier of SSD/ Hard Drive

    my $disk_errors = $smart->get_disk_errors('/dev/sda');

=cut

sub get_disk_errors {
    my ( $self, $device ) = @_;
    $self->_validate_param($device);

    my $smart_output = $self->{'devices'}->{$device}->{'SMART_OUTPUT'};
    my ($errors) = $smart_output =~ /SMART Error Log Version: [1-9](.*)SMART Self-test log/s;

    if ( !defined $errors ) {
        return 'N/A';
    }

    $errors =~ s/^\s+|\s+$//g;    #trim beginning and ending whitepace
    return $errors;
}

sub _validate_param {
    my ( $self, $device ) = @_;
    croak "$device not found in object, You probably didn't enter it right" if ( !exists $self->{'devices'}->{$device} );
}


1;

__END__

=head1 AUTHOR

 Paul Trost <ptrost@cpan.org>

=head1 LICENSE AND COPYRIGHT

 Copyright 2014 by Paul Trost
 This script is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License v2, or at your option any later version.
 <http://gnu.org/licenses/gpl.html>

=cut
