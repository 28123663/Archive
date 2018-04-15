--[[
ģ�����ƣ�linkair
ģ�鹦�ܣ�
ģ������޸�ʱ�䣺2017.02.13
]]

--����ģ��,����������
module(...,package.seeall)

require"protoair"
require"sms"
require"dbg"
require"ccair"

--���س��õ�ȫ�ֺ���������
local ssub,schar,smatch = string.sub,string.char,string.match
local SCK_IDX,KEEP_ALIVE_TIME = 1,720
--rests����յ��ı���
--shkcnt�𶯴���
local rests,shkcnt = "",0
--locshkλ���Ƿ����ƶ���"SIL"δ�ƶ���"SHK"�ƶ�
local locshk,firstloc,firstgps = "SIL"
--chgalm �͵籨��
--shkalm �𶯱���
local chgalm,shkalm = true,true
--vernoЭ��汾��
--mqttconnfailcnt mqttconn����ʧ�ܴ���
--mqttconn true mqtt����
local verno,mqttconnfailcnt,mqttconn = 1,0

local function print(...)
	_G.print("linkair",...)
end

--[[
��������getstatus
����  ����ȡ�豸״̬
����  ����
����ֵ���豸״̬��
]]
local function getstatus()
	local t = {}

	t.shake = (shkcnt > 0) and 1 or 0
	shkcnt = 0
	t.charger = chg.getcharger() and 1 or 0
	t.acc = 0
	t.gps = gps.isopen() and 1 or 0
	t.sleep = pm.isleep() and 1 or 0
	t.volt = chg.getvolt()

	return t
end

--[[
��������getgps
����  ����ȡgps��λ��Ϣ
����  ����
����ֵ��gps��λ��Ϣ��
]]
local function getgps()
	local t = {}
	print("getgps:",gps.getgpslocation(),gps.getgpscog(),gps.getgpsspd())
	t.fix = gps.isfix()
	if gps.isfix() then
		t.lng,t.lat = smatch(gps.getgpslocation(),"[EW]*,(%d+%.%d+),[NS]*,(%d+%.%d+)")
	else
		t.lng,t.lat = manage.getlastgps()
	end
	t.lng,t.lat = t.lng or "",t.lat or ""
	t.cog = gps.getgpscog()
	t.spd = gps.getgpsspd()

	return t
end

--[[
��������getgpstat
����  ����ȡ������
����  ����
����ֵ��������
]]
local function getgpstat()
	local t = {}
	t.satenum = gps.getgpssatenum()
	return t
end

local function getfncpara()
	local n1 = (manage.GUARDFNC and 1 or 0) + (manage.HANDLEPWRFNC and 1 or 0)*2 + (manage.MOTORPWRFNC and 1 or 0)*4 + (manage.RMTPWRFNC and 1 or 0)*8
	n1 = n1 + (manage.BUZZERFNC and 1 or 0)*16
	local n2,n3,n4,n5,n6,n7,n8 = 0,0,0,0,0,0,0
	return pack.pack("bbbbbbbb",n1,n2,n3,n4,n5,n6,n7,n8)
end

--[[
��������getcellinfo
����  ����ȡС����Ϣ
����  ����
����ֵ��С����Ϣ
]]
 function getcellinfo()
	return smatch(net.getcellinfo(),"(%w+%.%w+%.%w+;)")
end

--[[
��������getcellinfoext
����  ����ȡС����չ��Ϣ
����  ����
����ֵ��С����չ��Ϣ
]]
 function getcellinfoext()
	return smatch(net.getcellinfoext(),"(%w+%.%w+%.%w+%.%w+%.%w+;)")
end

local tget = {
	["VERSION"] = function() return _G.VERSION end,
	PROJECTID = function() return _G.PRJID end,
	PROJECT = function() return 1 end,
	HEART = function() return nvm.get("heart") end,
	IMEI = misc.getimei,
	IMSI = sim.getimsi,
	ICCID = sim.geticcid,
	RSSI = net.getrssi,
	MNC = function() return tonumber(net.getmnc()) end,
	MCC = function() return tonumber(net.getmcc()) end,
	CELLID = function() return tonumber(net.getci(),16) end,
	LAC = function() return tonumber(net.getlac(),16) end,
	CELLINFO = getcellinfo,--net.getcellinfo,
	CELLINFOEXT = getcellinfoext,--net.getcellinfoext,
	TA = net.getta,
	STATUS = getstatus,
	GPS = getgps,
	GPSTAT = getgpstat,
	FNCPARA = getfncpara,
	MOVSTA = function() return manage.getmovsta() end
}
local function getf(id)
	assert(tget[id] ~= nil,"getf nil id:" .. id)
	return tget[id]()
end

protoair.reget(getf)

local levt,lval,lerrevt,lerrval = "","","",""

--[[
��������datinactive
����  �����̨�Ͽ����Ӻ������豸
����  ����
����ֵ����
]]
local function datinactive()
    nvm.set("abnormal",true)
	--if nvm.get("workmod") == "SMS" or nvm.get("sleep") or nvm.get("gpsleep") then return end
	dbg.restart("AIRNODATA" .. ((levt ~= nil) and (",EVT=" .. levt) or "") .. ((lval ~= nil) and (",VAL=" .. lval) or "").. ((lerrevt ~= nil) and (",ERREVT=" .. lerrevt) or "") .. ((lerrval ~= nil) and (",ERRVAL=" .. lerrval) or ""))
	mqttconnfailcnt = 0
end

--[[
��������checkdatactive
����  �����3��KEEP_ALIVE_TIME+����ӻ�û���Ϻ�̨�������豸
����  ����
����ֵ����
]]
local function checkdatactive()
	if nvm.get("workmod") == "SMS" then return end
	sys.timer_start(datinactive,KEEP_ALIVE_TIME*1000*3+30000) --3������+�����
end

--[[
��������snd
����  �����̨���ͱ���
����  ��data,para,pos,ins
����ֵ��true�����ͳɹ���nil��false����ʧ��
]]
local function snd(data,para,pos,ins)
	return linkapp.scksnd(SCK_IDX,data,para,pos,ins)
end

--[[
��������chgalmrpt
����  ���͵籨���ϱ���ʵ��ֻ�����������ģ��Ƿ����͵͵籨���ɺ�̨����
����  ����
����ֵ����
]]
local function chgalmrpt()
	if nvm.get("guard") and not chg.getcharger() and chgalm then
		chgalm = false
		sys.dispatch("ALM_IND","CHG")
		heart()
		--startalmtimer("CHG",true)
	end
end

--[[
��������shkalmrpt
����  ���𶯱����ϱ���ʵ��ֻ�����������ģ��Ƿ������𶯱����ɺ�̨����
����  ����
����ֵ����
]]
local function shkalmrpt()
	print("shkalmrpt",nvm.get("guard"),shkalm)
	if nvm.get("guard") and shkalm then
		shkalm = false
		sys.dispatch("ALM_IND","SHK")
		heart()
		startalmtimer("SHK",true)
	end
end

--[[
��������almtimerfnc
����  ���͵硢�𶯱�����ʱ��������
����  ��tag�����ǵ͵籨�������𶯱���
����ֵ����
]]
function almtimerfnc(tag)
	print("almtimerfnc",tag)
	local val = nvm.get("guard")
	if tag == "CHG" then
		chgalm = val
		chgalmrpt()
	elseif tag == "SHK" then
		shkalm = val
	end
end

--[[
��������startalmtimer
����  ������������ʱ��
����  ��tag�����ǵ͵籨�������𶯱���
        val ��true�������򲻿���
����ֵ����
]]
function startalmtimer(tag,val)
	print("startalmtimer",tag,val,nvm.get("guard"))
	if nvm.get("guard") then
		if val then
			sys.timer_start(almtimerfnc,nvm.get("almfreq")*60000+5000,tag)
		end
	end
end

--[[
��������stopalmtimer
����  ��ͣ��������ʱ��
����  ��tag�����ǵ͵籨�������𶯱���
����ֵ����
]]
local function stopalmtimer(tag)
	print("stopalmtimer",tag)
	sys.timer_stop(almtimerfnc,tag)
end

--[[
��������alminit
����  ��������ʼ������ʼ���͵籨�����𶯱�������
����  ����
����ֵ����
]]
local function alminit()
	print("alminit",nvm.get("guard"))
	local val = nvm.get("guard")
	chgalm,shkalm = val,val
	stopalmtimer("CHG")
	stopalmtimer("SHK")
end

--[[
��������qrylocfnc
����  ��������λ
����  ����
����ֵ����
]]
local function qrylocfnc()
	locrpt("QRYLOC")
end

--[[
��������preloc
����  ��λ���ϱ�
����  ����
����ֵ����
]]
local function preloc()
	print("preloc",locshk)
	loc()
	--[[if locshk == "SHK" then
		local mod = nvm.get("fixmod")
		if mod == "LBS" then
			loc()
		elseif mod == "GPS" then
			loc()
		end
	end]]
end

--[[
��������loctimerfnc
����  ��λ�ö�ʱ�ϱ�
����  ����
����ֵ����
]]
local function loctimerfnc()
	print("loctimerfnc",locshk)
	if locshk == "SIL" then	locshk = "TMOUT" end
	preloc()
end

--[[
��������startloctimer
����  ������λ�ö�ʱ�ϱ���ʱ��
����  ����
����ֵ����
]]
function startloctimer()
	print("startloctimer",nvm.get("rptfreq"))
	sys.timer_start(loctimerfnc,nvm.get("rptfreq")*1000)
end

--[[
��������entopic
����  ��topic���
����  ��t��topic����
����ֵ���ַ���
]]
local function entopic(t)
	return "/v"..verno.."/device/"..tget["IMEI"]().."/"..t
end

--[[
��������starthearttimer
����  ������������ʱ�ϱ���ʱ��
����  ����
����ֵ����
]]
local function starthearttimer()
	print("starthearttimer",nvm.get("heart"))
	sys.timer_start(heart,nvm.get("heart")*1000)
end

--[[
��������locrpt
����  ��λ���ϱ�
����  ��r��λ����,w wifi�ȵ���Ϣ
����ֵ����
]]
function locrpt(r,w)
	if not mqttconn then return end
	local id,mod,extyp = protoair.LBS3,r or nvm.get("fixmod")
	if mod == "LBS" then
		id = nvm.get("lbstyp")==1 and protoair.LBS1 or protoair.LBS3
	elseif mod == "GPS" then
		id = gps.isfix() and (nvm.get("gpslbsmix") and protoair.GPSLBS1 or protoair.GPS) or (nvm.get("lbstyp")==1 and protoair.LBS1 or (nvm.get("gpslbsmix") and protoair.GPSLBS1 or protoair.LBS3))
	elseif mod == "QRYLOC" then
		id = protoair.GPSLBSWIFIEXT
		extyp = protoair.QRYPOS
	elseif mod == "KEYRPT" then
		id = protoair.GPSLBSWIFIEXT
		extyp = protoair.KEYPOS
	end	
	print("locrpt",id,w,r)
	local p = {}
	p.lbs1 = tget["LAC"]().."@"..tget["CELLID"]()
	p.lbs2 = tget["CELLINFOEXT"]()
	p.gpsfix = getgps().fix
	p.gps = getgps().lng.."@"..getgps().lat	
	return snd(mqtt.pack(mqtt.PUBLISH,{topic=entopic("devdata"),payload=protoair.pack(id,w,extyp)}),{typ="MQTTPUBLOC",val={typ=id,para=p}})
end

--[[
��������loc
����  ��λ���ϱ�
����  ��r��λ����,p wifi�ȵ���Ϣ
����ֵ����
]]
function loc(r,p)
	print("loc",gps.isfix(),r,nvm.get("gpsleep"),manage.getmovsta())
	startloctimer()
	if manage.getmovsta()=="SIL" then return end  --�˶�״̬��ֻ��λ�ò�����������ֹ״̬��ֻ�ϱ����������ϱ�λ��
	if gps.isfix() then
		local t = getgps()
		if manage.isgpsmove(t.lng,t.lat) then
			return locrpt(nil,p)
		else
			locshk = "SIL"
		end
	else
		if nvm.get("lbstyp")==1 and manage.islbs1move(tostring(tget["LAC"]()),tostring(tget["CELLID"]())) then
			return locrpt(nil,p)
		elseif nvm.get("lbstyp")==2 and manage.islbs2move(tget["CELLINFOEXT"]()) then
			return locrpt(nil,p)
		else
			locshk = "SIL"
		end
	end
end

--[[
��������heart
����  �����������ϱ�
����  ��v trueǿ���ϱ�����
����ֵ����
]]
function heart(v)
	print("heart",nvm.get("gpsleep"),mqttconn,manage.getmovsta(),v)
	starthearttimer()
	if not mqttconn then return end
	if manage.getmovsta()=="SIL" or v then--�˶�״̬��ֻ��λ�ò�����������ֹ״̬��ֻ�ϱ����������ϱ�λ��
		snd(mqtt.pack(mqtt.PUBLISH,{topic=entopic("devdata"),payload=protoair.pack(protoair.HEART)}),{typ="MQTTPUBHEART"})
	end
end

--[[
��������disconnect
����  ���Ͽ�����
����  ����
����ֵ����
]]
local function disconnect()
	snd(mqtt.pack(mqtt.DISCONNECT),"MQTTDISC")
end

--[[
��������pingreq
����  �����mqtt�Ƿ�Ͽ�����
����  ����
����ֵ����
]]
local function pingreq()
	snd(mqtt.pack(mqtt.PINGREQ))
	if not sys.timer_is_active(disconnect) then
		sys.timer_start(disconnect,(KEEP_ALIVE_TIME+30)*1000)
	end
end

--[[
��������enrptpara
����  ������Ҫ�ϱ��Ĳ������
����  ����
����ֵ���ַ���
]]
local function enrptpara(typ)
	local function enunsignshort(p)
		return pack.pack(">H",nvm.get(p))
	end	
	
	local proc =
	{
		rptfreq = {k=protoair.RPTFREQ,v=enunsignshort},
		almfreq = {k=protoair.ALMFREQ,v=enunsignshort},
		guard = {v=function() return schar(nvm.get("guard") and protoair.GUARDON or protoair.GUARDOFF) end},		
		fixmod = {v=function() return pack.pack("bb",protoair.FIXMOD,(nvm.get("fixmod")=="LBS") and 0 or ((nvm.get("fixmod")=="GPS") and 1 or 2)) end},
		workmod = {v=function() return pack.pack("bb",protoair.FIXMOD,(nvm.get("workmod")=="SMS") and 3 or ((nvm.get("workmod")=="GPS") and 4 or ((nvm.get("workmod")=="PWRGPS") and 5 or (nvm.get("workmod")=="LONGPS") and 6 or 7))) end},
	}
	if not proc[typ] then return "" end
	local ret = ""
	if proc[typ].k then ret = schar(proc[typ].k) end
	if proc[typ].v then ret = ret..proc[typ].v(typ) end
	return ret
end

local tpara,tparapend =
{
	"rptfreq","almfreq","guard","fixmod","workmod"
},{}

--[[
��������rptpara
����  ���ϱ�����
����  ����
����ֵ����
]]
local function rptpara(typ)
	if nvm.get("workmod") == "SMS" and typ~="workmod" then return end
	print("rptpara",typ,tget["IMEI"](),#tparapend)
	if typ then
		if tget["IMEI"]() ~= "" then
			for k,v in pairs(tpara) do
				if typ == v then
					mqttdup.rmv("PUBRPTPARA"..v)
					local dat,para = mqtt.pack(mqtt.PUBLISH,{qos=1,topic=entopic("devpararpt"),payload=protoair.pack(protoair.RPTPARA,enrptpara(v))})
					para.usr = v
					if not snd(dat,{typ="MQTTPUBRPTPARA",val=para},nil,true) then
						mqttpubrptparacb(para)
					else
						return true
					end
				end
			end
		else
			local fnd
			for i=1,#tparapend do
				if tparapend[i] == typ then fnd = true break end
			end
			if not fnd then
				for k,v in pairs(tpara) do
					if v == typ then tparapend[#tparapend+1] = typ end
				end
			end
		end
	else
		for i=1,#tparapend do
			if tparapend[i]~="workmod" then
				rptpara(tparapend[i])
			end
		end
		tparapend = {}
	end
end

--[[
��������connect
����  �����Ӻ�̨
����  ��cause
����ֵ����
]]
function connect(cause)
	if nvm.get("workmod") == "SMS" then return end
	linkapp.sckconn(SCK_IDX,cause,nvm.get("prot"),nvm.get("addr"),nvm.get("port"),ntfy,rcv)
end

--reconntimes��������
local reconntimes = 0
--[[
��������reconn
����  ��������̨
����  ����
����ֵ����
]]
local function reconn()
	if nvm.get("workmod") == "SMS" or nvm.get("gpsleep") then
		reconntimes = 0
		return
	end
	if reconntimes < 3 then
		reconntimes = reconntimes+1
		link.shut()
		connect(linkapp.NORMAL)
	else
		reconntimes = 0
		sys.timer_start(reconn,300000)
	end
end

--[[
��������connack
����  ������̨ack
����  ��packet�����Ӻ�̨���
����ֵ����
]]
local function connack(packet)
	print("connack",packet.suc)
	if packet.suc then
		mqttconn = true
		mqttdup.rmv("CONN")
		if nvm.get("workmodpend") then rptpara("workmod") end
		if nvm.get("gpsleep") or nvm.get("workmod")=="PWRGPS" or nvm.get("workmod")=="PWOFF" then
			heart()
		end
			if not sys.timer_is_active(heart) then starthearttimer() end
			mqttdup.rmv("SUB")
			local dat,para = mqtt.pack(mqtt.SUBSCRIBE,{topic={entopic("devparareq/+"),entopic("deveventreq/+")}})
			--print("connack",para.dup,common.binstohexs(para.seq))
			if not snd(dat,{typ="MQTTSUB",val=para}) then mqttsubcb(para) end
		--end		
	else
		mqttconnfailcnt = mqttconnfailcnt + 1
	end
end

--[[
��������devinfo
����  �������ն���Ϣ����
����  ����
����ֵ����
]]
function devinfo()
	if not mqttconn then return end
	snd(mqtt.pack(mqtt.PUBLISH,{topic=entopic("devdata"),payload=protoair.pack(protoair.INFO)}),{typ="MQTTPUBINFO"})
end

--[[
��������suback
����  �����ı���ack
����  ��packet���Ľ��
����ֵ����
]]
local function suback(packet)
	print("suback",common.binstohexs(packet.seq))
	mqttdup.rmv("SUB",nil,packet.seq)
	
	devinfo()
	
	if firstloc then
		preloc()
	else
		loc()
	end	
end

--[[
��������puback
����  ��publish ack
����  ��packet
����ֵ����
]]
local function puback(packet)	
	local typ = mqttdup.getyp(packet.seq) or ""
	print("puback",common.binstohexs(packet.seq),typ)
	if typ == "PUBDEVEVENTRSP"..protoair.RESET then
        nvm.set("abnormal",false)
		sys.timer_start(dbg.restart,2000,"AIRTCPSVR")  
	elseif typ == "PUBDEVEVENTRSP"..protoair.POWEROFF then
		sys.timer_start(sys.dispatch,3000,"REQ_PWOFF","SVR")
	elseif typ=="PUBRPTPARA".."workmod" then
		nvm.set("workmodpend",false)
	elseif smatch(typ,"^PUBQRYRCD&") then
        local seq,cur = smatch(typ,"PUBQRYRCD&(%d+)!(%d+)")
        sys.dispatch("SND_QRYRCD_CNF",true,seq,cur)
	end
	mqttdup.rmv(nil,nil,packet.seq)
end

--[[
��������fixmodpara
����  ������ģʽ�������޸�
����  ��p ����ģʽֵ
����ֵ��true
]]
local function fixmodpara(p)
	return nvm.set("workmod",p.val==3 and "SMS" or (p.val==4 and "GPS" or (p.val==5 and "PWRGPS" or (p.val==6 and "LONGPS" or "PWOFF"))),"SVR")
end

--[[
��������setpara
����  ���޸Ĳ���
����  ��packet ����
����ֵ��true
]]
local function setpara(packet)
	local procer,result = {
		[protoair.RPTFREQ] = "rptfreq",
		[protoair.ALMFREQ] = "almfreq",		
		[protoair.GUARDON] = {k="guard",v=true},
		[protoair.GUARDOFF] = {k="guard",v=false},		
		[protoair.FIXMOD] = fixmodpara,		
	}
	if procer[packet.cmd] then
		local typ = type(procer[packet.cmd])
		if typ == "function" then
			result = procer[packet.cmd](packet)
		elseif typ == "table" then
			if type(procer[packet.cmd].k) == "function" then
				result = procer[packet.cmd].k(packet,procer[packet.cmd].v)
			else
				result = nvm.set(procer[packet.cmd].k,procer[packet.cmd].v,"SVR")
			end
		else
			result = nvm.set(procer[packet.cmd],packet.val,"SVR")
		end		
	end
	mqttdup.rmv("PUBSETPARARSP"..packet.cmd)
	local dat,para = mqtt.pack(mqtt.PUBLISH,{qos=1,topic=entopic("devpararsp/"..(smatch(packet.topic,"devparareq/(.+)") or "")),payload=protoair.pack(protoair.SETPARARSP,packet.cmd,schar(result and 1 or 0))})
	para.usr = packet.cmd
	if not snd(dat,{typ="MQTTPUBSETPARARSP",val=para}) then mqttpubsetpararspcb(para) end
end

--[[
��������sendsms
����  �����Ͷ���
����  ��packet ����
����ֵ����
]]
local function sendsms(packet)
	if packet.coding == "UCS2" then
		local num,i = ""
		for i=1,#packet.num do
			print("sendsms",packet.num[i])
			if string.len(packet.num[i]) >= 5 and not string.match(num,packet.num[i]) then
				num = num..packet.num[i].."@"
			end
		end
		print("sendsms1",num)
		for i in string.gmatch(num,"(%d+)@") do
			sms.send(i,common.binstohexs(packet.data))
		end		
	end
end

--[[
��������dial
����  ������绰
����  ��packet ����
����ֵ����
]]
local function dial(packet)
	while #packet.num > 0 do
		sys.dispatch("CCAPP_ADD_NUM",table.remove(packet.num,1))
	end
	sys.dispatch("CCAPP_DIAL_NUM")
end

--[[
��������deveventrsp
����  �����������¼���Ӧ��
����  ��packet ����
����ֵ����
]]
local function deveventrsp(packet)
	mqttdup.rmv("PUBDEVEVENTRSP"..packet.id)
	local dat,para = mqtt.pack(mqtt.PUBLISH,{qos=1,topic=entopic("deveventrsp/"..(smatch(packet.topic,"deveventreq/(.+)") or "")),payload=protoair.pack(protoair.DEVEVENTRSP,packet.id,schar(1))})
	para.usr = packet.id
	if not snd(dat,{typ="MQTTPUBDEVEVENTRSP",val=para}) then mqttpubdeveventrspcb(para) end
end

--[[
��������qryloc
����  ��������λ
����  ��packet ����
����ֵ����
]]
local function qryloc(packet)
	--[[if not gpsapp.isactive(gpsapp.TIMERORSUC,{cause="QRYLOC"}) then
		gpsapp.open(gpsapp.TIMERORSUC,{cause="QRYLOC",val=120,cb=qrylocfnc})
	end]]
	deveventrsp(packet)
	qrylocfnc()
	sys.dispatch("SVR_QRY_LOC_IND")	
end

--[[
��������restore
����  ���ָ���������
����  ��packet ����
����ֵ����
]]
local function restore(packet)
	sys.dispatch("SVR_RESTORE_IND")
	deveventrsp(packet)
end

--[[
��������devqrypararsp
����  ����ѯ����Ӧ��
����  ��packet ����
����ֵ����
]]
local function devqrypararsp(packet,rsp)
	mqttdup.rmv("PUBDEVEVENTRSP"..packet.id..packet.val)
	local dat,para = mqtt.pack(mqtt.PUBLISH,{qos=1,topic=entopic("deveventrsp/"..smatch(packet.topic,"deveventreq/(.+)")),payload=protoair.pack(protoair.DEVEVENTRSP,packet.id,schar(packet.val)..rsp)})
	para.usr = packet.id..packet.val
	if not snd(dat,{typ="MQTTPUBDEVEVENTRSP",val=para}) then mqttpubdeveventrspcb(para) end
end

--[[
��������devqrypara
����  ����ѯ����
����  ��packet ����
����ֵ����
]]
local function qrypara(packet)
	local procer,rsp = {
		[protoair.VER] = function() return _G.PROJECT.."_".._G.VERSION end,
	}
	if procer[packet.val] then
		rsp = procer[packet.val]()
	end
	if rsp then devqrypararsp(packet,rsp) end
end

--[[
��������qryrcd
����  ������ʰ������
����  ��packet ����
����ֵ����
]]
local function qryrcd(packet)
	print("qryrcd",packet.val,packet.typ)
	deveventrsp(packet)
	sys.dispatch("QRY_RCD_IND",packet.val*1000,packet.typ)
end

--[[
��������sndqryrcdreq
����  ������¼���ļ�
����  ��s�������к�,
        w���ͷ�ʽ0��¼���ٷ� 1����¼�߷�,
        t����������,
        c��ǰ��������,
        tm��Ƶ�ļ�����,
        d��ǰ��������
����ֵ����
]]
local function sndqryrcdreq(s,w,t,c,tm,d)
	if not (s and w and t and c and tm and d) then sys.dispatch("SND_QRYRCD_CNF",false,s,c) return end
	mqttdup.rmv("PUBQRYRCD&"..s.."!"..c)
	local dat,para = mqtt.pack(mqtt.PUBLISH,{qos=1,topic=entopic("soundrecord"),payload=protoair.pack(protoair.QRYRCDREQ,s,w,t,c,0,tm,d)})
	para.usr = s.."!"..c
	if not snd(dat,{typ="MQTTPUBQRYRCD",val=para}) then 
	    sys.dispatch("SND_QRYRCD_CNF",false,s,c) 
    end
end

--[[
��������smsrptreq
����  �����յ��Ķ�����Ϣ�ϱ���̨
����  ��num����,
        data��������
        datetime�յ����ŵ�ʱ��
����ֵ��true
]]
local function smsrptreq(num,data,datetime)
    mqttdup.rmv("PUBSMSRPTREQ")
    local dat,para = mqtt.pack(mqtt.PUBLISH,{qos=1,topic=entopic("devdata"),payload=protoair.pack(protoair.SMSRPT,datetime,num,data)})
    if not snd(dat,{typ="MQTTPUBSMSRPTREQ",val=para}) then 
        sys.dispatch("SND_SMSRPT_CNF",false) 
    else
        sys.dispatch("SND_SMSRPT_CNF",true)
    end
    return true
end

--[[
��������ccrptreq
����  ���������ȥ���ϱ���̨
����  ��cctyp �绰���ͣ�0�����磬1��ȥ��
        num����,
        starttm �����ȥ�����ʼʱ��
        ringtm����ʱ��
        totaltmͨ����ʱ��
����ֵ��true
]]
local function ccrptreq(cctyp,ccnum,starttm,ringtm,totaltm)
    mqttdup.rmv("PUBCCRPTREQ")
    local dat,para = mqtt.pack(mqtt.PUBLISH,{qos=1,topic=entopic("devdata"),payload=protoair.pack(protoair.CCRPT,cctyp,ccnum,starttm,ringtm,totaltm)})
    if not snd(dat,{typ="MQTTPUBCCRPTREQ",val=para}) then sys.dispatch("SND_CCRPT_CNF",false) end
    return true
end

local cmds = {
	[protoair.SETPARA] = setpara,
	[protoair.SENDSMS] = sendsms,
	[protoair.DIAL] = dial,
	[protoair.QRYLOC] = qryloc,
	[protoair.RESET] = deveventrsp,
	[protoair.POWEROFF] = deveventrsp,	
	[protoair.RESTORE] = restore,
	[protoair.QRYPARA] = qrypara,
	[protoair.QRYRCD] = qryrcd,
}

--[[
��������publish
����  ������mqtt��������Ϣ
����  ��mqttpacket PUBLISH����
����ֵ����
]]
local function publish(mqttpacket)	
	local packet = protoair.unpack(mqttpacket.payload)
	if mqttpacket.qos == 1 then snd(mqtt.pack(mqtt.PUBACK,mqttpacket.seq)) end
	if packet and packet.id and cmds[packet.id] then
		packet.seq = mqttpacket.seq
		packet.topic = mqttpacket.topic
		cmds[packet.id](packet)
	end
end

--[[
��������pingrsp
����  ��PINGӦ��
����  ��mqttpacket PUBLISH����
����ֵ����
]]
local function pingrsp()
	sys.timer_stop(disconnect)
end

local mqttcmds = {
	[mqtt.CONNACK] = connack,
	[mqtt.SUBACK] = suback,
	[mqtt.PUBACK] = puback,
	[mqtt.PUBLISH] = publish,
	[mqtt.PINGRSP] = pingrsp,
}

--[[
��������mqttconncb
����  �����ӻص�����
����  ��v
����ֵ����
]]
local function mqttconncb(v)
	--print("mqttconncb",common.binstohexs(v))
	mqttdup.ins("CONN",v)
end

--[[
��������mqttsubcb
����  �����Ļص�����
����  ��v
����ֵ����
]]
function mqttsubcb(v)
	mqttdup.ins("SUB",mqtt.pack(mqtt.SUBSCRIBE,v),v.seq)
end

--[[
��������mqttdupcb
����  ��dup�ص�����
����  ��v
����ֵ����
]]
local function mqttdupcb(v)
	mqttdup.rsm(v)
end

--[[
��������mqttdiscb
����  ��mqtt�Ͽ��ص�����
����  ����
����ֵ����
]]
local function mqttdiscb()
	linkapp.sckdisc(SCK_IDX)
end

--[[
��������mqttpublocb
����  ���ϱ�λ�ûص�����
����  ��v��r
����ֵ����
]]
local function mqttpublocb(v,r)
	startloctimer()
	locshk = "SIL"
	if r then
		sys.dispatch("ITV_WAKE_SNDSUC")
		starthearttimer()	
		firstloc = true
		
		local function lbs1cb()
			manage.setlastlbs1(smatch(v.para.lbs1,"(%d+)@"),smatch(v.para.lbs1,"@(%d+)"),true)
		end
		
		local function lbs2cb()
			manage.setlastlbs2(v.para.lbs2,true)
		end
		
		local function gpscb()
			manage.setlastgps(smatch(v.para.gps,"([%.%d]+)@"),smatch(v.para.gps,"@([%.%d]+)"))
			manage.setlastlbs1(smatch(v.para.lbs1,"(%d+)@"),smatch(v.para.lbs1,"@(%d+)"))
			manage.setlastlbs2(v.para.lbs2)
		end
		
		local function gpslbscb()
			if v.para.gpsfix then manage.setlastgps(smatch(v.para.gps,"([%.%d]+)@"),smatch(v.para.gps,"@([%.%d]+)")) end
			manage.setlastlbs2(v.para.lbs2,not v.para.gpsfix)
		end
		
		local function gpslbswificb()
			if v.para.gpsfix then manage.setlastgps(smatch(v.para.gps,"([%.%d]+)@"),smatch(v.para.gps,"@([%.%d]+)")) end
			if v.para.wifi and #v.para.wifi > 0 then
				manage.setlastwifi(v.para.wifi)
				manage.setlastwifictl(v.para.wifi)
			end
			manage.setlastlbs2(v.para.lbs2,not (v.para.gpsfix or (v.para.wifi and #v.para.wifi > 0)))
		end
		
		local procer =
		{
			[protoair.LBS1] = lbs1cb,
			[protoair.LBS2] = lbs2cb,
			[protoair.LBS3] = lbs2cb,
			[protoair.GPS] = gpscb,
			[protoair.GPSLBS] = gpslbscb,
			[protoair.GPSLBS1] = gpslbscb,
			[protoair.GPSLBSWIFIEXT] = gpslbswificb,
		}
		if procer[v.typ] then procer[v.typ]() end
	end
end

--[[
��������mqttpubheartcb
����  ���ϱ������ص�����
����  ��v��r
����ֵ����
]]
local function mqttpubheartcb(v,r)
	--[[if nvm.get("sleep") then
		sys.dispatch("ITV_SLEEP_REQ")
	else]]if nvm.get("gpsleep") then
		--sys.dispatch("ITV_GPSLEEP_REQ")
		end
	-- else
		if r then starthearttimer() end
	--end
	if r then sys.dispatch("ITV_WAKE_SNDSUC") end
end

--[[
��������mqttpubrptparacb
����  ���ϱ������ص�����
����  ��v
����ֵ����
]]
function mqttpubrptparacb(v)
	print("mqttpubrptparacb",v.usr)
	mqttdup.ins("PUBRPTPARA"..v.usr,mqtt.pack(mqtt.PUBLISH,v),v.seq)
end

--[[
��������mqttpubsetpararspcb
����  �����ò����ص�����
����  ��v
����ֵ����
]]
function mqttpubsetpararspcb(v)
	print("mqttpubsetpararspcb",v.usr)
	mqttdup.ins("PUBSETPARARSP"..v.usr,mqtt.pack(mqtt.PUBLISH,v),v.seq)
end

--[[
��������mqttpubdeveventrspcb
����  ���¼�Ӧ�Իص�����
����  ��v
����ֵ����
]]
function mqttpubdeveventrspcb(v)
	print("mqttpubdeveventrspcb",v.usr)
	mqttdup.ins("PUBDEVEVENTRSP"..v.usr,mqtt.pack(mqtt.PUBLISH,v),v.seq)
end

--[[
��������mqttpubqryrcb
����  ��ʰ���ϱ��ص�����
����  ��v
����ֵ����
]]
function mqttpubqryrcb(v)
    print("mqttpubqryrcb",v.usr)
    mqttdup.ins("PUBQRYRCD&"..v.usr,mqtt.pack(mqtt.PUBLISH,v),v.seq)
end

--[[
��������mqttpubsmsrptreqcb
����  �������ϱ��ص�����
����  ��v
����ֵ����
]]
function mqttpubsmsrptreqcb(v)
    print("mqttpubsmsrptreqcb",v.usr)
    mqttdup.ins("PUBSMSRPTREQ",mqtt.pack(mqtt.PUBLISH,v),v.seq)
end

local sndcbs =
{
	MQTTCONN = mqttconncb,
	MQTTSUB = mqttsubcb,
	MQTTDUP = mqttdupcb,
	MQTTDISC = mqttdiscb,
	MQTTPUBLOC = mqttpublocb,
	MQTTPUBHEART = mqttpubheartcb,
	MQTTPUBRPTPARA = mqttpubrptparacb,
	MQTTPUBSETPARARSP = mqttpubsetpararspcb,
	MQTTPUBDEVEVENTRSP = mqttpubdeveventrspcb,
	MQTTPUBQRYRCD = mqttpubqryrcb,
	MQTTPUBSMSRPTREQ=mqttpubsmsrptreqcb,
}

--[[
��������enpwd
����  �����봦��
����  ��s���������
����ֵ������������
]]
local function enpwd(s)
	local tmp,ret,i = 0,""
	for i=1,string.len(s) do
		tmp = bit.bxor(tmp,string.byte(s,i))
		if i % 3 == 0 then
			ret = ret..schar(tmp)
			tmp = 0
		end
	end
	return common.binstohexs(ret)
end

--[[
��������ntfy
����  �����յ���CONNECT��STATE��DISCONNECT��SEND�¼�����Ӧ����
����  ��idx,evt,result,item
����ֵ����
]]
function ntfy(idx,evt,result,item)
	print("ntfy",evt,result)
	if evt == "CONNECT" then
		if result then
			if nvm.get("workmod") == "SMS" then
				linkapp.sckdisc(SCK_IDX)
			else
				sys.timer_stop(reconn)
				reconntimes = 0
				rests = ""
				
				local dat = mqtt.pack(mqtt.CONNECT,KEEP_ALIVE_TIME,tget["IMEI"](),tget["IMEI"](),enpwd(tget["IMEI"]()))
				mqttdup.rmv("CONN")
				if not snd(dat,"MQTTCONN") then mqttconncb(dat) end
				sys.dispatch("LINKAIR_CONNECT_SUC")
			end
		else
			sys.timer_start(reconn,5000)
		end
	elseif evt == "STATE" and result == "CLOSED" or evt == "DISCONNECT" then
		if nvm.get("gpsleep") then
			reconntimes,mqttconnfailcnt = 0,0
		else
			if mqttconnfailcnt <= 3 then sys.timer_start(reconn,5000) end
		end		
		sys.timer_stop(pingreq)
		mqttdup.rmvall()
		mqttconn = false
		sys.dispatch("LINKAIR_CONNECT_FAIL")
	elseif evt == "SEND" then
		if item.para then
			local typ = type(item.para) == "table" and item.para.typ or item.para
			local val = type(item.para) == "table" and item.para.val or item.data
			if sndcbs[typ] then sndcbs[typ](val,result)	end
		end
	end

	if smatch((type(result)=="string") and result or "","ERROR") then
		linkapp.sckdisc(SCK_IDX)
	end
end

--[[
��������rcv
����  �����ղ��������յ��ı���
����  ��id,data
����ֵ����
]]
function rcv(id,data)
	print("rcv",common.binstohexs(data))
	sys.timer_start(pingreq,KEEP_ALIVE_TIME*1000/2)
	rests = rests..data

	local f,h,t = mqtt.iscomplete(rests)

	while f do
		data = ssub(rests,h,t)
		rests = ssub(rests,t+1,-1)
		local packet = mqtt.unpack(data)
		if packet and packet.typ and mqttcmds[packet.typ] then
			mqttcmds[packet.typ](packet)
			if packet.typ ~= mqtt.CONNACK and packet.typ ~= mqtt.SUBACK then
				checkdatactive()				
			end
		end
		f,h,t = mqtt.iscomplete(rests)
	end
end

--[[
��������mqttdupind
����  ���ط�����
����  ��s
����ֵ����
]]
local function mqttdupind(s)
	if not snd(s,"MQTTDUP") then mqttdupcb(s) end
end

--[[
��������mqttdupfail
����  ����Ϣ�ط�ʧ��
����  ��t,s
����ֵ����
]]
local function mqttdupfail(t,s)
    if smatch(t,"^PUBQRYRCD&") then
        local seq,cur = smatch(t,"PUBQRYRCD&(%d+)!(%d+)")
        sys.dispatch("SND_QRYRCD_CNF",false,seq,cur)
    end
end

--[[
��������shkind
����  ������Ϣ������
����  ����
����ֵ��true
]]
local function shkind()
	print("shkind",locshk)
	local oldflg = locshk
	locshk = "SHK"
	if oldflg == "TMOUT" then
		preloc()
	end
	
	shkcnt = shkcnt + 1
	return true
end

--[[
��������chgind
����  ��DEV_CHG_IND��Ϣ������
����  ��evt�����Ϣ�¼�
����ֵ��true
]]
local function chgind(evt)
	if nvm.get("workmod") == "SMS" then return true end
	if evt ~= "CHARGER" then return true end
	chgalmrpt()
	if chg.getcharger() then
		chgalm = false
		stopalmtimer("CHG")
	elseif not sys.timer_is_active(almtimerfnc,"CHG") then
		startalmtimer("CHG",nvm.get("guard"))
	end
	return true
end

--[[
��������cconnect
����  ���绰��ͨ����ص�datinactive��ʱ��
����  ����
����ֵ����
]]
local function cconnect()
	--if nvm.get("workmod") == "SMS" then return end
	sys.timer_stop(datinactive)
end

--[[
��������ccdisc
����  ���绰�ҶϺ�������̨
����  ����
����ֵ����
]]
local function ccdisc()
	if nvm.get("workmod") == "SMS" then return end
	checkdatactive()
	reconntimes = 0
	connect(linkapp.NORMAL)
end

--[[
��������delaysmsmod
����  ����ʱ���Ź���ģʽ���л�������ģʽ�����޶��Ź���ģʽ�����Դ˺�����ʱδ�õ�
����  ����
����ֵ����
]]
local function delaysmsmod()
	linkapp.sckclrsnding(SCK_IDX)
	link.shut()
	cconnect()
end

--[[
��������workmodind
����  ������ģʽ�л�������
����  ��r,rpt
����ֵ����
]]
local function workmodind(r,rpt)
	if nvm.get("workmod") == "SMS" then
		sys.timer_start(delaysmsmod,10000)
		--delaysmsmod()
	else
		sys.timer_stop(delaysmsmod)
		locshk,firstloc,firstgps = "SIL"
		chgalm,shkalm = true,true
		alminit()
		manage.resetlastloc()
		ccdisc()
	end
	if not rpt and r~="SVR" then
		nvm.set("workmodpend",true)
	end
	heart()
end

--[[
��������gpstaind
����  ��gps�¼�������
����  ��evt gps�¼�
����ֵ��true
]]
local function gpstaind(evt)
	if nvm.get("workmod") == "SMS" then return end
	if evt == gps.GPS_LOCATION_SUC_EVT and manage.getlastyp() ~= "GPS" --[[and not firstgps]] then
		--if loc() then firstgps=true end
	end
	return true
end

--[[
��������parachangeloc
����  ��λ���ϱ�Ƶ�ʸı���߶�λģʽ�ı䣬�ϱ�һ��λ����Ϣ
����  ����
����ֵ����
]]
local function parachangeloc()
	locshk = "SHK"
	preloc()
end

--[[
��������rptgpsleep
����  ��gps�رգ��ϱ�������
����  ����
����ֵ����
]]
local function rptgpsleep()
	if nvm.get("gpsleep") then
		heart()
	end
end

--[[
��������stachange
����  ���豸���˶��л�����ֹ״̬���ϱ�������
����  ����
����ֵ��true
]]
local function stachange()
	if manage.getmovsta()=="SIL" then
		heart()
	end
    return true
end

--[[
��������tparachangeind
����  ���ɷǷ��������޸��˲��������޸ĺ�Ĳ����ϱ���̨
����  ��k,kk,v,r
����ֵ��true
]]
local function parachangeind(k,v,r)
	print("parachangeind",k,r)
	local rpt
	if r ~= "SVR" and nvm.get("workmod") ~= "SMS" then
		rpt = rptpara(k)
	end
	local procer =
	{
		rptfreq = parachangeloc,
		almfreq = alminit,
		guard = alminit,
		workmod = workmodind,
		fixmod = parachangeloc,
		heart = devinfo,
		--gpsleep = rptgpsleep,	
	}
	if procer[k] then procer[k](r,rpt) end
	return true
end

--[[
��������tparachangeind
����  ���ɷǷ��������޸��˲��������޸ĺ�Ĳ����ϱ���̨
����  ��k,kk,v,r
����ֵ��true
]]
local function tparachangeind(k,kk,v,r)
	if r ~= "SVR" then
		rptpara(k)
	end
	return true
end

--[[
��������imeirdy
����  ��IMEI��ȡ�ɹ��������̨�ϱ�tpara���еĲ���ֵ
����  ����
����ֵ����
]]
local function imeirdy()	
	rptpara()
end

--[[local function keyind()
	if nvm.get("workmod")~="LONGPS" then
		nvm.set("lastworkmod",nvm.get("workmod"),"KEY",false)
		nvm.set("workmod","LONGPS","KEY",false)
		nvm.flush()
	else
		nvm.set("workmod",nvm.get("lastworkmod"),"KEY")
	end
	return true
end]]

--�ػ�ԭ��ֵ,0x00�����ػ�,0x01�͵�ػ�
local pwoffcause

--[[
��������getpwoffcause
����  ����ȡ�ػ�ԭ��ֵ
����  ����
����ֵ���ػ�ԭ��ֵ
]]
function getpwoffcause()
	return pwoffcause
end

--[[
��������delpwoffcause
����  ��ɾ���ػ�ԭ��ֵ
����  ����
����ֵ����
]]
function delpwoffcause()
    pwoffcause=nil
end

--[[
��������rsp_pwoff
����  ��Ӧ��ػ�����1.������˺��벻Ϊ�գ������˺��뷢�͹ػ��ɹ����� 2���������� 3ִ�йػ�����
����  ��tag �ػ�ԭ��
����ֵ����
]]
local function rsp_pwoff(tag)
	if nvm.get("adminum")~="" then
		smsapp.send(nvm.get("adminum"),"�ػ��ɹ���")
	end
	if tag == "BAT_LOW" then
		pwoffcause=1
	end
	
	heart() 
    nvm.set("abnormal",false)
	sys.timer_start(rtos.poweroff,6000)
	return true
end

--keyrptpos true��ʾ�������µ�ʱ����Ҫ�ϱ�λ����Ϣ��false��nil���ϱ�����
--key_val_sta ��ǰ�����״̬��Ϣ�����λ[7:7]��ʾ����״̬��0���̰���1������[6:0]��ʾ����ֵ��0��������1״̬����
local keyrptpos,key_val_sta = true
--[[
��������resetkeyrptposflg
����  ���ָ����������Ƿ���Ҫ�ϱ�λ����Ϣ��flagֵ
����  ����
����ֵ����
]]
local function resetkeyrptposflg()
	keyrptpos = true
end

--[[
��������delkeyvalsta
����  ����ȡ����״ֵ̬
����  ����
����ֵ������״ֵ̬
]]
function getkeyvalsta()
	return key_val_sta
end

--[[
��������delkeyvalsta
����  ��ɾ������״ֵ̬
����  ����
����ֵ����
]]
function delkeyvalsta()
	key_val_sta=nil
end

--[[
��������keyrpt
����  ���ϱ�λ�ã�λ������Ϊ�����ϱ�
����  ����
����ֵ��true
]]
local function keyrpt() 
	locrpt("KEYRPT")
end

--[[
��������keyind
����  �������ǳ������Ƕ̰���һ��������N�����������ϱ�һ��λ����Ϣ��N-1������
����  ��k����ֵ
����ֵ��true
]]
local function keyind(k)
	print("keyind",k,keyrptpos,key_val_sta)
	if keyrptpos then
		keyrptpos=false
		sys.timer_start(resetkeyrptposflg,60000)
		if gps.isfix() then
		    keyrpt()
		else
		    sys.timer_start(keyrpt,8000)
		end
	else
		heart(true)
	end
	return true
end

--[[
��������shortkey
����  ���̰�������Ϣ������
����  ��k����ֵ
����ֵ��true
]]
local function shortkey(k)
    --key_val_sta���λ[7:7]��ʾ����״̬��0���̰���1������[6:0]��ʾ����ֵ��0��������1״̬��
	key_val_sta=0x0
	keyind(k)
	return true
end

--[[
��������longkey
����  ������������Ϣ������
����  ��k����ֵ
����ֵ��true
]]
local function longkey(k)
    --key_val_sta���λ[7:7]��ʾ����״̬��0���̰���1������[6:0]��ʾ����ֵ��0��������1״̬��
	key_val_sta=0x80
	keyind(k)
	return true
end

local procer =
{
	MQTT_DUP_IND = mqttdupind,
	MQTT_DUP_FAIL = mqttdupfail,
	DEV_SHK_IND = shkind,
	DEV_CHG_IND = chgind,
	CCAPP_CONNECT = cconnect,
	CCAPP_DISCONNECT = ccdisc,
	[gps.GPS_STATE_IND] = gpstaind,
	PARA_CHANGED_IND = parachangeind,
	TPARA_CHANGED_IND = tparachangeind,
	IMEI_READY = imeirdy,
	--MMI_KEYPAD_FIVETAP_IND = keyind,
	MMI_KEYPAD_LONGPRESS_IND = longkey,
	MMI_KEYPAD_IND = shortkey,
	REQ_PWOFF = rsp_pwoff,
	SND_QRYRCD_REQ = sndqryrcdreq,
	SMS_RPT_REQ = smsrptreq,
	CCRPT_REQ = ccrptreq,
    STA_CHANGE = stachange,
}

--ע��app��Ϣ������
sys.regapp(procer)
--���3��KEEP_ALIVE_TIME+����ӻ�û���Ϻ�̨�������豸
checkdatactive()
net.startquerytimer()
--���Ӻ�̨
connect(linkapp.NORMAL)

