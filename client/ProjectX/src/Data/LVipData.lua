
--[[
Vip及月卡礼包结构
]]
LMCAwardInfo = {}
LMCAwardInfo.__index = LMCAwardInfo
function LMCAwardInfo:New()
    local o = {}
    setmetatable(o,LMCAwardInfo)    
    o:ctor()
    return o
end

function LMCAwardInfo:ctor(id)
    self.CardPrice = 0            --礼包价格（vip对应最少充值数量）
    self.AwardPerDay = 0          --每天领取的奖励
    self.AwardId = {}             --奖励物品id
    self.AwardNum = {}            --奖励数量
    self.AwardPet = {}            --奖励宠物 
    self.Vipright = {}            --奖励权限
    self.mcAwardInfo = {}         --月卡信息
end

function LMCAwardInfo:Delete()
    self.CardPrice = nil
    self.AwardPerDay = nil
    self.AwardId = nil
    self.AwardNum = nil
    self.AwardPet = nil
    self.Vipright = nil
    self.AwardPetEquip=nil
    self.mcAwardInfo = nil
end

function LMCAwardInfo:getAwardValue(type)
    -- body
    for i=1, #self.mcAwardInfo do
        local data = self.mcAwardInfo[i]
        if data.mcType == type then
            return data.awardPerValue
        end
    end
    return 100
end

function LMCAwardInfo:getMcAwardData( type )
    -- body
    for i=1, #self.mcAwardInfo do
        local data = self.mcAwardInfo[i]
        if data.mcType == type then
            return data
        end
    end
    return nil
end

LVIPDataInfo = {}
LVIPDataInfo.__index = LVIPDataInfo
function LVIPDataInfo:New()
    local o = {}
    setmetatable(o,LVIPDataInfo)    
    o:ctor()
    return o
end

function LVIPDataInfo:ctor()
    self.vipLevel = 0          --vip等级
    self.vipMoney = 0          --累计充值数量
    self.mcLeftTime = 0        --月卡权限剩余时间
    self.mcType = 0            --是否有月卡权现
    self.mcGiftState = 0       --月卡礼包是否领取
    self.mcGiftMonState = 0    --月卡元宝是否领取
    self.mcGiftMoneyCount = 0  --vip元宝数量
    self.mcLifeGiftMonState = 0 --终身月卡领取状态（0 未领取, 1 已领取
    self.totalRecharge = 0 --累计充值
end

function LVIPDataInfo:Reset()
    self.vipLevel = 0          --vip等级
    self.vipMoney = 0          --累计充值数量
    self.mcLeftTime = 0        --月卡权限剩余时间
    self.mcType = 0            --是否有月卡权现
    self.mcGiftState = 0       --月卡礼包是否领取
    self.mcGiftMonState = 0    --月卡元宝是否领取
    self.mcGiftMoneyCount = 0  --vip元宝数量
    self.mcLifeGiftMonState = 0
    self.isHasLmCard = false --是否有终生月卡
    self.isHasMcCard = false --是否有月卡
    self.isHasMcCardTemp = false --是否月临时月卡
end

function LVIPDataInfo:Delete()
    self.vipLevel = nil
    self.vipMoney = nil
    self.mcLeftTime = nil
    self.mcType = nil
    self.mcGiftState = nil
    self.mcGiftMonState = nil
    self.mcGiftMoneyCount = nil
end

LPrivilegeCard = {}
LPrivilegeCard.__index = LPrivilegeCard
function LPrivilegeCard:New()
    local o = {}
    setmetatable(o,LPrivilegeCard)    
    o:ctor()
    return o
end

function LPrivilegeCard:ctor(id)
    self.id = {}
    self.price = {}
    self.isHave = {}
    self.leftTime = {}
    self.time = ""
    self.canGet = 0
    self.yuanbao = 0
end

function LPrivilegeCard:Delete()
    self.id = nil
    self.price = nil
    self.isHave = nil
    self.leftTime = nil
    self.time = nil
    self.canGet = nil
    self.yuanbao = nil
end

--[[
神秘商店物品信息
]]
LSMItemInfo = {}
LSMItemInfo.__index = LSMItemInfo
function LSMItemInfo:New()
    local o = {}
    setmetatable(o,LSMItemInfo)    
    o:ctor()
    return o
end

function LSMItemInfo:ctor(id)
    self.id = 0
    self.itemId = 0
    self.itemNum = 0
    self.vipLimit = 0  --开启所需vip等级等于0已开启
    self.price = 0
end

function LSMItemInfo:Delete()
    self.id = nil
    self.itemId = nil
    self.itemNum = nil
    self.vipLimit = nil
    self.price = nil
end

--[[
神秘商店信息po
]]
LShopMysteryInfo = {}
LShopMysteryInfo.__index = LShopMysteryInfo
function LShopMysteryInfo:New()
    local o = {}
    setmetatable(o,LShopMysteryInfo)    
    o:ctor()
    return o
end

function LShopMysteryInfo:ctor(id)
    self.time = 0
    self.num = 0
    self.ItemData = {}
    self.logMegNum = 0
    self.logMeg = {}
end

function LShopMysteryInfo:Delete()
    self.time = nil
    self.num = nil
    self.ItemData = nil
    self.logMegNum = nil
    self.logMeg = nil
end

--[[
神秘商店信息po
]]
LPayPricelist = {}
LPayPricelist.__index = LPayPricelist
function LPayPricelist:New()
    local o = {}
    setmetatable(o,LPayPricelist)    
    o:ctor()
    return o
end

function LPayPricelist:ctor(id)
    self.type = 0
    self.index = 0
    self.picId = 0
    self.chongzhi = 0
    self.fanli = 0
    self.showDouble = 0 --1可首充，0首充过了
    self.itemId = 0
    self.itemNum = 0
end

function LPayPricelist:Delete()
    self.type = nil
    self.index = nil
    self.picId = 0
    self.chongzhi = nil
    self.fanli = nil
    self.showDouble = nil
    self.itemId = nil
    self.itemNum = nil
end

