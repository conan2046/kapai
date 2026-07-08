LServerHeroInfo = {}
LServerHeroInfo.__index = LServerHeroInfo
function LServerHeroInfo:New()
	local o = {}
	setmetatable(o,LServerHeroInfo)	
    
	o:Init()
	return o
end

function LServerHeroInfo:Init()
	self.id = -1
	self.sex = -1
	self.head = -1
	self.level = -1
	self.name = nil
end

function LServerHeroInfo:Delete()
	self.id = nil
	self.sex = nil
	self.head = nil
	self.level = nil
	self.name = nil
end

--服务器列表
LServerInfo = {}
LServerInfo.__index = LServerInfo
function LServerInfo:New()
	local o = {}
	setmetatable(o,LServerInfo)	
    
	o:Init()
	return o
end

function LServerInfo:Init()
	self.id = -1
	self.page = -1
	self.serId = -1
	self.serName = ""
	self.serIp = ""
	self.serPort = -1
	self.errMsg = ""--消息
	self.serType = -1--0正常 1推荐 2新服
	self.onlineState = -1--0绿 1黄 2红
	self.serState = -1--0正常 1维护中
	self.serPic = -1--服务器名称图片ID
	self.needLineUp = false--是否需要排队
	self.lineUpIp = ""--排队服ip
	self.lineUpPort = -1--排队服端口
end

function LServerInfo:Delete()
	self.id = nil
	self.page = nil
	self.serId = nil
	self.serName = nil
	self.serIp = nil
	self.serPort = nil
	self.errMsg = nil--消息
	self.serType = nil--0正常 1推荐 2新服
	self.onlineState = nil--0绿 1黄 2红
	self.serState = nil--0正常 1维护中
	self.serPic = nil--服务器名称图片ID
	self.needLineUp = nil--是否需要排队
	self.lineUpIp = nil--排队服ip
	self.lineUpPort = nil--排队服端口
end

LUserAccount = {}
LUserAccount.__index = LUserAccount
function LUserAccount:New()
	local o = {}
	setmetatable(o,LUserAccount)	
    
	o:Init()
	return o
end

function LUserAccount:Init()
	self:Reset()
end

function LUserAccount:Reset()
	self.Account = ""
	self.Password = ""
end

--账号显示信息
LAccountData = {}
LAccountData.__index = LAccountData
function LAccountData:New()
	local o = {}
	setmetatable(o,LAccountData)	
    
	o:Init()
	return o
end

function LAccountData:Init()
	self:Reset()
end

function LAccountData:Reset()
	self.userid = 0
	self.roleid = 0
	self.name = ""
	self.head = 0--头像
	self.professional = 0--职业
	self.level = 0
	self.sex = 0
	self.type = 0--服务器类型 1跨服0非跨服
end



LCAccount = {}
LCAccount.__index = LCAccount
function LCAccount:New()
	local o = {}
	setmetatable(o,LCAccount)	
    
	o:Init()
	return o
end

function LCAccount:Init()
	self.serverList = {}
    self.serverHeroInfo = {}
	self.userAccount = LUserAccount:New()
	self.m_AccountData = LAccountData:New()--我的账号显示信息
    self.selServer = -1
    self.uid = -1--登陆数据
    self.sid = ""
	self.accountID = ""--平台账号ID
	self.expires_in = ""--token有效期
	self.access_token = ""--平台token
	self.refresh_token = ""
	self.isBindPhone = 0--是否绑定手机
	self.phoneNum = ""--绑定手机号码
	self.isRealName = 0--是否实名
	self.getCheckNumTime = 0
	self.imie = ""
	self.serverTime = 0
	self.isSortExchangeList = 0
	self.chatNextTime = 0
end

function LCAccount:Reset()
--	for i = #self.serverList, 1 -1 do
--		self.serverList[i]:Delete()
--		self.serverList[i] = nil
--	end
	-- self.serverList = {}
	-- -- for i = #self.serverHeroInfo, 1 -1 do
	-- -- 	self.serverHeroInfo[i]:Delete()
	-- -- 	self.serverHeroInfo[i] = nil
	-- -- end
 --    self.serverHeroInfo = {}
	-- self.userAccount:Reset()
	-- self.m_AccountData:Reset()
 --    self.selServer = -1
 --    self.uid = -1--登陆数据
 --    self.sid = ""
	-- self.accountID = ""--平台账号ID
	-- self.expires_in = ""--token有效期
	-- self.access_token = ""--平台token
	-- self.refresh_token = ""
	-- self.isBindPhone = 0--是否绑定手机
	-- self.phoneNum = ""--绑定手机号码
	-- self.isRealName = 0--是否实名
	-- self.getCheckNumTime = 0
	-- self.imie = ""
	-- self.serverTime = 0
	-- self.isSortExchangeList = 0
	-- self.chatNextTime = 0
end

function LCAccount:DeleteServerHeroInfo()
	for i = #self.serverHeroInfo,1,-1 do
		self.serverHeroInfo[i]:Delete()
	end
	self.serverHeroInfo = {}
end

function LCAccount:GetServerHeroInfo(serverId)
	for i = 1,#self.serverHeroInfo do
		if serverId == self.serverHeroInfo[i].id then
			return self.serverHeroInfo[i]
		end
	end
	return nil
end

function LCAccount:IsFindHero(serverId)
	for i = 1,#self.serverHeroInfo do
		if serverId == self.serverHeroInfo[i].id then
			return i
		end
	end
	return 0
end

function LCAccount:UpdateServerHeroList(info)
	local index = self:IsFindHero(info.id)
	if index > 0 then
		self.serverHeroInfo[index]:Delete()
		self.serverHeroInfo[index] = info
	else
		table.insert(self.serverHeroInfo, info)
	end
end

--是否在跨服中
function LCAccount:IsMultiServer()
	return self.m_AccountData.type == 1
end

function LCAccount:GetIsRealName()
	return self.isRealName
end

function LCAccount:GetIsBindPhone()
	return self.isBindPhone
end

function LCAccount:GetPhoneNum()
	return self.phoneNum
end