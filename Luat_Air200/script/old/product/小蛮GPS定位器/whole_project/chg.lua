--[[
ģ�����ƣ���Դģ��
ģ�鹦�ܣ����������ã���ص��������״̬��Ϣ����
ģ������޸�ʱ�䣺2017.02.13
]]

--����ģ��,����������
require"sys"
module(...,package.seeall)

local inf = {}
--��ذٷ�ֵ����ص����Ķ�Ӧ���
local tcap =
{
	[1] = {cap=100,volt=4200},
	[2] = {cap=90,volt=4060},
	[3] = {cap=80,volt=3980},
	[4] = {cap=70,volt=3920},
	[5] = {cap=60,volt=3870},
	[6] = {cap=50,volt=3820},
	[7] = {cap=40,volt=3790},
	[8] = {cap=30,volt=3770},
	[9] = {cap=20,volt=3740},
	[10] = {cap=10,volt=3680},
	[11] = {cap=5,volt=3500},
	[12] = {cap=0,volt=3400},
}

--[[
��������getcap
����  �����ݵ�ص�������ɶ�Ӧ�İٷֱ�
����  ��volt����ص���
����ֵ����ص�����Ӧ�İٷֱ�
]]
local function getcap(volt)
	if not volt then return 50 end
	if volt >= tcap[1].volt then return 100 end
	if volt <= tcap[#tcap].volt then return 0 end
	local idx,val,highidx,lowidx,highval,lowval = 0
	for idx=1,#tcap do
		if volt == tcap[idx].volt then
			return tcap[idx].cap
		elseif volt < tcap[idx].volt then
			highidx = idx
		else
			lowidx = idx
		end
		if highidx and lowidx then
			return (volt-tcap[lowidx].volt)*(tcap[highidx].cap-tcap[lowidx].cap)/(tcap[highidx].volt-tcap[lowidx].volt) + tcap[lowidx].cap
		end
	end
end

--[[
��������proc
����  ����Դ��Ϣ�Ĵ���
����  ��msg����ص���
����ֵ����
]]
local function proc(msg)
	if msg then	
		print("chg proc",msg.charger,msg.state,msg.level,msg.voltage)
		if msg.level == 255 then return end
        --msg.charger false ���������λ��true�������λ
		setcharger(msg.charger)
        --msg.state 0δ���ӳ����,1����У�2�ѳ���
		if inf.state ~= msg.state then
			inf.state = msg.state
			sys.dispatch("DEV_CHG_IND","CHG_STATUS",getstate())
		end
		inf.vol = msg.voltage
		inf.lev = getcap(msg.voltage)

        --flag���͵��Ҳ��ڳ����Ϊtrue������Ϊfalse
		local flag = (islowvolt() and getstate() ~= 1)
        --����͵��Ǹ�֮ǰ�ĵ͵���ֵ��ͬ����ַ��͵���Ϣ
		if inf.low ~= flag then
			if (inf.low and (getstate()==1)) or flag then
				inf.low = flag
				sys.dispatch("DEV_CHG_IND","BAT_LOW",flag)
			end
			--[[inf.low = flag
			sys.dispatch("DEV_CHG_IND","BAT_LOW",flag)]]
		end		
		--flag���͵�1�Ҳ��ڳ����Ϊtrue������Ϊfalse
		local flag = (islow1volt() and getstate() ~= 1)
        --����͵���1��֮ǰ�ĵ͵���1ֵ��ͬ����ַ��͵�1��Ϣ
		if inf.low1 ~= flag then
			if (inf.low1 and (getstate()==1)) or flag then
				inf.low1 = flag
				sys.dispatch("DEV_CHG_IND","BAT_LOW1",flag)
			end
		end	
		
        --��������ȼ�Ϊ0�ҳ��������λ�����͹ػ����󣬷���ص����͹ػ�����Ķ�ʱ��
		if inf.lev == 0 and not inf.chg then
			if not inf.poweroffing then
				inf.poweroffing = true
				sys.timer_start(sys.dispatch,30000,"REQ_PWOFF","BAT_LOW")
			end
		elseif inf.poweroffing then
			sys.timer_stop(sys.dispatch,"REQ_PWOFF","BAT_LOW")
			inf.poweroffing = false
		end
	end
end

--[[
��������init
����  �����������ã���ʼ��
����  ����
����ֵ����
]]
local function init()	
	inf.vol = 3800
	inf.lev = 50
	inf.chg = false
	inf.state = false
	inf.poweroffing = false
	
	inf.lowvol = 3500
	inf.lowlev = 10
	inf.low = false
	inf.low1vol = _G.LOWVOLT_FLY
	inf.low1 = false
	
	local para = {}
	para.batdetectEnable = 0--pmd�����λ���
	para.currentFirst = 200--���õ�һ�׶γ�����
	para.currentSecond = 100--���õڶ��׶γ�����
	para.currentThird = 50--���õ����׶γ�����
	para.intervaltimeFirst = 180--���õ�һ�׶γ�糬ʱʱ�䵥λ��
	para.intervaltimeSecond = 60--���õڶ��׶γ�糬ʱʱ�䵥λ��
	para.intervaltimeThird = 30--���õ����׶γ�糬ʱʱ�䵥λ��
	para.battlevelFirst = 4100--δʹ��
	para.battlevelSecond = 4150--δʹ��
	para.pluschgctlEnable = 1--���������
	para.pluschgonTime = 5--������ʱ�䣬��λ��
	para.pluschgoffTime = 1--����ֹͣ���ʱ�䣬��λ��
	pmd.init(para)
end

--[[
��������getcharger
����  ����ȡ�������λ���
����  ����
����ֵ��false ���������λ��true�������λ
]]
function getcharger()
	return inf.chg
end

--[[
��������setcharger
����  �����ó������λ���
����  ��f��false ���������λ��true�������λ
����ֵ����
]]
function setcharger(f)
	if inf.chg ~= f then
		inf.chg = f
		sys.dispatch("DEV_CHG_IND","CHARGER",f)
	end
end

--[[
��������getvolt
����  ����ȡ��ص���
����  ����
����ֵ����ص���ֵ
]]
function getvolt()
	return inf.vol
end

--[[
��������getlev
����  ����ȡ��ص����ȼ�
����  ����
����ֵ����ص����ȼ�ֵ
]]
function getlev()
	if inf.lev == 255 then inf.lev = 95 end
	return inf.lev
end

--[[
��������getstate
����  ����ȡ��س��״̬
����  ����
����ֵ��0��δ��磬1���ڳ�磬2�ѳ���
]]
function getstate()
	return inf.state
end

--[[
��������islow
����  ���ж��Ƿ�͵�
����  ����
����ֵ��true���͵磬false�����ǵ͵�
]]
function islow()
	return inf.low
end

--[[
��������islow1
����  ���ж��Ƿ�͵�1
����  ����
����ֵ��true���͵磬false�����ǵ͵�
]]
function islow1()
	return inf.low1
end

--[[
��������islowvolt
����  ���жϵ����Ƿ���ڵ���lowvol
����  ����
����ֵ��true���ǣ�false����
]]
function islowvolt()
	return inf.vol<=inf.lowvol
end

--[[
��������islow1volt
����  ���жϵ����Ƿ���ڵ���lowvol1
����  ����
����ֵ��true���ǣ�false����
]]
function islow1volt()
	return inf.vol<=inf.low1vol
end

--ע���Դ��Ϣ������
sys.regmsg(rtos.MSG_PMD,proc)
--��ʼ���������
init()
