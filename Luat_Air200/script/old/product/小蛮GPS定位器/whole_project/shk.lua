--[[
ģ�����ƣ���ģ��
ģ�鹦�ܣ���ʼ��gsensor������𶯲��ַ�����Ϣ
ģ������޸�ʱ�䣺2017.02.13
]]

module(...,package.seeall)

local i2cid,intregaddr = 1,0x1A
local initstr,indcnt1,indcnt2 = "",0,0

--[[
��������clrint
����  ������ж�
����  ����
����ֵ����
]]
local function clrint()
	print("shk.clrint 1")
	if pins.get(pins.GSENSOR) then
		print("shk.clrint 2")
		i2c.read(i2cid,intregaddr,1)
	end
end

--[[
��������init2
����  ����ʼ��gsensor2�׶�
����  ����
����ֵ����
]]
local function init2()
	local cmd,i = {0x1B,0x00,0x6A,0x01,0x1E,0x20,0x21,0x04,0x1B,0x00,0x1B,0xDA,0x1B,0xDA}
	--local cmd,i = {0x1B,0x00,0x6A,0x01,0x1E,0x20,0x21,0x04,0x1D,0x06,0x1B,0x1A,0x1B,0x9A}
	--local cmd,i = {0x1B,0x00,0x6A,0x01,0x1E,0x20,0x21,0x04,0x1B,0x1A,0x1B,0x9A}
	for i=1,#cmd,2 do
		i2c.write(i2cid,cmd[i],cmd[i+1])
		print("shk.init2",string.format("%02X",cmd[i]),string.format("%02X",string.byte(i2c.read(i2cid,cmd[i],1))))
		initstr = initstr..","..(string.format("%02X",cmd[i]) or "nil")..":"..(string.format("%02X",string.byte(i2c.read(i2cid,cmd[i],1))) or "nil")
	end
	clrint()
end

--[[
��������checkready
����  �����gsensor�Ƿ�׼������
����  ����
����ֵ����
]]
local function checkready()
	local s = i2c.read(i2cid,0x1D,1)
	print("shk.checkready",s,(s and s~="") and string.byte(s) or "nil")
	if s and s~="" then
		if bit.band(string.byte(s),0x80)==0 then
			init2()
			return
		end
	end
	sys.timer_start(checkready,1000)
end

--[[
��������init
����  ����ʼ��gsensor 1�׶�
����  ����
����ֵ����
]]
local function init()
	local i2cslaveaddr = 0x0E
	if i2c.setup(i2cid,i2c.SLOW,i2cslaveaddr) ~= i2c.SLOW then
		print("shk.init fail")
		initstr = "fail"
		return
	end
	i2c.write(i2cid,0x1D,0x80)
	sys.timer_start(checkready,1000)
end

--[[
��������getdebugstr
����  ����ȡ������Ϣ�������ж�1�ж�2���ϱ�������
����  ����
����ֵ����ʼ��������Ϣ+�ж�1�ж�2���ϱ�����
]]
function getdebugstr()
	return initstr..";".."indcnt1:"..indcnt1..";".."indcnt2:"..indcnt2
end

--[[
��������ind
����  ��gsensor�ж���Ϣ�����ַ�����Ϣ
����  ����
����ֵ����
]]
local function ind(id,data)
	print("shk.ind",id,data)
	if data then
		indcnt1 = indcnt1 + 1
	else
		indcnt2 = indcnt2 + 1
	end	
	if id == string.format("PIN_%s_IND",pins.GSENSOR.name) then
		if data then
			clrint()
			print("shk.ind DEV_SHK_IND")
			sys.dispatch("DEV_SHK_IND")
		end
	end
end

--ע���жϴ�����
sys.regapp(ind,string.format("PIN_%s_IND",pins.GSENSOR.name))
--��ʼ��gsensor
init()
--ÿ30����һ���ж�
sys.timer_loop_start(clrint,30000)
