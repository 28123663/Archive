--[[
ģ�����ƣ�ͨ������
ģ�鹦�ܣ����Ժ������
ģ������޸�ʱ�䣺2017.02.23
]]

module(...,package.seeall)


--[[
��������print
����  ����ӡ�ӿڣ����ļ��е����д�ӡ�������testǰ׺
����  ����
����ֵ����
]]
local function print(...)
	_G.print("test",...)
end

--[[
��������connected
����  ��ͨ���ѽ�������Ϣ������
����  ��
		id��ͨ��id
����ֵ����
]]
local function connected(id)
	print("connected:"..(id or "nil"))
	--����mic����
	audio.setmicrophonegain(7)
	--10����֮����������ͨ��
	sys.timer_start(cc.hangup,10000,"AUTO_DISCONNECT")
end

--[[
��������disconnected
����  ��ͨ���ѽ�������Ϣ������
����  ��
		id��ͨ��id
����ֵ����
]]
local function disconnected(id)
	print("disconnected:"..(id or "nil"))
	sys.timer_stop(cc.hangup,"AUTO_DISCONNECT")
end

--��ʾ�ڼ�������
local incomingIdx = 1
--[[
��������incoming
����  ��������Ϣ������
����  ��
		id��ͨ��id
����ֵ����
]]
local function incoming(id)
	print("incoming:"..(id or "nil"))
	--��ż�������磬�Զ�����
	if incomingIdx%2==0 then
		cc.accept()
	--�����������磬�Զ��Ҷ�
	else
		cc.hangup()
	end	
	incomingIdx = incomingIdx+1
end

local procer =
{
	CALL_INCOMING = incoming, --����ʱ��lib�е�cc.lua�����sys.dispatch�ӿ��׳�CALL_INCOMING��Ϣ
	CALL_DISCONNECTED = disconnected,	--ͨ��������lib�е�cc.lua�����sys.dispatch�ӿ��׳�CALL_DISCONNECTED��Ϣ
}

--�������д�����ע����Ϣ�����������ַ�ʽ
--���ߵ���������Ϣ���������յ��Ĳ�����ͬ
--��һ�ַ�ʽ�ĵ�һ����������ϢID
--�ڶ��ַ�ʽ�ĵ�һ����������ϢID����Զ������
--��ο�incoming��connected��disconnected�еĴ�ӡ
sys.regapp(connected,"CALL_CONNECTED") --����ͨ����lib�е�cc.lua�����sys.dispatch�ӿ��׳�CALL_CONNECTED��Ϣ
sys.regapp(procer)

--������1���Ӻ����10086
sys.timer_start(cc.dial,60000,"10086")

