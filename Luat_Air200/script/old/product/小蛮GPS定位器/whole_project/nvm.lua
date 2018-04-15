--[[
ģ�����ƣ���������ģ��
ģ�鹦�ܣ��ṩ�޸ģ���ȡ��������������Ľӿ�
ģ������޸�ʱ�䣺2017.02.13
]]
module(...,package.seeall)
require"config"

package.path = "/?.lua;".."/?.luae;"..package.path

local configname,econfigname,paraname,para = "/lua/config.lua","/lua/config.luae","/para.lua"

--[[
��������restore
����  ���������ָ���Ĭ�ϲ���
����  ����
����ֵ����
]]
function restore()
	local fpara,fconfig = io.open(paraname,"wb"),io.open(configname,"rb")
	if not fconfig then fconfig = io.open(econfigname,"rb") end
	fpara:write(fconfig:read("*a"))
	fpara:close()
	fconfig:close()
	para = config
end

--[[
��������serialize
����  �����޸ĺ��ֵд���ļ���
����  ����
����ֵ����
]]
local function serialize(pout,o)
	if type(o) == "number" then
		pout:write(o)
	elseif type(o) == "string" then
		pout:write(string.format("%q", o))
	elseif type(o) == "boolean" then
		pout:write(tostring(o))
	elseif type(o) == "table" then
		pout:write("{\n")
		for k,v in pairs(o) do
			if type(k) == "number" then
				pout:write(" [", k, "] = ")
			elseif type(k) == "string" then
				pout:write(" [\"", k,"\"] = ")
			else
				error("cannot serialize table key " .. type(o))
			end
			serialize(pout,v)
			pout:write(",\n")
		end
		pout:write("}\n")
	else
		error("cannot serialize a " .. type(o))
	end
end

--[[
��������upd
����  �����config�еĲ���û������para�У���config�ļ��еĲ���������para�У�
����  ����
����ֵ����
]]
local function upd()
	--local f = io.open(paraname,"ab")
	for k,v in pairs(config) do
		if k ~= "_M" and k ~= "_NAME" and k ~= "_PACKAGE" then
			if para[k] == nil then
				--f:write(k, " = ")
				--serialize(f,v)
				--f:write("\n")
				para[k] = v
			end			
		end
	end
	--f:close()
end

--[[
��������load
����  ������para�ļ�
����  ����
����ֵ����
]]
local function load()
	local f = io.open(paraname,"rb")
	if not f or f:read("*a") == "" then
		if f then f:close() end
		restore()
		return
	end
	f:close()
	--����para�ļ�
	f,para = pcall(require,"para")
    --�������para�ļ�ʧ�ܣ��ָ���Ĭ�ϲ���
	if not f then
		restore()
		return
	end
	upd()
end

--[[
��������save
����  ���洢����
����  ��s,swei true�ű��棬���򲻱���
����ֵ����
]]
local function save(s)
	if not s then return end
	local f = io.open(paraname,"wb")

	f:write("module(...)\n")

	for k,v in pairs(para) do
		if k ~= "_M" and k ~= "_NAME" and k ~= "_PACKAGE" then
			f:write(k, " = ")
			serialize(f,v)
			f:write("\n")
		end
	end

	f:close()
end

--[[
��������set
����  ���޸Ĳ���ֵ
����  ��k,��������
        v �޸ĺ��ֵ
        r ��˭�޸ĵģ�������������Ϊnil�����ַ�PARA_CHANGED_IND��Ϣ�����򲻷���PARA_CHANGED_IND��Ϣ
        s �޸ĺ��Ƿ����ϱ��棬fasle��������򱣴�
����ֵ��true
]]
function set(k,v,r,s)
	local bchg
	if type(v) == "table" then
		for kk,vv in pairs(para[k]) do
			if vv ~= v[kk] then bchg = true break end
		end
	else
		bchg = (para[k] ~= v)
	end
	print("nvm.set",bchg,k,v,r,s)
	if bchg then		
		para[k] = v
		save(s or s==nil)
		if r then sys.dispatch("PARA_CHANGED_IND",k,v,r) end
	end
	return true
end

--[[
��������sett
����  ���޸�����Ϊtable�Ĳ����е�ĳһԪ��
����  ��k,�������ƣ�����Ϊtable��
        kk������Ԫ������ֵ
        v �޸ĺ��ֵ
        r ��˭�޸ĵģ�������������Ϊnil�����ַ�TPARA_CHANGED_IND��Ϣ�����򲻷���TPARA_CHANGED_IND��Ϣ
        s �޸ĺ��Ƿ����ϱ��棬fasle��������򱣴�
����ֵ��true
]]
function sett(k,kk,v,r,s)
	if para[k][kk] ~= v then
		para[k][kk] = v
		save(s or s==nil)
		if r then sys.dispatch("TPARA_CHANGED_IND",k,kk,v,r) end
	end
	return true
end

--[[
��������flush
����  ���������
����  ����
����ֵ����
]]
function flush()
	save(true)
end

--[[
��������get
����  ����ȡ����ֵ
����  ��k��������
����ֵ������ֵ
]]
function get(k)
	if type(para[k]) == "table" then
		local tmp = {}
		for kk,v in pairs(para[k]) do
			tmp[kk] = v
		end
		return tmp
	else
		return para[k]
	end
end

--[[
��������gett
����  ����ȡ����ĳһԪ��
����  ��k,�������ƣ�����Ϊtable��
        kk������Ԫ������ֵ
����ֵ������ĳһԪ��
]]
function gett(k,kk)
	return para[k][kk]
end

load()
