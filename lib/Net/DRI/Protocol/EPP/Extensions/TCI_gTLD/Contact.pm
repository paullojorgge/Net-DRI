package Net::DRI::Protocol::EPP::Extensions::TCI_gTLD::Contact;
#===============================================================================
#
#         FILE:  Contact.pm
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Dmitry Belyavsky (BelDmit), <beldmit@tcinet.ru>
#      COMPANY:  tcinet.ru
#      VERSION:  1.0
#      CREATED:  06/24/2013 05:33:35 PM MSK
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use utf8;

use Net::DRI::Exception;
use Net::DRI::Util;
use Net::DRI::Protocol::EPP::Util;

our $VERSION=do { my @r=(q$Revision: 1.3 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

####################################################################################################

sub register_commands
{
	my ($class, $version) = @_;
	my %tmp = ( 
		create => [ \&create, undef ],
		update => [ \&update, undef ],
		info   => [ undef, \&info_parse ],
	);

	return { 'contact' => \%tmp };
}

####################################################################################################
sub build_ext_data
{
 my ($epp, $contact, $mes, $op) = @_;

 my @n;

 if ($contact->person)
 {
 	my $data = $contact->person;

	push @n, ['contact:birthday', $data->{birthday}];

	push @n, ['contact:passport', $data->{passport}];
	push @n, ['contact:TIN',      $data->{TIN}] if exists $data->{TIN};

	if ($op eq 'create')
	{
		$epp->message()->command_extension('contact', [$op, ['contact:person', @n], {'xmlns:contact'=>'http://www.tcinet.ru/epp/tci-contact-ext-1.0'}]);
	}
	elsif ($op eq 'update')
	{
		$epp->message()->command_extension('contact', [$op, ['contact:chg', ['contact:person', @n]], {'xmlns:contact'=>'http://www.tcinet.ru/epp/tci-contact-ext-1.0'}]);
	}
 }
 else
 {
 	my $data = $contact->organization();
	my $addr = $data->{legalAddr};
	
	my @addr;

	my @streets = (ref $addr->{street}) ? @{$addr->{street}} : ($addr->{street});

  for my $street (@streets)
	{
		push @addr, ["contact:street", $street];
	}

	for my $key (qw(city sp pc cc))
	{
		push @addr, ["contact:$key", $addr->{$key}] if $addr->{$key};
	}
	push @n, ['contact:legalAddr', @addr, {type => 'loc'}];
	push @n, ['contact:TIN', $data->{TIN}];

	if ($op eq 'create')
	{
		$epp->message()->command_extension('contact', [$op, ['contact:organization', @n], {'xmlns:contact'=>$epp->message()->ns('tci-contact-ext')}]);
	}
	elsif ($op eq 'update')
	{
		$epp->message()->command_extension('contact', [$op, ['contact:chg', ['contact:organization', @n]], {'xmlns:contact'=>'http://www.tcinet.ru/epp/tci-contact-ext-1.0'}]);
	}
 }
}

sub create
{
 my ($epp,$contact)=@_;
 my $mes=$epp->message();

 build_ext_data($epp, $contact, $mes, 'create');
}


sub update
{
 my ($epp,$contact,$todo)=@_;
 my $mes=$epp->message();

 build_ext_data($epp, $contact, $mes, 'update');
}


sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension('contact','infData');
 return unless $infdata;

 my $ns=$mes->ns('tci-contact-ext');
 $infdata=Net::DRI::Util::xml_traverse($infdata,$ns,'infData','contact');
 return unless defined $infdata;

 my $contact=$rinfo->{contact}->{$oname}->{self};

 foreach my $el (Net::DRI::Util::xml_list_children($infdata))
 {
  my ($name,$c)=@$el;
  if ($name eq 'person')
  {
   $contact->person(parse_person($c)); 
  } 
	elsif ($name eq 'organization')
  {
   $contact->organization(parse_org($c));
  } 
	else
  {
		Net::DRI::Exception::usererr_invalid_parameters('Smthing strange from registry');
  }
 }
}

sub parse_person
{
	my $element = shift;
	my $result  = {};
	
	foreach my $el (Net::DRI::Util::xml_list_children($element))
	{
		my ($name,$c)=@$el;

		if ($name eq 'passport')
		{
			push @{$result->{$name}}, $c->textContent();
		}
		else
		{
		 $result->{$name} = $c->textContent();
		}
	}
	return $result;
}

sub parse_org
{
	my $element = shift;
	my $result  = {};

	foreach my $el (Net::DRI::Util::xml_list_children($element))
	{
		my ($name,$c)=@$el;

		if ($name eq 'legalAddr')
		{
			foreach my $a_el (Net::DRI::Util::xml_list_children($element))
			{
				my ($a_name,$a_c)=@$a_el;

				if ($a_name eq 'street')
				{
					push @{$result->{$name}{$a_name}}, $a_c->textContent();
				}
				else
				{
		 			$result->{$name}{$a_name} = $a_c->textContent();
				}
			}
		}
		else
		{
		 $result->{$name} = $c->textContent();
		}
	}

	return $result;
}

1;

