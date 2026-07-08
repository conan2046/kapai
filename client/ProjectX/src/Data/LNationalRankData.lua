LNationalRankData = {}
LNationalRankData.__index = LNationalRankData
function LNationalRankData:New()
	local o = {}
	setmetatable(o, LNationalRankData )	
	o:ctor()
	return o
end

function LNationalRankData:ctor()
    self.roleID = 0          --roleID
    self.name = ""       --名字
    self.professor = 0
    self.vip = 0
    self.score = 0
    self.itemInfo = {}
end

function LNationalRankData:Delete(id)
    self.roleID = nil
    self.name = nil
    self.professor = nil
    self.vip = nil
    self.score = nil
    self.itemInfo = nil
end



LXianhuaShopData = {}
LXianhuaShopData.__index = LXianhuaShopData
function LXianhuaShopData:New()
    local o = {}
    setmetatable(o, LXianhuaShopData ) 
    o:ctor()
    return o
end

function LXianhuaShopData:ctor()
    self.type = 1           --1、鲜花商店类型 2、国庆送礼类型
    self.id = 0         --roleID
    self.num = 0         --数量
    self.buy_type = 0       --
    self.price = 0
    self.sendScore = 0
    self.getScore = 0       --奖励ID
    self.qinmi = 0
    self.meili = 0
end

function LXianhuaShopData:Delete(id)
    self.type = nil           --1、鲜花商店类型 2、国庆送礼类型
    self.id = nil         --roleID
    self.num = nil         --数量
    self.buy_type = nil       --
    self.price = nil
    self.sendScore = nil
    self.getScore = nil       --奖励ID
    self.qinmi = 0
    self.meili = 0
end


