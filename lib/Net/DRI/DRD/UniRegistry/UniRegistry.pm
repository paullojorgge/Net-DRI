## Domain Registry Interface, UniRegistry Driver
##
## Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2013 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
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

package Net::DRI::DRD::UniRegistry::UniRegistry;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;
use Net::DRI::Data::Contact::UniRegistry;

use DateTime::Duration;

=pod

=head1 NAME

Net::DRI::DRD::UniRegistry::UniRegistry - UniRegistry Driver for Net::DRI

=head1 DESCRIPTION

Additional domain extension UniRegistry New Generic TLDs

UniRegistry utilises the following standard extensions. Please see the test files for more examples.

=head2 Standard extensions:

=head3 L<Net::DRI::Protocol::EPP::Extensions::secDNS> urn:ietf:params:xml:ns:secDNS-1.1

=head3 L<Net::DRI::Protocol::EPP::Extensions::GracePeriod> urn:ietf:params:xml:ns:rgp-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::LaunchPhase> urn:ietf:params:xml:ns:launch-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::IDN> urn:ietf:params:xml:ns:idn-1.0

=head2 Custom extensions:

=head3 L<Net::DRI::Protocol::EPP::Extensions::CentralNic::Fee> urn:centralnic:params:xml:ns:fee-0.7

=head3 L<Net::DRI::Protocol::EPP::Extensions::UniRegistry::Centric> http://ns.uniregistry.net/centric-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::UniRegistry::Market> http://ns.uniregistry.net/market-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::UniRegistry::Market> (poll parser suppliment)

=head2 Other extensions:

=head3 L<Net::DRI::Protocol::EPP::Extensions::VeriSign::Sync> http://www.verisign.com/epp/sync-1.0

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Michael Holloway, E<lt>michael@thedarkwinter.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>.
          (c) 2013 Michael Holloway <michael@thedarkwinter.com>.
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
 $self->{info}->{host_as_attr}=0;
 $self->{info}->{contact_i18n}=4; ## LOC+INT
 return $self;
}

sub periods  { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name     { return 'UniRegistry::UniRegistry'; }

sub tlds     { return ('audio', 'blackfriday', 'christmas', 'click', 'country', 'diet', 'flowers', 'game', 'gift', 'guitars', 'help', 'hiphop', 'hiv', 'hosting', 'juegos', 'link', 'lol', 'mom', 'photo', 'pics', 'property', 'sexy', 'tattoo', 'trust'); }
sub object_types { return ('domain','contact','ns'); }
sub profile_types { return qw/epp/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::UniRegistry',{ 'brown_fee_version' => '0.7' }) if $type eq 'epp';
 return;
}

sub set_factories
{
 my ($self,$po)=@_;
 $po->factories('contact',sub { return Net::DRI::Data::Contact::UniRegistry->new(@_); });
 return;
}

####################################################################################################
sub market_check
{
 my ($self,$ndr,@p)=@_;
 my (@names,$rd);
 foreach my $p (@p)
 {
  if (defined $p && ref $p eq 'HASH')
  {
   Net::DRI::Exception::usererr_invalid_parameters('Only one optional ref hash with extra parameters is allowed in market_check') if defined $rd;
   $rd=Net::DRI::Util::create_params('market_check',$p);
  }
  #$self->enforce_domain_name_constraints($ndr,$p,'check');
  push @names,$p;
 }
 Net::DRI::Exception::usererr_insufficient_parameters('market_check needs at least one domain name to check') unless @names;
 $rd={} unless defined $rd;

 my (@rs,@todo);
 my (%seendom,%seenrc);
 foreach my $domain (@names)
 {
  next if exists $seendom{$domain};
  $seendom{$domain}=1;
  my $rs=$ndr->try_restore_from_cache('market',$domain,'check');
  if (! defined $rs)
  {
   push @todo,$domain;
  } else
  {
   push @rs,$rs unless exists $seenrc{''.$rs}; ## Some ResultStatus may relate to multiple domain names (this is why we are doing this anyway !), so make sure not to use the same ResultStatus multiple times
   $seenrc{''.$rs}=1;
  }
 }
 return Net::DRI::Util::link_rs(@rs) unless @todo;

 if (@todo > 1 && $ndr->protocol()->has_action('market','check_multi'))
 {
  my $l=$self->info('check_limit');
  if (! defined $l)
  {
   $ndr->log_output('notice','core','No check_limit specified in driver, assuming 10 for domain_check action. Please report if you know the correct value');
   $l=10;
  }
  while (@todo)
  {
   my @lt=splice(@todo,0,$l);
   push @rs,$ndr->process('market','check_multi',[\@lt,$rd]);
  }
 } else ## either one domain only, or more than one but no check_multi available at protocol level
 {
  push @rs,map { $ndr->process('market','check',[$_,$rd]); } @todo;
 }
 return Net::DRI::Util::link_rs(@rs);
}

sub market_info
{
 my ($self,$reg,$id)=@_;
 return $reg->process('market','info',[$id]);
}

sub market_create
{
  my ($self,$reg,$id,$rd)=@_;
  return $reg->process('market','create',[$id,$rd]);
}

sub market_update
{
  my ($self,$reg,$rd,$todo)=@_;
  return $reg->process('market','update',[$rd,$todo]);
}

####################################################################################################
sub eps_check
{
 my ($self,$ndr,@p)=@_;
 my (@names,$rd);
 foreach my $p (@p)
 {
  if (defined $p && ref $p eq 'HASH')
  {
   Net::DRI::Exception::usererr_invalid_parameters('Only one optional ref hash with extra parameters is allowed in eps_check') if defined $rd;
   $rd=Net::DRI::Util::create_params('eps_check',$p);
  }
  push @names,$p;
 }
 Net::DRI::Exception::usererr_insufficient_parameters('eps_check needs at least one label to check') unless @names;
 $rd={} unless defined $rd;

 my (@rs,@todo);
 my (%seenlab,%seenrc);
 foreach my $label (@names)
 {
  next if exists $seenlab{$label};
  $seenlab{$label}=1;
  my $rs=$ndr->try_restore_from_cache('eps',$label,'check');
  if (! defined $rs)
  {
   push @todo,$label;
  } else
  {
   push @rs,$rs unless exists $seenrc{''.$rs}; ## Some ResultStatus may relate to multiple labels (this is why we are doing this anyway !), so make sure not to use the same ResultStatus multiple times
   $seenrc{''.$rs}=1;
  }
 }
 return Net::DRI::Util::link_rs(@rs) unless @todo;

 if (@todo > 1 && $ndr->protocol()->has_action('eps','check_multi'))
 {
  my $l=$self->info('check_limit');
  if (! defined $l)
  {
   $ndr->log_output('notice','core','No check_limit specified in driver, assuming 10 for eps_check action. Please report if you know the correct value');
   $l=10;
  }
  while (@todo)
  {
   my @lt=splice(@todo,0,$l);
   push @rs,$ndr->process('eps','check_multi',[\@lt,$rd]);
  }
 } else ## either one label only, or more than one but no check_multi available at protocol level
 {
  push @rs,map { $ndr->process('eps','check',[$_,$rd]); } @todo;
 }
 return Net::DRI::Util::link_rs(@rs);
}

sub eps_info
{
 my ($self,$reg,$id,$rd)=@_;
 return $reg->process('eps','info',[$id,$rd]);
}

sub eps_exempt
{
 my ($self,$ndr,@p)=@_;
 my (@names,$rd);
 foreach my $p (@p)
 {
  if (defined $p && ref $p eq 'HASH')
  {
   Net::DRI::Exception::usererr_invalid_parameters('Only one optional ref hash with extra parameters is allowed in eps_exempt') if defined $rd;
   $rd=Net::DRI::Util::create_params('eps_exempt',$p);
  }
  push @names,$p;
 }
 Net::DRI::Exception::usererr_insufficient_parameters('eps_exempt needs at least one label to check') unless @names;
 $rd={} unless defined $rd;

 my (@rs,@todo);
 my (%seenlab,%seenrc);
 foreach my $label (@names)
 {
  next if exists $seenlab{$label};
  $seenlab{$label}=1;
  my $rs=$ndr->try_restore_from_cache('eps',$label,'check');
  if (! defined $rs)
  {
   push @todo,$label;
  } else
  {
   push @rs,$rs unless exists $seenrc{''.$rs}; ## Some ResultStatus may relate to multiple labels (this is why we are doing this anyway !), so make sure not to use the same ResultStatus multiple times
   $seenrc{''.$rs}=1;
  }
 }
 return Net::DRI::Util::link_rs(@rs) unless @todo;

 if (@todo > 1 && $ndr->protocol()->has_action('eps','exempt_multi'))
 {
  my $l=$self->info('exempt_limit');
  if (! defined $l)
  {
   $ndr->log_output('notice','core','No exempt_limit specified in driver, assuming 10 for eps_exempt action. Please report if you know the correct value');
   $l=10;
  }
  while (@todo)
  {
   my @lt=splice(@todo,0,$l);
   push @rs,$ndr->process('eps','exempt_multi',[\@lt,$rd]);
  }
 } else ## either one label only, or more than one but no exempt_multi available at protocol level
 {
  push @rs,map { $ndr->process('eps','exempt',[$_,$rd]); } @todo;
 }
 return Net::DRI::Util::link_rs(@rs);
}

sub eps_create
{
 my ($self,$reg,$id,$rd)=@_;
 $id = $id->[0] if ref($id) eq 'ARRAY' && scalar(@$id) eq 1;
 return $reg->process('eps','create',[$id,$rd]);
}

sub eps_delete
{
 my ($self,$reg,$id,$rd)=@_;
 return $reg->process('eps','delete',[$id,$rd]);
}

sub eps_renew
{
 my ($self,$reg,$id,$rd)=@_;
 return $reg->process('eps','renew',[$id,$rd]);
}

# by documentation only op="request" is supported for EPS objects
sub eps_transfer_request
{
 my ($self,$reg,$id,$rd)=@_;
 return $reg->process('eps','transfer_request',[$id,$rd]);
}

sub eps_update
{
 my ($self,$reg,$id,$rd)=@_;
 return $reg->process('eps','update',[$id,$rd]);
}

# used to set a password to permit the registration of a domain object blocked by an EPS object
sub eps_release_create
{
 my ($self,$reg,$id,$rd)=@_;
 return $reg->process('eps','release_create',[$id,$rd]);
}

# used to delete a password set to permit the registration of a domain object blocked by an EPS object
sub eps_release_delete
{
 my ($self,$reg,$id,$rd)=@_;
 return $reg->process('eps','release_delete',[$id,$rd]);
}

####################################################################################################
1;
