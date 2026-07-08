--ÁÄÌìÊý¾Ý
LChatMsgNode = {}
LChatMsgNode.__index = LChatMsgNode

function LChatMsgNode:New()
	local o = {}
	setmetatable(o,LChatMsgNode)	
	o:Init()
	return o
end

function LChatMsgNode:Init()
	self.id = 0
    self.chanel = 0;
    self.roleId = 0;
    self.vipLevel = 0;
    self.head = 0;
    self.sex = 0;
    self.roleName = "";
    self.chatContent = "";
end

function LChatMsgNode:DecodeFromServer(channel, stream)
	self.chanel = channel;
	self.roleId = stream:ReadUInt();
	self.roleName = stream:ReadString();
	self.vipLevel = stream:ReadByte();
	self.head = stream:ReadByte();--头像
	self.sex = stream:ReadByte();
	self.chatContent = stream:ReadString();
end

function LChatMsgNode:Delete()
	self.id = nil
    self.chanel = nil;
    self.roleId = nil;
    self.vipLevel = nil;
    self.head = nil;
    self.sex = nil;
    self.roleName = nil;
    self.chatContent = nil;
end


--Ë½ÁÄÊý¾Ý
LPcChatMsg = {}
LPcChatMsg.__index = LPcChatMsg
function LPcChatMsg:New()
	local o = {}
	setmetatable(o,LPcChatMsg)	
	o:Init()
	return o
end

function LPcChatMsg:Init()
    self.sendId = 0;
	self.sendTeamId = 0;
	self.sendFactionId = 0;
	self.revId = 0;
	self.sendProf = 0;--ÃÅÅÉ
	self.sendSex = 0;--ÐÔ±ð
	self.sendLv = 0;--µÈ¼¶
	self.sendVip = 0;
	self.sendName = "";
	self.time = 0;
	self.msg = "";
end

function LPcChatMsg:Delete()
    self.sendId = nil;
	self.sendTeamId = nil;
	self.sendFactionId = nil;
	self.revId = nil;
	self.sendProf = nil;--ÃÅÅÉ
	self.sendSex = nil;--ÐÔ±ð
	self.sendLv = nil;--µÈ¼¶
	self.sendVip = nil;
	self.sendName = nil;
	self.time = nil;
	self.msg = nil;
end


