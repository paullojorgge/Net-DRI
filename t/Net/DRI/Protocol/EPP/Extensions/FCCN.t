#!/usr/bin/perl

use strict;
use warnings;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;

use Test::More tests => 103;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1;}
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r { my ($c,$m)=@_;  return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10});
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('DNSPT');
$dri->target('DNSPT')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});
print $@->as_string() if $@;

my ($rc,$s,$d,$dh,@c,$co,$co2,$e,$cs,$c1,$toc);

## Session commands
$R2='';
$rc=$dri->process('session','noop',[]);
is($R1,$E1.'<hello/>'.$E2,'session noop build');
is($rc->is_success(),1,'session noop is_success');


$R2=$E1.'<response>'.r(1500).$TRID.'</response>'.$E2;
$rc=$dri->process('session','logout',[]);
is($R1,$E1.'<command><logout/><clTRID>ABC-12345</clTRID></command>'.$E2,'session logout build');
is($rc->is_success(),1,'session logout is_success');


$R2=$E1.'<greeting><svID>DNS.PT EPP Server</svID><svDate>2019-08-06T15:02:52Z</svDate><svcMenu><version>1.0</version><lang>en</lang><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>urn:ietf:params:xml:ns:host-1.0</objURI><svcExtension><extURI>http://eppdev.dns.pt/schemas/ptcontact-1.0</extURI><extURI>http://eppdev.dns.pt/schemas/ptdomain-1.0</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI></svcExtension></svcMenu><dcp><access><all/></access><statement><purpose><admin/><prov/></purpose><recipient><ours/><public/></recipient><retention><stated/></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]);
is($R1,$E1.'<hello/>'.$E2,'session noop build (hello command)');
is($rc->is_success(),1,'session noop is_success');
is($rc->get_data('session','server','server_id'),'DNS.PT EPP Server','session noop get_data(session,server,server_id)');
is($rc->get_data('session','server','date'),'2019-08-06T15:02:52','session noop get_data(session,server,date)');
is_deeply($rc->get_data('session','server','version'),['1.0'],'session noop get_data(session,server,version)');
is_deeply($rc->get_data('session','server','lang'),['en'],'session noop get_data(session,server,lang)');
is_deeply($rc->get_data('session','server','objects'),['urn:ietf:params:xml:ns:contact-1.0','urn:ietf:params:xml:ns:domain-1.0','urn:ietf:params:xml:ns:host-1.0'],'session noop get_data(session,server,objects)');
is_deeply($rc->get_data('session','server','extensions_announced'),['http://eppdev.dns.pt/schemas/ptcontact-1.0','http://eppdev.dns.pt/schemas/ptdomain-1.0','urn:ietf:params:xml:ns:secDNS-1.1'],'session noop get_data(session,server,extensions_announced)');
is_deeply($rc->get_data('session','server','extensions_selected'),['http://eppdev.dns.pt/schemas/ptcontact-1.0','http://eppdev.dns.pt/schemas/ptdomain-1.0','urn:ietf:params:xml:ns:secDNS-1.1'],'session noop get_data(session,server,extensions_selected)');
is($rc->get_data('session','server','dcp_string'),'<access><all/></access><statement><purpose><admin/><prov/></purpose><recipient><ours/><public/></recipient><retention><stated/></retention></statement>','session noop get_data(session,server,dcp_string)');

$R2='';
$rc=$dri->process('session','login',['foobar','Passw0123',{client_newpassword => 'Password'}]);
is($R1,$E1.'<command><login><clID>foobar</clID><pw>Passw0123</pw><newPW>Password</newPW><options><version>1.0</version><lang>en</lang></options><svcs><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>urn:ietf:params:xml:ns:host-1.0</objURI><svcExtension><extURI>http://eppdev.dns.pt/schemas/ptcontact-1.0</extURI><extURI>http://eppdev.dns.pt/schemas/ptdomain-1.0</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI></svcExtension></svcs></login><clTRID>ABC-12345</clTRID></command>'.$E2,'session login build');
is($rc->is_success(),1,'session login is_success');

####################################################################################################
## Domain commands

$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="0">notavailable.pt</domain:name><domain:reason>Domain name already exists.</domain:reason></domain:cd><domain:cd><domain:name avail="1">available.pt</domain:name></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('notavailable.pt','available.pt');
is($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>notavailable.pt</domain:name><domain:name>available.pt</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check multi build');
is($rc->is_success(),1,'domain_check multi is_success');
is($dri->get_info('exist','domain','notavailable.pt'),1,'domain_check multi get_info(exist) 1/2');
is($dri->get_info('exist_reason','domain','notavailable.pt'),'Domain name already exists.','domain_check multi get_info(exist_reason)');
is($dri->get_info('exist','domain','available.pt'),0,'domain_check multi get_info(exist) 2/2');

$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>dns.pt</domain:name><domain:crDate>2018-12-12T11:31:40Z</domain:crDate><domain:exDate>2019-12-12T11:31:40Z</domain:exDate></domain:creData></resData>'.$TRID.'</response>'.$E2;
$cs=$dri->local_object('contactset');
$c1=$dri->local_object('contact')->srid('DTTC-779896-ADNS');
$cs->set($c1,'registrant');
$cs->set($c1,'tech');
$dh=$dri->local_object('hosts');
$dh->add('ns.dns.com',[],[],1);
$dh->add('ns.dns.pt',['192.0.2.2'],['2a04:6d80::'],1);
$rc=$dri->domain_create('dns.pt',
{
    pure_create=>1,
    duration=>DateTime::Duration->new(years=>3),
    contact=>$cs,
    ns=>$dh,
    auth=>{pw=>'Passw0rd'},
    legitimacy=>1,
    registration_basis=>'2',
    auto_renew=>'true',
    arbitration=>'true',
    owner_conf=>'false',
    secdns=>[{keyTag=>'46146',alg=>7,digestType=>2,digest=>'CE5E330AEA4AC9D9951A14153A0F6122EF4DE2F640434A116424F00495F8C994'}]
});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>dns.pt</domain:name><domain:period unit="y">3</domain:period><domain:ns><domain:hostAttr><domain:hostName>ns.dns.com</domain:hostName></domain:hostAttr><domain:hostAttr><domain:hostName>ns.dns.pt</domain:hostName><domain:hostAddr ip="v4">192.0.2.2</domain:hostAddr><domain:hostAddr ip="v6">2a04:6d80::</domain:hostAddr></domain:hostAttr></domain:ns><domain:registrant>DTTC-779896-ADNS</domain:registrant><domain:contact type="tech">DTTC-779896-ADNS</domain:contact><domain:authInfo><domain:pw>Passw0rd</domain:pw></domain:authInfo></domain:create></create><extension><ptdomain:create xmlns:ptdomain="http://eppdev.dns.pt/schemas/ptdomain-1.0" xsi:schemaLocation="http://eppdev.dns.pt/schemas/ptdomain-1.0 ptdomain-1.0.xsd"><ptdomain:legitimacy>1</ptdomain:legitimacy><ptdomain:registration_basis>2</ptdomain:registration_basis><ptdomain:autoRenew>true</ptdomain:autoRenew><ptdomain:Arbitration>true</ptdomain:Arbitration><ptdomain:ownerConf>false</ptdomain:ownerConf></ptdomain:create><secDNS:create xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1" xsi:schemaLocation="urn:ietf:params:xml:ns:secDNS-1.1 secDNS-1.1.xsd"><secDNS:dsData><secDNS:keyTag>46146</secDNS:keyTag><secDNS:alg>7</secDNS:alg><secDNS:digestType>2</secDNS:digestType><secDNS:digest>CE5E330AEA4AC9D9951A14153A0F6122EF4DE2F640434A116424F00495F8C994</secDNS:digest></secDNS:dsData></secDNS:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create build');
is($dri->get_info('action'),'create','domain_create get_info(action)');
is($dri->get_info('exist'),1,'domain_create get_info(exist)');
is($dri->get_info('name'),'dns.pt','domain_create get_info(name)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','domain_create get_info(crDate)');
is("".$d,'2018-12-12T11:31:40','domain_create get_info(crDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_create get_info(exDate)');
is("".$d,'2019-12-12T11:31:40','domain_create get_info(exDate) value');

$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>foobar.pt</domain:name><domain:roid>2134454</domain:roid><domain:status s="ok" /><domain:registrant>GCAA-111111-ADNS</domain:registrant><domain:contact type="tech">UABC-111111-FCCN</domain:contact><domain:ns><domain:hostAttr><domain:hostName>dns01.registred.pt</domain:hostName><domain:hostAddr ip="v4">192.0.2.2</domain:hostAddr><domain:hostAddr ip="v6">1080:0:0:0:8:800:200C:417A</domain:hostAddr></domain:hostAttr><domain:hostAttr><domain:hostName>dns02.dns.pt</domain:hostName></domain:hostAttr></domain:ns><domain:clID>UABC-111111-FCCN</domain:clID><domain:crID>UABC-111111-FCCN</domain:crID><domain:crDate>2013-09-11T01:00:00.000Z</domain:crDate><domain:upID>UABC-111111-FCCN</domain:upID><domain:upDate>2018-09-09T01:00:00.000Z</domain:upDate><domain:exDate>2019-09-10T00:00:00.000Z</domain:exDate><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:infData></resData><extension><ptdomain:infData xmlns:ptdomain="http://eppdev.dns.pt/schemas/ptdomain-1.0" xsi:schemaLocation="http://eppdev.dns.pt/schemas/ptdomain-1.0 ptdomain-1.0.xsd"><ptdomain:legitimacy>X</ptdomain:legitimacy><ptdomain:registration_basis>X</ptdomain:registration_basis><ptdomain:autoRenew>false</ptdomain:autoRenew><ptdomain:Arbitration>true</ptdomain:Arbitration><ptdomain:ownerConf>false</ptdomain:ownerConf><ptdomain:rl>false</ptdomain:rl></ptdomain:infData><secDNS:infData xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1" xsi:schemaLocation="urn:ietf:params:xml:ns:secDNS-1.1 secDNS-1.1.xsd"><secDNS:dsData><secDNS:keyTag>46146</secDNS:keyTag><secDNS:alg>7</secDNS:alg><secDNS:digestType>2</secDNS:digestType><secDNS:digest>CE5E330AEA4AC9D9951A14153A0F6122EF4DE2F640434A116424F00495F8C994</secDNS:digest></secDNS:dsData></secDNS:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('foobar.pt');
is($R1,$E1.'<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">foobar.pt</domain:name></domain:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_info');
is($dri->get_info('action'),'info','domain_info get_info(action)');
is($dri->get_info('exist'),1,'domain_info get_info(exist)');
is($dri->get_info('roid'),'2134454','domain_info get_info(roid)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['ok'],'domain_info get_info(status) list');
is($s->is_active(),1,'domain_info get_info(status) is_active');
$s=$dri->get_info('contact');
isa_ok($s,'Net::DRI::Data::ContactSet','domain_info get_info(contact)');
is_deeply([$s->types()],['registrant','tech'],'domain_info get_info(contact) types');
is($s->get('registrant')->srid(),'GCAA-111111-ADNS','domain_info get_info(contact) registrant srid');
is($s->get('tech')->srid(),'UABC-111111-FCCN','domain_info get_info(contact) tech srid');
$dh=$dri->get_info('ns');
isa_ok($dh,'Net::DRI::Data::Hosts','domain_info get_info(subordinate_hosts)');
@c=$dh->get_names();
is_deeply(\@c,['dns01.registred.pt','dns02.dns.pt'],'domain_info get_info(host) get_names');
$dh=$dri->get_info('ns');
isa_ok($dh,'Net::DRI::Data::Hosts','domain_info get_info(ns)');
@c=$dh->get_names();
is_deeply(\@c,['dns01.registred.pt','dns02.dns.pt'],'domain_info get_info(ns) get_names');
is($dri->get_info('clID'),'UABC-111111-FCCN','domain_info get_info(clID)');
is($dri->get_info('crID'),'UABC-111111-FCCN','domain_info get_info(crID)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','domain_info get_info(crDate)');
is("".$d,'2013-09-11T01:00:00','domain_info get_info(crDate) value');
is($dri->get_info('upID'),'UABC-111111-FCCN','domain_info get_info(upID)');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','domain_info get_info(upDate)');
is("".$d,'2018-09-09T01:00:00','domain_info get_info(upDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_info get_info(exDate)');
is("".$d,'2019-09-10T00:00:00','domain_info get_info(exDate) value');
is_deeply($dri->get_info('auth'),{pw=>'2fooBAR'},'domain_info get_info(auth)');
# ptdomain extension
is($dri->get_info('legitimacy'),'X','domain_info get_info(legitimacy)');
is($dri->get_info('auto_renew'),'false','domain_info get_info(auto_renew)');
is($dri->get_info('owner_conf'),'false','domain_info get_info(owner_conf)');
is($dri->get_info('rl'),'false','domain_info get_info(rl)');
# secdns
is($dri->get_info('exist'),1,'domain_info get_info(exist) +SecDNS 1');
is($dri->protocol()->ns()->{secDNS}->[0],'urn:ietf:params:xml:ns:secDNS-1.1','secDNS 1.1 for server announcing 1.1 only');
$e=$dri->get_info('secdns');
is_deeply($e,[{keyTag=>'46146',alg=>7,digestType=>2,digest=>'CE5E330AEA4AC9D9951A14153A0F6122EF4DE2F640434A116424F00495F8C994'}],'domain_info get_info(secdns) +SecDNS 1');

$R2='';
$toc=$dri->local_object('changes');
$dh=$dri->local_object('hosts');
$dh->add('ns02.example.pt',['192.0.2.2'],['2001:db8::2'],1);
$toc->add('ns',$dh);
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('DTTC-779896-ADNS'),'tech');
$toc->add('contact',$cs);
$dh=$dri->local_object('hosts');
$dh->add('ns01.example.pt',['192.0.2.1'],['2001:db8::1'],1);
$toc->del('ns',$dh);
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('DTTC-779896-ADNS'),'tech');
$toc->del('contact',$cs);
$toc->set('auth',{pw=>'Passw0rd'});
$toc->set('auto_renew','true');
$toc->set('arbitration','true');
$toc->set('owner_conf','true');
$toc->del('secdns',
  [
    {
      keyTag        =>  '12345',
      alg           =>  '3',
      digestType    =>  '1',
      digest        =>  '38EC35D5B3A34B33C99B'
    }
  ]
);
$toc->add('secdns',
  [
    {
      keyTag        =>  '12346',
      alg           =>  '3',
      digestType    =>  '1',
      digest        =>  '38EC35D5B3A34B44C39B'
    }
  ]
);
$rc=$dri->domain_update('example.pt',$toc);
is($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.pt</domain:name><domain:add><domain:ns><domain:hostAttr><domain:hostName>ns02.example.pt</domain:hostName><domain:hostAddr ip="v4">192.0.2.2</domain:hostAddr><domain:hostAddr ip="v6">2001:db8::2</domain:hostAddr></domain:hostAttr></domain:ns><domain:contact type="tech">DTTC-779896-ADNS</domain:contact></domain:add><domain:rem><domain:ns><domain:hostAttr><domain:hostName>ns01.example.pt</domain:hostName></domain:hostAttr></domain:ns><domain:contact type="tech">DTTC-779896-ADNS</domain:contact></domain:rem><domain:chg><domain:authInfo><domain:pw>Passw0rd</domain:pw></domain:authInfo></domain:chg></domain:update></update><extension><ptdomain:update xmlns:ptdomain="http://eppdev.dns.pt/schemas/ptdomain-1.0" xsi:schemaLocation="http://eppdev.dns.pt/schemas/ptdomain-1.0 ptdomain-1.0.xsd"><ptdomain:autoRenew>true</ptdomain:autoRenew><ptdomain:Arbitration>true</ptdomain:Arbitration><ptdomain:ownerConf>true</ptdomain:ownerConf></ptdomain:update><secDNS:update xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1" xsi:schemaLocation="urn:ietf:params:xml:ns:secDNS-1.1 secDNS-1.1.xsd"><secDNS:rem><secDNS:dsData><secDNS:keyTag>12345</secDNS:keyTag><secDNS:alg>3</secDNS:alg><secDNS:digestType>1</secDNS:digestType><secDNS:digest>38EC35D5B3A34B33C99B</secDNS:digest></secDNS:dsData></secDNS:rem><secDNS:add><secDNS:dsData><secDNS:keyTag>12346</secDNS:keyTag><secDNS:alg>3</secDNS:alg><secDNS:digestType>1</secDNS:digestType><secDNS:digest>38EC35D5B3A34B44C39B</secDNS:digest></secDNS:dsData></secDNS:add></secDNS:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update build');

$R2='';
$rc=$dri->domain_renew('example.pt',{duration => DateTime::Duration->new(years=>1), current_expiration => DateTime->new(year=>2019,month=>12,day=>12),auto_renew=>'true'});
is($R1,$E1.'<command><renew><domain:renew xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example.pt</domain:name><domain:curExpDate>2019-12-12</domain:curExpDate><domain:period unit="y">1</domain:period></domain:renew></renew><extension><ptdomain:renew xmlns:ptdomain="http://eppdev.dns.pt/schemas/ptdomain-1.0" xsi:schemaLocation="http://eppdev.dns.pt/schemas/ptdomain-1.0 ptdomain-1.0.xsd"><ptdomain:autoRenew>true</ptdomain:autoRenew></ptdomain:renew></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_renew build');

$R2=$E1.'<response>'.r().'<resData><domain:trnData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>pjti3p9d.com.pt</domain:name><domain:trStatus>serverApproved</domain:trStatus><domain:reID>DTTC-779896-ADNS</domain:reID><domain:reDate>2018-12-21T09:19:45.767Z</domain:reDate><domain:acID>DTTC-779896-ADNS</domain:acID><domain:acDate>2018-12-21T09:19:45.767Z</domain:acDate></domain:trnData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_transfer_start('pjti3p9d.com.pt',{auth=>{pw=>'Passw0rd'},auto_renew=>'true'});
is($R1,$E1.'<command><transfer op="request"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>pjti3p9d.com.pt</domain:name><domain:authInfo><domain:pw>Passw0rd</domain:pw></domain:authInfo></domain:transfer></transfer><extension><ptdomain:transfer xmlns:ptdomain="http://eppdev.dns.pt/schemas/ptdomain-1.0" xsi:schemaLocation="http://eppdev.dns.pt/schemas/ptdomain-1.0 ptdomain-1.0.xsd"><ptdomain:autoRenew>true</ptdomain:autoRenew></ptdomain:transfer></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_transfer_request build');
is($dri->get_info('action'),'transfer','domain_transfer_start get_info(action)');
is($dri->get_info('exist'),1,'domain_transfer_start get_info(exist)');
is($dri->get_info('trStatus'),'serverApproved','domain_transfer_start get_info(trStatus)');
is($dri->get_info('reID'),'DTTC-779896-ADNS','domain_transfer_start get_info(reID)');
$d=$dri->get_info('reDate');
isa_ok($d,'DateTime','domain_transfer_start get_info(reDate)');
is("".$d,'2018-12-21T09:19:45','domain_transfer_start get_info(reDate) value');
is($dri->get_info('acID'),'DTTC-779896-ADNS','domain_transfer_start get_info(acID)');
$d=$dri->get_info('acDate');
isa_ok($d,'DateTime','domain_transfer_start get_info(acDate)');
is("".$d,'2018-12-21T09:19:45','domain_transfer_start get_info(acDate) value');

$R2='';
$rc=$dri->domain_delete('domainregistrar.pt',{pure_delete=>1});
is($R1,$E1.'<command><delete><domain:delete xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>domainregistrar.pt</domain:name></domain:delete></delete><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_delete build');
is($rc->is_success(),1,'domain_delete is_success');

#########################################################################################################
## Contact commands

$R2=$E1.'<response>'.r().'<resData><contact:chkData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:cd><contact:id avail="1">SSIO-933460-ADNC</contact:id></contact:cd><contact:cd><contact:id avail="0">SSIO-933460-ADNS</contact:id><contact:reason>The Nic-Handle is already in use in the system.</contact:reason></contact:cd></contact:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->contact_check(map { $dri->local_object('contact')->srid($_) } ('SSIO-933460-ADNC','SSIO-933460-ADNS'));
is($R1,$E1.'<command><check><contact:check xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>SSIO-933460-ADNC</contact:id><contact:id>SSIO-933460-ADNS</contact:id></contact:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_check multi build');
is($rc->is_success(),1,'contact_check multi is_success');
is($dri->get_info('exist','contact','SSIO-933460-ADNC'),0,'contact_check multi get_info(exist) 1/1');
is($dri->get_info('exist','contact','SSIO-933460-ADNS'),1,'contact_check multi get_info(exist) 2/2');
is($dri->get_info('exist_reason','contact','SSIO-933460-ADNS'),'The Nic-Handle is already in use in the system.','contact_check multi get_info(exist_reason)');

$R2=$E1.'<response>'.r().'<resData><contact:creData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>AAAAA</contact:id><contact:crDate>2018-12-27T19:40:32Z</contact:crDate></contact:creData></resData>'.$TRID.'</response>'.$E2;
$co=$dri->local_object('contact')->srid('AAAAA');
$co->name('RegistrarTeste');
$co->org('Registrar Teste1');
$co->street(['Rua Latino Coelho, 13']);
$co->city('Lisboa');
$co->pc('1050-132');
$co->cc('PT');
$co->voice('+351.211111111');
$co->email('JSP1Ldrr@registrarteste.pt');
$co->auth({pw=>'JSP1Ldrr'});
$co->vat('PT510222222');
$co->mobile('+351.922222222');
$rc=$dri->contact_create($co);
is_string($R1,$E1.'<command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>AAAAA</contact:id><contact:postalInfo type="int"><contact:name>RegistrarTeste</contact:name><contact:org>Registrar Teste1</contact:org><contact:addr><contact:street>Rua Latino Coelho, 13</contact:street><contact:city>Lisboa</contact:city><contact:pc>1050-132</contact:pc><contact:cc>PT</contact:cc></contact:addr></contact:postalInfo><contact:voice>+351.211111111</contact:voice><contact:email>JSP1Ldrr@registrarteste.pt</contact:email><contact:authInfo><contact:pw>JSP1Ldrr</contact:pw></contact:authInfo></contact:create></create><extension><ptcontact:create xmlns:ptcontact="http://eppdev.dns.pt/schemas/ptcontact-1.0" xsi:schemaLocation="http://eppdev.dns.pt/schemas/ptcontact-1.0 ptcontact-1.0.xsd"><ptcontact:vat>PT510222222</ptcontact:vat><ptcontact:mobile>+351.922222222</ptcontact:mobile></ptcontact:create></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_create build');
is($rc->is_success(),1,'contact_create is_success');
is($dri->get_info('id'),'AAAAA','contact_create get_info(id)');
is($dri->get_info('action','contact','AAAAA'),'create','contact_create get_info(action)');
is($dri->get_info('exist','contact','AAAAA'),1,'contact_create get_info(exist)');
$d=$dri->get_info('crDate','contact','AAAAA');
isa_ok($d,'DateTime','contact_create get_info(crDate)');
is("".$d,'2018-12-27T19:40:32','contact_create get_info(crDate) value');

$R2=$E1.'<response>'.r().'<resData><contact:infData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>AAAA-999999-AAAA</contact:id><contact:postalInfo type="int"><contact:name>Registrar Teste</contact:name><contact:org> Registrar Teste </contact:org><contact:addr><contact:street>Rua Latino Coelho, 13</contact:street><contact:city>Lisboa</contact:city><contact:pc>1050-132</contact:pc><contact:cc>PT</contact:cc></contact:addr></contact:postalInfo><contact:voice>+351.912345678</contact:voice><contact:email>registrar.teste@registrar.pt</contact:email><contact:crDate>2018-09-18T12:58:24Z</contact:crDate><contact:upDate>2018-10-25T09:36:41Z</contact:upDate></contact:infData></resData><extension><ptcontact:infData xmlns:ptcontact="http://eppdev.dns.pt/schemas/ptcontact-1.0" xsi:schemaLocation="http://eppdev.dns.pt/schemas/ptdomain-1.0 ptdomain-1.0.xsd"><ptcontact:vat>PT255555555</ptcontact:vat><ptcontact:mobile>+351.213908258</ptcontact:mobile></ptcontact:infData></extension>'.$TRID.'</response>'.$E2;
$co=$dri->local_object('contact')->srid('AAAA-999999-AAAA');
$rc=$dri->contact_info($co);
is($R1,$E1.'<command><info><contact:info xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>AAAA-999999-AAAA</contact:id></contact:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_info build');
is($rc->is_success(),1,'contact_info is_success');
is($dri->get_info('action'),'info','contact_info get_info(action)');
is($dri->get_info('exist'),1,'contact_info get_info(exist)');
$co=$dri->get_info('self');
isa_ok($co,'Net::DRI::Data::Contact','contact_info get_info(self)');
is($co->srid(),'AAAA-999999-AAAA','contact_info get_info(self) srid');
is($co->voice(),'+351.912345678','contact_info get_info(self) voice');
is($co->email(),'registrar.teste@registrar.pt','contact_info get_info(self) email');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','contact_info get_info(crDate)');
is("".$d,'2018-09-18T12:58:24','contact_info get_info(crDate) value');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','contact_info get_info(upDate)');
is("".$d,'2018-10-25T09:36:41','contact_info get_info(upDate) value');
# ptcontact extension
is($co->vat(),'PT255555555','contact_info get_info(self) vat');
is($co->mobile(),'+351.213908258','contact_info get_info(self) mobile');

$R2='';
$co=$dri->local_object('contact')->srid('AAAA-999999-AAAA');
$toc=$dri->local_object('changes');
$co2=$dri->local_object('contact');
$co2->street(['124 Example Dr.','Suite 200']);
$co2->city('Dulles');
$co2->pc('20166-6503');
$co2->cc('US');
$co2->voice('+1.7034444444');
$co2->email('adsdd@registarteste.pt');
$co2->mobile('+351.922222222');
$toc->set('info',$co2);
$rc=$dri->contact_update($co,$toc);
is_string($R1,$E1.'<command><update><contact:update xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>AAAA-999999-AAAA</contact:id><contact:chg><contact:postalInfo type="int"><contact:addr><contact:street>124 Example Dr.</contact:street><contact:street>Suite 200</contact:street><contact:city>Dulles</contact:city><contact:pc>20166-6503</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:voice>+1.7034444444</contact:voice><contact:email>adsdd@registarteste.pt</contact:email></contact:chg></contact:update></update><extension><ptcontact:update xmlns:ptcontact="http://eppdev.dns.pt/schemas/ptcontact-1.0" xsi:schemaLocation="http://eppdev.dns.pt/schemas/ptcontact-1.0 ptcontact-1.0.xsd"><ptcontact:mobile>+351.922222222</ptcontact:mobile></ptcontact:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_update build');
is($rc->is_success(),1,'contact_update is_success');

exit 0;
