--[[
ģ�����ƣ�manage
ģ�鹦�ܣ������豸���˶�״̬���л���SIM����������ȵ�һЩ�ӿ�
ģ������޸�ʱ�䣺2017.02.13
]]
module(...,package.seeall)

GUARDFNC,HANDLEPWRFNC,MOTORPWRFNC,RMTPWRFNC,BUZZERFNC = true,false,false,false,false

local lastyp,lastlng,lastlat,lastmlac,lastmci,lastlbs2 = "","","","","",""
local sta = "MOV"

--[[
��������setlastgps
����  ��������һ��gps�ľ�γ��
����  ��lng ��һ��gps�ľ���
		lat����һ��gps��γ��
����ֵ����
]]
function setlastgps(lng,lat)
	lastyp,lastlng,lastlat = "GPS",lng,lat
	nvm.set("lastlng",lng,nil,false)
	nvm.set("lastlat",lat)
end

--[[
��������getlastgps
����  ����ȡ��һ��gps�ľ�γ��
����  ����
����ֵ����һ��gps�ľ��ȣ���һ��gps��γ��
]]
function getlastgps()
	return nvm.get("lastlng"),nvm.get("lastlat")
end

--[[
��������isgpsmove
����  ���ж�gps�Ƿ����ƶ����˺�����δ�õ���Ϊ�պ���
����  ��lng,lat
����ֵ��true
]]
function isgpsmove(lng,lat)
	--[[if nvm.get("workmod") ~= "GPS" then return true end
	if lastlng=="" or lastlat=="" or lastyp~="GPS" then return true end
	local dist = gps.diffofloc(lat,lng,lastlat,lastlng)
	print("isgpsmove",lat,lng,lastlat,lastlng,dist)
	return dist >= 15*15 or dist < 0]]
	return true
end

--[[
��������setlastlbs1
����  ��������һ�λ�վ��Ϣ
����  ��lac,ci,flg
����ֵ����
]]
function setlastlbs1(lac,ci,flg)
	lastmlac,lastmci = lac,ci
	if flg then lastyp = "LBS1" end
end

--[[
��������islbs1move
����  ���˺�����δ�õ���Ϊ�պ���
����  ��lac,ci
����ֵ��true
]]
function islbs1move(lac,ci)
	--[[if nvm.get("workmod") ~= "GPS" then return true end
	return lac ~= lastmlac or ci ~= lastmci]]
	return true
end

--[[
��������setlastlbs2
����  ��������һ�λ�վ��Ϣ
����  ��v,flg
����ֵ����
]]
function setlastlbs2(v,flg)
	lastlbs2 = v
	if flg then lastyp = "LBS2" end
end

--[[
��������islbs2move
����  ���˺�����δ�õ���Ϊ�պ���
����  ��v
����ֵ��true
]]
function islbs2move(v)
	--[[if nvm.get("workmod") ~= "GPS" then return true end
	if lastlbs2 == "" then return true end
	local oldcnt,newcnt,subcnt,chngcnt,laci = 0,0,0,0
	
	for laci in string.gmatch(lastlbs2,"(%d+%.%d+%.%d+%.%d+%.)%d+;") do
		oldcnt = oldcnt + 1
	end
	
	for laci in string.gmatch(v,"(%d+%.%d+%.%d+%.%d+%.)%d+;") do
		newcnt = newcnt + 1
		if not string.match(lastlbs2,laci) then chngcnt = chngcnt + 1 end
	end
	
	if oldcnt > newcnt then chngcnt = chngcnt + (oldcnt-newcnt) end
	local move = chngcnt*100/(newcnt>oldcnt and newcnt or oldcnt)
	print("islbs2move",lastlbs2,v,move)
	return move >= 50]]
	return true
end

--[[
��������getlastyp
����  ����ȡ��һ�ζ�λ����
����  ����
����ֵ����һ�ζ�λ����
]]
function getlastyp()
	return lastyp
end

--[[
��������resetlastloc
����  ��������һ��λ����Ϣ
����  ����
����ֵ����
]]
function resetlastloc()
	lastyp,lastlng,lastlat,lastmlac,lastmci,lastlbs2 = "","","","","",""
end

--[[
��������chgind
����  ��DEV_CHG_IND��Ϣ������
����  ��evt �����Ϣ�¼�
        val true��false
����ֵ��true
]]
local function chgind(evt,val)
	print("manage chgind",nvm.get("workmod"),evt,val)
    --����ǵ͵��¼������͹ػ�����
    if evt == "BAT_LOW" and val then
        sys.dispatch("REQ_PWOFF","BAT_LOW")
    end
	return true
end

--[[
��������handle_silsta
����  ���豸��ֹ״̬�Ĵ���
����  ����
����ֵ��true
]]
local function handle_silsta()
    print("manage handle_silsta ",sta)
    --���֮ǰ���˶�״̬����ַ�״̬�ı����󣬸����豸���е���ֹ״̬
    if sta ~= "SIL" then
        sta = "SIL"
        sys.dispatch("STA_CHANGE",sta)
    end
    return true
end

--[[
��������handle_movsta
����  ���豸�˶�״̬�Ĵ���
����  ����
����ֵ��true
]]
local function handle_movsta()
    print("manage handle_movsta ",sta)
    --���֮ǰ�Ǿ�ֹ״̬����ַ�״̬�ı����󣬸����豸���е��˶�״̬
    if sta ~= "MOV" then
        sta = "MOV"
        sys.dispatch("STA_CHANGE",sta)
        sys.timer_start(handle_silsta,_G.STA_SIL_VALIDSHK_CNT*_G.STA_SIL_VALIDSHK_FREQ*1000)
    end
    return true
end

--[[
��������handle_movsta
����  ��STA_CHANGE��Ϣ�Ĵ���������δ�ã�ʵΪ�պ���
����  ��sta
����ֵ��true
]]
local function sta_change(sta)
    local mod = nvm.get("workmod")
    print("manage sta_change mod",mod,sta)
    --workmodind()
    return true
end

--[[
��������shkind
����  ������Ϣ�Ĵ�����
����  ����
����ֵ��true
]]
local function shkind()
    sys.timer_stop(handle_silsta)
    sys.timer_start(handle_silsta,_G.STA_SIL_VALIDSHK_CNT*_G.STA_SIL_VALIDSHK_FREQ*1000)
    return true
end

--[[
��������getmovsta
����  ����ȡ�豸���˶�״̬
����  ����
����ֵ��"MOV"�˶���"SIL"��ֹ
]]
function getmovsta()
    return sta
end

local hassim=true
--[[
��������simind
����  ��SIM_IND��Ϣ������
����  ��para���ϱ�����Ϣ����
����ֵ��true
]]
local function simind(para)
	print("simind p",para)
    --SIM��������
	if para == "NIST" then
        if hassim then
            nvm.set("abnormal",true)
            sys.timer_start(sys.restart,300000,"power on without sim")
        end
        hassim=false
    --SIM��׼������
    elseif para == "RDY" then
        hassim=true
        sys.timer_stop(sys.restart,"power on without sim")
    end

	return true
end

--[[
��������issimexist
����  ����ѯSIM���Ƿ����
����  ����
����ֵ��true�����ڣ�����ֵ��������
]]
function issimexist()
	return hassim
end

local procer =
{
	DEV_CHG_IND = chgind,
	SIM_IND = simind,
	DEV_SHK_IND = shkind,
    STA_MOV_VALIDSHK_IND = handle_movsta,
    --STA_CHANGE = sta_change,
}

--ע��app��Ϣ������
sys.regapp(procer)
sys.timer_start(handle_silsta,_G.STA_SIL_VALIDSHK_CNT*_G.STA_SIL_VALIDSHK_FREQ*1000)
