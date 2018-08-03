## Domain Registry Interface, InternetEE (.EE)
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

package Net::DRI::DRD::InternetEE;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

__PACKAGE__->make_exception_for_unavailable_operations(qw/contact_transfer contact_transfer_start contact_transfer_stop contact_transfer_query contact_transfer_accept contact_transfer_refuse contact_update_status contact_update_status_add contact_update_status_del contact_update_status_set domain_transfer_stop domain_transfer_query domain_transfer_accept domain_transfer_refuse/);

=pod

=head1 NAME

Net::DRI::DRD::InternetEE - .EE

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

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

sub new
{
 my $class=shift;
 my $self=$class->SUPER::new(@_);
 $self->{info}->{host_as_attr}=2;
 $self->{info}->{contact_i18n}=2; ## INT only
 return $self;
}

sub periods  { return map { DateTime::Duration->new(months => $_) } (1..120); } # they also accept unit="d" but not using here! Examples only use "y/m"
sub name     { return 'InternetEE'; }
sub tlds     { return (qw/ee/, map { $_.'.ee'} qw/com edu fie lib med org pri/ ); } # I got them from here: https://en.wikipedia.org/wiki/.ee
sub object_types { return qw(domain contact); }
sub profile_types { return qw/epp/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;
 return ('Net::DRI::Transport::Socket',{ 'ssl_version'=>'TLSv12', 'ssl_cipher_list' => undef },'Net::DRI::Protocol::EPP::Extensions::InternetEE',{}) if $type eq 'epp';
 return;
}

####################################################################################################
1;
