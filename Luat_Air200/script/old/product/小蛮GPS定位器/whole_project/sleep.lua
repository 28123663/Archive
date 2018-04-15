--[[
ģ�����ƣ�gps���߹���ģ��
ģ�鹦�ܣ�
ģ������޸�ʱ�䣺2017.02.09
]]

module(...,package.seeall)

local function print(...)
	_G.print("sleep",...)
end

--[[
��������itvwakesndfail
����  ����λ����12Сʱ�ڶ�����ʧ�ܣ������豸
����  ����
����ֵ����
]]
local function itvwakesndfail()
	nvm.set("abnormal",true)
	dbg.restart("itvwakesndfail")
end

--[[
��������itvwakesndsuc
����  ����λ���ݷ��ͳɹ����ر������Ķ�ʱ��
����  ����
����ֵ����
]]
local function itvwakesndsuc()
	print("itvwakesndsuc")
	sys.timer_stop(itvwakesndfail)
end

--[[
��������connsuc
����  �����Ӻ�̨�ɹ����������ݷ���ʧ���������Ķ�ʱ������
����  ����
����ֵ��true
]]
local function connsuc()
	if not sys.timer_is_active(itvwakesndfail) then
		sys.timer_start(itvwakesndfail,43200000)
	end
	return true
end

--[[
��������wakegps
����  ������gps
����  ����
����ֵ����
]]
local function wakegps()
	print("wakegps",nvm.get("workmod"))
	nvm.set("gpsleep",false,"gps")
	sys.timer_stop(sys.dispatch,"ITV_GPSLEEP_REQ")
end

--[[
��������shkind
����  ������Ϣ����
����  ����
����ֵ��true
]]
local function shkind()
	print("shkind",nvm.get("workmod"),nvm.get("gpsleep")) 
	if nvm.get("gpsleep") then
		sys.timer_start(sys.dispatch,_G.GPSMOD_WAKE_NOSHK_SLEEP_FREQ*1000,"ITV_GPSLEEP_REQ")
	else
		initgps()
	end	
	return true
end

--[[
��������parachangeind
����  ���������ģʽ�ı䣬���¿���gps
����  ��k,v,r
����ֵ��true
]]
local function parachangeind(k,v,r)	
	print("parachangeind",k)
	if k == "workmod" then
		wakegps()
		initgps()
	end
	return true
end

--[[
��������gpsleep
����  ��gps����sleepģʽ��˵���豸���뾲ֹ״̬
����  ����
����ֵ����
]]
local function gpsleep()
	print("gpsleep",nvm.get("workmod"))
	nvm.set("gpsleep",true,"gps")
end

--[[
��������itvgpslp
����  ������gps����ģʽ
����  ����
����ֵ����
]]
local function itvgpslp()
	print("itvgpslp")
	gpsleep()
	sys.timer_stop(sys.dispatch,"ITV_GPSLEEP_REQ")
end

--[[
��������initgps
����  ��Ϊ��gpsleep״̬�����5������û��⵽��Ч�񶯣���������ģʽ
        ��Ϊ����ģʽ���رս�������ģʽ�Ķ�ʱ�����رշ���ITV_GPSLEEP_REQ�Ķ�ʱ��
����  ����
����ֵ��true
]]
function initgps()
	print("initgps",nvm.get("workmod"),nvm.get("gpsleep"))	
	if not nvm.get("gpsleep") then
		sys.timer_start(gpsleep,_G.GPSMOD_CLOSE_SCK_INVALIDSHK_FREQ*1000)
	else
		sys.timer_stop(gpsleep)
		sys.timer_stop(sys.dispatch,"ITV_GPSLEEP_REQ")
	end	
	return true
end

--[[
��������gpsmodopnsck
����  ����gps
����  ����
����ֵ��true
]]
local function gpsmodopnsck()
	print("gpsmodopnsck")
	initgps()
	wakegps()
	return true
end


local procer = {
	DEV_SHK_IND = shkind,
	GPSMOD_OPN_SCK_VALIDSHK_IND = gpsmodopnsck,
	PARA_CHANGED_IND = parachangeind,
	ITV_GPSLEEP_REQ = itvgpslp,
	ITV_WAKE_SNDSUC = itvwakesndsuc,
	LINKAIR_CONNECT_SUC = connsuc,
}

--ע��app��Ϣ������
sys.regapp(procer)
nvm.set("gpsleep",false)
initgps()
