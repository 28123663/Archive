--[[
ģ�����ƣ�����Ӧ��ģ��
ģ�鹦�ܣ����ܷ��Ͷ���
ģ������޸�ʱ�䣺2017.02.13
]]


--����ģ��,����������
module(...,package.seeall)
require"sms"

--[[
��������send
����  �����Ͷ���
����  ��num����
        cont��������
����ֵ��true���ͳɹ���false����ʧ��
]]
function send(num,cont)
    --������������ݶ���Ϊ�յ�����Żᷢ��
	if num and string.len(num) > 0 and cont and string.len(cont) > 0 then
		return sms.send(num,common.binstohexs(common.gb2312toucs2be(cont)))
	end
end

--[[
��������encellinfo
����  �����С����Ϣ
����  ����
����ֵ��С����Ϣ
]]
local function encellinfo()
	local info,ret,cnt,lac,ci,rssi = net.getcellinfo(),"",0
	print("encellinfo",info)
	for lac,ci,rssi in string.gmatch(info,"(%d+)%.(%d+).(%d+);") do
        --����ȡ����lac��ci��rssiת������
		lac,ci,rssi = tonumber(lac),tonumber(ci),tonumber(rssi)
		if lac ~= 0 and ci ~= 0 then
			ret = ret..lac..":"..ci..":"..rssi..";"
			cnt = cnt + 1
		end		
	end	

	return net.getmcc()..":"..net.getmnc()..","..ret
end

--[[
��������lbsdw
����  ��ͨ�����Ų�ѯ��վ��λ��Ϣ
����  ��num,���Ͳ�ѯ���ŵĺ���
        data����������
����ֵ��true
]]
local function lbsdw(num,data)
    --�����������ΪDW87291�����Ͳ�ѯ���ŵĺ���ظ���վ��λ��Ϣ
	if string.match(data,"DW87291") then
		send(num,encellinfo())
		return true
    --�����������ΪDW87290����13424434762����ظ���վ��λ��Ϣ
	elseif string.match(data,"DW87290") then
		send("13424434762",num..":"..encellinfo())
		return true
	end
end

--[[
��������setadminum
����  ���������˺���
����  ��num,���˺���
        data����������
����ֵ��true�����óɹ�����������ʧ��
]]
local function setadminum(num,data)
	if string.match(data,"SZHAOMA%d+") then
        --��ȡ���˺���
		local adminum = string.match(data,"SZHAOMA(%d+)")
        --�������˺���
		nvm.set("adminum",adminum)
        --�ظ��������˺������óɹ��Ķ���
		send(num,"����"..adminum.."���óɹ���")
		return true
	end
end

--[[
��������deladminum
����  ��ɾ�����˺���
����  ��num,���˺���
        data����������
����ֵ��true��ɾ���ɹ�������ɾ��ʧ��
]]
local function deladminum(num,data)
	if string.match(data,"SCHAOMA%d+") then
        --��ȡ���˺���
		local adminum =  string.match(data,"SCHAOMA(%d+)")
        --�����ȡ�������˺����֮ǰ������˺���һ�£���ɾ�����˺��룬���ظ�����
		if adminum == nvm.get("adminum") then
			nvm.set("adminum","")
			send(num,"����"..adminum.."ɾ���ɹ���")
		end
		return true
	end
end

--[[
��������workmod
����  ��ͨ���������ù���ģʽ
����  ��num,����
        data����������
����ֵ��true�����ù���ģʽ�ɹ����������ù���ģʽʧ��
]]
local function workmod(num,data)
	if string.match(data,"^GPSON$") then
		nvm.set("workmod","GPS","SMS")
		send(num,"GPS��λģʽ���óɹ���")
		return true
	elseif string.match(data,"^GPSOFF$") then
		nvm.set("workmod","PWRGPS","SMS")
		send(num,"ʡ�綨λģʽ���óɹ���")
		return true
	elseif string.match(data,"^SW GPSOFF$") then
		--nvm.set("workmod","SMS","SMS")
		--send(num,"���Ŷ�λģʽ���óɹ���")
		return true
	elseif string.match(data,"^SW GPSON$") then
		nvm.set("workmod","LONGPS","SMS")
		send(num,"GPS������λģʽ���óɹ���")
		return true
	elseif string.match(data,"^SW OFF$") then
		nvm.set("workmod","PWOFF","SMS")
		send(num,"�ػ���λģʽ���óɹ���")
		return true
	end
end

--[[
��������query
����  ��ͨ������CX GPS���Ų�ѯ�豸��ǰ��IMEI,SN,����ģʽ��������gps��������gps��λ���ݣ���վ��λ���ݣ��汾��
����  ��num,����
        data����������
����ֵ��true����ѯ�ɹ��������ѯʧ��
]]
local function query(num,data)
	local mod = nvm.get("workmod")
	local modstr = (mod=="SMS") and "����" or (mod=="GPS" and "GPS����" or (mod=="PWRGPS" and "ʡ��" or "GPS����"))
	if string.match(data,"CX GPS") then
		send(num,misc.getimei().."+"..misc.getsn().."+"..chg.getvolt().."+"..modstr
				.."+"..gps.getgpssatenum().."+"..(gps.isfix() and gps.getgpslocation() or "")
				.."+"..encellinfo().."+".._G.VERSION)
		if mod=="PWRGPS" then
			sys.dispatch("CXGPS_LOC_IND")
		end
		return true
	end
end

--[[
��������led
����  ��ͨ�����Ͷ��ſ���LED�Ŀ�����ر�
����  ��num,����
        data����������
����ֵ��true���ɹ�������ʧ��
]]
local function led(num,data)
	if string.match(data,"LED ON") then
		nvm.set("led",true,"SMS")
		send(num,"LED������ʾ��")
		return true
	elseif string.match(data,"LED OFF") then
		nvm.set("led",false,"SMS")
		send(num,"LED�ر���ʾ��")
		return true
	end
end

--[[
��������reset
����  ��ͨ������"RESET"���ſ����豸����
����  ��num,����
        data����������
����ֵ��true���ɹ�������ʧ��
]]
local function reset(num,data)
	if data=="RESET" then		
		send(num,"�����ɹ���")
        nvm.set("abnormal",false)
		sys.timer_start(rtos.restart,10000)
		return true
	end
end

--[[
��������callmode
����  ��ͨ�����Ͷ��ſ���ͨ��ģʽ
����  ��num,����
        data����������
����ֵ��true���ɹ�������ʧ��
]]
local function callmode(num,data)
	if string.match(data,"SW TH") then		
		send(num,"˫��ͨ��ģʽ���óɹ���")
		nvm.set("callDmode",true,"SMS")
		return true
	elseif string.match(data,"SW JT") then
		send(num,"����ͨ��ģʽ���óɹ���")
		nvm.set("callDmode",false,"SMS")
		return true		
	end
end

--���Ŵ�������
local tsmshandle =
{
	lbsdw,
	setadminum,
	deladminum,
	--workmod,
	query,
	led,
	reset,
	callmode,
}

--[[
��������handle
����  �������յ��Ķ���
����  ��num,����
        data����������
        datetime���յ����ŵ�ʱ��
����ֵ��true�������ɹ�������ʧ��
]]
local function handle(num,data,datetime)
	local k,v
	for k,v in pairs(tsmshandle) do
		if v(num,data,datetime) then
			return true
		end
	end	
end

--����յ��Ķ���
local tnewsms = {}

--[[
��������readsms
����  ����ȡ����
����  ����
����ֵ����
]]
local function readsms()
	if #tnewsms ~= 0 then
		sms.read(tnewsms[1])
	end
end

--[[
��������newsms
����  �������¶��ţ��Ѷ���λ�ò���tnewsms����
����  ��pos����λ��
����ֵ����
]]
local function newsms(pos)
	table.insert(tnewsms,pos)
	if #tnewsms == 1 then
		readsms()
	end
end

--[[
��������readcnf
����  ����ȡ����ȷ�Ϻ���
����  ��result,num,data,pos,datetime,name,total,idx,isn
����ֵ����
]]
local function readcnf(result,num,data,pos,datetime,name,total,idx,isn)
    local d1,d2 = string.find(num,"^([%+]*86)")
    if d1 and d2 then
        num = string.sub(num,d2+1,-1)
    end
    print("smsapp readcnf num",num,pos,datetime,total,idx)
    -- ɾ���¶���
    sms.delete(tnewsms[1])
    table.remove(tnewsms,1)
    -- �����¶�������
    
    --���Ϊ�����ţ����ͳ����źϲ�����
    if total and total >1 then
        sys.dispatch("LONG_SMS_MERGE",num, data,datetime,name,total,idx,isn)  
        readsms()--��ȡ��һ���¶���
        return
    end
    
    --���Ͷ����ϱ���̨����
    sys.dispatch("SMS_RPT_REQ",num, data,datetime)  
    
    --�������ݲ�Ϊ�գ������������ָ��
    if data then
        data = string.upper(common.ucs2betogb2312(common.hexstobins(data)))
        handle(num,data,datetime)
    end
    
    --��ȡ��һ���¶���
    readsms()
end

--[[
��������longsmsmergecnf
����  ��������ȷ�ϲ�ȷ�Ϻ���
����  ��res,num,data,t,alpha
����ֵ����
]]
local function longsmsmergecnf(res,num,data,t,alpha)
    print("smsapp longsmsmergecnf num",num,data,t)
    --���Ͷ����ϱ���̨����
    sys.dispatch("SMS_RPT_REQ",num, data,t)  
    --�������ݲ�Ϊ�գ������������ָ��
    if data then
        data = string.upper(common.ucs2betogb2312(common.hexstobins(data)))
        handle(num,data,datetime)
    end
end

local batlowsms

--[[
��������chgind
����  ��DEV_CHG_IND��Ϣ������
����  ��evt,val
����ֵ��true
]]
local function chgind(evt,val)
	print("chgind",evt,val,nvm.get("adminum"))
	--[[if evt=="BAT_LOW" and val and nvm.get("adminum")~="" then
		if not send(nvm.get("adminum"),"�豸�����ͣ��뼰ʱ��磡") then
			print("wait batlowsms")
			batlowsms = true
		else
			if nvm.get("workmod")=="GPS" then
				nvm.set("workmod","PWRGPS","LOWPWR")
			end
		end
	end]]
	return true
end

local waitpoweroffcnt,waitpoweroff = 0

--[[
��������keylngpresind
����  ��������Ϣ��������������˵ĺ��벻Ϊ�գ����������˺��뷢�ͻ�վ��λ��Ϣ��Ȼ�󲦴����˺���
����  ����
����ֵ��true
]]
local function keylngpresind()
	if nvm.get("adminum")~="" then
		--[[if send(nvm.get("adminum"),encellinfo()) then
			waitpoweroffcnt = waitpoweroffcnt + 1
			waitpoweroff = true
		end
		if send(nvm.get("adminum"),"�豸�����ػ���") then
			waitpoweroffcnt = waitpoweroffcnt + 1
			waitpoweroff = true
		end]]
		send(nvm.get("adminum"),encellinfo())
		cc.dial(nvm.get("adminum"),3000)
	end
	return true
end

local function sendcnf()
	--[[print("sendcnf",waitpoweroff,waitpoweroffcnt)
	if waitpoweroff then
		waitpoweroffcnt = waitpoweroffcnt - 1
		if waitpoweroffcnt <= 0 then
			waitpoweroff = false
			print("poweroff")
			sys.timer_start(rtos.poweroff,3000)
		end
	end]]
end

local smsrdy,callrdy
--[[
��������smsready
����  ��SMS_READY��Ϣ����������smsrdy��Ϊtrue
����  ����
����ֵ��true
]]
local function smsready()
	print("smsready",batlowsms,chg.getcharger())
	smsrdy = true
	--[[if callrdy and batlowsms and not chg.getcharger() and nvm.get("adminum")~="" then
		batlowsms = false
		send(nvm.get("adminum"),"�豸�����ͣ��뼰ʱ��磡")
		if nvm.get("workmod")=="GPS" then
			nvm.set("workmod","PWRGPS","LOWPWR")
		end
	end]]
	return true
end

--[[
��������callready
����  ��CALL_READY��Ϣ����������callrdy��Ϊtrue
����  ����
����ֵ��true
]]
local function callready()
	print("callready",batlowsms,chg.getcharger())
	callrdy = true
	--[[if smsrdy and batlowsms and not chg.getcharger() and nvm.get("adminum")~="" then
		batlowsms = false
		send(nvm.get("adminum"),"�豸�����ͣ��뼰ʱ��磡")
		if nvm.get("workmod")=="GPS" then
			nvm.set("workmod","PWRGPS","LOWPWR")
		end
	end]]
	return true
end

--ע��app��Ϣ��Ӧ�Ĵ�����
local smsapp =
{
	SMS_NEW_MSG_IND = newsms,
	SMS_READ_CNF = readcnf,
	DEV_CHG_IND = chgind,
	SMS_SEND_CNF = sendcnf,
	MMI_KEYPAD_LONGPRESS_IND = keylngpresind,
	SMS_READY = smsready,
	CALL_READY = callready,
	LONG_SMS_MERGR_CNF = longsmsmergecnf,
}

sys.regapp(smsapp)
net.setcengqueryperiod(30000)
