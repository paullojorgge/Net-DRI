#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;

use Test::More tests => 188;
use Test::Exception;

use Data::Dumper;

eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="https://epp.tld.ee/schema/epp-ee-1.0.xsd" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="https://epp.tld.ee/schema/epp-ee-1.0.xsd epp-ee-1.0.xsd">';
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
my ($dh,@c,$toc,$csadd,$csdel,$cs,$c1,$c2,$c3,$secdns,$co,$co2);
my ($legal_document,$legal_document_attr,$reserved);
my ($ident,$ident_type,$ident_cc);

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
## Domain check - single domain
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="https://epp.tld.ee/schema/domain-eis-1.0.xsd"><domain:cd><domain:name avail="1">one.ee</domain:name></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('one.ee');
is($R1,$E1.'<command><check><domain:check xmlns:domain="https://epp.tld.ee/schema/domain-eis-1.0.xsd" xsi:schemaLocation="https://epp.tld.ee/schema/domain-eis-1.0.xsd domain-eis-1.0.xsd"><domain:name>one.ee</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check build');
is($rc->is_success(),1,'domain_check is_success');
is($dri->get_info('action'),'check','domain_check get_info(action)');
is($dri->get_info('exist'),0,'domain_check get_info(exist)');
is($dri->get_info('exist','domain','one.ee'),0,'domain_check get_info(exist) from cache');
####################################################################################################

####################################################################################################
## Domain check - multiple domains
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="https://epp.tld.ee/schema/domain-eis-1.0.xsd"><domain:cd><domain:name avail="1">foobarone.ee</domain:name></domain:cd><domain:cd><domain:name avail="1">two.ee</domain:name></domain:cd><domain:cd><domain:name avail="1">three.ee</domain:name></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('foobarone.ee', 'two.ee', 'three.ee');
is($R1,$E1.'<command><check><domain:check xmlns:domain="https://epp.tld.ee/schema/domain-eis-1.0.xsd" xsi:schemaLocation="https://epp.tld.ee/schema/domain-eis-1.0.xsd domain-eis-1.0.xsd"><domain:name>foobarone.ee</domain:name><domain:name>two.ee</domain:name><domain:name>three.ee</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check multi build');
is($rc->is_success(),1,'domain_check multi is_success');
is($dri->get_info('exist','domain','foobarone.ee'),0,'domain_check multi get_info(exist) 1/3');
is($dri->get_info('exist','domain','two.ee'),0,'domain_check multi get_info(exist) 2/3');
is($dri->get_info('exist','domain','three.ee'),0,'domain_check multi get_info(exist) 3/3');
####################################################################################################

####################################################################################################
## Domain info
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="https://epp.tld.ee/schema/domain-eis-1.0.xsd"><domain:name>domain56.ee</domain:name><domain:roid>EIS-69</domain:roid><domain:status s="clientHold"/><domain:registrant>FIXED:REGISTRANT6384423854</domain:registrant><domain:contact type="tech">FIXED:SH46786741126</domain:contact><domain:contact type="admin">FIXED:SH96052327125</domain:contact><domain:ns><domain:hostAttr><domain:hostName>ns.westkeebler168.ee</domain:hostName><domain:hostAddr ip="v4">192.168.1.1</domain:hostAddr></domain:hostAttr><domain:hostAttr><domain:hostName>ns.wuckert169.ee</domain:hostName><domain:hostAddr ip="v4">192.168.1.1</domain:hostAddr></domain:hostAttr><domain:hostAttr><domain:hostName>ns.runolfssoneffertz170.ee</domain:hostName><domain:hostAddr ip="v4">192.168.1.1</domain:hostAddr></domain:hostAttr><domain:hostAttr><domain:hostName>ns1.example.com</domain:hostName><domain:hostAddr ip="v4">192.168.1.1</domain:hostAddr><domain:hostAddr ip="v6">1080:0:0:0:8:800:200C:417A</domain:hostAddr></domain:hostAttr></domain:ns><domain:clID>registrar1</domain:clID><domain:crDate>2015-09-09T09:42:12Z</domain:crDate><domain:upDate>2015-09-09T09:42:12Z</domain:upDate><domain:exDate>2016-09-09T09:42:12Z</domain:exDate><domain:authInfo><domain:pw>98oiewslkfkd</domain:pw></domain:authInfo></domain:infData></resData><extension><secDNS:infData xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1"><secDNS:dsData><secDNS:keyTag>123</secDNS:keyTag><secDNS:alg>3</secDNS:alg><secDNS:digestType>1</secDNS:digestType><secDNS:digest>0D85A305D22FCB355BBE29AE9809363D697B64782B9CC73AE349350F8C2AE4BB</secDNS:digest><secDNS:keyData><secDNS:flags>257</secDNS:flags><secDNS:protocol>3</secDNS:protocol><secDNS:alg>3</secDNS:alg><secDNS:pubKey>AwEAAddt2AkLfYGKgiEZB5SmIF8EvrjxNMH6HtxWEA4RJ9Ao6LCWheg8</secDNS:pubKey></secDNS:keyData></secDNS:dsData><secDNS:dsData><secDNS:keyTag>123</secDNS:keyTag><secDNS:alg>3</secDNS:alg><secDNS:digestType>1</secDNS:digestType><secDNS:digest>0D85A305D22FCB355BBE29AE9809363D697B64782B9CC73AE349350F8C2AE4BB</secDNS:digest><secDNS:keyData><secDNS:flags>0</secDNS:flags><secDNS:protocol>3</secDNS:protocol><secDNS:alg>5</secDNS:alg><secDNS:pubKey>700b97b591ed27ec2590d19f06f88bba700b97b591ed27ec2590d19f</secDNS:pubKey></secDNS:keyData></secDNS:dsData></secDNS:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('domain56.ee',{auth=>{pw=>'2fooBAR'}});
is($R1,$E1.'<command><info><domain:info xmlns:domain="https://epp.tld.ee/schema/domain-eis-1.0.xsd" xsi:schemaLocation="https://epp.tld.ee/schema/domain-eis-1.0.xsd domain-eis-1.0.xsd"><domain:name hosts="all">domain56.ee</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_info build with auth');
is($dri->get_info('action'),'info','domain_info get_info(action)');
is($dri->get_info('exist'),1,'domain_info get_info(exist)');
is($dri->get_info('roid'),'EIS-69','domain_info get_info(roid)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['clientHold'],'domain_info get_info(status) list');
$s=$dri->get_info('contact');
isa_ok($s,'Net::DRI::Data::ContactSet','domain_info get_info(contact)');
is_deeply([$s->types()],['admin','registrant','tech'],'domain_info get_info(contact) types');
is($s->get('registrant')->srid(),'FIXED:REGISTRANT6384423854','domain_info get_info(contact) registrant srid');
is($s->get('admin')->srid(),'FIXED:SH96052327125','domain_info get_info(contact) admin srid');
is($s->get('tech')->srid(),'FIXED:SH46786741126','domain_info get_info(contact) tech srid');
$dh=$dri->get_info('ns');
isa_ok($dh,'Net::DRI::Data::Hosts','domain_info get_info(ns)');
@c=$dh->get_names();
is_deeply(\@c,['ns.westkeebler168.ee','ns.wuckert169.ee','ns.runolfssoneffertz170.ee','ns1.example.com'],'domain_info get_info(ns) get_names');
my @d=$dh->get_details(4);
is_deeply(\@d,['ns1.example.com',['192.168.1.1'],['1080:0:0:0:8:800:200C:417A'],undef],'domain_info get_info(ns) get_names');
is($dri->get_info('clID'),'registrar1','domain_info get_info(clID)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','domain_info get_info(crDate)');
is("".$d,'2015-09-09T09:42:12','domain_info get_info(crDate) value');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','domain_info get_info(upDate)');
is("".$d,'2015-09-09T09:42:12','domain_info get_info(upDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_info get_info(exDate)');
is("".$d,'2016-09-09T09:42:12','domain_info get_info(exDate) value');
is_deeply($dri->get_info('auth'),{pw=>'98oiewslkfkd'},'domain_info get_info(auth)');
my $e=$dri->get_info('secdns');
is_deeply($e,[{'digest' => '0D85A305D22FCB355BBE29AE9809363D697B64782B9CC73AE349350F8C2AE4BB', 'keyTag' => '123', 'key_flags' => '257', 'alg' => '3', 'key_protocol' => '3', 'digestType' => '1', 'key_pubKey' => 'AwEAAddt2AkLfYGKgiEZB5SmIF8EvrjxNMH6HtxWEA4RJ9Ao6LCWheg8', 'key_alg' => '3'}, {'key_flags' => '0', 'digest' => '0D85A305D22FCB355BBE29AE9809363D697B64782B9CC73AE349350F8C2AE4BB', 'keyTag' => '123', 'key_pubKey' => '700b97b591ed27ec2590d19f06f88bba700b97b591ed27ec2590d19f', 'key_alg' => '5', 'key_protocol' => '3', 'alg' => '3', 'digestType' => '1'}],'domain_info get_info(secdns)');
####################################################################################################

####################################################################################################
## Domain create
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="https://epp.tld.ee/schema/domain-eis-1.0.xsd"><domain:name>example1689235482901404.ee</domain:name><domain:crDate>2015-09-09T09:41:01Z</domain:crDate><domain:exDate>2016-09-09T09:41:01Z</domain:exDate></domain:creData></resData>'.$TRID.'</response>'.$E2;
$cs=$dri->local_object('contactset');
$c1=$dri->local_object('contact')->srid('FIXED:CITIZEN_1234');
$c2=$dri->local_object('contact')->srid('FIXED:SH8013');
$c3=$dri->local_object('contact')->srid('FIXED:SH801333');
$cs->set($c1,'registrant');
$cs->set($c2,'admin');
$cs->set([$c2,$c3],'tech');
$dh=$dri->local_object('hosts');
$dh->add('ns1.example.net',['192.0.2.2'],['1080:0:0:0:8:800:200C:417A'],1);
$dh->add('ns2.example.net',[],[],1);
$secdns = [{key_flags=>'257',key_alg=>5,key_protocol=>3,key_pubKey=>'AwEAAddt2AkLfYGKgiEZB5SmIF8EvrjxNMH6HtxWEA4RJ9Ao6LCWheg8'}];
$legal_document = 'dGVzdCBmYWlsCg==';
$legal_document_attr = 'pdf';
$rc=$dri->domain_create('example1689235482901404.ee',{pure_create=>1,duration=>DateTime::Duration->new(years=>1),ns=>$dh,contact=>$cs,auth=>{pw=>'2fooBAR'},secdns=>$secdns,legal_document=>$legal_document,legal_document_attr=>$legal_document_attr});
is($R1,$E1.'<command><create><domain:create xmlns:domain="https://epp.tld.ee/schema/domain-eis-1.0.xsd" xsi:schemaLocation="https://epp.tld.ee/schema/domain-eis-1.0.xsd domain-eis-1.0.xsd"><domain:name>example1689235482901404.ee</domain:name><domain:period unit="y">1</domain:period><domain:ns><domain:hostAttr><domain:hostName>ns1.example.net</domain:hostName><domain:hostAddr ip="v4">192.0.2.2</domain:hostAddr><domain:hostAddr ip="v6">1080:0:0:0:8:800:200C:417A</domain:hostAddr></domain:hostAttr><domain:hostAttr><domain:hostName>ns2.example.net</domain:hostName></domain:hostAttr></domain:ns><domain:registrant>FIXED:CITIZEN_1234</domain:registrant><domain:contact type="admin">FIXED:SH8013</domain:contact><domain:contact type="tech">FIXED:SH8013</domain:contact><domain:contact type="tech">FIXED:SH801333</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><secDNS:create xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1" xsi:schemaLocation="urn:ietf:params:xml:ns:secDNS-1.1 secDNS-1.1.xsd"><secDNS:keyData><secDNS:flags>257</secDNS:flags><secDNS:protocol>3</secDNS:protocol><secDNS:alg>5</secDNS:alg><secDNS:pubKey>AwEAAddt2AkLfYGKgiEZB5SmIF8EvrjxNMH6HtxWEA4RJ9Ao6LCWheg8</secDNS:pubKey></secDNS:keyData></secDNS:create><eis:extdata xmlns:eis="https://epp.tld.ee/schema/eis-1.0.xsd" xsi:schemaLocation="https://epp.tld.ee/schema/eis-1.0.xsd eis-1.0.xsd"><eis:legalDocument type="pdf">dGVzdCBmYWlsCg==</eis:legalDocument></eis:extdata></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build');
is($dri->get_info('action'),'create','domain_create get_info(action)');
is($dri->get_info('exist'),1,'domain_create get_info(exist)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','domain_create get_info(crDate)');
is("".$d,'2015-09-09T09:41:01','domain_create get_info(crDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_create get_info(exDate)');
is("".$d,'2016-09-09T09:41:01','domain_create get_info(exDate) value');
####################################################################################################

####################################################################################################
## Domain create - reserved
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="https://epp.tld.ee/schema/domain-eis-1.0.xsd"><domain:name>example1689235482901404.ee</domain:name><domain:crDate>2015-09-09T09:41:01Z</domain:crDate><domain:exDate>2016-09-09T09:41:01Z</domain:exDate></domain:creData></resData>'.$TRID.'</response>'.$E2;
$cs=$dri->local_object('contactset');
$c1=$dri->local_object('contact')->srid('FIXED:CITIZEN_1234');
$c2=$dri->local_object('contact')->srid('FIXED:SH8013');
$c3=$dri->local_object('contact')->srid('FIXED:SH801333');
$cs->set($c1,'registrant');
$cs->set($c2,'admin');
$cs->set([$c2,$c3],'tech');
$dh=$dri->local_object('hosts');
$dh->add('ns1.example.net',['192.0.2.2'],['1080:0:0:0:8:800:200C:417A'],1);
$dh->add('ns2.example.net',[],[],1);
$secdns = [{key_flags=>'257',key_alg=>5,key_protocol=>3,key_pubKey=>'AwEAAddt2AkLfYGKgiEZB5SmIF8EvrjxNMH6HtxWEA4RJ9Ao6LCWheg8'}];
$legal_document = 'dGVzdCBmYWlsCg==';
$legal_document_attr = 'pdf';
$reserved = 'abc';
$rc=$dri->domain_create('example1689235482901404.ee',{pure_create=>1,duration=>DateTime::Duration->new(years=>1),ns=>$dh,contact=>$cs,auth=>{pw=>'2fooBAR'},secdns=>$secdns,legal_document=>$legal_document,legal_document_attr=>$legal_document_attr,reserved=>$reserved});
is($R1,$E1.'<command><create><domain:create xmlns:domain="https://epp.tld.ee/schema/domain-eis-1.0.xsd" xsi:schemaLocation="https://epp.tld.ee/schema/domain-eis-1.0.xsd domain-eis-1.0.xsd"><domain:name>example1689235482901404.ee</domain:name><domain:period unit="y">1</domain:period><domain:ns><domain:hostAttr><domain:hostName>ns1.example.net</domain:hostName><domain:hostAddr ip="v4">192.0.2.2</domain:hostAddr><domain:hostAddr ip="v6">1080:0:0:0:8:800:200C:417A</domain:hostAddr></domain:hostAttr><domain:hostAttr><domain:hostName>ns2.example.net</domain:hostName></domain:hostAttr></domain:ns><domain:registrant>FIXED:CITIZEN_1234</domain:registrant><domain:contact type="admin">FIXED:SH8013</domain:contact><domain:contact type="tech">FIXED:SH8013</domain:contact><domain:contact type="tech">FIXED:SH801333</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><extension><secDNS:create xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1" xsi:schemaLocation="urn:ietf:params:xml:ns:secDNS-1.1 secDNS-1.1.xsd"><secDNS:keyData><secDNS:flags>257</secDNS:flags><secDNS:protocol>3</secDNS:protocol><secDNS:alg>5</secDNS:alg><secDNS:pubKey>AwEAAddt2AkLfYGKgiEZB5SmIF8EvrjxNMH6HtxWEA4RJ9Ao6LCWheg8</secDNS:pubKey></secDNS:keyData></secDNS:create><eis:extdata xmlns:eis="https://epp.tld.ee/schema/eis-1.0.xsd" xsi:schemaLocation="https://epp.tld.ee/schema/eis-1.0.xsd eis-1.0.xsd"><eis:legalDocument type="pdf">dGVzdCBmYWlsCg==</eis:legalDocument><eis:reserved><eis:pw>abc</eis:pw></eis:reserved></eis:extdata></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create reserved build');
is($dri->get_info('action'),'create','domain_create reserved get_info(action)');
is($dri->get_info('exist'),1,'domain_create reserved get_info(exist)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','domain_create reserved get_info(crDate)');
is("".$d,'2015-09-09T09:41:01','domain_create reserved get_info(crDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_create reserved get_info(exDate)');
is("".$d,'2016-09-09T09:41:01','domain_create reserved get_info(exDate) value');
####################################################################################################

####################################################################################################
## Domain delete - EPP Domain with valid domain deletes domain
$R2='';
$legal_document = 'dGVzdCBmYWlsCg==';
$legal_document_attr = 'pdf';
$rc=$dri->domain_delete('domain62.ee',{pure_delete=>1, legal_document=>$legal_document, legal_document_attr=>$legal_document_attr});
is($R1,$E1.'<command><delete><domain:delete xmlns:domain="https://epp.tld.ee/schema/domain-eis-1.0.xsd" xsi:schemaLocation="https://epp.tld.ee/schema/domain-eis-1.0.xsd domain-eis-1.0.xsd"><domain:name>domain62.ee</domain:name></domain:delete></delete><extension><eis:extdata xmlns:eis="https://epp.tld.ee/schema/eis-1.0.xsd" xsi:schemaLocation="https://epp.tld.ee/schema/eis-1.0.xsd eis-1.0.xsd"><eis:legalDocument type="pdf">dGVzdCBmYWlsCg==</eis:legalDocument></eis:extdata></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_delete build - EPP domain with valid domain deletes domain');
is($rc->is_success(),1,'domain_delete is_success - EPP domain with valid domain deletes domain');

# document type is not valid
$legal_document_attr = 'foobar';
throws_ok { $dri->domain_delete('domain62.ee',{pure_delete=>1, legal_document=>$legal_document, legal_document_attr=>$legal_document_attr}) } qr/legal_document_attr type is not valid!/, 'domain_delete - with non valid document type';

# delete command without legal document
throws_ok { $dri->domain_delete('domain62.ee',{pure_delete=>1}) } qr/legal_document mandatory to delete domain!/, 'domain_delete - without legal document';

# legal document is not base64
$legal_document = 'foobar';
throws_ok { $dri->domain_delete('domain62.ee',{pure_delete=>1, legal_document=>$legal_document, legal_document_attr=>$legal_document_attr}) } qr/legal_document is not base64!/, 'domain_delete - legal document is not base64';
####################################################################################################

####################################################################################################
## Domain renew
$R2=$E1.'<response>'.r().'<resData><domain:renData xmlns:domain="https://epp.tld.ee/schema/domain-eis-1.0.xsd"><domain:name>domain42.ee</domain:name><domain:exDate>2017-09-09T09:42:01Z</domain:exDate></domain:renData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_renew('domain42.ee',{duration => DateTime::Duration->new(years=>1), current_expiration => DateTime->new(year=>2016,month=>9,day=>9)});
is($R1,$E1.'<command><renew><domain:renew xmlns:domain="https://epp.tld.ee/schema/domain-eis-1.0.xsd" xsi:schemaLocation="https://epp.tld.ee/schema/domain-eis-1.0.xsd domain-eis-1.0.xsd"><domain:name>domain42.ee</domain:name><domain:curExpDate>2016-09-09</domain:curExpDate><domain:period unit="y">1</domain:period></domain:renew></renew><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_renew build');
is($dri->get_info('action'),'renew','domain_renew get_info(action)');
is($dri->get_info('exist'),1,'domain_renew get_info(exist)');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_renew get_info(exDate)');
is("".$d,'2017-09-09T09:42:01','domain_renew get_info(exDate) value');

## Domain renew with no period specified - if it's the case default is 1 year!
$R2=$E1.'<response>'.r().'<resData><domain:renData xmlns:domain="https://epp.tld.ee/schema/domain-eis-1.0.xsd"><domain:name>domain42.ee</domain:name><domain:exDate>2017-09-09T09:42:01Z</domain:exDate></domain:renData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_renew('domain42.ee',{current_expiration => DateTime->new(year=>2016,month=>9,day=>9)});
is($R1,$E1.'<command><renew><domain:renew xmlns:domain="https://epp.tld.ee/schema/domain-eis-1.0.xsd" xsi:schemaLocation="https://epp.tld.ee/schema/domain-eis-1.0.xsd domain-eis-1.0.xsd"><domain:name>domain42.ee</domain:name><domain:curExpDate>2016-09-09</domain:curExpDate></domain:renew></renew><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_renew no period build');
is($dri->get_info('action'),'renew','domain_renew  no period get_info(action)');
is($dri->get_info('exist'),1,'domain_renew no period get_info(exist)');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_renew no period get_info(exDate)');
is("".$d,'2017-09-09T09:42:01','domain_renew no period get_info(exDate) value');
####################################################################################################

####################################################################################################
## Domain update
$R2='';
$toc=$dri->local_object('changes');
$toc->add('ns',$dri->local_object('hosts')->set(['ns1.example.com'],['ns2.example.com']));
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('FIXED:PENDINGMAK21'),'tech');
$toc->add('contact',$cs);
$toc->add('status',$dri->local_object('status')->no('update'));
$cs=$dri->local_object('contactset');
$toc->set('registrant',$dri->local_object('contact')->srid('FIXED:CITIZEN_1234'));
$toc->add('secdns',[{key_flags=>0,key_alg=>5,key_protocol=>3,key_pubKey=>'700b97b591ed27ec2590d19f06f88bba700b97b591ed27ec2590d19f'},{key_flags=>256,key_alg=>'254',key_protocol=>3,key_pubKey=>'841936717ae427ace63c28d04918569a841936717ae427ace63c28d0'}]);
$rc=$dri->domain_update('domain35.ee',$toc,{legal_document=>'dGVzdCBmYWlsCg==',legal_document_attr=>'pdf'});
is($R1,$E1.'<command><update><domain:update xmlns:domain="https://epp.tld.ee/schema/domain-eis-1.0.xsd" xsi:schemaLocation="https://epp.tld.ee/schema/domain-eis-1.0.xsd domain-eis-1.0.xsd"><domain:name>domain35.ee</domain:name><domain:add><domain:ns><domain:hostAttr><domain:hostName>ns1.example.com</domain:hostName></domain:hostAttr><domain:hostAttr><domain:hostName>ns2.example.com</domain:hostName></domain:hostAttr></domain:ns><domain:contact type="tech">FIXED:PENDINGMAK21</domain:contact><domain:status s="clientUpdateProhibited"/></domain:add><domain:chg><domain:registrant>FIXED:CITIZEN_1234</domain:registrant></domain:chg></domain:update></update><extension><secDNS:update xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1" xsi:schemaLocation="urn:ietf:params:xml:ns:secDNS-1.1 secDNS-1.1.xsd"><secDNS:add><secDNS:keyData><secDNS:flags>0</secDNS:flags><secDNS:protocol>3</secDNS:protocol><secDNS:alg>5</secDNS:alg><secDNS:pubKey>700b97b591ed27ec2590d19f06f88bba700b97b591ed27ec2590d19f</secDNS:pubKey></secDNS:keyData><secDNS:keyData><secDNS:flags>256</secDNS:flags><secDNS:protocol>3</secDNS:protocol><secDNS:alg>254</secDNS:alg><secDNS:pubKey>841936717ae427ace63c28d04918569a841936717ae427ace63c28d0</secDNS:pubKey></secDNS:keyData></secDNS:add></secDNS:update><eis:extdata xmlns:eis="https://epp.tld.ee/schema/eis-1.0.xsd" xsi:schemaLocation="https://epp.tld.ee/schema/eis-1.0.xsd eis-1.0.xsd"><eis:legalDocument type="pdf">dGVzdCBmYWlsCg==</eis:legalDocument></eis:extdata></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update build');
is($rc->is_success(),1,'domain_update is_success');

$R2='';
$toc=$dri->local_object('changes');
$toc->del('ns',$dri->local_object('hosts')->set(['ns1.example.com']));
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('FIXED:CITIZEN_1234'),'tech');
$toc->del('contact',$cs);
$toc->del('status',$dri->local_object('status')->no('publish'));
$toc->del('secdns',[{key_flags=>256,key_alg=>254,key_protocol=>3,key_pubKey=>'700b97b591ed27ec2590d19f06f88bba700b97b591ed27ec2590d19f'}]);
$rc=$dri->domain_update('domain37.ee',$toc);
is($R1,$E1.'<command><update><domain:update xmlns:domain="https://epp.tld.ee/schema/domain-eis-1.0.xsd" xsi:schemaLocation="https://epp.tld.ee/schema/domain-eis-1.0.xsd domain-eis-1.0.xsd"><domain:name>domain37.ee</domain:name><domain:rem><domain:ns><domain:hostAttr><domain:hostName>ns1.example.com</domain:hostName></domain:hostAttr></domain:ns><domain:contact type="tech">FIXED:CITIZEN_1234</domain:contact><domain:status s="clientHold"/></domain:rem></domain:update></update><extension><secDNS:update xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1" xsi:schemaLocation="urn:ietf:params:xml:ns:secDNS-1.1 secDNS-1.1.xsd"><secDNS:rem><secDNS:keyData><secDNS:flags>256</secDNS:flags><secDNS:protocol>3</secDNS:protocol><secDNS:alg>254</secDNS:alg><secDNS:pubKey>700b97b591ed27ec2590d19f06f88bba700b97b591ed27ec2590d19f</secDNS:pubKey></secDNS:keyData></secDNS:rem></secDNS:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update 2 build');
is($rc->is_success(),1,'domain_update 2 is_success');
####################################################################################################

####################################################################################################
## Domain transfer request (standard)
$R2=$E1.'<response>'.r().'<resData><domain:trnData xmlns:domain="https://epp.tld.ee/schema/domain-eis-1.0.xsd" xsi:schemaLocation="https://epp.tld.ee/schema/domain-eis-1.0.xsd domain-eis-1.0.xsd"><domain:name>domain3.ee</domain:name><domain:trStatus>serverApproved</domain:trStatus><domain:reID>REGDOMAIN2</domain:reID><domain:reDate>2015-09-09T09:41:30Z</domain:reDate><domain:acID>REGDOMAIN1</domain:acID><domain:acDate>2015-09-09T09:41:30Z</domain:acDate><domain:exDate>2016-09-09T09:41:30Z</domain:exDate></domain:trnData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_transfer_start('domain3.ee',{auth=>{pw=>'98oiewslkfkd'}});
is($R1,$E1.'<command><transfer op="request"><domain:transfer xmlns:domain="https://epp.tld.ee/schema/domain-eis-1.0.xsd" xsi:schemaLocation="https://epp.tld.ee/schema/domain-eis-1.0.xsd domain-eis-1.0.xsd"><domain:name>domain3.ee</domain:name><domain:authInfo><domain:pw>98oiewslkfkd</domain:pw></domain:authInfo></domain:transfer></transfer><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_transfer_request standard build');
is($dri->get_info('action'),'transfer','domain_transfer_start get_info(action)');
is($dri->get_info('exist'),1,'domain_transfer_start get_info(exist)');
is($dri->get_info('trStatus'),'serverApproved','domain_transfer_start get_info(trStatus)');
is($dri->get_info('reID'),'REGDOMAIN2','domain_transfer_start get_info(reID)');
$d=$dri->get_info('reDate');
isa_ok($d,'DateTime','domain_transfer_start get_info(reDate)');
is("".$d,'2015-09-09T09:41:30','domain_transfer_start get_info(reDate) value');
is($dri->get_info('acID'),'REGDOMAIN1','domain_transfer_start get_info(acID)');
$d=$dri->get_info('acDate');
isa_ok($d,'DateTime','domain_transfer_start get_info(acDate)');
is("".$d,'2015-09-09T09:41:30','domain_transfer_start get_info(acDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_transfer_start get_info(exDate)');
is("".$d,'2016-09-09T09:41:30','domain_transfer_start get_info(exDate) value');

## Domain transfer request (with extdata)
$R2=$E1.'<response>'.r().'<resData><domain:trnData xmlns:domain="https://epp.tld.ee/schema/domain-eis-1.0.xsd" xsi:schemaLocation="https://epp.tld.ee/schema/domain-eis-1.0.xsd domain-eis-1.0.xsd"><domain:name>domain2.ee</domain:name><domain:trStatus>serverApproved</domain:trStatus><domain:reID>REGDOMAIN2</domain:reID><domain:reDate>2015-09-09T09:41:30Z</domain:reDate><domain:acID>REGDOMAIN1</domain:acID><domain:acDate>2015-09-09T09:41:30Z</domain:acDate><domain:exDate>2016-09-09T09:41:30Z</domain:exDate></domain:trnData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_transfer_start('domain2.ee',{auth=>{pw=>'98oiewslkfkd'},legal_document=>'dGVzdCBmYWlsCg==',legal_document_attr=>'pdf'});
is($R1,$E1.'<command><transfer op="request"><domain:transfer xmlns:domain="https://epp.tld.ee/schema/domain-eis-1.0.xsd" xsi:schemaLocation="https://epp.tld.ee/schema/domain-eis-1.0.xsd domain-eis-1.0.xsd"><domain:name>domain2.ee</domain:name><domain:authInfo><domain:pw>98oiewslkfkd</domain:pw></domain:authInfo></domain:transfer></transfer><extension><eis:extdata xmlns:eis="https://epp.tld.ee/schema/eis-1.0.xsd" xsi:schemaLocation="https://epp.tld.ee/schema/eis-1.0.xsd eis-1.0.xsd"><eis:legalDocument type="pdf">dGVzdCBmYWlsCg==</eis:legalDocument></eis:extdata></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_transfer_request with extdata build');
is($dri->get_info('action'),'transfer','domain_transfer_start get_info(action) (extdata)');
is($dri->get_info('exist'),1,'domain_transfer_start get_info(exist) (extdata)');
is($dri->get_info('trStatus'),'serverApproved','domain_transfer_start get_info(trStatus) (extdata)');
is($dri->get_info('reID'),'REGDOMAIN2','domain_transfer_start get_info(reID) (extdata)');
$d=$dri->get_info('reDate');
isa_ok($d,'DateTime','domain_transfer_start get_info(reDate) (extdata)');
is("".$d,'2015-09-09T09:41:30','domain_transfer_start get_info(reDate) value (extdata)');
is($dri->get_info('acID'),'REGDOMAIN1','domain_transfer_start get_info(acID) (extdata)');
$d=$dri->get_info('acDate');
isa_ok($d,'DateTime','domain_transfer_start get_info(acDate) (extdata)');
is("".$d,'2015-09-09T09:41:30','domain_transfer_start get_info(acDate) value (extdata)');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_transfer_start get_info(exDate) (extdata)');
is("".$d,'2016-09-09T09:41:30','domain_transfer_start get_info(exDate) value (extdata)');

# document type is not valid
throws_ok { $dri->domain_transfer_start('domain222.ee',{auth=>{pw=>'98oiewslkfkd'},legal_document=>'dGVzdCBmYWlsCg==',legal_document_attr=>'pdff'}) } qr/legal_document_attr type is not valid!/, 'domain_transfer_start - with non valid document type';
####################################################################################################

####################################################################################################
## Domain transfer approve (with extdata)
$R2=$E1.'<response>'.r().'<resData><domain:trnData xmlns:domain="https://epp.tld.ee/schema/domain-eis-1.0.xsd" xsi:schemaLocation="https://epp.tld.ee/schema/domain-eis-1.0.xsd domain-eis-1.0.xsd"><domain:name>domain17.ee</domain:name><domain:trStatus>clientApproved</domain:trStatus><domain:reID>REGDOMAIN2</domain:reID><domain:reDate>2015-09-09T09:41:34Z</domain:reDate><domain:acID>REGDOMAIN1</domain:acID><domain:acDate>2015-09-09T09:41:34Z</domain:acDate><domain:exDate>2016-09-09T09:41:34Z</domain:exDate></domain:trnData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_transfer_accept('domain17.ee',{auth=>{pw=>'98oiewslkfkd'},legal_document=>'dGVzdCBmYWlsCg==',legal_document_attr=>'pdf'});
is($R1,$E1.'<command><transfer op="approve"><domain:transfer xmlns:domain="https://epp.tld.ee/schema/domain-eis-1.0.xsd" xsi:schemaLocation="https://epp.tld.ee/schema/domain-eis-1.0.xsd domain-eis-1.0.xsd"><domain:name>domain17.ee</domain:name><domain:authInfo><domain:pw>98oiewslkfkd</domain:pw></domain:authInfo></domain:transfer></transfer><extension><eis:extdata xmlns:eis="https://epp.tld.ee/schema/eis-1.0.xsd" xsi:schemaLocation="https://epp.tld.ee/schema/eis-1.0.xsd eis-1.0.xsd"><eis:legalDocument type="pdf">dGVzdCBmYWlsCg==</eis:legalDocument></eis:extdata></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_transfer_accept with extdata build');
is($dri->get_info('action'),'transfer','domain_transfer_accept get_info(action) (extdata)');
is($dri->get_info('exist'),1,'domain_transfer_accept get_info(exist) (extdata)');
is($dri->get_info('name'),'domain17.ee','domain_transfer_accept get_info(trStatus) (extdata)');
is($dri->get_info('trStatus'),'clientApproved','domain_transfer_accept get_info(trStatus) (extdata)');
is($dri->get_info('reID'),'REGDOMAIN2','domain_transfer_accept get_info(reID) (extdata)');
$d=$dri->get_info('reDate');
isa_ok($d,'DateTime','domain_transfer_accept get_info(reDate) (extdata)');
is("".$d,'2015-09-09T09:41:34','domain_transfer_accept get_info(reDate) value (extdata)');
is($dri->get_info('acID'),'REGDOMAIN1','domain_transfer_accept get_info(acID) (extdata)');
$d=$dri->get_info('acDate');
isa_ok($d,'DateTime','domain_transfer_accept get_info(acDate) (extdata)');
is("".$d,'2015-09-09T09:41:34','domain_transfer_accept get_info(acDate) value (extdata)');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_transfer_accept get_info(exDate) (extdata)');
is("".$d,'2016-09-09T09:41:34','domain_transfer_accept get_info(exDate) value (extdata)');
####################################################################################################

####################################################################################################
## Domain transfer approve (with extdata)
$R2=$E1.'<response>'.r().'<resData><domain:trnData xmlns:domain="https://epp.tld.ee/schema/domain-eis-1.0.xsd" xsi:schemaLocation="https://epp.tld.ee/schema/domain-eis-1.0.xsd domain-eis-1.0.xsd"><domain:name>domain17.ee</domain:name><domain:trStatus>clientApproved</domain:trStatus><domain:reID>REGDOMAIN2</domain:reID><domain:reDate>2015-09-09T09:41:34Z</domain:reDate><domain:acID>REGDOMAIN1</domain:acID><domain:acDate>2015-09-09T09:41:34Z</domain:acDate><domain:exDate>2016-09-09T09:41:34Z</domain:exDate></domain:trnData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_transfer_accept('domain17.ee',{auth=>{pw=>'98oiewslkfkd'},legal_document=>'dGVzdCBmYWlsCg==',legal_document_attr=>'pdf'});
is($R1,$E1.'<command><transfer op="approve"><domain:transfer xmlns:domain="https://epp.tld.ee/schema/domain-eis-1.0.xsd" xsi:schemaLocation="https://epp.tld.ee/schema/domain-eis-1.0.xsd domain-eis-1.0.xsd"><domain:name>domain17.ee</domain:name><domain:authInfo><domain:pw>98oiewslkfkd</domain:pw></domain:authInfo></domain:transfer></transfer><extension><eis:extdata xmlns:eis="https://epp.tld.ee/schema/eis-1.0.xsd" xsi:schemaLocation="https://epp.tld.ee/schema/eis-1.0.xsd eis-1.0.xsd"><eis:legalDocument type="pdf">dGVzdCBmYWlsCg==</eis:legalDocument></eis:extdata></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_transfer_accept with extdata build');
is($dri->get_info('action'),'transfer','domain_transfer_accept get_info(action) (extdata)');
is($dri->get_info('exist'),1,'domain_transfer_accept get_info(exist) (extdata)');
is($dri->get_info('name'),'domain17.ee','domain_transfer_accept get_info(trStatus) (extdata)');
is($dri->get_info('trStatus'),'clientApproved','domain_transfer_accept get_info(trStatus) (extdata)');
is($dri->get_info('reID'),'REGDOMAIN2','domain_transfer_accept get_info(reID) (extdata)');
$d=$dri->get_info('reDate');
isa_ok($d,'DateTime','domain_transfer_accept get_info(reDate) (extdata)');
is("".$d,'2015-09-09T09:41:34','domain_transfer_accept get_info(reDate) value (extdata)');
is($dri->get_info('acID'),'REGDOMAIN1','domain_transfer_accept get_info(acID) (extdata)');
$d=$dri->get_info('acDate');
isa_ok($d,'DateTime','domain_transfer_accept get_info(acDate) (extdata)');
is("".$d,'2015-09-09T09:41:34','domain_transfer_accept get_info(acDate) value (extdata)');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_transfer_accept get_info(exDate) (extdata)');
is("".$d,'2016-09-09T09:41:34','domain_transfer_accept get_info(exDate) value (extdata)');
####################################################################################################

####################################################################################################
## Domain transfer reject (with extdata)
$R2=$E1.'<response>'.r().'<resData><domain:trnData xmlns:domain="https://epp.tld.ee/schema/domain-eis-1.0.xsd" xsi:schemaLocation="https://epp.tld.ee/schema/domain-eis-1.0.xsd domain-eis-1.0.xsd"><domain:name>domain18.ee</domain:name><domain:trStatus>clientRejected</domain:trStatus><domain:reID>REGDOMAIN2</domain:reID><domain:reDate>2015-09-09T09:41:34Z</domain:reDate><domain:acID>REGDOMAIN1</domain:acID><domain:acDate>2015-09-09T09:41:34Z</domain:acDate><domain:exDate>2016-09-09T09:41:34Z</domain:exDate></domain:trnData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_transfer_refuse('domain18.ee',{auth=>{pw=>'98oiewslkfkd'},legal_document=>'dGVzdCBmYWlsCg==',legal_document_attr=>'pdf'});
is($R1,$E1.'<command><transfer op="reject"><domain:transfer xmlns:domain="https://epp.tld.ee/schema/domain-eis-1.0.xsd" xsi:schemaLocation="https://epp.tld.ee/schema/domain-eis-1.0.xsd domain-eis-1.0.xsd"><domain:name>domain18.ee</domain:name><domain:authInfo><domain:pw>98oiewslkfkd</domain:pw></domain:authInfo></domain:transfer></transfer><extension><eis:extdata xmlns:eis="https://epp.tld.ee/schema/eis-1.0.xsd" xsi:schemaLocation="https://epp.tld.ee/schema/eis-1.0.xsd eis-1.0.xsd"><eis:legalDocument type="pdf">dGVzdCBmYWlsCg==</eis:legalDocument></eis:extdata></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_transfer_refuse with extdata build');
is($dri->get_info('action'),'transfer','domain_transfer_refuse get_info(action) (extdata)');
is($dri->get_info('exist'),1,'domain_transfer_refuse get_info(exist) (extdata)');
is($dri->get_info('name'),'domain18.ee','domain_transfer_refuse get_info(trStatus) (extdata)');
is($dri->get_info('trStatus'),'clientRejected','domain_transfer_refuse get_info(trStatus) (extdata)');
is($dri->get_info('reID'),'REGDOMAIN2','domain_transfer_refuse get_info(reID) (extdata)');
$d=$dri->get_info('reDate');
isa_ok($d,'DateTime','domain_transfer_refuse get_info(reDate) (extdata)');
is("".$d,'2015-09-09T09:41:34','domain_transfer_refuse get_info(reDate) value (extdata)');
is($dri->get_info('acID'),'REGDOMAIN1','domain_transfer_refuse get_info(acID) (extdata)');
$d=$dri->get_info('acDate');
isa_ok($d,'DateTime','domain_transfer_refuse get_info(acDate) (extdata)');
is("".$d,'2015-09-09T09:41:34','domain_transfer_refuse get_info(acDate) value (extdata)');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_transfer_refuse get_info(exDate) (extdata)');
is("".$d,'2016-09-09T09:41:34','domain_transfer_refuse get_info(exDate) value (extdata)');
####################################################################################################

####################################################################################################
## Contact check (multi)
$R2=$E1.'<response>'.r().'<resData><contact:chkData xmlns:contact="https://epp.tld.ee/schema/contact-ee-1.1.xsd" xsi:schemaLocation="https://epp.tld.ee/schema/contact-ee-1.1.xsd contact-ee-1.1.xsd"><contact:cd><contact:id avail="0">FIXED:CHECK-1234</contact:id><contact:reason>in use</contact:reason></contact:cd><contact:cd><contact:id avail="1">check-4321</contact:id></contact:cd></contact:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->contact_check(map { $dri->local_object('contact')->srid($_) } ('FIXED:CHECK-1234','check-4321'));
is($R1,$E1.'<command><check><contact:check xmlns:contact="https://epp.tld.ee/schema/contact-ee-1.1.xsd" xsi:schemaLocation="https://epp.tld.ee/schema/contact-ee-1.1.xsd contact-ee-1.1.xsd"><contact:id>FIXED:CHECK-1234</contact:id><contact:id>check-4321</contact:id></contact:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_check multi build');
is($rc->is_success(),1,'contact_check multi is_success');
is($dri->get_info('exist','contact','check-4321'),0,'contact_check multi get_info(exist) 1/2');
is($dri->get_info('exist','contact','FIXED:CHECK-1234'),1,'contact_check multi get_info(exist) 2/2');
is($dri->get_info('exist_reason','contact','FIXED:CHECK-1234'),'in use','contact_check multi get_info(exist_reason)');
####################################################################################################

####################################################################################################
## Contact delete
$R2='';
$co=$dri->local_object('contact')->srid('FIRST0:SH159792');
$rc=$dri->contact_delete($co);
is($R1,$E1.'<command><delete><contact:delete xmlns:contact="https://epp.tld.ee/schema/contact-ee-1.1.xsd" xsi:schemaLocation="https://epp.tld.ee/schema/contact-ee-1.1.xsd contact-ee-1.1.xsd"><contact:id>FIRST0:SH159792</contact:id></contact:delete></delete><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_delete build');
is($rc->is_success(),1,'contact_delete is_success');

## Contact delete with extdata
$R2='';
$co2=$dri->local_object('contact')->srid('FIRST0:SH159793');
$co2->legal_document('dGVzdCBmYWlsCg==');
$co2->legal_document_attr('pdf');
$co2->ident('37605030299');
$co2->ident_type_attr('priv');
$co2->ident_cc_attr('EE');
$rc=$dri->contact_delete($co2);
is($R1,$E1.'<command><delete><contact:delete xmlns:contact="https://epp.tld.ee/schema/contact-ee-1.1.xsd" xsi:schemaLocation="https://epp.tld.ee/schema/contact-ee-1.1.xsd contact-ee-1.1.xsd"><contact:id>FIRST0:SH159793</contact:id></contact:delete></delete><extension><eis:extdata xmlns:eis="https://epp.tld.ee/schema/eis-1.0.xsd" xsi:schemaLocation="https://epp.tld.ee/schema/eis-1.0.xsd eis-1.0.xsd"><eis:ident cc="EE" type="priv">37605030299</eis:ident><eis:legalDocument type="pdf">dGVzdCBmYWlsCg==</eis:legalDocument></eis:extdata></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_delete with extdata build');
is($rc->is_success(),1,'contact_delete with extdata is_success');

# ident_cc_attr not valid
$co2->ident_cc_attr('EEE');
throws_ok { $dri->contact_delete($co2) } qr/ident_cc_attr can only have 2 chars!/, 'contact_delete extdata - with non valid ident_cc_attr';

# ident_type_attr not valid
$co2->ident_cc_attr('EE');
$co2->ident_type_attr('foobar');
throws_ok { $dri->contact_delete($co2) } qr/ident_type_attr type is not valid!/, 'contact_delete extdata - with non valid ident_type_attr';
####################################################################################################

####################################################################################################
## Contact info
$R2=$E1.'<response>'.r().'<resData><contact:infData xmlns:contact="https://epp.tld.ee/schema/contact-ee-1.1.xsd" xsi:schemaLocation="https://epp.tld.ee/schema/contact-ee-1.1.xsd contact-ee-1.1.xsd"><contact:id>FIXED:INFO-4444</contact:id><contact:roid>EIS-30</contact:roid><contact:status s="ok"/><contact:postalInfo type="int"><contact:name>Johnny Awesome</contact:name><contact:addr><contact:street>Short street 11</contact:street><contact:city>Tallinn</contact:city><contact:sp/><contact:pc>11111</contact:pc><contact:cc>EE</contact:cc></contact:addr></contact:postalInfo><contact:voice>+372.12345678</contact:voice><contact:email>jerod@monahan.name</contact:email><contact:clID>fixed registrar</contact:clID><contact:crID>TEST-CREATOR</contact:crID><contact:crDate>2015-09-09T09:40:57Z</contact:crDate><contact:authInfo><contact:pw>password</contact:pw></contact:authInfo></contact:infData></resData><extension><eis:extdata xmlns:eis="https://epp.tld.ee/schema/eis-1.0.xsd" xsi:schemaLocation="https://epp.tld.ee/schema/eis-1.0.xsd eis-1.0.xsd"><eis:ident type="priv" cc="EE">37605030299</eis:ident></eis:extdata></extension>'.$TRID.'</response>'.$E2;
$co=$dri->local_object('contact')->srid('FIXED:INFO-4444')->auth({pw=>'password'});
$rc=$dri->contact_info($co);
is($R1,$E1.'<command><info><contact:info xmlns:contact="https://epp.tld.ee/schema/contact-ee-1.1.xsd" xsi:schemaLocation="https://epp.tld.ee/schema/contact-ee-1.1.xsd contact-ee-1.1.xsd"><contact:id>FIXED:INFO-4444</contact:id><contact:authInfo><contact:pw>password</contact:pw></contact:authInfo></contact:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_info build');
is($rc->is_success(),1,'contact_info is_success');
is($dri->get_info('action'),'info','contact_info get_info(action)');
is($dri->get_info('exist'),1,'contact_info get_info(exist)');
$co=$dri->get_info('self');
isa_ok($co,'Net::DRI::Data::Contact','contact_info get_info(self)');
is($co->srid(),'FIXED:INFO-4444','contact_info get_info(self) srid');
is($co->roid(),'EIS-30','contact_info get_info(self) roid');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','contact_info get_info(status)');
is_deeply([$s->list_status()],['ok'],'contact_info get_info(status) list_status');
is([$co->name()]->[1],'Johnny Awesome','contact_info get_info(self) name');
is_deeply([$co->street()]->[1],['Short street 11'],'contact_info get_info(self) street');
is([$co->city()]->[1],'Tallinn','contact_info get_info(self) city');
is([$co->sp()]->[1],'','contact_info get_info(self) sp');
is([$co->pc()]->[1],'11111','contact_info get_info(self) pc');
is([$co->cc()]->[1],'EE','contact_info get_info(self) cc');
is($co->voice(),'+372.12345678','contact_info get_info(self) voice');
is($co->email(),'jerod@monahan.name','contact_info get_info(self) email');
is($dri->get_info('clID'),'fixed registrar','contact_info get_info(clID)');
is($dri->get_info('crID'),'TEST-CREATOR','contact_info get_info(crID)'),
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','contact_info get_info(crDate)');
is("".$d,'2015-09-09T09:40:57','contact_info get_info(crDate) value');
is_deeply($co->auth(),{pw=>'password'},'contact_info get_info(self) auth');
is($co->ident(),'37605030299','contact_info get_info(ident)');
is($co->ident_type_attr(),'priv','contact_info get_info(ident_type_attr)');
is($co->ident_cc_attr(),'EE','contact_info get_info(ident_cc_attr)');
####################################################################################################

####################################################################################################
## Contact create
$R2=$E1.'<response>'.r().'<resData><contact:creData xmlns:contact="https://epp.tld.ee/schema/contact-ee-1.1.xsd" xsi:schemaLocation="https://epp.tld.ee/schema/contact-ee-1.1.xsd contact-ee-1.1.xsd"><contact:id>FIRST0:84FC4612</contact:id><contact:crDate>2015-09-09T09:40:29Z</contact:crDate></contact:creData></resData>'.$TRID.'</response>'.$E2;
$co=$dri->local_object('contact')->srid('abc12345');
$co->name('John Doe');
$co->street(['123 Example']);
$co->city('Tallinn');
$co->pc('123456');
$co->cc('EE');
$co->voice('+372.1234567');
$co->email('test@example.example');
$co->auth({pw=>'2fooBAR'});
$co->legal_document('dGVzdCBmYWlsCg==');
$co->legal_document_attr('pdf');
$co->ident('37605030299');
$co->ident_type_attr('priv');
$co->ident_cc_attr('EE');
$rc=$dri->contact_create($co);
is_string($R1,$E1.'<command><create><contact:create xmlns:contact="https://epp.tld.ee/schema/contact-ee-1.1.xsd" xsi:schemaLocation="https://epp.tld.ee/schema/contact-ee-1.1.xsd contact-ee-1.1.xsd"><contact:id>abc12345</contact:id><contact:postalInfo type="int"><contact:name>John Doe</contact:name><contact:addr><contact:street>123 Example</contact:street><contact:city>Tallinn</contact:city><contact:pc>123456</contact:pc><contact:cc>EE</contact:cc></contact:addr></contact:postalInfo><contact:voice>+372.1234567</contact:voice><contact:email>test@example.example</contact:email><contact:authInfo><contact:pw>2fooBAR</contact:pw></contact:authInfo></contact:create></create><extension><eis:extdata xmlns:eis="https://epp.tld.ee/schema/eis-1.0.xsd" xsi:schemaLocation="https://epp.tld.ee/schema/eis-1.0.xsd eis-1.0.xsd"><eis:ident cc="EE" type="priv">37605030299</eis:ident><eis:legalDocument type="pdf">dGVzdCBmYWlsCg==</eis:legalDocument></eis:extdata></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_create build');
is($rc->is_success(),1,'contact_create is_success');

# org not valid
$co->org('Example Inc.');
throws_ok { $dri->contact_create($co) } qr/Invalid contact information: org/, 'contact_create - with non valid org';

# org/fax not valid
$co->fax('+372.123456789');
throws_ok { $dri->contact_create($co) } qr/Invalid contact information: org\/fax/, 'contact_create - with non valid org/fax';

# ident is mandatory
delete $co->{org};
delete $co->{fax};
delete $co->{ident};
throws_ok { $dri->contact_create($co) } qr/contact identifier/, 'contact_create - missing mandatory ident';

# # TODO: add test in case legal_document is mandatory (I don't think it's!)
# delete $co->{org};
# delete $co->{fax};
# delete $co->{ident};
# throws_ok { $dri->contact_create($co) } qr/contact identifier/, 'contact_create - missing mandatory ident';
####################################################################################################

####################################################################################################
## Contact update
$R2='';
$co=$dri->local_object('contact')->srid('FIRST0:SH8013');
$toc=$dri->local_object('changes');
$co2=$dri->local_object('contact');
$co2->name('John Doe Edited');
$co2->voice('+372.7654321');
$co2->email('edited@example.example');
$co2->auth({pw=>'password'});
$co->legal_document('dGVzdCBmYWlsCg==');
$co->legal_document_attr('pdf');
$toc->set('info',$co2);
$rc=$dri->contact_update($co,$toc);
is_string($R1,$E1.'<command><update><contact:update xmlns:contact="https://epp.tld.ee/schema/contact-ee-1.1.xsd" xsi:schemaLocation="https://epp.tld.ee/schema/contact-ee-1.1.xsd contact-ee-1.1.xsd"><contact:id>FIRST0:SH8013</contact:id><contact:chg><contact:postalInfo type="int"><contact:name>John Doe Edited</contact:name></contact:postalInfo><contact:voice>+372.7654321</contact:voice><contact:email>edited@example.example</contact:email><contact:authInfo><contact:pw>password</contact:pw></contact:authInfo></contact:chg></contact:update></update><extension><eis:extdata xmlns:eis="https://epp.tld.ee/schema/eis-1.0.xsd" xsi:schemaLocation="https://epp.tld.ee/schema/eis-1.0.xsd eis-1.0.xsd"><eis:legalDocument type="pdf">dGVzdCBmYWlsCg==</eis:legalDocument></eis:extdata></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_update build');
is($rc->is_success(),1,'contact_update is_success');

## Contact update with non supported org field
$R2='';
$co=$dri->local_object('contact')->srid('FIRST0:SH8013');
$toc=$dri->local_object('changes');
$co2=$dri->local_object('contact');
$co2->org('should not save');
$co2->name('John Doe Edited');
$co2->voice('+372.7654321');
$co2->email('edited@example.example');
$co2->auth({pw=>'password'});
$co->legal_document('dGVzdCBmYWlsCg==');
$co->legal_document_attr('pdf');
$toc->set('info',$co2);
throws_ok { $dri->contact_update($co,$toc) } qr/Invalid contact information: org/, 'contact_update - with non supported org field';
####################################################################################################



####################################################################################################
exit 0;
