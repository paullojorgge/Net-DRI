## Domain Registry Interface, .EE policies from 'https://github.com/internetee/registry/blob/master/doc/epp/README.md'
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

package Net::DRI::Protocol::EPP::Extensions::InternetEE;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP/;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::EE - .EE EPP extensions 'https://github.com/internetee/registry/blob/master/doc/epp/README.md' for Net::DRI

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

sub setup
{
  my ($self,$rp)=@_;
  $self->ns({
      ee_all        => ['https://epp.tld.ee/schema/all-ee-1.0','all-ee-1.0.xsd'],
      ee_eis        => ['https://epp.tld.ee/schema/eis-1.0.xsd','eis-1.0.xsd'],
      ee_epp        => ['https://epp.tld.ee/schema/epp-ee-1.0.xsd','epp-ee-1.0.xsd'],
      domain_eis    => ['https://epp.tld.ee/schema/domain-eis-1.0.xsd','domain-eis-1.0.xsd'],
      contact_eis   => ['https://epp.tld.ee/schema/contact-eis-1.0.xsd','contact-eis-1.0.xsd'],
      contact_ee    => ['https://epp.tld.ee/schema/contact-ee-1.1.xsd','contact-ee-1.1.xsd'],
    });

  return;
}

sub default_extensions { return qw/SecDNS CL::Message/; } # FIXME!!!!

####################################################################################################
1;
