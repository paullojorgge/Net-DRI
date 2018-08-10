## Domain Registry Interface, InternetEE - .EE Contact EPP extension commands
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

package Net::DRI::Protocol::EPP::Extensions::InternetEE::Contact;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception qw/(all)/;
use Net::DRI::Protocol::EPP::Util;

use Data::Dumper;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::InternetEE::Contact - .EE EPP Contact extension commands for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Paulo Jorge, E<lt>paullojorgge@gmail.comE<gt>

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

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=(
          check             => [ undef, undef ],
        #   create            => [ \&create, undef ],
          delete            => [ \&delete, undef ],
        #   update            => [ \&update, undef ],
         );
 $tmp{check_multi}=$tmp{check};

 return { 'contact' => \%tmp };
}

####################################################################################################

sub delete
{
  my ($epp,$contact,$rd)=@_;
  return unless ( $rd->{'legal_document'} || $rd->{'ident'} );

  my $mes=$epp->message();
  Net::DRI::Protocol::EPP::Extensions::InternetEE::Domain::eis_extdata_build_command($epp,$contact,$rd,$mes);

  return;
}

####################################################################################################
1;