--[[
ģ�����ƣ�������Ϣ����ģ��
ģ�鹦�ܣ���ʼ���������󣬼�ⰴ�����µ�����Ϣ�����ַ�������Ϣ
ģ������޸�ʱ�䣺2017.02.09
]]
module(...,package.seeall)

--curkey��ǰ��⵽�İ���
local curkey
--����ʱ��ֵ
local KEY_LONG_PRESS_TIME_PERIOD = 3000
KEY_SOS = "SOS"
--����ӳ���
local keymap = {["12"] = KEY_SOS}
local sta = "IDLE"

--[[
��������keylongpresstimerfun
����  ������������ʱ��������
����  ����
����ֵ����
]]
local function keylongpresstimerfun ()
    --�����ǰ����ֵ��Ϊnil����ַ�����������Ϣ
	if curkey then
		sys.dispatch("MMI_KEYPAD_LONGPRESS_IND",curkey)
		sta = "LONG"
	end
end

--[[
��������stopkeylongpress
����  ���رճ��������������Ķ�ʱ��
����  ����
����ֵ����
]]
local function stopkeylongpress()
	curkey = nil
	sys.timer_stop(keylongpresstimerfun)
end

--[[
��������startkeylongpress
����  ���������������������Ķ�ʱ��
����  ��key ��ǰ��⵽�İ���
����ֵ����
]]
local function startkeylongpress(key)
	stopkeylongpress()
	curkey = key
	sys.timer_start(keylongpresstimerfun,KEY_LONG_PRESS_TIME_PERIOD)
end

--[[
��������keymsg
����  ���������İ��£�����״̬����⵱ǰ���°���ֵ
����  ��msg ������Ϣ
����ֵ����
]]
local function keymsg(msg)
	print("keypad.keymsg",msg.key_matrix_row,msg.key_matrix_col)
	local key = keymap[msg.key_matrix_row..msg.key_matrix_col]
	if key then
		if msg.pressed then
            --��⵽�������£����״̬�Ұ��£�����������ʱ����ʱ��
			sta = "PRESSED"
			startkeylongpress(key)			
		else
            --��⵽��������1�ص�������ʱ����ʱ��,2�������״̬Ϊ���£���ַ��̰���Ϣ��3�ָ�����״̬
			stopkeylongpress()
			if sta == "PRESSED" then
				sys.dispatch("MMI_KEYPAD_IND",key)
			end
			sta = "IDLE"
		end
	end
end

--����̰���Ϣ�Ĵ���
local fivetap = 0

--[[
��������resetfivetap
����  ��������̰�������fivetap�ָ�Ϊ0
����  ����
����ֵ����
]]
local function resetfivetap()
	fivetap = 0
end

--[[
��������keyind
����  ������̰���Ϣ�����1�����д��ڵ���5�ζ̰���������ַ�MMI_KEYPAD_FIVETAP_IND��Ϣ
����  ����
����ֵ��true
]]
local function keyind()
	fivetap = fivetap+1
	if fivetap >= 5 then
		resetfivetap()
		sys.timer_stop(resetfivetap)
		sys.dispatch("MMI_KEYPAD_FIVETAP_IND")
	else
		sys.timer_start(resetfivetap,1000)
	end
	return true
end

--ע�ᰴ����Ϣ������
sys.regmsg(rtos.MSG_KEYPAD,keymsg)
--ע��̰���Ϣ������
sys.regapp(keyind,"MMI_KEYPAD_IND")
--��ʼ����������
rtos.init_module(rtos.MOD_KEYPAD,0,0x04,0x02)
