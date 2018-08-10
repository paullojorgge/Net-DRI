## Domain Registry Interface, InternetEE - .EE Domain EPP extension commands
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

package Net::DRI::Protocol::EPP::Extensions::InternetEE::Domain;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Exception qw/(all)/;
use Net::DRI::Protocol::EPP::Util;
use DateTime::Duration;

use Data::Dumper;

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::InternetEE::Domain - .EE EPP Domain extension commands for Net::DRI

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
          create            => [ \&create, undef ],
          delete            => [ \&delete, undef ],
          update            => [ \&update, undef ],
          transfer_query	=> [ \&transfer_extdata, undef ],
          transfer_request	=> [ \&transfer_extdata, undef ],
          transfer_cancel 	=> [ \&transfer_extdata, undef ],
          transfer_answer 	=> [ \&transfer_extdata, undef ],
         );

 return { 'domain' => \%tmp };
}

####################################################################################################

sub create
{
  my ($epp,$domain,$rd)=@_;
  my $mes=$epp->message();
  # TODO: need to double check if <eis:exdata> is really mandatory!
  # TODO:looking at the documentation it's: https://github.com/internetee/registry/blob/master/doc/epp/domain.md
  Net::DRI::Exception::usererr_insufficient_parameters('legal_document mandatory to create domain!') unless $rd->{'legal_document'};
  eis_extdata_build_command($epp,$domain,$rd,$mes);

  return;
}


sub delete
{
  my ($epp,$domain,$rd)=@_;
  my $mes=$epp->message();
  # TODO: need to double check if <eis:exdata> is really mandatory!
  # TODO:looking at the documentation it's: https://github.com/internetee/registry/blob/master/doc/epp/domain.md
  Net::DRI::Exception::usererr_insufficient_parameters('legal_document mandatory to delete domain!') unless $rd->{'legal_document'};
  eis_extdata_build_command($epp,$domain,$rd,$mes);

  return;
}


sub update
{
  my ($epp,$domain,$rd,$eis_extdata)=@_;
  my $mes=$epp->message();
  return unless $eis_extdata->{'legal_document'};
  Net::DRI::Exception::usererr_insufficient_parameters('legal_document mandatory to update domain!') unless $eis_extdata->{'legal_document'};
  eis_extdata_build_command($epp,$domain,$eis_extdata,$mes);

  return;
}

sub transfer_extdata
{
  my ($epp,$domain,$rd)=@_;
  my $mes=$epp->message();
  eis_extdata_build_command($epp,$domain,$rd,$mes) if $rd->{'legal_document'};

  return;
}


### EIS - Ident with type and country code
# this is only used on contact objects but implemented here (Domain.pm) with other <eis:extdata> variations.
# maybe I should create a different module? EIS.pm or something similar?
sub _ident
{
  my ($rd,$mes)=@_;
  my @eis_extdata_ident;

  Net::DRI::Exception::usererr_insufficient_parameters('ident') unless $rd->{'ident'};
  Net::DRI::Exception::usererr_insufficient_parameters('ident_type_attr') unless $rd->{'ident_type_attr'}; # use required!
  # ident_cc_attr: their xml schema doesn't define as mandatory but lets do it - all their examples have this attribute :)
  Net::DRI::Exception::usererr_insufficient_parameters('ident_cc_attr') unless $rd->{'ident_cc_attr'};
  my @ident_enum_type = (qw/org priv birthday/);
  Net::DRI::Exception::usererr_invalid_parameters('ident_type_attr type is not valid!') unless ( grep $_ eq $rd->{'ident_type_attr'}, @ident_enum_type );
  Net::DRI::Exception::usererr_invalid_parameters('ident_cc_attr can only have 2 chars!') unless Net::DRI::Util::xml_is_token($rd->{'ident_cc_attr'},2,2);
  push @eis_extdata_ident, [ 'eis:ident', { type => ($rd->{'ident_type_attr'}, cc => $rd->{'ident_cc_attr'}) }, $rd->{'ident'} ];

  return @eis_extdata_ident;
}


### EIS - Legal document, encoded in base64 and only accept the following doc types: pdf asice asics sce scs adoc bdoc edoc ddoc zip rar gz tar 7z odt doc docx
sub _legal_document
{
  my ($rd,$mes)=@_;
  require MIME::Base64;
  my @eis_extdata_legal_document;

  Net::DRI::Exception::usererr_insufficient_parameters('legal_document') unless $rd->{'legal_document'};
  Net::DRI::Exception::usererr_insufficient_parameters('legal_document_attr') unless $rd->{'legal_document_attr'};
  Net::DRI::Exception::usererr_invalid_parameters('legal_document is not base64!') unless Net::DRI::Util::verify_base64($rd->{'legal_document'});
  my @legal_doc_type = (qw/pdf asice asics sce scs adoc bdoc edoc ddoc zip rar gz tar 7z odt doc docx/);
  Net::DRI::Exception::usererr_invalid_parameters('legal_document_attr type is not valid!') unless ( grep $_ eq $rd->{'legal_document_attr'}, @legal_doc_type );
  push @eis_extdata_legal_document, [ 'eis:legalDocument', { type => ($rd->{'legal_document_attr'}) }, $rd->{'legal_document'} ];

  return @eis_extdata_legal_document;
}


### EIS - Reserved for providing passwords for reserved domains
sub _reserved
{
  my ($rd,$mes)=@_;
  my @eis_extdata_reserved;
  push @eis_extdata_reserved, [ 'eis:reserved', [ 'eis:pw', $rd->{'reserved'} ] ];

  return @eis_extdata_reserved;
}


### build <eis:extdata>
sub eis_extdata_build_command
{
  my ($epp,$domain,$rd,$mes) = @_;
  my $eid=$mes->command_extension_register('eis:extdata',sprintf('xmlns:eis="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('ee_eis')));
  my @eis_extdata;

  push @eis_extdata, _ident($rd,$mes) if ( $rd->{'ident'} );
  push @eis_extdata, _legal_document($rd,$mes) if ( $rd->{'legal_document'} || $rd->{'legal_document_attr'} );
  push @eis_extdata, _reserved($rd,$mes) if ( $rd->{'reserved'} );

  $mes->command_extension($eid,\@eis_extdata);

  return $mes;
}

####################################################################################################
1;
