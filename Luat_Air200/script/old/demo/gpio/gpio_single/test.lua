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

-------------------------PIN22���Կ�ʼ-------------------------
local pin22flg = true
--[[
��������pin22set
����  ������PIN22���ŵ������ƽ��1�뷴תһ��
����  ����
����ֵ����
]]
local function pin22set()
	pins.set(pin22flg,pins.PIN22)
	pin22flg = not pin22flg
end
--����1���ѭ����ʱ��������PIN22���ŵ������ƽ
sys.timer_loop_start(pin22set,1000)
-------------------------PIN22���Խ���-------------------------


-------------------------PIN23���Կ�ʼ-------------------------
local pin23flg = true
--[[
��������pin23set
����  ������PIN23���ŵ������ƽ��1�뷴תһ��
����  ����
����ֵ����
]]
local function pin23set()
	pins.set(pin23flg,pins.PIN23)
	pin23flg = not pin23flg
end
--����1���ѭ����ʱ��������PIN22���ŵ������ƽ
sys.timer_loop_start(pin23set,1000)
-------------------------PIN23���Խ���-------------------------


-------------------------PIN5���Կ�ʼ-------------------------
--[[
��������ind
����  ������PIN5�����߼��жϴ���
����  ��
        e����Ϣ��"PIN_PIN5_IND"
		v�����Ϊtrue����ʾ�ߵ�ƽ�жϣ�false��ʾ�͵�ƽ�ж�
����ֵ����
]]
local function ind(e,v)
	print("ind",e,v)
end
--ע��PIN5�����߼��жϵĴ�����
sys.regapp(ind,"PIN_"..pins.PIN5.name.."_IND")
-------------------------PIN5���Խ���-------------------------


-------------------------PIN20���Կ�ʼ-------------------------
--[[
��������pin20get
����  ����ȡPIN20���ŵ������ƽ
����  ����
����ֵ����
]]
local function pin20get()
	local v = pins.get(pins.PIN20)
	print("pin20get",v and "low" or "high")
end
--����1���ѭ����ʱ������ȡPIN22���ŵ������ƽ
sys.timer_loop_start(pin20get,1000)
-------------------------PIN20���Խ���-------------------------
