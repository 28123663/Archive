--[[
ģ�����ƣ�ָʾ��
ģ�鹦�ܣ�����������豸��ĳЩ״̬�ò�ͬ�Ƶ���ɫ���Ƶ���˸Ƶ��������ʾ
ģ������޸�ʱ�䣺2017.02.13
]]
module(...,package.seeall)

local appid

--[[
1-5�����ȼ��ɵ͵��ߣ�
	IDLE:���Ƴ���	
	CHGING:����У���Ƴ���
	CHGFULL:�������̵Ƴ������������
	LOWVOL:������������λ�����ҵ�ѹ����3.6V���������
	LINKERR:����һ���Ӻ��豸���̨û�н������ӣ��̵����������60��û�б仯�����Զ������
	LINKSUC:����һ���Ӻ��豸���̨���ӳɹ����̵Ƴ������������60��û�б仯�����Զ������
	GPSFIXFAIL: �����ɹ����ٴ�GPSû�ж�λ�ɹ�����������������GPSʱ�䳬��120���Ӻ���û�ж�λ�ɹ������Զ������
	GPSFIXSUC:GPS��λ�ɹ������Ƴ��������60����û�б仯�����Զ������
	
	
	SHORTKEY:�����̰�5�Σ��̵���һ��
	LONGKEY:������������һ��
	FAC:���������У�������������˸
1-3��״̬��
	INACTIVE:δ����
	PEND:�ȴ�������
	ACTIVE:����
--]]
--���ƵƵ����ȼ�
local IDLE,CHGING,CHGFULL,WORKSTA,LINKERR,LINKSUC,GPSFIXFAIL,GPSFIXSUC,SHORTKEY,LONGKEY,GSMSTA2,GSMSTA1,GPSSTA2,GPSSTA1,LOWVOL,FAC,PWOFF,PRIORITYCNT = 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,17
local INACTIVE,PEND,ACTIVE = 1,2,3
local tcause = {}
local linksuc,pwoffcause
--���պ���������ÿ����ռ��2��λ�ã�ÿ��λ�ÿ��������Ƿ���Ч���Ƿ�������Լ���Ӧ��ʱ��(Ĭ��1����)
local tledpin = 
{
	[pmd.KP_LEDR]=0,
	[pmd.KP_LEDG]=0,
	[pmd.KP_LEDB]=0,
}
local tled,ledcnt,ledpos,ledidx = {},3,2,1

--[[
��������isvalid
����  ���Ƿ�����Ч�ĵ�
����  ����
����ֵ����
]]
local function isvalid()
	local i
	for i=1,ledpos*ledcnt do
		if tled[i].valid then return true end
	end
end

--[[
��������init
����  ����ʼ����ֻ��IDLEΪ����״̬���������ȼ�״̬Ϊ�Ǽ�����պ���������ÿ����ռ��2��λ�ã�ÿ��λ��������Ч�����������Լ���Ӧ��ʱ��(Ĭ��1����)
����  ����
����ֵ����
]]
local function init()
	local i
	--ֻ��IDLEΪ����״̬���������ȼ�״̬Ϊ�Ǽ���
	tcause[IDLE] = ACTIVE
	for i=IDLE+1,PRIORITYCNT do
		tcause[i] = INACTIVE
	end
	
    --���պ���������ÿ����ռ��2��λ�ã�ÿ��λ��������Ч�����������Լ���Ӧ��ʱ��(Ĭ��1����)
	for i=1,ledpos*ledcnt do
		tled[i] = {}
		tled[i].pin = (i > ledpos*(ledcnt-1)) and pmd.KP_LEDB or((i > ledpos*(ledcnt-2)) and pmd.KP_LEDG or pmd.KP_LEDR)
		tled[i].valid = true
		tled[i].on = false
		tled[i].prd = 1000
	end
end

--[[
��������starttimer
����  ����ʱ��
����  ��idx,cb,prd
����ֵ����
]]
local function starttimer(idx,cb,prd)
	if tcause[idx] == ACTIVE and not sys.timer_is_active(cb) then
		sys.timer_start(cb,prd)
	end
end

--[[
��������proc
����  �����ƵƵ�����
����  ����
����ֵ����
]]
local function proc()
	if not isvalid() then return end
	local i = ledidx
	while true do
		if tled[i].valid then			
			print("light.proc",i,tled[i].on,tled[i].prd)
			local k,v
			for k,v in pairs(tledpin) do
				if k ~= tled[i].pin and v ~= 0 then
					pmd.ldoset(0,k)
					tledpin[k] = 0
					print("light.ldo",k,0)
				end
			end
			local flag,pin = (tled[i].on and 1 or 0),tled[i].pin
			if tledpin[pin] ~= flag then
				pmd.ldoset(flag,pin)
				tledpin[pin] = flag
				--print("light.ldo",pin,flag)
			end			
			starttimer(LONGKEY,longkeyend,500)
			starttimer(SHORTKEY,shortkeyend,500)
			sys.timer_start(proc,tled[i].prd)
			ledidx = (i+1 > ledcnt*ledpos) and 1 or (i+1)
			if tcause[IDLE] == ACTIVE then
				tled[i].valid = false
			end
			return
		else
			i = (i+1 > ledcnt*ledpos) and 1 or (i+1)
		end
	end
end

--[[
��������updflicker
����  �����ƵƵ���˸
����  ��head,tail,onprd,offprd
����ֵ����
]]
local function updflicker(head,tail,onprd,offprd)
	--print("light.updflicker",head,tail,onprd,offprd)
	local j
	--[[for j=1,ledpos*ledcnt do
		print("light tled["..j.."].valid",tled[j].valid)
		print("light tled["..j.."].on",tled[j].on)
		print("light tled["..j.."].onprd",tled[j].prd)
	end]]
	for j=1,ledpos*ledcnt do
		if j>=head and j<=tail then
			tled[j].valid = true
			tled[j].on = (j%ledpos == 1)
			tled[j].prd = tled[j].on and onprd or offprd
		else
			tled[j].valid = false
		end			
	end
	--[[for j=1,ledpos*ledcnt do
		print("light tled["..j.."].valid",tled[j].valid)
		print("light tled["..j.."].on",tled[j].on)
		print("light tled["..j.."].prd",tled[j].onprd)
	end]]
end

--[[
��������updled
����  �����صƵ���ʾ
����  ����
����ֵ����
]]
local function updled()
	local i,idx
	for i=IDLE,PRIORITYCNT do
		--print("light.updled",i,tcause[i])
		if tcause[i] == ACTIVE then idx=i break end
	end
	print("light.updled",idx)
	if idx == FAC then
		updflicker(1,6,1000,1000)
	elseif idx == PWOFF then
		updflicker(1,6,1000,1000)
	elseif idx == LONGKEY then
		updflicker(5,5,500)
	elseif idx == SHORTKEY then
		updflicker(3,3,500)
	elseif idx == CHGFULL then
		updflicker(3,3,1000)	
	elseif idx == CHGING then
		updflicker(1,1,1000)
	elseif idx == GPSFIXFAIL then
		updflicker(5,6,1000,1000)
	elseif idx == GPSFIXSUC then
		updflicker(5,5,1000)
	elseif idx == WORKSTA then
		updflicker(3,4,1000,1000)
	elseif idx == LINKERR then
		updflicker(3,4,1000,1000)
	elseif idx == LINKSUC then
		updflicker(3,3,1000)
	elseif idx == LOWVOL then
		updflicker(1,2,1000,1000)
	elseif idx == GSMSTA1 then
		updflicker(3,4,100,200)
	elseif idx == GSMSTA2 then
		updflicker(3,3,1000)
	elseif idx == GPSSTA1 then
		updflicker(5,6,100,200)
	elseif idx == GPSSTA2 then
		updflicker(5,5,1000)
	elseif idx == IDLE then
		updflicker(2,2,1000,1000)
	end
	if not sys.timer_is_active(proc) then proc() end
end

--[[
��������updcause
����  ������Ƶ���ʾ
����  ��idx���ȼ�,val true�򿪵� ��false�رյ�
����ֵ����
]]
local function updcause(idx,val)
	local i,pend,upd
	print("light.updcause",idx,val)
	for i=1,PRIORITYCNT do
		print("light tcause["..i.."]="..tcause[i])
	end
	if val then--�򿪵Ƶ���ʾ
        --��������ȼ����ߵ�״̬��������ʾ��ȴ���ʾ������ȴ�����
		for i=idx+1,PRIORITYCNT do
			if tcause[i] == PEND or tcause[i] == ACTIVE then
				tcause[idx] = PEND
				pend = true
				break
			end
		end
        --����ȴ�����Ϊ���ұ�״̬��Ϊ����״̬������״̬��Ϊ����״̬
		if not pend and tcause[idx] ~= ACTIVE then
			tcause[idx] = ACTIVE
            --������ڱ����ȼ���״̬��Ϊ����״̬�ģ��򽫵��ڱ�״̬��״̬����Ϊ�ȴ�״̬
			for i=1,idx-1 do
				if tcause[i] == ACTIVE then tcause[i] = PEND end
			end
			upd = true
		end
	else--�رյƵ���ʾ
		if tcause[idx] == ACTIVE then
			for i=idx-1,1,-1 do
				if tcause[i] == PEND then tcause[i] = ACTIVE break end
			end
			upd = true
		end
		tcause[idx] = INACTIVE
	end
	--[[print("light.updcause",pend,upd)
	for i=1,PRIORITYCNT do
		print("light tcause["..i.."]="..tcause[i])
	end]]
	if upd then updled() end
end

--[[
��������chgind
����  ��������������У���Ƴ�����
        ���������������̵Ƴ�����
        ���������λ����ƣ������̵ƣ���
        �͵�ѹ��ʾ������ ������������λ�����ҵ�ѹ����3.6V�����������
����  ��evt,val
����ֵ��true
]]
local function chgind(evt,val)
	print("light.chgind",evt,val,pwoffcause)
	if evt == "CHG_STATUS" then
		if val == 0 then
			updcause(CHGING,false)
			updcause(CHGFULL,false)
		elseif val == 1 then
			if pwoffcause == "VOL_LEV0" or pwoffcause == "BAT_LOW" then
				updcause(PWOFF,false)
			end
			updcause(LOWVOL,false)
			updcause(CHGFULL,false)
			updcause(CHGING,true)
		elseif val == 2 then
			if pwoffcause == "VOL_LEV0" or pwoffcause == "BAT_LOW" then
				updcause(PWOFF,false)
			end
			updcause(LOWVOL,false)
			updcause(CHGING,false)
			updcause(CHGFULL,true)
		end
	elseif evt == "BAT_LOW1" then
		if val then
			updcause(LOWVOL,true)
		else
			updcause(LOWVOL,false)
		end
	end
	return true
end

local keycnt,longkeycnt,leftm,keyflag=0,0,32
--[[
��������resetkey
����  ���ָ����ƶ̰���������ʾ��һЩ����ֵ
����  ����
����ֵ����
]]
local function resetkey()
	keycnt,leftm,keyflag = keycnt+1,32
	--updcause(GSMSTA2,false)
end

--[[
��������checkleftm
����  �����㳤����̰�ʱ����ʾ��ʣ��ʱ�䣬���ʣ��ʱ�䲻��3�룬��ʾ3��
����  ����
����ֵ����
]]
local function checkleftm()
	print("light.checkleftm:",leftm)
	if leftm>=4 then
		sys.timer_start(checkleftm,1000)
		leftm = leftm-1
	end
end

--[[
��������keyind
����  ���̰����������̵ƿ���2��Ȼ��������ʾGSM�����������ٰ����𣨲��̰ܶ�����������������30����Զ�Ϩ��
        �̵�һֱ��������ʾGSMδ�������ӣ��ٰ����𣨲��̰ܶ�����������������30����Զ�Ϩ��
����  ����
����ֵ����
]]
local function keyind()
	print("light.keyind ",keycnt,linksuc,keyflag)
	if keyflag == "LNGKEY" then
		keylngpresind()
		return true
	end
	keyflag = "SHORTKEY"
	keycnt = keycnt+1
	if keycnt%2 == 1 then--��ʾGSM����״̬
		updcause(GSMSTA1,true)       
		if linksuc then
			sys.timer_start(updcause,2000,GSMSTA1,false)
			updcause(GSMSTA2,true)
			sys.timer_start(updcause,32000,GSMSTA2,false)            
		else
			sys.timer_start(updcause,32000,GSMSTA1,false)
		end
		sys.timer_start(checkleftm,1000)
		sys.timer_start(resetkey,32000)
	else--�ر�GSM����״̬��ʾ
		sys.timer_stop(updcause,GSMSTA1,false)
		sys.timer_stop(updcause,GSMSTA2,false)
		sys.timer_stop(resetkey)
		sys.timer_stop(checkleftm)
		updcause(GSMSTA1,false)
		updcause(GSMSTA2,false)
		leftm,keyflag=32
	end
	return true
end

--[[
��������resetlongkey
����  ���ָ����Ƴ�����������ʾ��һЩ����ֵ
����  ����
����ֵ����
]]
local function resetlongkey()
	longkeycnt,leftm,keyflag = longkeycnt+1,32
	--updcause(GPSSTA2,false)
end

--[[
��������keylngpresind
����  �������������������ȿ���Ȼ����������30�룬��ʾGPS��λ������
        �ٰ����𣨲��̰ܶ�����������������30����Զ�Ϩ��
����  ����
����ֵ��true
]]
function keylngpresind()
	print("light.keylngpresind ",longkeycnt,gps.isfix())
	longkeycnt = longkeycnt+1
	keyflag = "LNGKEY"
	if longkeycnt%2 == 1 then--��ʾGPS����״̬
        --���ƿ���
		updcause(GPSSTA1,true) 
        --�����λ�ɹ������ƿ���������Ƴ���30��
        --����λʧ�ܣ����ƿ���32����������
		if gps.isfix() then
			sys.timer_start(updcause,2000,GPSSTA1,false)
			updcause(GPSSTA2,true)
			sys.timer_start(updcause,32000,GPSSTA2,false)
		else
			sys.timer_start(updcause,32000,GPSSTA1,false)
		end
		sys.timer_start(checkleftm,1000)
		sys.timer_start(resetlongkey,32000)
	else--�ر�GPS����״̬��ʾ
		sys.timer_stop(updcause,GPSSTA1,false)
		sys.timer_stop(updcause,GPSSTA2,false)
		sys.timer_stop(resetlongkey)
		sys.timer_stop(checkleftm)
		updcause(GPSSTA1,false)
		updcause(GPSSTA2,false)
		leftm,keyflag=32
	end
	return true
end

--[[
��������shortkeyend
����  ���رն̰���������ʾ
����  ����
����ֵ����
]]
function shortkeyend()
	updcause(SHORTKEY,false)
end

--[[
��������longkeyend
����  ���رճ�����������ʾ
����  ����
����ֵ����
]]
function longkeyend()
	updcause(LONGKEY,false)
end

--[[
function chingend()
	updcause(CHGING,false)
end

local netok,neterr
local function netind(sta)
	if sta == "REGISTERED" then
		if not netok then
			updcause(WORKSTA,true)
			sys.timer_start(updcause,60000,WORKSTA,false)
			netok = true
		end
	else
		if not neterr then
			updcause(WORKSTA,false)
			sys.timer_stop(updcause,WORKSTA,false)
			neterr = true
		end
	end
	return true
end]]

--[[
��������linkerr
����  ������ʧ���ҷ��쳣�������̵�����60��
����  ����
����ֵ����
]]
local function linkerr()
	if rtos.poweron_reason()==rtos.POWERON_RESTART and nvm.get("abnormal") then return end    
	if not linksuc then
		--updcause(WORKSTA,false)
		--sys.timer_stop(updcause,WORKSTA,false)
		updcause(LINKERR,true)
		sys.timer_start(updcause,600000,LINKERR,false)
	end
end

--[[
��������linkconsuc
����  ���豸���̨���ӳɹ�
����  ����
����ֵ��true
]]
local function linkconsuc()
	print("light.linkconsuc ",keyflag)
	linksuc = true
    --����ж̰��������£����̵Ƴ���leftm(<=30)��
	if keyflag =="SHORTKEY" then
		sys.timer_stop(checkleftm)
		updcause(GSMSTA1,false)
		sys.timer_stop(updcause,GSMSTA1,false)  
		updcause(GSMSTA2,true)
		sys.timer_start(updcause,leftm*1000,GSMSTA2,false)
	end
    --������쳣���������������ɹ���������ʾ
	if rtos.poweron_reason()==rtos.POWERON_RESTART and nvm.get("abnormal") then return true end	
	--���������ɹ��̵Ƴ���60��
    sys.timer_stop(linkerr)
	updcause(LINKERR,false)
	sys.timer_stop(updcause,LINKERR,false)
	updcause(LINKSUC,true)
	sys.timer_start(updcause,60000,LINKSUC,false)
	return true
end

--[[
��������linkconfail
����  ���豸���̨�Ͽ�����
����  ����
����ֵ��true
]]
local function linkconfail()
	print("light.linkconfail ")
	linksuc = false
	return true
end

local gpsfirstfix,gpsfstopn = true,true
--[[
��������gpsfixsuc
����  ��gps�״ζ�λ�ɹ��ҷ��쳣�������Ƴ���60��
        �����������������ȿ���2��Ȼ����������30�룬��ʾGPS��λ�������ٰ����𣨲��̰ܶ�����������������30����Զ�Ϩ��
����  ����
����ֵ��true
]]
local function gpsfixsuc()
	print("light.gpsfixsuc ",keyflag,gpsfirstfix)
	if gpsfirstfix then
		gpsfirstfix = nil
		if rtos.poweron_reason()==rtos.POWERON_RESTART and nvm.get("abnormal") then
		else
			updcause(GPSFIXFAIL,false)
			sys.timer_stop(updcause,GPSFIXFAIL,false)
			updcause(GPSFIXSUC,true)
			sys.timer_start(updcause,60000,GPSFIXSUC,false)
		end	
	elseif keyflag=="LNGKEY" then
		sys.timer_stop(checkleftm)
		updcause(GPSSTA1,false)
		sys.timer_stop(updcause,GPSSTA1,false) 
		updcause(GPSSTA2,true)
		sys.timer_start(updcause,leftm*1000,GPSSTA2,false)
	end
	return true
end

--[[
��������gpsfstopnind
����  ���״δ�gps��������쳣�������״δ�gps�Ʋ�����ʾ
����  ����
����ֵ����
]]
local function gpsfstopnind()
	print("light.gpsfstopnind ")
	if gpsfstopn then
		gpsfstopn = nil
		if rtos.poweron_reason()==rtos.POWERON_RESTART and nvm.get("abnormal") then return true end
		updcause(GPSFIXFAIL,true)
		sys.timer_start(updcause,120000,GPSFIXFAIL,false)
	end
end

--[[
��������facind
����  ���յ����̲�����Ϣ
����  ����
����ֵ����
]]
local function facind()
	updcause(FAC,true)
end

--[[
��������rsp_pwoff
����  ���ػ�����Ӧ��
����  ��cause�ػ�ԭ��ֵ
����ֵ����
]]
local function rsp_pwoff(cause)
	print("light rsp_pwoff",cause)
	pwoffcause=cause
	updcause(PWOFF,true)
end

local procer =
{
	DEV_CHG_IND = chgind,
	--NET_STATE_CHANGED = netind,
	MMI_KEYPAD_LONGPRESS_IND = keylngpresind,
	MMI_KEYPAD_IND = keyind,
	LINKAIR_CONNECT_SUC = linkconsuc,
	LINKAIR_CONNECT_FAIL = linkconfail,
	GPS_FIX_SUC = gpsfixsuc,
	GPS_FST_OPN = gpsfstopnind,
	FAC_IND = facind,
	REQ_PWOFF = rsp_pwoff,
}

--[[
��������updmodule
����  �����ص���ʾ
����  ����
����ֵ����
]]
local function updmodule()
	init()
	if nvm.get("led") then
		appid = sys.regapp(procer)
		proc()
		chgind("CHG_STATUS",chg.getstate())
	else
		sys.timer_stop(longkeyend)
		sys.timer_stop(shortkeyend)
		sys.timer_stop(proc)
		sys.timer_stop(updcause,WORKSTA,false)
		sys.timer_stop(linkerr)
		sys.timer_stop(updcause,LINKERR,false)
		sys.timer_stop(updcause,GPSFIXSUC,false)
		pmd.ldoset(0,pmd.LDO_SINK)
		pmd.ldoset(0,pmd.LDO_KEYPAD)
		pins.set(false,pins.LIGHTB)
		if appid then
			sys.deregapp(appid)
			appid = nil
		end
	end
end

--[[
��������parachangeind
����  ���������led�Ƿ����ı������ͱ仯�����¼��ص���ʾ
����  ��e,k�޸ĵĲ�����
����ֵ��true
]]
local function parachangeind(e,k)
	if k == "led" then updmodule() end
	return true
end

--ע��PARA_CHANGED_IND��Ϣ������
sys.regapp(parachangeind,"PARA_CHANGED_IND")
--���ص���ʾ
updmodule()
--����δ���Ϻ�̨����������Ӧ��ʾ
linkerr()--sys.timer_start(linkerr,60000)

