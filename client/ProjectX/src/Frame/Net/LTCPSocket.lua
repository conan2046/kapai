LTcpSocket = LNetBase:New()
LTcpSocket.__index = LTcpSocket
--local this = LTcpSocket
function LTcpSocket:New()
	local o = {}
	setmetatable(o,LTcpSocket)
	o:Awake()
	return o
end

function LTcpSocket:Awake()
	self.msgIds = 
	{
		LTCPEvent.LoginConnect,
		LTCPEvent.LoginDisConnect,
		LTCPEvent.LoginSendMsg,
		LTCPEvent.RecvMsg,

		LTCPEvent.GameConnect,
		LTCPEvent.GameDisConnect,
		LTCPEvent.GameSendMsg,
		LTCPEvent.RecvSession
	}

	self:RegistSelf(self,self.msgIds)
	self:InitCommonMsg()
end

--[[
初始化一些常用的消息缓存
]]
function LTcpSocket:InitCommonMsg()
	self.m_pSendMsg = TCPMsg:new()
	self.m_pSendMsg:retain()
end

--[[
发送登录服务器的消息
]]
function LTcpSocket:SendLoginLuaMsg(msg)
	--TCPMsg是C#里面的消息
	self.m_pSendMsg:ChangeLuaMsg(CEnum.TCPEvent.TcpLoginSendMsg, msg.m_pNetMsg)
	self:SendMsg(self.m_pSendMsg)
end

--[[
发送游戏服务器的消息
]]
function LTcpSocket:SendGameLuaMsg(msg)
	--TCPMsg是C#里面的消息
	self.m_pSendMsg:ChangeLuaMsg(CEnum.TCPEvent.TcpGameSendMsg, msg.m_pNetMsg)
	self:SendMsg(self.m_pSendMsg)
end

function LTcpSocket:ConnectLoginSocket(backid, ip, port)
	print("ConnectLoginSocket",backid, ip, port)
	local msg = TCPConnectMsg:new(CEnum.TCPEvent.TcpLoginConnect,backid, ip,port)
	self:SendMsg(msg)
end

function LTcpSocket:ConnectGameSocket(backid, ip, port)
	print("ConnectGameSocket")
	local msg = TCPConnectMsg:new(CEnum.TCPEvent.TcpGameConnect,backid, ip,port)
	self:SendMsg(msg)
end

function LTcpSocket:DisConnectGameSocket()
	local msg = MsgBase:new()
	msg:ChangeEventId(CEnum.TCPEvent.TcpGameDisConnect)
	self:SendMsg(msg)
end

function LTcpSocket:DisConnectLoginSocket()
	local msg = MsgBase:new()
	msg:ChangeEventId(CEnum.TCPEvent.TcpLoginDisConnect)
	self:SendMsg(msg)
end

function LTcpSocket:ProcessEvent(msg)
	--print("LTcpSocket:ProcessEvent")


	if msg.msgId == LTCPEvent.LoginConnect then
		self:ConnectLoginSocket(msg.backId, msg.ip, msg.port)
	elseif msg.msgId == LTCPEvent.LoginDisConnect then
		self:DisConnectLoginSocket(msg)
	elseif msg.msgId == LTCPEvent.LoginSendMsg then
		self:SendLoginLuaMsg(msg)
	elseif msg.msgId == LTCPEvent.GameConnect then
		self:ConnectGameSocket(msg.backId, msg.ip, msg.port)
	elseif msg.msgId == LTCPEvent.GameDisConnect then
		self:DisConnectGameSocket(msg)
	elseif msg.msgId == LTCPEvent.GameSendMsg then
		self:SendGameLuaMsg(msg)
	elseif msg.msgId == LTCPEvent.RecvMsg then
	elseif msg.msgId == LTCPEvent.RecvSession then
		
	end 
end

LTcpSocket:Awake()
