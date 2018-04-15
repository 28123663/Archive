--[[
ģ�����ƣ����̲���ģ��
ģ�鹦�ܣ��豸�Ĺ��ܲ��ԣ��𶯣�gps�����������״̬�����Ź������磬IMEI��SN����д����ȡ��
ģ������޸�ʱ�䣺2017.02.13
]]
module(...,package.seeall)

--ftrlt���ܲ��Խ��ֵ
--fttimes���ܲ���ʱ��ֵ
--shkflag �𶯱�ǣ�true�����𶯣�false��nil��δ��
--keyflag ������ǣ�true����⵽�������£�false��nil��δ��⵽��������
local ftrlt,fttimes,shkflag,keyflag = 0,0
local smatch,slen = string.match,string.len
local waitrst

--[[
��������rsp
����  �����յ���ָ������Ӧ��
����  ��s��Ӧ�������
����ֵ����
]]
local function rsp(s)
	print("factory rsp",s)
	uart.write(3,s)
end

--[[
��������timeout
����  �����ܲ��Գ�ʱ����
����  ����
����ֵ����
]]
local function timeout()
	local s1
	fttimes = fttimes + 1
	print("factory timeout",fttimes)
    --���ܲ���ʱ�䳬��20��Ҳ��������Ӧ��
	if fttimes > 20 then
	    s1 = "\r\n" .. "+FT5315:" .. "\r\n" .. ftrlt .. "\r\n" .. "OK" .. "\r\n"
		rsp(s1)
		return
	end
    --���в����ͨ����������һ�ֵļ��
	checkft()
end

--[[
��������checkft
����  ����⹦�ܲ��Խ��
����  ����
����ֵ����
]]
function checkft()
	print("factory checkft",net.getstate(),net.getrssi(),gps.getgpssn(),shkflag,chg.getcharger(),chg.getstate(),keyflag)
	local s1
    --�������ע��ɹ�����rssiֵ����15������ΪGSM������ͨ�������ftrlt��0λΪ0���򽫵�0λ��1
	if net.getstate()=="REGISTERED" and net.getrssi() > 15 and (ftrlt % 2) == 0 then
		ftrlt = ftrlt + 1
	end
    --���gps�����ֵ����30������ΪGPS������ͨ�������ftrlt��1λΪ0���򽫵�1λ��1
	if gps.getgpssn() > 30 then
		if (ftrlt % 4) < 2 then
			ftrlt = ftrlt + 2
		end
	end
    --��������ϱ���ftrlt��2λλ0���򽫵�2λ��1
	if shkflag then
		if (ftrlt % 8) < 4 then
			ftrlt = ftrlt + 4
		end
	end
	--if acc.getflag() then
		if (ftrlt % 16) < 8 then
			ftrlt = ftrlt + 8
		end
	--end
    --����������λ��ftrlt��4λλ0���򽫵�4λ��1
	if chg.getcharger() then
		if (ftrlt % 32) < 16 then
			ftrlt = ftrlt + 16
		end
	end
    --���������ڳ��������ftrlt��5λλ0���򽫵�5λ��1
	if chg.getstate()~=0 then
		if (ftrlt % 64) < 32 then
			ftrlt = ftrlt + 32
		end
	end
    --�����⵽�����ϱ���ftrlt��6λλ0���򽫵�6λ��1
	if keyflag then
		if (ftrlt % 128) < 64 then
			ftrlt = ftrlt + 64
		end
	end

    --������Բ�ͨ����10����ٴμ����Խ�������������ȫͨ����ֱ���򹤾�����Ӧ��
	if ftrlt < 127 then
		print("factory timeout",fttimes)
		sys.timer_start(timeout,1000)
	else		
		s1 = "\r\n" .. "+FT5315:" .. "\r\n" .. ftrlt .. "\r\n" .. "OK" .. "\r\n"
		rsp(s1)
	end
end

--[[
��������cb
����  ���ص�����
����  ��cmd,success,response,intermediate
����ֵ����
]]
local function cb(cmd,success,response,intermediate)
	if (smatch(cmd,"WIMEI=") or smatch(cmd,"WISN=") or smatch(cmd,"AMFAC=")) and success then
		rsp("\r\nOK\r\n")
	end
end

--[[
��������proc
����  �������յ������ݵĴ�����
����  ��s �����յ�������
����ֵ����
]]
local function proc(s)
	s = string.upper(s)
	if smatch(s,"WIMEI=") then
		misc.set("WIMEI",smatch(s,"=\"(.+)\""),cb)
		waitrst = true
	elseif smatch(s,"CGSN") then
		if waitrst then
			rsp("\r\nAT+CGSN\r\nWAIT RST\r\nOK\r\n")
		else
			local imei = misc.getimei()
			if imei and slen(imei) > 0 then
				rsp("\r\nAT+CGSN\r\n" .. imei .. "\r\nOK\r\n")
			end
		end
	elseif smatch(s,"WISN=") then
		misc.set("WISN",smatch(s,"=\"(.+)\""),cb)
		waitrst = true
	elseif smatch(s,"WISN%?") then
		if waitrst then
			rsp("\r\nAT+WISN?\r\nWAIT RST\r\nOK\r\n")
		else
			local sn = misc.getsn()
			if sn and slen(sn) > 0 then
				rsp("\r\nAT+WISN?\r\n" .. sn .. "\r\nOK\r\n")
			end
		end
	elseif smatch(s,"VER") then
		rsp("\r\nAT+VER\r\n" .. _G.PROJECT .. "_" .. _G.VERSION .."\r\nOK\r\n")
	elseif smatch(s,"CHARGER?") then
		rsp("\r\nAT+CHARGER?\r\n" .. (chg.getcharger() and 1 or 0) .."\r\nOK\r\n")
	elseif smatch(s,"AMFAC=") then
		gpsapp.open(gpsapp.OPEN_DEFAULT,{cause="FAC"})
		misc.set("AMFAC",smatch(s,"=(.+)"),cb)
	elseif smatch(s,"CFUN=") then
		--gpsapp.close(gpsapp.OPEN_DEFAULT,{cause="FAC"})
		--misc.set("CFUN",smatch(s,"=(.+)"))
		waitrst = true
		--uart.close(3)
		rtos.restart()
	elseif smatch(s,"WDTEST") then
		rsp("\r\nAT+WDTEST\r\nOK\r\n")
		wdt153b.test()
	elseif smatch(s,"AT%+FT5315") then
		sys.dispatch("FAC_IND")
		gpsapp.open(gpsapp.OPEN_DEFAULT,{cause="FAC"})
		checkft()
	end
end

--[[
��������read
����  �����ڽ�����Ϣ����
����  ����
����ֵ����
]]
local function read()
	local t1
	local s1 = ""
	local rd = true
	while rd == true do
		t1 = uart.read(3,"*l",0)
		if t1 and t1~="" then
			s1 = s1 .. t1
		else
			rd = false
		end		
	end

	if s1 ~= "" then
		print("factory proc:",s1)
	end
    --�������յ�������
	proc(s1)
end

--[[
��������ind
����  ���𶯣�������Ϣ������
����  ��id����Ϣid
         data�� �յ�������
����ֵ����
]]
local function ind(id,data)
	if id == "DEV_SHK_IND" then
		shkflag = true
	elseif id=="MMI_KEYPAD_IND" then
		keyflag= true
	end
	return true
end

--���ô��ڣ������빤�̲��ԵĹ���ͨ��
uart.setup(3,921600,8,uart.PAR_NONE,uart.STOP_1,2)
--ע�ᴮ�ڵĽ�����Ϣ����
sys.reguart(3,read)
net.startquerytimer()
--ע���𶯣�������Ϣ������
sys.regapp(ind,"DEV_SHK_IND","MMI_KEYPAD_IND")
