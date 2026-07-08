--翅膀配置
LWingConfig = {}
LWingConfig.__index = LWingConfig
function LWingConfig:New()
    local o = {}
    setmetatable(o,LWingConfig)    
    o:ctor()
    return o
end

function LWingConfig:ctor()
    self.id = 0          --id
    self.name = ""       --名称
    self.getWay = 0      --获得方式
    self.needItem = 0    --需要的物品
    self.needNum = 0     --需要的数量
    self.desc = ""      --获取方式描述
    self.attrs = {}      --属性
end

function LWingConfig:Delete()
    self.id = nil
    self.name = nil
    self.getWay = nil
    self.needItem = nil
    self.needNum = nil
    self.desc = nil
    self.attrs = nil
end

--翅膀强化信息
LWingStar = {}
LWingStar.__index = LWingStar
function LWingStar:New()
    local o = {}
    setmetatable(o,LWingStar)    
    o:ctor()
    return o
end

function LWingStar:ctor()
    self.star = 0          --id
    self.needExp = 0       --需要经验
    self.attrs = {}        --属性
end

function LWingStar:Delete()
    self.star = nil
    self.needExp = nil
    self.attrs = nil
end

--翅膀强化信息
LWingDevelop = {}
LWingDevelop.__index = LWingDevelop
function LWingDevelop:New()
    local o = {}
    setmetatable(o,LWingDevelop)    
    o:ctor()
    return o
end

function LWingDevelop:ctor()
    self.level = 0          --id
    self.stars = {}
end

function LWingDevelop:Delete()
    self.level = nil
    self.stars = nil
end

--翅膀信息
LChiBangData = {}
LChiBangData.__index = LChiBangData
function LChiBangData:New()
    local o = {}
    setmetatable(o,LChiBangData)    
    o:ctor()
    return o
end

function LChiBangData:ctor()
    self.id = 0        --id
    self.basicAttack = 0      --攻击
    self.basicRecovery = 0  --基础防御
    self.basicHP = 0        --基础气血
    self.basicSpeed = 0     --速度加成
    self.basicShanBi = 0    --闪避
    self.basicMingZhong = 0  --命中
    self.basicBaoJi = 0      --暴击
    self.basicRenXing = 0    --韧性
    self.basicFanShang = 0   --反伤
    self.basicJianShang = 0  --减伤
end
function LChiBangData:Delete()
    self.id = nil        --id
    self.basicAttack = nil      --攻击
    self.basicRecovery = nil  --基础防御
    self.basicHP = nil        --基础气血
    self.basicSpeed = nil     --速度加成
    self.basicShanBi = nil    --闪避
    self.basicMingZhong = nil  --命中
    self.basicBaoJi = nil      --暴击
    self.basicRenXing = nil    --韧性
    self.basicFanShang = nil   --反伤
    self.basicJianShang = nil  --减伤
end
function LChiBangData:GetId()  return id end        --id
function LChiBangData:GetBasicAttack()   return basicAttack end      --攻击
function LChiBangData:GetBasicRecovery()   return basicRecovery end  --基础防御
function LChiBangData:GetBasicHP()   return basicHP end        --基础气血
function LChiBangData:GetBasicSpeed()   return basicSpeed end     --速度加成
function LChiBangData:GetBasicShanBi()   return basicShanBi end    --闪避
function LChiBangData:GetBasicMimgZhong()   return basicMingZhong end  --命中
function LChiBangData:GetBasicBaoJi()   return basicBaoJi end      --暴击
function LChiBangData:GetBasicRenXing()   return basicRenXing end    --韧性
function LChiBangData:GetBasicFanShang()   return basicFanShang end   --反伤
function LChiBangData:GetBasicJianShang()   return basicJianShang end  --减伤

LChiBangOtherInfo = {}
LChiBangOtherInfo.__index = LChiBangOtherInfo
function LChiBangOtherInfo:New()
    local o = {}
    setmetatable(o,LChiBangOtherInfo)    
    o:ctor()
    return o
end

function LChiBangOtherInfo:ctor()
    self.useIndex = 0xff
    self.Level = 0
    self.MaxLevel = 0
    self.Star = 0
    self.Exp = 0

    self.srcID = 0     --当前最高可进阶翅膀ID， =0为没有可进阶翅膀
    self.targetID = 0  --下阶ID  =0为最高阶
    self.curAttack = 0
    self.curRecovery = 0
    self.curHP = 0
    self.curSpeed = 0
    self.nextAttack = 0
    self.nextRecovery = 0
    self.nextHP = 0
    self.nextSpeed = 0
    self.LimitExp = 0

    self.fightPower = 0
    self.attrs = {}
end

function LChiBangOtherInfo:Reset()
    self.useIndex = 0xff
    self.Level = 0
    self.MaxLevel = 0
    self.Star = 0
    self.Exp = 0

    self.srcID = 0     --当前最高可进阶翅膀ID， =0为没有可进阶翅膀
    self.targetID = 0  --下阶ID  =0为最高阶
    self.curAttack = 0
    self.curRecovery = 0
    self.curHP = 0
    self.curSpeed = 0
    self.nextAttack = 0
    self.nextRecovery = 0
    self.nextHP = 0
    self.nextSpeed = 0
    self.LimitExp = 0

    self.fightPower = 0
    self.attrs = {}
end
function LChiBangOtherInfo:Delete()
    self.useIndex = nil
    self.Level = nil
    self.MaxLevel = nil
    self.Star = nil
    self.Exp = nil

    self.srcID = nil     --当前最高可进阶翅膀ID， =nil为没有可进阶翅膀
    self.targetID = nil  --下阶ID  =nil为最高阶
    self.curAttack = nil
    self.curRecovery = nil
    self.curHP = nil
    self.curSpeed = nil
    self.nextAttack = nil
    self.nextRecovery = nil
    self.nextHP = nil
    self.nextSpeed = nil
    self.LimitExp = nil

    self.fightPower = nil
    self.attrs = nil
end
function LChiBangOtherInfo:GetUseIndex()  return self.useIndex end
function LChiBangOtherInfo:GetqhLevel() return self.Level end
function LChiBangOtherInfo:GetMaxLevel()  return self.MaxLevel end
function LChiBangOtherInfo:GetqhStar() return self.Star end
function LChiBangOtherInfo:GetqhExp()  return self.Exp end

function LChiBangOtherInfo:GetSrcID()  return self.srcID end    --当前最高可进阶翅膀ID， =0为没有可进阶翅膀
function LChiBangOtherInfo:GetTargetID()  return self.targetID end --下阶ID  =0为最高阶
function LChiBangOtherInfo:GetCurAttack()  return self.curAttack end
function LChiBangOtherInfo:GetCurRecovery()  return self.curRecovery end
function LChiBangOtherInfo:GetCurHP()  return self.curHP end
function LChiBangOtherInfo:GetCurSpeed()  return self.curSpeed end
function LChiBangOtherInfo:GetNextAttack()  return self.nextAttack end
function LChiBangOtherInfo:GetNextRecovery()  return self.nextRecovery end
function LChiBangOtherInfo:GetNextHP()  return self.nextHP end
function LChiBangOtherInfo:GetNextSpeed()  return self.nextSpeed end
function LChiBangOtherInfo:GetLimitExp()  return self.LimitExp end

function LChiBangOtherInfo:GetFightPower() return self.fightPower end
function LChiBangOtherInfo:GetTotalAttack()  return self.totalAttack end      --攻击
function LChiBangOtherInfo:GetTotalRecovery()  return self.totalRecovery end  --基础防御
function LChiBangOtherInfo:GetTotalHP()  return self.totalHP end        --基础气血
function LChiBangOtherInfo:GetTotalSpeed()  return self.totalSpeed end     --速度加成
function LChiBangOtherInfo:GetTotalShanBi()  return self.totalShanBi end    --闪避
function LChiBangOtherInfo:GetTotalMimgZhong()  return self.totalMingZhong end  --命中
function LChiBangOtherInfo:GetTotalBaoJi()  return self.totalBaoJi end      --暴击
function LChiBangOtherInfo:GetTotalRenXing()  return self.totalRenXing end    --韧性
function LChiBangOtherInfo:GetTotalFanShang()  return self.totalFanShang end   --反伤
function LChiBangOtherInfo:GetTotalJianShang()  return self.totalJianShang end  --减伤


LServerChiBang = {}
LServerChiBang.__index = LServerChiBang
function LServerChiBang:New()
    local o = {}
    setmetatable(o,LServerChiBang)    
    o:ctor()
    return o
end

function LServerChiBang:ctor()
    self.id = 0        --id
    self.IsGet = false           --是否获得
    self.name = ""      --翅膀名字
    self.desc = ""      --获取条件
    self.getWay = 0    --0进阶获取或直接购买，1元宝购买，2道具兑换
    self.exValue = 0   --元宝数或道具兑换数
    self.exItemId = 0  --道具物品ID（兑换用）
    self.basicAttack = 0      --攻击
    self.basicRecovery = 0  --基础防御
    self.basicHP = 0        --基础气血
    self.basicSpeed = 0     --速度加成
    self.basicShanBi = 0    --闪避
    self.basicMingZhong = 0  --命中
    self.basicBaoJi = 0      --暴击
    self.basicRenXing = 0    --韧性
    self.basicFanShang = 0   --反伤
    self.basicJianShang = 0  --减伤
    self.basicZhandouli = 0  --战斗力
end
function LServerChiBang:Delete()
    self.id = nil        --id
    self.IsGet = nil           --是否获得
    self.name = nil      --翅膀名字
    self.desc = nil      --获取条件
    self.getWay = nil    --nil进阶获取或直接购买，1元宝购买，2道具兑换
    self.exValue = nil   --元宝数或道具兑换数
    self.exItemId = nil  --道具物品ID（兑换用）
    self.basicAttack = nil      --攻击
    self.basicRecovery = nil  --基础防御
    self.basicHP = nil        --基础气血
    self.basicSpeed = nil     --速度加成
    self.basicShanBi = nil    --闪避
    self.basicMingZhong = nil  --命中
    self.basicBaoJi = nil      --暴击
    self.basicRenXing = nil    --韧性
    self.basicFanShang = nil   --反伤
    self.basicJianShang = nil  --减伤
    self.basicZhandouli = nil  --战斗力
end
function LServerChiBang:GetId()  return self.id end        --id
function LServerChiBang:CheckIsGet()  return self.IsGet end
function LServerChiBang:GetName()   return self.name end
function LServerChiBang:GetDesc()   return self.desc end
function LServerChiBang:GetgetWay()   return self.getWay end
function LServerChiBang:GetExValue()   return self.exValue end
function LServerChiBang:GetExItemId()   return self.exItemId end
function LServerChiBang:GetBasicAttack()   return self.basicAttack end      --攻击
function LServerChiBang:GetBasicRecovery()   return self.basicRecovery end  --基础防御
function LServerChiBang:GetBasicHP()   return self.basicHP end        --基础气血
function LServerChiBang:GetBasicSpeed()   return self.basicSpeed end     --速度加成
function LServerChiBang:GetBasicShanBi()   return self.basicShanBi end    --闪避
function LServerChiBang:GetBasicMimgZhong()   return self.basicMingZhong end  --命中
function LServerChiBang:GetBasicBaoJi()   return self.basicBaoJi end      --暴击
function LServerChiBang:GetBasicRenXing()   return self.basicRenXing end    --韧性
function LServerChiBang:GetBasicFanShang()   return self.basicFanShang end   --反伤
function LServerChiBang:GetBasicJianShang()   return self.basicJianShang end  --减伤
function LServerChiBang:GetBasicZhandouli()   return self.basicZhandouli end  --zhandouli