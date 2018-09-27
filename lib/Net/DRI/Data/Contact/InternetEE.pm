## Domain Registry Interface, Handling of contact data for InternetEE (.EE)
##
## Copyright (c) 2018 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2018 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
##           (c) 2018 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
##
## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
####################################################################################################

package Net::DRI::Data::Contact::InternetEE;

use strict;
use warnings;

use base qw/Net::DRI::Data::Contact/;
use Net::DRI::Exception;
use Net::DRI::Util;

__PACKAGE__->register_attributes(qw(ident ident_type_attr ident_cc_attr legal_document legal_document_attr));

=pod

=head1 NAME

Net::DRI::Data::Contact::InternetEE - Handle InternetEE (.EE) contact data for Net::DRI

=head1 DESCRIPTION

This subclass of Net::DRI::Data::Contact adds accessors and validation for
.EE specific data.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/

=head1 AUTHOR

Paulo Jorge E<lt>paullojorgge@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2018: Paulo Jorge <paullojorgge@gmail.com>;
Michael Holloway <michael@thedarkwinter.com>;
Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub validate
{
 my ($self,$change)=@_;
 $change||=0;
 my @errs;

 $self->SUPER::validate($change); ## will trigger an Exception if problem

 if (!$change)
 {
  Net::DRI::Exception::usererr_insufficient_parameters('ident (contact identifier) is mandatory') unless ($self->ident() && $self->ident_type_attr() && $self->ident_cc_attr());
 }

 push @errs, 'org' if ($self->org()); # org is not supported
 push @errs, 'fax' if ($self->fax()); # fax is not supported

 Net::DRI::Exception::usererr_invalid_parameters('Invalid contact information: '.join('/',@errs)) if @errs;

 return 1; ## everything ok.
}

sub init
{
 my ($self,$what,$ndr)=@_;
 my $a=$self->auth();
 $self->auth({pw=>''}) unless ($a && (ref($a) eq 'HASH') && exists($a->{pw})); ## Mandatory but can be empty for create and info commands
 return;
}

####################################################################################################
1;
