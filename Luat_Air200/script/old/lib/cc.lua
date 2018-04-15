--[[
ģ�����ƣ�ͨ������
ģ�鹦�ܣ����롢�������������Ҷ�
ģ������޸�ʱ�䣺2017.02.20
]]

--����ģ��,����������
local base = _G
local string = require"string"
local table = require"table"
local sys = require"sys"
local ril = require"ril"
local net = require"net"
local pm = require"pm"
local aud = require"audio"
module("cc")

--���س��õ�ȫ�ֺ���������
local ipairs,pairs = base.ipairs,base.pairs
local dispatch = sys.dispatch
local req = ril.request

--�ײ�ͨ��ģ���Ƿ�׼��������true������false����nilδ����
local ccready = false
--ͨ�����ڱ�־��������״̬ʱΪtrue��
--���к����У����������У�ͨ����
local callexist = false
--��¼������뱣֤ͬһ�绰�������ֻ��ʾһ��
local incoming_num = nil 
--���������
local emergency_num = {"112", "911", "000", "08", "110", "119", "118", "999"}
--ͨ���б�
local clcc = {}

--[[
��������isemergencynum
����  ���������Ƿ�Ϊ��������
����  ��
		num����������
����ֵ��trueΪ�������룬false��Ϊ��������
]]
function isemergencynum(num)
	for k,v in ipairs(emergency_num) do
		if v == num then
			return true
		end
	end
	return false
end

--[[
��������clearincomingflag
����  ������������
����  ����
����ֵ����
]]
local function clearincomingflag()
	incoming_num = nil
end

--[[
��������discevt
����  ��ͨ��������Ϣ����
����  ��
		reason������ԭ��
����ֵ����
]]
local function discevt(reason)
	callexist = false -- ͨ������ ���ͨ��״̬��־
	if incoming_num then sys.timer_start(clearincomingflag,1000) end
	pm.sleep("cc")
	--�����ڲ���ϢCALL_DISCONNECTED��֪ͨ�û�����ͨ������
	dispatch("CALL_DISCONNECTED",reason)
end

--[[
��������anycallexist
����  ���Ƿ����ͨ��
����  ����
����ֵ������ͨ������true�����򷵻�false
]]
function anycallexist()
	return callexist
end

--[[
��������qrylist
����  ����ѯͨ���б�
����  ����
����ֵ����
]]
local function qrylist()
	clcc = {}
	req("AT+CLCC")
end

local function proclist()
	local k,v,isactive
	for k,v in pairs(clcc) do
		if v.sta == "0" then isactive = true break end
	end
	if isactive and #clcc > 1 then
		for k,v in pairs(clcc) do
			if v.sta ~= "0" then req("AT+CHLD=1"..v.id) end
		end
	end
end

--[[
��������dial
����  ������һ������
����  ��
		number������
		delay����ʱdelay����󣬲ŷ���at������У�Ĭ�ϲ���ʱ
����ֵ����
]]
function dial(number,delay)
	if number == "" or number == nil then
		return false
	end

	if ccready == false and not isemergencynum(number) then
		return false
	end

	pm.wake("cc")
	req(string.format("%s%s;","ATD",number),nil,nil,delay)
	callexist = true -- ���к���

	return true
end

--[[
��������hangup
����  �������Ҷ�����ͨ��
����  ����
����ֵ����
]]
function hangup()
	aud.stop()
	req("AT+CHUP")
end

--[[
��������accept
����  ����������
����  ����
����ֵ����
]]
function accept()
	aud.stop()
	req("ATA")
	pm.wake("cc")
end

--[[
��������ccurc
����  ��������ģ���ڡ�ע��ĵײ�coreͨ�����⴮�������ϱ���֪ͨ���Ĵ���
����  ��
		data��֪ͨ�������ַ�����Ϣ
		prefix��֪ͨ��ǰ׺
����ֵ����
]]
local function ccurc(data,prefix)
	--�ײ�ͨ��ģ��׼������
	if data == "CALL READY" then
		ccready = true
		dispatch("CALL_READY")
		req("AT+CCWA=1")
	--ͨ������֪ͨ
	elseif data == "CONNECT" then
		qrylist()
		dispatch("CALL_CONNECTED")
	--ͨ���Ҷ�֪ͨ
	elseif data == "NO CARRIER" or data == "BUSY" or data == "NO ANSWER" then
		qrylist()
		discevt(data)
	--��������
	elseif prefix == "+CLIP" then
		qrylist()
		local number = string.match(data,"\"(%+*%d*)\"",string.len(prefix)+1)
		callexist = true -- ��������
		if incoming_num ~= number then
			incoming_num = number
			dispatch("CALL_INCOMING",number)
		end
	elseif prefix == "+CCWA" then
		qrylist()
	--ͨ���б���Ϣ
	elseif prefix == "+CLCC" then
		local id,dir,sta = string.match(data,"%+CLCC:%s*(%d+),(%d),(%d)")
		if id then
			table.insert(clcc,{id=id,dir=dir,sta=sta})
			proclist()
		end
	end
end

--[[
��������ccrsp
����  ��������ģ���ڡ�ͨ�����⴮�ڷ��͵��ײ�core�����AT�����Ӧ����
����  ��
		cmd����Ӧ���Ӧ��AT����
		success��AT����ִ�н����true����false
		response��AT�����Ӧ���е�ִ�н���ַ���
		intermediate��AT�����Ӧ���е��м���Ϣ
����ֵ����
]]
local function ccrsp(cmd,success,response,intermediate)
	local prefix = string.match(cmd,"AT(%+*%u+)")
	--����Ӧ��
	if prefix == "D" then
		if not success then
			discevt("CALL_FAILED")
		end
	--�Ҷ�����ͨ��Ӧ��
	elseif prefix == "+CHUP" then
		discevt("LOCAL_HANG_UP")
	--��������Ӧ��
	elseif prefix == "A" then
		incoming_num = nil
		dispatch("CALL_CONNECTED")
	end
	qrylist()
end

--ע������֪ͨ�Ĵ�����
ril.regurc("CALL READY",ccurc)
ril.regurc("CONNECT",ccurc)
ril.regurc("NO CARRIER",ccurc)
ril.regurc("NO ANSWER",ccurc)
ril.regurc("BUSY",ccurc)
ril.regurc("+CLIP",ccurc)
ril.regurc("+CLCC",ccurc)
ril.regurc("+CCWA",ccurc)
--ע������AT�����Ӧ������
ril.regrsp("D",ccrsp)
ril.regrsp("A",ccrsp)
ril.regrsp("+CHUP",ccrsp)
ril.regrsp("+CHLD",ccrsp)

--����������,æ�����
req("ATX4") 
--��������urc�ϱ�
req("AT+CLIP=1")
