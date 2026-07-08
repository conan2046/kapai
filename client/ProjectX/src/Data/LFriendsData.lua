--好友信息
LFriendsData = {}
LFriendsData.__index = LFriendsData

function LFriendsData:New()
	local o = {}
	setmetatable(o,LFriendsData)	
	o:Init()
	return o
end

function LFriendsData:Init()
    self:Reset();
end

function LFriendsData:Reset()
    self.id = 0
    self.head = 0
	self.name = ""			        --名称
    self.sex = 0                   --0男1女
	self.level = 0			        --等级
	self.fightPower= 0             --战斗力
	self.bpId = 0--帮派id
	self.bpName = ""--帮派名字
    self.optVal = 0	            --友好度//亲密度//仇恨度//师徒位阶
	self.mapId = 0			        --地图ID及位置
	self.teamId = 0		        --队伍ID
	-- self.factionId = 0		        --帮派Id
	self.roleType = -1		        --0师傅 丈夫 1 徒弟 妻子 -1陌生人
	self.pupilNum = 0		        --可收徒数量
	self.MaxExp = 1			    --最大经验
	self.CurExp = 0			    --当前经验
	self.qingMiDu = 0              --鲜花系统亲密度
	self.sendFlag = 0--0为赠送，1已赠送
	self.offSecond = 0;
	self.msgUread = false		    --未读信息
--	vector<PcChatMsg> msgList--私聊信息
    self.msgList = {} --私聊信息
--	vector<int> isShow		        --是否有奖励可领
    self.isShow = {}                --是否有奖励可领
end

function LFriendsData:DecodeFromServer(stream)
	--[[
	op=1    num   { roleId  roleName  level   sex   head   power  offSecond  bangpaiId  bangpaiName  qinmi  isSend }
	1byte  1byte    4byte    string   2byte  1byte  1byte  4byte    4byte      4byte      string     4byte   1byte
	]]
	self.id = stream:ReadUInt();
	self.name = stream:ReadString();			        --名称
	self.level = stream:ReadWord();			        --等级
    self.sex = stream:ReadByte();                   --0男1女
	self.head = stream:ReadByte();
	self.fightPower= stream:ReadULongInt();             --战斗力
	self.offSecond = stream:ReadUInt();
	self.bpId = stream:ReadUInt();--帮派id
	self.bpName = stream:ReadString();--帮派名字
	self.qingmi = stream:ReadUInt();
	self.sendFlag = stream:ReadByte();--0为赠送，1已赠送
end

function LFriendsData:isGiftSended()
	if self.sendFlag == 0 then
		return false
	end
	return true
end

function LFriendsData:DecodeApplyDataFromServer(stream)
	--[[
		op=2    num   { roleId  roleName  level   sex   head   power  offSecond  bangpaiId  bangpaiName  }
		1byte  1byte    4byte    string   2byte  1byte  1byte  4byte    4byte      4byte      string
	]]
	self.id = stream:ReadUInt();
	self.name = stream:ReadString();			        --名称
	self.level = stream:ReadWord();			        --等级
    self.sex = stream:ReadByte();                   --0男1女
	self.head = stream:ReadByte();
	self.fightPower= stream:ReadULongInt();             --战斗力
	self.offSecond = stream:ReadUInt();
	self.bpId = stream:ReadUInt();--帮派id
	self.bpName = stream:ReadString();--帮派名字
end

function LFriendsData:DecodeBlackDataFromServer(stream)
	--[[
		op=12  maxNum   num   { roleId  roleName  level   sex   head   power  offSecond  bangpaiId  bangpaiName  }
		1byte  1byte   1byte    4byte    string   2byte  1byte  1byte  4byte    4byte      4byte      string
	]]
	self.id = stream:ReadUInt();
	self.name = stream:ReadString();			        --名称
	self.level = stream:ReadWord();			        --等级
    self.sex = stream:ReadByte();                   --0男1女
	self.head = stream:ReadByte();
	self.fightPower= stream:ReadULongInt();             --战斗力
	self.offSecond = stream:ReadUInt();
	self.bpId = stream:ReadUInt();--帮派id
	self.bpName = stream:ReadString();--帮派名字
end

function LFriendsData:Delete()
    self.id = nil
	self.name = nil			    --名称
    self.sex = nil                 --0男1女
	self.level = nil			    --等级
	self.fightPower= nil           --战斗力
	self.prof = nil			    --门派
	self.profession = nil	        --职业
    self.optVal = nil	            --友好度//亲密度//仇恨度//师徒位阶
	self.mapId = nil			    --地图ID及位置
	self.teamId = nil		        --队伍ID
	self.factionId = nil		    --帮派Id
	self.roleType = nil		    --0师傅 丈夫 1 徒弟 妻子 -1陌生人
	self.pupilNum = nil		    --可收徒数量
	self.MaxExp = nil			    --最大经验
	self.CurExp = nil			    --当前经验
	self.qingMiDu = nil            --鲜花系统亲密度

	self.msgUread = nil		    --未读信息
--	vector<PcChatMsg> msgList--私聊信息
    self.msgList = nil              --私聊信息
--	vector<int> isShow		         --是否有奖励可领
    self.isShow = nil --是否有奖励可领
end