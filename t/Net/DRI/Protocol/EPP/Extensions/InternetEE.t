#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;

use Test::More tests => 80;
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
my ($dh,@c,$toc,$csadd,$csdel,$cs,$c1,$c2,$c3,$secdns);
my ($legal_document,$legal_document_attr,$reserved);

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
$R2=$E1.'<response>'.r().'
<resData><domain:infData xmlns:domain="https://epp.tld.ee/schema/domain-eis-1.0.xsd"><domain:name>domain56.ee</domain:name><domain:roid>EIS-69</domain:roid><domain:status s="clientHold"/><domain:registrant>FIXED:REGISTRANT6384423854</domain:registrant><domain:contact type="tech">FIXED:SH46786741126</domain:contact><domain:contact type="admin">FIXED:SH96052327125</domain:contact><domain:ns><domain:hostAttr><domain:hostName>ns.westkeebler168.ee</domain:hostName><domain:hostAddr ip="v4">192.168.1.1</domain:hostAddr></domain:hostAttr><domain:hostAttr><domain:hostName>ns.wuckert169.ee</domain:hostName><domain:hostAddr ip="v4">192.168.1.1</domain:hostAddr></domain:hostAttr><domain:hostAttr><domain:hostName>ns.runolfssoneffertz170.ee</domain:hostName><domain:hostAddr ip="v4">192.168.1.1</domain:hostAddr></domain:hostAttr><domain:hostAttr><domain:hostName>ns1.example.com</domain:hostName><domain:hostAddr ip="v4">192.168.1.1</domain:hostAddr><domain:hostAddr ip="v6">1080:0:0:0:8:800:200C:417A</domain:hostAddr></domain:hostAttr></domain:ns><domain:clID>registrar1</domain:clID><domain:crDate>2015-09-09T09:42:12Z</domain:crDate><domain:upDate>2015-09-09T09:42:12Z</domain:upDate><domain:exDate>2016-09-09T09:42:12Z</domain:exDate><domain:authInfo><domain:pw>98oiewslkfkd</domain:pw></domain:authInfo></domain:infData></resData><extension><secDNS:infData xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1"><secDNS:dsData><secDNS:keyTag>123</secDNS:keyTag><secDNS:alg>3</secDNS:alg><secDNS:digestType>1</secDNS:digestType><secDNS:digest>0D85A305D22FCB355BBE29AE9809363D697B64782B9CC73AE349350F8C2AE4BB</secDNS:digest><secDNS:keyData><secDNS:flags>257</secDNS:flags><secDNS:protocol>3</secDNS:protocol><secDNS:alg>3</secDNS:alg><secDNS:pubKey>AwEAAddt2AkLfYGKgiEZB5SmIF8EvrjxNMH6HtxWEA4RJ9Ao6LCWheg8</secDNS:pubKey></secDNS:keyData></secDNS:dsData><secDNS:dsData><secDNS:keyTag>123</secDNS:keyTag><secDNS:alg>3</secDNS:alg><secDNS:digestType>1</secDNS:digestType><secDNS:digest>0D85A305D22FCB355BBE29AE9809363D697B64782B9CC73AE349350F8C2AE4BB</secDNS:digest><secDNS:keyData><secDNS:flags>0</secDNS:flags><secDNS:protocol>3</secDNS:protocol><secDNS:alg>5</secDNS:alg><secDNS:pubKey>700b97b591ed27ec2590d19f06f88bba700b97b591ed27ec2590d19f</secDNS:pubKey></secDNS:keyData></secDNS:dsData></secDNS:infData></extension>
'.$TRID.'</response>'.$E2;
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
exit 0;