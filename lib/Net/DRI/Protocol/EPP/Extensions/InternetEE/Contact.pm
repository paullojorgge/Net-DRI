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
          create            => [ \&create, undef ],
          delete            => [ \&delete, undef ],
          update            => [ \&update, undef ],
          info              => [ undef, \&info_parse ]
         );
 $tmp{check_multi}=$tmp{check};

 return { 'contact' => \%tmp };
}

####################################################################################################

sub create
{
  my ($epp,$contact)=@_;
  # return unless ( $contact->{'legal_document'} || $contact->{'ident'} ); # FIXME: do we need legal_document???? Specs say it's optional. Need to confirm
  return unless ( $contact->{'ident'} );

  my $mes=$epp->message();
  Net::DRI::Protocol::EPP::Extensions::InternetEE::Domain::eis_extdata_build_command($epp,$contact,$contact,$mes);

  return;
}

sub delete
{
  my ($epp,$contact)=@_;
  # return unless ( $contact->{'legal_document'} || $contact->{'ident'} ); # FIXME: do we need legal_document???? Specs say it's optional. Need to confirm
  return unless ( $contact->{'ident'} );

  my $mes=$epp->message();
  Net::DRI::Protocol::EPP::Extensions::InternetEE::Domain::eis_extdata_build_command($epp,$contact,$contact,$mes);

  return;
}

sub update
{
  my ($epp,$contact)=@_;
  return unless ( $contact->{'legal_document'} || $contact->{'ident'} );

  my $mes=$epp->message();
  Net::DRI::Protocol::EPP::Extensions::InternetEE::Domain::eis_extdata_build_command($epp,$contact,$contact,$mes);

  return;
}

# README: do they return for legal_document and reserved? schema doesn't specify and no samples but lets had just in case :)
# for this case samples are only for contact object. If it's done for domain move/create function on Domain::eis_extdata_info_parse()
sub info_parse
{
  my ($po, $otype, $oaction, $oname, $rinfo) = @_;
  my $mes = $po->message();
  return unless $mes->is_success();

  my $s = $rinfo->{contact}->{$oname}->{self};

  my $node_extension = $mes->node_extension();
  return unless $node_extension;

  foreach my $el (Net::DRI::Util::xml_list_children($node_extension)) {
    my ($name, $content) = @$el;
    if ($name && $name eq 'extdata') {
      foreach my $el2 (Net::DRI::Util::xml_list_children($content)) {
        my ($name2, $content2) = @$el2;
        if ($name2 && lc($name2) eq 'ident') {
          $s->{$name2} = $content2->textContent();
          $s->{$name2.'_type_attr'} = $content2->getAttribute('type') if $content2->getAttribute('type');
          $s->{$name2.'_cc_attr'} = $content2->getAttribute('cc') if $content2->getAttribute('cc');
        } elsif ($name2 && lc($name2) eq 'legal_document') {
          $s->{$name2} = $content2->textContent();
          $s->{$name2.'_type_attr'} = $content2->getAttribute('type') if $content2->getAttribute('type');
        } elsif ($name2 && lc($name2) eq 'reserved') {
          $s->{$name2} = $content2->textContent();
        }
      }
    }
  }

  return;
}

####################################################################################################
1;