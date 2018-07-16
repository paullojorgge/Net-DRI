#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;

use Test::More tests => 15;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('InternetEE');
$dri->target('InternetEE')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
print $@->as_string() if $@;

my $rc;
my $s;
my $d;
my ($dh,@c,$toc,$cs,$csadd,$csdel,$c1,$c2);

####################################################################################################
# EPP Session when not connected greets client upon connection
$R2=$E1.'<greeting><svID>EPP server (EIS)</svID><svDate>2015-09-09T09:42:29Z</svDate><svcMenu><version>1.0</version><lang>en</lang><objURI>https://epp.tld.ee/schema/domain-eis-1.0.xsd</objURI><objURI>https://epp.tld.ee/schema/contact-ee-1.1.xsd</objURI><objURI>urn:ietf:params:xml:ns:host-1.0</objURI><objURI>urn:ietf:params:xml:ns:keyrelay-1.0</objURI><svcExtension><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>https://epp.tld.ee/schema/eis-1.0.xsd</extURI></svcExtension></svcMenu><dcp><access><all/></access><statement><purpose><admin/><prov/></purpose><recipient><public/></recipient><retention><stated/></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]);
is($R1,$E1.'<hello/>'.$E2,'session noop build (hello command)');
is($rc->is_success(),1,'session noop is_success');
is($rc->get_data('session','server','server_id'),'EPP server (EIS)','session noop get_data(session,server,server_id)');
is($rc->get_data('session','server','date'),'2015-09-09T09:42:29','session noop get_data(session,server,date)');
is_deeply($rc->get_data('session','server','version'),['1.0'],'session noop get_data(session,server,version)');
is_deeply($rc->get_data('session','server','lang'),['en'],'session noop get_data(session,server,lang)');
is_deeply($rc->get_data('session','server','objects'),['https://epp.tld.ee/schema/domain-eis-1.0.xsd','https://epp.tld.ee/schema/contact-ee-1.1.xsd','urn:ietf:params:xml:ns:host-1.0','urn:ietf:params:xml:ns:keyrelay-1.0'],'session noop get_data(session,server,objects)');
is_deeply($rc->get_data('session','server','extensions_announced'),['urn:ietf:params:xml:ns:secDNS-1.1','https://epp.tld.ee/schema/eis-1.0.xsd'],'session noop get_data(session,server,extensions_announced)');
is_deeply($rc->get_data('session','server','extensions_selected'),['urn:ietf:params:xml:ns:secDNS-1.1','https://epp.tld.ee/schema/eis-1.0.xsd'],'session noop get_data(session,server,extensions_selected)');
is($rc->get_data('session','server','dcp_string'),'<access><all/></access><statement><purpose><admin/><prov/></purpose><recipient><public/></recipient><retention><stated/></retention></statement>','session noop get_data(session,server,dcp_string)');
####################################################################################################

####################################################################################################
## Login
$R2='';
$rc=$dri->process('session','login',['gitlab','ghyt9e4fu',{client_newpassword => 'abcdefg'}]);
is($R1,$E1.'<command><login><clID>gitlab</clID><pw>ghyt9e4fu</pw><newPW>abcdefg</newPW><options><version>1.0</version><lang>en</lang></options><svcs><objURI>https://epp.tld.ee/schema/domain-eis-1.0.xsd</objURI><objURI>https://epp.tld.ee/schema/contact-ee-1.1.xsd</objURI><objURI>urn:ietf:params:xml:ns:host-1.0</objURI><objURI>urn:ietf:params:xml:ns:keyrelay-1.0</objURI><svcExtension><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>https://epp.tld.ee/schema/eis-1.0.xsd</extURI></svcExtension></svcs></login><clTRID>ABC-12345</clTRID></command>'.$E2,'session login build');
is($rc->is_success(),1,'session login is_success');
####################################################################################################

####################################################################################################
## Logout
$R2=$E1.'<response>'.r(1500).$TRID.'</response>'.$E2;
$rc=$dri->process('session','logout',[]);
is($R1,$E1.'<command><logout/><clTRID>ABC-12345</clTRID></command>'.$E2,'session logout build');
is($rc->is_success(),1,'session logout is_success');
####################################################################################################



####################################################################################################
exit 0;