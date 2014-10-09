package Disk::SMART;

use warnings;
use strict;
use Carp;
use Math::Round;

{
    $Disk::SMART::VERSION = '0.05'
}

our $smartctl = '/usr/sbin/smartctl';

=head1 NAME

Disk::SMART - Provides an interface to smartctl

=head1 SYNOPSIS

Disk::SMART is an object ooriented module that provides an interface to get SMART disk info from a device as well as initiate testing.

    use Disk::SMART;

    my $smart = Disk::SMART->new('/dev/sda');

=cut


=head1 CONSTRUCTOR

=head2 B<new(DEVICE)>

Instantiates the Disk::SMART object

C<DEVICE> - Device identifier of SSD / Hard Drive

    my $smart = Disk::SMART->new( 'dev/sda', '/dev/sdb' );

Returns C<Disk::SMART> object if smartctl is available and can poll the given device.

=cut

sub new {
    my ( $class, @devices ) = @_;
    my $self = bless {}, $class;

    croak "Valid device identifier not supplied to constructor for $class.\n" if ( !@devices );
    croak "smartctl binary was not found on your system, are you running as root?\n" if !-f $smartctl;

    foreach my $device (@devices) {
        $self->update_data($device);
    }
    return $self;
}


=head1 USER METHODS


=head2 B<get_disk_attributes(DEVICE)>

Returns hash of the SMART disk attributes and values

C<DEVICE> - Device identifier of SSD/ Hard Drive

    my %disk_attributes = $smart->get_disk_attributes('/dev/sda');

=cut

sub get_disk_attributes {
    my ( $self, $device ) = @_;
    return $self->{'devices'}->{$device}->{'attributes'};
}


=head2 B<get_disk_errors(DEVICE)>

Returns scalar of any listed errors

C<DEVICE> - Device identifier of SSD/ Hard Drive

    my $disk_errors = $smart->get_disk_errors('/dev/sda');

=cut

sub get_disk_errors {
    my ( $self, $device ) = @_;
    return $self->{'devices'}->{$device}->{'errors'};
}


=head2 B<get_disk_health(DEVICE)>

Returns the health of the disk. Output is "PASSED", "FAILED", or "N/A".

C<DEVICE> - Device identifier of SSD / Hard Drive

    my $disk_health = $smart->get_disk_health('/dev/sda');

=cut

sub get_disk_health {
    my ( $self, $device ) = @_;
    return $self->{'devices'}->{$device}->{'health'};
}


=head2 B<get_disk_model(DEVICE)>

Returns the model of the device. eg. "ST3250410AS".

C<DEVICE> - Device identifier of SSD / Hard Drive

    my $disk_model = $smart->get_disk_model('/dev/sda');

=cut

sub get_disk_model {
    my ( $self, $device ) = @_;
    return $self->{'devices'}->{$device}->{'model'};
}


=head2 B<get_disk_temp(DEVICE)>

Returns an array with the temperature of the device in Celsius and Farenheit, or N/A.

C<DEVICE> - Device identifier of SSD / Hard Drive

    my ($temp_c, $temp_f) = $smart->get_disk_temp('/dev/sda');

=cut

sub get_disk_temp {
    my ( $self, $device ) = @_;
    return @{ $self->{'devices'}->{$device}->{'temp'} };
}


=head2 B<update_data>

Updates the SMART output and attributes of a device. Returns undef.

C<DEVICE> - Device identifier of SSD/ Hard Drive

    $smart->update_data('/dev/sda');

=cut

sub update_data {
    my ( $self, $device ) = @_;

    chomp( my $out = qx($smartctl -a $device) );
    croak "Smartctl couldn't poll device $device\n" if $out =~ /No such device/;
    $self->{'devices'}->{$device}->{'SMART_OUTPUT'} = $out;
    
    # update_data() can be called at any time with a device name. Let's check
    # the device name given to make sure it matches what was given during
    # object construction.
    croak "$device not found in object, You probably didn't enter it right" if ( !exists $self->{'devices'}->{$device} );

    $self->_process_disk_attributes($device);
    $self->_process_disk_errors($device);
    $self->_process_disk_health($device);
    $self->_process_disk_model($device);
    $self->_process_disk_temp($device);

    return 1;
}

sub _process_disk_attributes {
    my ( $self, $device ) = @_;

    my $smart_output = $self->{'devices'}->{$device}->{'SMART_OUTPUT'};
    my ($smart_attributes) = $smart_output =~ /(ID# ATTRIBUTE_NAME.*)\nSMART Error/s;
    my @attributes = split /\n/, $smart_attributes;
    shift @attributes;

    foreach my $attribute (@attributes) {
        my $name  = substr $attribute, 4,  +24;
        my $value = substr $attribute, 83, +50;
        $name  =~ s/\s+$//g;    # trim ending whitespace
        $value =~ s/^\s+//g;    # trim beginning and ending whitepace
        $self->{'devices'}->{$device}->{'attributes'}->{$name} = $value;
    }
    return;
}

sub _process_disk_errors {
    my ( $self, $device ) = @_;
    $self->_validate_param($device);

    my $smart_output = $self->{'devices'}->{$device}->{'SMART_OUTPUT'};
    my ($errors) = $smart_output =~ /SMART Error Log Version: [1-9](.*)SMART Self-test log/s;

    if ( !defined $errors ) {
        $self->{'devices'}->{$device}->{'errors'} = 'N/A';
        return;
    }

    $errors =~ s/^\s+|\s+$//g;    #trim beginning and ending whitepace
    $self->{'devices'}->{$device}->{'errors'} = $errors;
    return;
}

sub _process_disk_health {
    my ( $self, $device ) = @_;
    $self->_validate_param($device);
    my $smart_output = $self->{'devices'}->{$device}->{'SMART_OUTPUT'};
    my ($health) = $smart_output =~ /(SMART overall-health self-assessment.*\n)/;

    if ( (!defined $health) or $health !~ /PASSED|FAILED/x ) {
        $self->{'devices'}->{$device}->{'health'} = 'N/A';
        return;
    }

    $health =~ s/.*: //;
    chomp $health;
    $self->{'devices'}->{$device}->{'health'} = $health;
    return;
}

sub _process_disk_model {
    my ( $self, $device ) = @_;
    $self->_validate_param($device);
    my $smart_output = $self->{'devices'}->{$device}->{'SMART_OUTPUT'};
    my ($model) = $smart_output =~ /(Device\ Model.*\n)/;

    if ( !defined $model ) {
        $self->{'devices'}->{$device}->{'model'} = 'N/A';
        return;
    }

    $model =~ s/.*:\ //;
    $model =~ s/^\s+|\s+$//g;    #trim beginning and ending whitepace
    $self->{'devices'}->{$device}->{'model'} = $model;
    return;
}

sub _process_disk_temp {
    my ( $self, $device ) = @_;
    $self->_validate_param($device);
    my $smart_output = $self->{'devices'}->{$device}->{'SMART_OUTPUT'};
    my ($temp_c) = $smart_output =~ /(Temperature_Celsius.*\n)/;

    if ( !defined $temp_c || $smart_output =~ qr/S.M.A.R.T. not available/x ) {
        $self->{'devices'}->{$device}->{'temp'} = 'N/A';
        return;
    }

    chomp($temp_c);
    $temp_c = substr $temp_c, 83, +3;
    $temp_c =~ s/ //g;

    my $temp_f = round( ( $temp_c * 9 ) / 5 + 32 );
    $self->{'devices'}->{$device}->{'temp'} = [ ( int $temp_c, int $temp_f ) ];
    return;
}

sub _validate_param {
    my ( $self, $device ) = @_;
    croak "$device not found in object, You probably didn't enter it right" if ( !exists $self->{'devices'}->{$device} );
    return;
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
