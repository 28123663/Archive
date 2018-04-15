--[[
ģ�����ƣ�¼��ģ��
ģ�鹦�ܣ��ṩʵʱ¼���ӿڣ���¼�������ϱ��������ӿ�
ģ������޸�ʱ�䣺2017.02.13
]]
module(...,package.seeall)

--ing true����ʼ¼������ false����nilδ��¼����������¼������
--rcdlen¼��ʱ��
--rcdsta ��RCDING������¼�� "RCDRPT" �����ϱ�¼���ļ�
--rcdtyp 0ʵʱ¼����¼���ϱ���̨�� 1������ʰ����¼�겻�ϱ���̨
local ing,rcdlen,rcdsta,rcdtyp
--RCD_ID ¼���ļ����
--RCD_FILE¼���ļ���
--RCD_SPLITSIZEδ�õ�
local RCD_ID,RCD_FILE,RCD_SPLITSIZE = 1,"/RecDir/rec001",1002
--seq�������к�
--unitlen¼���ļ��ְ�ÿ�������
--way ���ͷ�ʽ��0��¼���ٷ� 1����¼�߷�
--total����������
--cur��ǰ��������
local seq,unitlen,way,total,cur=0,1024,0
--���¼������Ļ���������ĳ��ʱ��������յ����¼�����������¼��������¼���ļ�
local buf={}

local function print(...)
	_G.print("rcd",...)
end

--[[
��������start
����  ����ʼ¼����¼��ǰ��ɾ��֮ǰ��¼���ļ�
����  ����
����ֵ����
]]
local function start()
	print("start",ing,rcdlen)
    --�����ʰ���������ڽ���
	ing = true
    --ɾ����ǰ��¼���ļ�
	os.remove(RCD_FILE)
    --��ʼ¼��
	audio.beginrecord(RCD_ID,rcdlen*1000)
end

--[[local function stoprcd()
	print("stoprcd")
	audio.endrecord(RCD_ID)
	rcdendind(true)
end]]

--[[
��������rcdcnf
����  ��AUDIO_RECORD_CNF��Ϣ������
����  ��suc��sucΪtrue��ʾ��ʼ¼������¼��ʧ��
����ֵ��true
]]
local function rcdcnf(suc)
	print("rcdcnf",suc,rcdsta)
	if suc and not rcdsta then
		rcdsta = "RCDING"
	end
	return true
end

--[[
��������getrcddata
����  ����ȡ¼���ļ�ָ������������
����  ��s�������к�
        idx��������
����ֵ��¼���ļ�ָ������������
]]
function getrcddata(s,idx)
	local f,rt = io.open(RCD_FILE,"rb")
    --������ļ�ʧ�ܣ���������Ϊ�ա���
	if not f then print("getrcddata can not open file",f) return "" end
	if not f:seek("set",(idx-1)*unitlen) then print("getfdata seek err") return "" end
    --��ȡһ����Ԫ���ȵ�����
	rt = f:read(unitlen)
	f:close()
	print("getrcddata",string.len(rt),s,idx)
	return rt or ""
end

--[[
��������getrcdinf
����  ����ȡ�������кţ���ǰ¼���ļ��ı���������
����  ����
����ֵ���������кţ���ǰ¼���ļ��ı�������������һ����������ֵ
]]
local function getrcdinf()
	local f,rt = io.open(RCD_FILE,"rb")
	if not f then print("getrcdinf can not open file",f) return nil,0,0 end
	local size = f:seek("end")
	if not size or size == 0 then print("getrcdinf seek err") return nil,0,0 end
	f:close()
    --�������кţ�0-255��
	seq = (seq+1>255) and 0 or (seq+1)
    --���㱨��������
	total,cur = (size-1)/unitlen+1,1
	print("getrcdinf",size,seq,total,cur)
	return seq,(size-1)/unitlen+1,1
end

--[[
��������rcdendind
����  ��¼������������
����  ��suc��true��¼���ɹ���false¼��ʧ��
����ֵ��true
]]
local function rcdendind(suc)
	print("rcdendind",suc,rcdsta)
	--sys.timer_stop(stoprcd)
    --¼���ɹ�
	if suc and rcdsta=="RCDING" then
		rcdsta="RCDRPT"  
		collectgarbage()
        --��ȡ¼���ļ���Ϣ
		getrcdinf()
		--��ʼ���͵�һ��¼���ļ�
        sys.dispatch("SND_QRYRCD_REQ",seq,way,total,cur,rcdlen,getrcddata(seq,cur))	
		print("rcdendind",suc,rcdsta,seq,total,cur,rcdlen)
	else
        --¼��ʧ�ܣ�ɾ��¼���ļ�
		os.remove(RCD_FILE)
		ing,rcdlen,rcdsta = nil
	end
	return true
end

--[[
��������rcdind
����  ��¼����������
����  ��length��¼������
        typ��¼�����ͣ�0ʵʱ¼����¼���ϱ���̨�� 1������ʰ����¼�겻�ϱ���̨
����ֵ��true
]]
local function rcdind(length,typ)
	print("rcdind",length,ing)
    --��¼ʰ�����ͣ���ֻ֧��ʵʱ¼��
	rcdtyp = typ
	if typ ~= 0 then return print("rcdind can not support local record ") end
	if length <= 0 then print("rcdind length can not be 0") return end
    --�����ʱ��ʰ���������ڽ����У�����������뻺��������ǰ���ʰ��������ɺ���ִ�д�ʰ������
	if ing then
		table.insert(buf,{length,typ})
	else
        --���û��ʰ����������ִ�У�����ִ�б���ʰ������
		--if length and (length > 5000 or length < 0) then length = 5000 end
		rcdlen = (length or 5000)/1000
		start()
	end
	return true
end

--[[
��������sndcnf
����  ��¼����������
����  ��res ��true���ͳɹ���false����ʧ��
        s �������к�
        c ���ĵ�ǰ����
����ֵ��true
]]
local function sndcnf(res,s,c)
	print("sndcnf",res,s,c,seq,cur,total)  
    --ʰ�����ķ��ͳɹ�
	if res and tonumber(s)==seq and tonumber(c)== cur then
		cur = cur+1
		print("sndcnf111",res,s,c,seq,cur,total)  
        --���¼���ļ�û�����꣬�������һ��¼���ļ��ķ���
		if cur<=total then
			print("sndcnf222",res,s,c,seq,cur,total)   
			sys.dispatch("SND_QRYRCD_REQ",seq,way,total,cur,rcdlen,getrcddata(seq,cur))  
			return true
		end 
	end
    --����¼�����ݷ�����ϣ�ɾ��¼���ļ�
	os.remove(RCD_FILE)
	cur,total,ing,rcdlen,rcdsta = nil
    --���buf�л���ûִ�����ʰ�����󣬼���ִ��ʰ���������
	if #buf>0 then
		local rcdinfo=table.remove(buf,1)
		rcdind(rcdinfo[1],rcdinfo[2])
	end
    return true
end

--ע��app������
local procer = {
	QRY_RCD_IND = rcdind,
	AUDIO_RECORD_CNF = rcdcnf,
	AUDIO_RECORD_IND = rcdendind,
	SND_QRYRCD_CNF=sndcnf,
}
sys.regapp(procer)
