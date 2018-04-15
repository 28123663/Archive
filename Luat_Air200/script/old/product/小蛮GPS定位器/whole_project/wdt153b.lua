--[[
ģ�����ƣ����Ź�ģ��
ģ�鹦�ܣ�MCU��153B��Ƭ��ʵ��˫��ι�����ܣ���ֹMCU����
ģ������޸�ʱ�䣺2017.02.13
]]
module(...,package.seeall)

local typ = 1 --0:SGM706; 1:EM78P153B
local scm_active,get_scm_cnt = true,20
local testcnt,testing = 0

--[[
local function change()
	watchdog.kick()
	sys.timer_start(change,1000)
end]]

--[[
��������getscm
����  ���жϵ�Ƭ����û�ж�ʱ��MCUι��
����  ��tag��ι����ǩ�����������ι�����ǿ��Ź�����ʱι��
����ֵ����
]]
local function getscm(tag)
	if tag=="normal" and testing then return end
	get_scm_cnt = get_scm_cnt - 1
	if tag=="test" then
		sys.timer_stop(getscm,"normal")
	end
	if get_scm_cnt > 0 then
		if tag=="test" then
			if not pins.get(pins.WATCHDOG) then				
				testcnt = testcnt+1
				if testcnt<3 then
					sys.timer_start(feed,100,"test")
					get_scm_cnt = 20
					return
				else
					testing = nil
				end
			end
		end
		sys.timer_start(getscm,100,tag)
	else
		get_scm_cnt = 20
		if tag=="test" then
			testing = nil
		end
	end

    --�жϵ�Ƭ���Ƿ��и�MCUι���������ι����scm_activeιtrue
	if pins.get(pins.WATCHDOG) then
		scm_active = true
		print("wdt scm_active = true")
	end
end

--[[
��������feedend
����  ��������Ƭ��ι�����޸�ι������Ϊ���룬�Ա��ȡι���ź��жϵ�Ƭ���Ƿ�����MCU��ʱι��
����  ��tag��ι����ǩ�����������ι�����ǿ��Ź�����ʱι��
����ֵ����
]]
local function feedend(tag)
	if tag=="normal" and testing then return end
	pins.setdir(pio.INPUT,pins.WATCHDOG)
	print("wdt feedend",tag)
	if tag=="test" then
		sys.timer_stop(getscm,"normal")
	end
	sys.timer_start(getscm,100,tag)
end

--[[
��������feed
����  ��ι��
����  ��tag��ι����ǩ�����������ι�����ǿ��Ź�����ʱι��
����ֵ����
]]
function feed(tag)
	if tag=="normal" and testing then return end
    --�����Ƭ���ж�ʱ��MCUι������scm_active��false�������Ƭ��û��ʱ��MCUι����������Ƭ��
	if scm_active or tag=="test" then
		scm_active = false
	else
		pins.set(false,pins.RST_SCMWD)
		sys.timer_start(pins.set,100,true,pins.RST_SCMWD)
		print("wdt reset 153b",tag)
	end

    --��153Bι��
	pins.setdir(pio.OUTPUT,pins.WATCHDOG)
	pins.set(true,pins.WATCHDOG)
	print("wdt feed",tag)

    --����2���Ӻ��ٴ���153B��Ƭ��ι���Ķ�ʱ��
	sys.timer_start(feed,120000,"normal")
	if tag=="test" then
		sys.timer_stop(feedend,"normal")
	end
    --2��������Ƭ��ι������
	sys.timer_start(feedend,2000,tag)
end

--[[
��������open
����  ���򿪿��Ź�
����  ����
����ֵ����
]]
local function open()
	if typ == 0 then
		--sys.timer_start(change,1000)
		--watchdog.open(watchdog.DEFAULT,pins.WATCHDOG.pin)
	elseif typ == 1 then
		sys.timer_start(feed,120000,"normal")
		--pins.set(false,pins.WATCHDOG)
	end
end

--[[
��������test
����  �����Խӿں���
����  ����
����ֵ����
]]
function test()
	if not testing then
		testcnt,testing = 0,true
		feed("test")
	end
end

--����Ŀ��׷��β׺
_G.appendprj("_WD"..typ)
--��ʱ�������Ź�
sys.timer_start(open,200)
--sys.timer_start(test,10000)
