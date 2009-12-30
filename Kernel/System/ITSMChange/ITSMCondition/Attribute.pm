# --
# Kernel/System/ITSMChange/ITSMCondition/Attribute.pm - all condition attribute functions
# Copyright (C) 2003-2009 OTRS AG, http://otrs.com/
# --
# $Id: Attribute.pm,v 1.2 2009-12-23 15:59:13 mae Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::ITSMChange::ITSMCondition::Attribute;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.2 $) [1];

=head1 NAME

Kernel::System::ITSMChange::ITSMCondition::Attribute - condition attribute lib

=head1 SYNOPSIS

All functions for condition attributes in ITSMChangeManagement.

=head1 PUBLIC INTERFACE

=over 4

=item AttributeAdd()

Add a new attribute.

    my $ConditionID = $ConditionObject->AttributeAdd(
        UserID => 1,
        Name   => 'AttributeObject',
    );

=cut

sub AttributeAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(UserID Name)) {
        if ( !$Param{$Argument} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # make lookup with given name for checks
    my $CheckAttributeID = $Self->AttributeLookup(
        UserID => $Param{UserID},
        Name   => $Param{Name},
    );

    # check if attribute name is already given
    if ($CheckAttributeID) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => "Condition attribute ($Param{Name}) already exists!",
        );
        return;
    }

    # add new attribute name to database
    return if !$Self->{DBObject}->Do(
        SQL => 'INSERT INTO condition_attribute '
            . '(name) '
            . 'VALUES (?)',
        Bind => [ \$Param{Name} ],
    );

    # get id of created attribute
    my $AttributeID = $Self->AttributeLookup(
        UserID => $Param{UserID},
        Name   => $Param{Name},
    );

    # check if attribute could be added
    if ( !$AttributeID ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => "AttributeAdd() failed!",
        );
        return;
    }

    return $AttributeID;
}

=item AttributeUpdate()

Update a condition attribute.

    my $Success = $ConditionObject->AttributeUpdate(
        UserID      => 1,
        AttributeID => 1234,
        Name        => 'NewConditionAttribute',
    );

=cut

sub AttributeUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(AttributeID UserID Name)) {
        if ( !$Param{$Argument} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # get attribute data
    my $AttributeData = $Self->AttributeGet(
        UserID      => $Param{UserID},
        AttributeID => $Param{AttributeID},
    );

    # check attribute data
    if ( !$AttributeData ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => "AttributeUpdate of $Param{AttributeID} failed!",
        );
        return;
    }

    # update attribute in database
    return if !$Self->{DBObject}->Do(
        SQL => 'UPDATE condition_attribute '
            . 'SET name = ? '
            . 'WHERE id = ?',
        Bind => [
            \$Param{Name},
            \$Param{AttributeID},
        ],
    );

    return 1;
}

=item AttributeGet()

Get a condition attribute for a given attribute id.
Returns an hash reference of the attribute data.

    my $ConditionAttributetRef = $ConditionObject->AttributeGet(
        UserID    => 1,
        Attribute => 1234,
    );

The returned hash reference contains following elements:

    $ConditionAttribute{Name}

=cut

sub AttributeGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Attribute (qw(AttributeID UserID)) {
        if ( !$Param{$Attribute} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Attribute!",
            );
            return;
        }
    }

    # prepare SQL statement
    return if !$Self->{DBObject}->Prepare(
        SQL   => 'SELECT name FROM condition_attribute WHERE id = ?',
        Bind  => [ \$Param{AttributeID} ],
        Limit => 1,
    );

    # fetch the result
    my %AttributeData;
    while ( my @Row = $Self->{DBObject}->FetchrowArray() ) {
        $AttributeData{Name} = $Row[0];
    }

    # check error
    if ( !%AttributeData ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => "AttributeID $Param{AttributeID} does not exist!",
        );
        return;
    }

    return \%AttributeData;
}

=item AttributeLookup()

This method does a lookup for a condition attribute. If a attribute
id is given, it returns the name of the attribute. If the attributes
name is given, the appropriate id is returned.

    my $AttributeName = $ConditionObject->AttributeLookup(
        UserID      => 1234,
        AttributeID => 4321
    );

    my $AttributeID = $ConditionObject->AttributeLookup(
        UserID     => 1234,
        Name => 'AttributeObject',
    );

=cut

sub AttributeLookup {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Attribute (qw(UserID)) {
        if ( !$Param{$Attribute} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Attribute!",
            );
            return;
        }
    }

    # check if both parameters are given
    if ( $Param{AttributeID} && $Param{Name} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'Need AttributeID or Name - not both!',
        );
        return;
    }

    # check if both parameters are not given
    if ( !$Param{AttributeID} && !$Param{Name} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'Need AttributeID or Name - none is given!',
        );
        return;
    }

    # prepare SQL statements
    if ( $Param{AttributeID} ) {
        return if !$Self->{DBObject}->Prepare(
            SQL   => 'SELECT name FROM condition_attribute WHERE id = ?',
            Bind  => [ \$Param{AttributeID} ],
            Limit => 1,
        );
    }
    elsif ( $Param{Name} ) {
        return if !$Self->{DBObject}->Prepare(
            SQL   => 'SELECT id FROM condition_attribute WHERE name = ?',
            Bind  => [ \$Param{Name} ],
            Limit => 1,
        );
    }

    # fetch the result
    my $AttributeLookup;
    while ( my @Row = $Self->{DBObject}->FetchrowArray() ) {
        $AttributeLookup = $Row[0];
    }

    return $AttributeLookup;
}

=item AttributeList()

return a list of all condition attribute ids as array reference

    my $ConditionAttributeIDsRef = $ConditionObject->AttributeList(
        UserID   => 1,
    );

=cut

sub AttributeList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Attribute (qw(UserID)) {
        if ( !$Param{$Attribute} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Attribute!",
            );
            return;
        }
    }

    # prepare SQL statement
    return if !$Self->{DBObject}->Prepare(
        SQL  => 'SELECT name FROM condition_attribute',
        Bind => [],
    );

    # fetch the result
    my @AttributeList;
    while ( my @Row = $Self->{DBObject}->FetchrowArray() ) {
        push @AttributeList, $Row[0];
    }

    # check error
    if ( !@AttributeList ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => "Attribute list could not be gathered!",
        );
        return;
    }

    return \@AttributeList;
}

=item AttributeDelete()

Delete a condition attribute.

    my $Success = $ConditionObject->AttributeDelete(
        AttributeID => 123,
        UserID      => 1,
    );

=cut

sub AttributeDelete {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Attribute (qw(AttributeID UserID)) {
        if ( !$Param{$Attribute} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Attribute!",
            );
            return;
        }
    }

    # delete condition attribute from database
    return if !$Self->{DBObject}->Do(
        SQL => 'DELETE FROM condition_attribute '
            . 'WHERE id = ?',
        Bind => [ \$Param{ObjectID} ],
    );

    return 1;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (http://otrs.org/).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see http://www.gnu.org/licenses/agpl.txt.

=cut

=head1 VERSION

$Revision: 1.2 $ $Date: 2009-12-23 15:59:13 $

=cut