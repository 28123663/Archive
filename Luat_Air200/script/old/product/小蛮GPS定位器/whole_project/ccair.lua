--[[
ģ�����ƣ�CC�ϲ�Ӧ��ģ��
ģ�鹦�ܣ�����ȥ����ؽӿڹ���
ģ������޸�ʱ�䣺2017.02.13
]]

--����ģ��,����������
module(...,package.seeall)
require"cc"

--stat�û��Զ����CC״̬��Ϣ:"IDLE","DIALING","CONNECT"
--num�洢�������ĵ绰����
--linkshut����Ͽ���ʶ����û�õ�
local stat,num,linkshut = "IDLE",{}
--starttm �����ȥ��Ŀ�ʼʱ��
--totaltm �����ȥ���ͨ����ʱ��
--ringtm �����ȥ�������ʱ��
--cctyp �绰���ͣ�0�����磬1��ȥ��
--ccnum �����ȥ��ĺ���
--tmtemp ��������绰��ʱ��������ʱ������Ƶı���
local starttm,totaltm,ringtm,cctyp,ccnum,tmtemp--cctyp:0�����磬1��ȥ��

--[[
��������checktm
����  ��ÿ��һ�δ˺�������tmtempֵ��1
����  ��
		��
����ֵ����
]]
local function checktm()
    tmtemp=tmtemp+1
end

--[[
��������addnum
����  ����num���м���������ĺ���
����  ��id,app��Ϣid
		val ��Ҫ����num���еĺ���ֵ
����ֵ����
]]
local function addnum(id,val)
	print("ccapp addmun",id,val,stat)
    --ֻ�к��벻Ϊ���ҵ�ǰ״̬Ϊ"IDLE"ʱ�Ž�������ӵ�num����
	if val and string.len(val) > 0 and stat == "IDLE" then
		table.insert(num,val)
	end
end

--[[
��������dialnum
����  ���绰����
����  ����
����ֵ�������ɹ�Ϊtrue������Ϊnil
]]
local function dialnum()
	print("ccapp dialnum",#num)
	if #num > 0 then		
		--link.shut()
		--linkshut = true
        --������Ƶͨ��
		if nvm.get("callDmode") then
			audio.setaudiochannel(audiocore.LOUDSPEAKER)
		else
			audio.setaudiochannel(audiocore.AUX_HANDSET)	
		end	
        --ȡ���еĵ�һ�����룬�������еĵ�һ������ɾ��
		ccnum = table.remove(num,1)	
        --��ʼ����������������ɹ��������������һ������
		if not cc.dial(ccnum,2000) then dialnum() end
        --��ǵ绰����cctypΪ1��ȥ�磬��tmtemp���㣬�Ա�ͳ������ʱ��
		cctyp,tmtemp=1,0 
        --��ȡȥ�����ʼʱ��
		starttm = misc.getclockstr()
        --���ֵ�ǰ״̬Ϊȥ��״̬
		stat = "DIALING"
        --���һֱû�˽���������40���Զ��ҶϹ���
		sys.timer_start(cc.hangup,40000,"r1")
        --��ʼ��������ʱ��
		sys.timer_loop_start(checktm,1000)
		return true
	end
end

--[[
��������connect
����  ���绰��ͨ����
����  ����
����ֵ��true
]]
local function connect()
    --����绰��ͨ���ص�40����Զ��ҶϵĶ�ʱ��
	sys.timer_stop(cc.hangup,"r1")
    --��ǵ�ǰ״̬Ϊ��ͨ״̬
	stat = "CONNECT"
    --��ź����num����գ���������ʱ��
	num,ringtm = {},tmtemp
    --tmtemp�ٴ���0����ʼ����ͨ��ʱ��
	tmtemp=0
	sys.dispatch("CCAPP_CONNECT")
	return true
end

--[[
��������disconnect
����  ���绰�Ҷϴ���
����  ����
����ֵ��true
]]
local function disconnect()
    --�ر��Զ��������Զ��Ҷ϶�ʱ��
	sys.timer_stop(cc.accept)
	sys.timer_stop(cc.hangup,"r1")
	--[[if linkshut then
		linkshut = nil
		link.reset()
	end]]
    --�رռ�������ʱ��/ͨ��ʱ���Ķ�ʱ��
	sys.timer_stop(checktm)	
    --��������ʱ����ͨ����ʱ��
	if stat ~= "CONNECT" then
	    ringtm=tmtemp
	    totaltm=0
	else
	    totaltm = tmtemp
	end
	tmtemp=0
    --���͵绰�ϱ�����
	sys.dispatch("CCRPT_REQ",cctyp,ccnum,starttm,ringtm,totaltm)
	print("ccair CCRPT_REQ",cctyp,ccnum,starttm,ringtm,totaltm)
	if not dialnum() then
		stat = "IDLE"
		sys.dispatch("CCAPP_DISCONNECT")
	end
	--sys.restart("restart with cc disconnect") 
	return true
end

--[[
��������incoming
����  �����紦��
����  ��typ��app��Ϣid
        num���������
����ֵ����
]]
local function incoming(typ,num)
    --�������ģʽ��ʡ��ģʽ����ҵ��绰
	if nvm.get("workmod")=="PWRGPS" then
		cc.hangup()
		return
	end

    --���adminum�Ų�Ϊ�գ���������벻��adminum���룬��ҵ��绰
	if nvm.get("adminum")~="" then
		if num~="" and num~=nil and num~=nvm.get("adminum") then
			cc.hangup()
			return
		end
	end
	--link.shut()
	--linkshut = true
    --��ǵ绰����cctypΪ0�����磬��tmtemp��0�Ա��������ʱ�䣬���������洢��ccnum
	cctyp,tmtemp,ccnum=0,0,num
    --��ȡ���翪ʼʱ��
	starttm = misc.getclockstr()
	print("ccair incoming",cctyp,ccnum,starttm,ringtm,totaltm)
    --������Ƶͨ��
	if nvm.get("callDmode") then
		audio.setaudiochannel(audiocore.LOUDSPEAKER)
	else
		audio.setaudiochannel(audiocore.AUX_HANDSET)	
	end	
    --10S���Զ�����
	sys.timer_start(cc.accept,10000)
    --������������ʱ��Ķ�ʱ��
	sys.timer_loop_start(checktm,1000)
end

--ע��app������
sys.regapp(incoming,"CALL_INCOMING")
sys.regapp(connect,"CALL_CONNECTED")
sys.regapp(disconnect,"CALL_DISCONNECTED")
sys.regapp(addnum,"CCAPP_ADD_NUM")
sys.regapp(dialnum,"CCAPP_DIAL_NUM")
--������Ƶͨ��
audio.setaudiochannel(audiocore.AUX_HANDSET)
--����MIC����
audio.setmicrophonegain(7)
