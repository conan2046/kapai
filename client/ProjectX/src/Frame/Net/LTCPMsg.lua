LTCPMsg = LMsgBase:New()
LTCPMsg.__index = LTCPMsg
function LTCPMsg:New(msgid, length)
    if length == nil then
        length = 1024
    end
    local o = LMsgBase:New(msgid)
    setmetatable(o,LTCPMsg)
    o.m_pNetMsg = NetMsgBase:new(length)
    o.m_pNetMsg:retain()
    return o
end

function LTCPMsg:Reset()
	--头两个字节是长度
    self.m_pNetMsg:SetSeek(4)
end

function LTCPMsg:ResetNetMsg()
    self.m_pNetMsg:Reset()
end

function LTCPMsg:GetSeek()
    local v = self.m_pNetMsg:GetSeek()
    return v
end

function LTCPMsg:GetSize()
    local v = self.m_pNetMsg:GetCurLen()
    return v
end
function LTCPMsg:ReadUInt()
    local v = self.m_pNetMsg:ReadUInt()
    return v
end

function LTCPMsg:ReadInt()
    local v = self.m_pNetMsg:ReadInt()
    return v
end

function LTCPMsg:ReadByte()
    local v = self.m_pNetMsg:ReadByte()
    return v
end

function LTCPMsg:ReadWord()
    local v = self.m_pNetMsg:ReadWord()
    return v
end

function LTCPMsg:ReadUShort()
    local v = self.m_pNetMsg:ReadUShort()
    return v
end

function LTCPMsg:ReadShort()
    local v = self.m_pNetMsg:ReadShort()
    return v
end

function LTCPMsg:ReadULongInt()
    local v = self.m_pNetMsg:ReadULongInt()
    return v
end

function LTCPMsg:ReadDouble()
    local v = self.m_pNetMsg:ReadDouble()
    return v
end

function LTCPMsg:ReadFloat(size)
    local v = self.m_pNetMsg:ReadFloat(size)
    return v
end

function LTCPMsg:ReadString()
    local v = self.m_pNetMsg:ReadString()
    return v
end


function LTCPMsg:WriteByte(l_byte)
    self.m_pNetMsg:WriteByte(l_byte)
end

function LTCPMsg:WriteWord(v)
    self.m_pNetMsg:WriteWord(v)
end

function LTCPMsg:WriteUInt(v)
    self.m_pNetMsg:WriteUInt(v)
end

function LTCPMsg:WriteInt(v)
    self.m_pNetMsg:WriteUInt(v)
end

function LTCPMsg:WriteString(v)
    self.m_pNetMsg:WriteString(v)
end

function LTCPMsg:WriteUShort(v)
    self.m_pNetMsg:WriteUShort(v)
end

function LTCPMsg:Delete()
    self.m_pNetMsg:release()
    self.m_pNetMsg = nil
end


-- function LTCPMsg:ReadLong()
-- 	local v = self.m_pNetMsg:ReadLong()
--     return v
-- end

-- --[[
--     @功能：读取一个32位的整型
--     @return:int
-- ]]--
-- function LTCPMsg:ReadInt()

-- 	local v = self.m_pNetMsg:ReadInt()
--     return v
-- end

-- --[[
-- 读取浮点数
-- ]]
-- function LTCPMsg:ReadSingle()
--     local v = self.m_pNetMsg:ReadSingle()
--     return v
-- end

-- --[[
--     @功能：读取一个16位的整型（默认带符号）
--     @return:short
-- ]]--
-- function LTCPMsg:ReadShort()
--     local v = self.m_pNetMsg:ReadShort()
--     return v
-- end

-- --[[
--     @功能：读取一个无符号的16位的整型
--     @return:ushort
-- ]]--
-- function LTCPMsg:ReadUShort()
--     local v = self.m_pNetMsg:ReadUShort()
--     return v
-- end

-- --[[
-- 打印字节流
-- ]]
-- function LTCPMsg:PrintLog(ind)
--     self.m_pNetMsg:PrintLog(ind)
-- end

-- --[[
--     @功能：读取一个字节（默认带符号）
--     @return:byte
-- ]]--
-- function LTCPMsg:ReadByte()
--     local v = self.m_pNetMsg:ReadByte()
--     return v
-- end

-- --[[
--     @功能：读取一个字节数组（默认带两个字节长度）
--     @return:byte
-- ]]--
-- function LTCPMsg:ReadBytes()
-- 	local v = self.m_pNetMsg:ReadBytes()
--     return v
-- end

-- --[[
--     @功能：读取一个无符号的字节
--     @return:int
-- ]]--
-- function LTCPMsg:ReadUByte()
-- 	local v = self.m_pNetMsg:ReadUByte()
--     return v
-- end

-- --[[
--     @功能：读取一个字符串(默认UFT8)
--     @return:string
-- ]]--
-- function LTCPMsg:ReadString()
--     local v = self.m_pNetMsg:ReadString()
--     return v
-- end

-- --[[
-- 写入一个64位的整型
-- ]]
-- function LTCPMsg:WriteLong(v)
-- 	self.m_pNetMsg:WriteLong(v)
-- end

-- --[[
--     @功能：写入一个32位的整型
--     @param1:v(int)要写入的数据
--     @return:void
-- ]]--
-- function LTCPMsg:WriteInt(v)
-- 	self.m_pNetMsg:WriteInt(v)
-- end

-- --[[
--     @功能：写入一个32位的整型
--     @param1:v(int)要写入的数据
--     @return:void
-- ]]--
-- function LTCPMsg:WriteUInt(v)
-- 	self.m_pNetMsg:WriteUInt(v)
-- end

-- --[[
--     @功能：写入一个16位的整型（默认带符号）
--     @param1:v(short)要写入的数据
--     @return:void
-- ]]--
-- function LTCPMsg:WriteShort(v)
-- 	self.m_pNetMsg:WriteShort(v)
-- end

-- --[[
--     @功能：写入一个无符号的16位的整型
--     @param1:v(ushort)要写入的数据
--     @return:void
-- ]]--
-- function LTCPMsg:WriteUShort(v)
-- 	self.m_pNetMsg:WriteUShort(v)
-- end

-- --[[
--     @功能：写入一个字节
--     @param1:v(byte)要写入的数据
--     @return:void
-- ]]--
-- function LTCPMsg:WriteByte(v)
-- 	self.m_pNetMsg:WriteByte(v)
-- end

-- --[[
--     @功能：写入一个字节数组
--     @param1:v(byte[])要写入的数据
--     @return:void
-- ]]--
-- function LTCPMsg:WriteBytes(v)
-- 	self.m_pNetMsg:WriteBytes(v)
-- end

-- --[[
--     @功能：写入一个字符串(默认UFT8)
--     @param1:str(string)要写入的数据
--     @return:void
-- ]]--
-- function LTCPMsg:WriteString(str)
-- 	self.m_pNetMsg:WriteString(str)
-- end
