## Domain Registry Interface, DNSPT (.PT) Registry Driver for Net::DRI
##
## Copyright (c) 2008-2011,2013,2016 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##
## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
#########################################################################################

package Net::DRI::DRD::DNSPT;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use DateTime::Duration;
use Net::DRI::Util;
use Net::DRI::Data::Contact::FCCN;

__PACKAGE__->make_exception_for_unavailable_operations(qw/contact_delete contact_update contact_transfer contact_transfer_start contact_transfer_stop contact_transfer_query contact_transfer_accept contact_transfer_refuse domain_delete message_retrieve message_delete message_waiting message_count/);

=pod

=head1 NAME

Net::DRI::DRD::DNSPT - DNSPT (.PT) Registry driver for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2008-2011,2013,2016 Patrick Mevzek <netdri@dotandco.com>.
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
 $self->{info}->{host_as_attr}=1;
 $self->{info}->{contact_i18n}=2; ## INT only ## FCCN only accept type "int" with UTF-8
 $self->{info}->{force_native_idn}=0; ## will cause problems if enabled
 return $self;
}

sub periods      { return map { DateTime::Duration->new(years => $_) } (1,3,5); }
sub name         { return 'DNSPT'; }
sub tlds         { return qw/pt net.pt org.pt edu.pt int.pt publ.pt com.pt nome.pt/; }
sub object_types { return ('domain','contact'); }
sub profile_types { return qw/epp whois/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::FCCN',{})            if $type eq 'epp';
 return ('Net::DRI::Transport::Socket',{remote_host=>'whois.nic.pt'},'Net::DRI::Protocol::Whois',{}) if $type eq 'whois';
 return;
}

sub set_factories
{
 my ($self,$po)=@_;
 $po->factories('contact',sub { return Net::DRI::Data::Contact::FCCN->new(@_); });
 return;
}

####################################################################################################

sub domain_renounce
{
 my ($self,$ndr,$domain,$rd)=@_;
 $self->enforce_domain_name_constraints($ndr,$domain,'renounce');

 return $ndr->process('domain','renounce',[$domain,$rd]);
}

####################################################################################################
1;
